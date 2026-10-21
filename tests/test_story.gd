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
