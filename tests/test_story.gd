extends BaseTest
## Hikâye (docs/gdd.md §10.5): açılış filminin sözleri iki dilde var ve film kutusunda en çok iki
## satıra sığar; her konuşanın portresi ve adı var; Gölün Bekçisi'nin yolu derin suda; film yalnızca
## yeni oyunda oynar; hikâyenin devamı (bölümler) sırayla ve birer kez anlatılır.

## Film kutusundaki sözün en çok satırı.
const MAX_LINES := 2


func test_intro_lines_exist_and_fit_two_lines() -> void:
	var rows := _csv_rows()
	var font := UiKit.body_font()
	var width := StoryPanel.text_width()
	assert_true(width > 900.0, "film kutusunda yazıya yer var (%.0f)" % width)
	for line: Array in Story.LINES:
		var key := str(line[0])
		assert_true(rows.has(key), "%s çevirisi var" % key)
		if not rows.has(key):
			continue
		for column in [1, 2]:
			var text: String = (rows[key] as PackedStringArray)[column]
			assert_true(not text.strip_edges().is_empty(), "%s (%s) boş değil" % [key, _lang(column)])
			var lines := _lines(font, text, width, StoryPanel.TEXT_SIZE)
			assert_true(lines <= MAX_LINES, "%s (%s) %d satır: %s" % [key, _lang(column), lines, text])
	for key: String in ["UI_INTRO_SKIP", "UI_INTRO_GIFT", "UI_STORY_DEDE", "UI_STORY_NINE"]:
		assert_true(rows.has(key), "%s çevirisi var" % key)


## Film yaklaşık bir dakika (iki dilde): logo ve sözlerin süreleri; Bekçi'nin geçişi uzun kalır.
func test_intro_length() -> void:
	var rows := _csv_rows()
	for column in [1, 2]:
		var total := StoryPanel.LOGO_TIME
		for i in Story.LINES.size():
			var key := str(Story.LINES[i][0])
			if rows.has(key):
				total += Story.line_time(i, (rows[key] as PackedStringArray)[column])
		assert_between(total, 40.0, 75.0, "filmin süresi (%s)" % _lang(column))
	for i in Story.LINES.size():
		if str(Story.LINES[i][2]) == "keeper":
			assert_true(Story.line_time(i, "") >= 6.0, "Bekçi'nin geçişi uzun kalır")


## Film bir kez: yeni oyunda oynar; görülünce ya da balık tutulmuş kayıtta (eski oyuncu) oynamaz.
func test_intro_only_in_a_new_game() -> void:
	var save := SaveData.create_new(1_700_000_000)
	assert_true(Story.wants_intro(save), "yeni oyunda film oynar")
	Story.mark_seen(save)
	assert_true(not Story.wants_intro(save), "görülen film yeniden oynamaz")
	var old := SaveData.create_new(1_700_000_000)
	old.catches = 4
	assert_true(not Story.wants_intro(old), "balık tutulmuş kayıtta film oynamaz")
	var restored := SaveData.from_dict(save.to_dict())
	assert_true(not Story.wants_intro(restored), "bayrak kayıtla saklanır")


## Sözlerin konuşanı Dede ya da Nine; adları ve portreleri var (portre yoksa kutuda yüz gizlenir,
## ama Ersin'in portreleri oyunda: her konuşanın her ifadesi test_moods'ta).
func test_intro_speakers_and_shots() -> void:
	var shots := ["nine", "dede", "lake", "reeds", "deep", "keeper", "dock", "gift"]
	var keeper := 0
	var gift := 0
	for line: Array in Story.LINES:
		var speaker := str(line[1])
		assert_true(StoryPanel.NAMES.has(speaker), "%s: konuşan bilinir (%s)" % [line[0], speaker])
		assert_true(str(line[2]) in shots, "%s: çekim bilinir (%s)" % [line[0], line[2]])
		assert_true(Moods.face(speaker, str(line[0])) != null, "%s: %s'nin yüzü var" % [line[0], speaker])
		keeper += 1 if str(line[2]) == "keeper" else 0
		gift += 1 if str(line[2]) == "gift" else 0
	assert_eq(keeper, 1, "Bekçi bir kez geçer")
	assert_eq(gift, 1, "hediye bir kez")
	assert_eq(str(Story.LINES[Story.LINES.size() - 1][2]), "gift", "film hediyeyle biter")
	assert_eq(str(Story.LINES[0][1]), "nine", "ilk sözü Nine söyler (karşılama)")


## Bekçi'nin yolu derin ortada: her noktası suda ve en az KEEPER_DEPTH derinlikte; ekranı soldan
## sağa geçer (kameranın yatay açısına göre; derin suda kalsın diye en çok 60° döner).
func test_keeper_path_in_deep_water() -> void:
	var db := content()
	var across := Vector2(cos(FollowCamera.YAW), -sin(FollowCamera.YAW))
	var path := Story.keeper_path(db, db.main_spot, across)
	assert_true(path.size() >= 2, "yol var (%d nokta)" % path.size())
	if path.size() < 2:
		return
	var lake := db.lake(db.main_spot)
	var shallow := 99.0
	for p in path:
		assert_true(lake.is_water(p), "yol suda: %s" % str(p))
		shallow = minf(shallow, lake.depth_at(p))
	assert_true(shallow >= Story.KEEPER_DEPTH, "yolun en sığ yeri %.1f m (en az %.1f)" % [shallow, Story.KEEPER_DEPTH])
	var span := path[path.size() - 1] - path[0]
	assert_between(span.length(), Story.KEEPER_SPAN * 0.95, Story.KEEPER_SPAN * 1.05, "yolun boyu")
	assert_true(span.normalized().dot(across) >= cos(deg_to_rad(60.5)), "ekranın sağına doğru")
	# Sandal bölgesi yoksa (testlerin gölü) yol boş: film göl çekimine düşer.
	assert_eq(Story.keeper_path(db, "home_lake", across).size(), 0, "sandal bölgesi yoksa yol yok")


## Hikâyenin devamı: rütbesi gelen bölüm sırayla (atlanan rütbelerde en eskisi önce) ve birer kez.
func test_chapters_in_order_once() -> void:
	var save := SaveData.create_new(1_700_000_000)
	assert_eq(Story.next_chapter(2, save), 0, "rütbe 2'de bölüm yok")
	assert_eq(Story.next_chapter(3, save), 3, "rütbe 3'te ilk bölüm")
	assert_eq(Story.tell(3, save), "UI_DEDE_STORY_3", "ilk bölümün sözü")
	assert_eq(Story.next_chapter(3, save), 0, "anlatılan bölüm yinelenmez")
	assert_eq(Story.next_chapter(11, save), 6, "atlanan rütbelerde en eskisi önce")
	Story.tell(6, save)
	assert_eq(Story.next_chapter(11, save), 10, "sonra sıradaki")
	Story.tell(10, save)
	assert_eq(Story.next_chapter(11, save), 0, "rütbesi gelmeyen bölüm beklenir")
	var restored := SaveData.from_dict(save.to_dict())
	assert_eq(Story.next_chapter(20, restored), 15, "anlatılanlar kayıtla saklanır")
	var rows := _csv_rows()
	var ranks := content().max_rank()
	for rank: int in Story.CHAPTERS:
		var key := str(Story.CHAPTERS[rank])
		assert_true(rows.has(key), "%s çevirisi var" % key)
		assert_true(rank <= ranks, "bölümün rütbesi (%d) oyunda var (en çok %d)" % [rank, ranks])
		assert_eq(Moods.of(key), Moods.STORY, "%s: Dede anlatır" % key)


## Bitiş filminin sözleri iki dilde var, film kutusunda en çok iki satıra sığar; konuşanlar ve çekimler
## bilinir; Bekçi'nin turuyla başlar, gölün geniş çekimiyle biter; Bekçi'nin turu uzun kalır.
func test_ending_lines_exist_and_fit_two_lines() -> void:
	var rows := _csv_rows()
	var font := UiKit.body_font()
	var width := StoryPanel.text_width()
	var shots := ["circle", "dawn", "bloom", "cheer", "wide"]
	for line: Array in Story.ENDING:
		var key := str(line[0])
		var speaker := str(line[1])
		assert_true(StoryPanel.NAMES.has(speaker), "%s: konuşan bilinir (%s)" % [key, speaker])
		assert_true(str(line[2]) in shots, "%s: çekim bilinir (%s)" % [key, line[2]])
		assert_true(Moods.face(speaker, key) != null, "%s: %s'nin yüzü var" % [key, speaker])
		assert_true(rows.has(key), "%s çevirisi var" % key)
		if not rows.has(key):
			continue
		for column in [1, 2]:
			var text: String = (rows[key] as PackedStringArray)[column]
			assert_true(not text.strip_edges().is_empty(), "%s (%s) boş değil" % [key, _lang(column)])
			var lines := _lines(font, text, width, StoryPanel.TEXT_SIZE)
			assert_true(lines <= MAX_LINES, "%s (%s) %d satır: %s" % [key, _lang(column), lines, text])
	assert_eq(str(Story.ENDING[0][2]), "circle", "bitiş Bekçi'nin turuyla başlar")
	assert_eq(str(Story.ENDING[Story.ENDING.size() - 1][2]), "wide", "gölün geniş çekimiyle biter")
	assert_true(Story.line_time(0, "", Story.ENDING) >= StoryFilm.CIRCLE_TIME, "Bekçi'nin turu bitene kadar söz kalır")
	for column in [1, 2]:
		var total := 0.0
		for i in Story.ENDING.size():
			var key := str(Story.ENDING[i][0])
			if rows.has(key):
				total += Story.line_time(i, (rows[key] as PackedStringArray)[column], Story.ENDING)
		assert_between(total, 25.0, 50.0, "bitiş filminin süresi (%s)" % _lang(column))


## Bekçi'nin bitiş filmindeki turu: X'te sandalın çevresinde, bütün noktaları suda ve kıyıdan uzak; kapalı bir
## tur (ilk ve son nokta aynı).
func test_keeper_circle_in_water() -> void:
	var db := content()
	var x := Secret.keeper_x(db, db.main_spot)
	assert_true(Dice.is_point(x), "haritanın X'i var")
	if not Dice.is_point(x):
		return
	var center := x + LakeScene.BUOY_MOOR
	var path := Story.keeper_circle(db, db.main_spot, center)
	assert_true(path.size() > 8, "tur var (%d nokta)" % path.size())
	var lake := db.lake(db.main_spot)
	for p in path:
		assert_true(lake.is_water(p) and lake.shore_distance(p) >= Story.CIRCLE_SHORE, "tur suda: %s" % str(p))
	assert_true(path[0].distance_to(path[path.size() - 1]) < 0.001, "kapalı tur")
	assert_true(path[0].distance_to(center) >= Story.CIRCLE_RADII[-1] - 0.001, "sandalın çevresinde")


## Jeneriğin her satırı (görevler, adlar, son söz) iki dilde var ve tek satıra sığar (başlık fontunda).
func test_credits_fit() -> void:
	var rows := _csv_rows()
	var font := UiKit.display_font()
	var keys: Array[String] = ["UI_CREDITS_END", "UI_ENDING_REPLAY"]
	for role: Array in CreditsPanel.ROLES:
		keys.append(str(role[0]))
		for who: String in role[1]:
			if who.begins_with("UI_"):
				keys.append(who)
			else:
				var size := font.get_string_size(UiKit.upper(who), HORIZONTAL_ALIGNMENT_LEFT, -1, CreditsPanel.NAME_SIZE)
				assert_true(size.x <= CreditsPanel.WIDTH, "%s tek satıra sığar (%.0f)" % [who, size.x])
	for key in keys:
		assert_true(rows.has(key), "%s çevirisi var" % key)
		if not rows.has(key):
			continue
		for column in [1, 2]:
			var text := UiKit.upper((rows[key] as PackedStringArray)[column])
			var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, CreditsPanel.NAME_SIZE)
			assert_true(size.x <= CreditsPanel.WIDTH, "%s (%s) tek satıra sığar: %.0f > %.0f" % [key, _lang(column),
					size.x, CreditsPanel.WIDTH])


## Finalden sonra son bölüm kendi sözüyle (Bekçi bırakıldı).
func test_last_chapter_after_the_final() -> void:
	var save := SaveData.create_new(1_700_000_000)
	assert_eq(Story.tell(20, save), "UI_DEDE_STORY_20", "finalden önce bölümün kendi sözü")
	var after := SaveData.create_new(1_700_000_000)
	after.keeper = 1
	assert_eq(Story.tell(20, after), "UI_DEDE_STORY_20_KEEPER", "Bekçi bırakıldıysa finalden sonraki sözü")
	assert_eq(Moods.of("UI_DEDE_STORY_20_KEEPER"), Moods.STORY, "Dede anlatır")
	assert_true(_csv_rows().has("UI_DEDE_STORY_20_KEEPER"), "çevirisi var")


## Ayarlar'daki HİKÂYE düğmesinin yazısı (büyük harfle: Â, İ) başlık fontunda var.
func test_replay_button_in_font() -> void:
	var rows := _csv_rows()
	var font := UiKit.display_font()
	for key: String in ["UI_STORY_REPLAY", "UI_ENDING_REPLAY"]:
		assert_true(rows.has(key), "%s çevirisi var" % key)
		if not rows.has(key):
			continue
		for column in [1, 2]:
			var text := (rows[key] as PackedStringArray)[column].replace("i", "İ").to_upper()
			for i in text.length():
				var c := text.unicode_at(i)
				assert_true(c == 32 or font.has_char(c), "%s (%s): başlık fontunda yok: %s" % [key, _lang(column), char(c)])


static func _lines(font: Font, text: String, width: float, size: int) -> int:
	var flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var box := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, flags)
	return roundi(box.y / font.get_height(size))


static func _lang(column: int) -> String:
	return "en" if column == 1 else "tr"


static func _csv_rows() -> Dictionary:
	var rows := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while f != null and not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3:
			rows[row[0]] = row
	return rows
