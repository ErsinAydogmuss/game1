extends SceneTree
## Karakter sayfası: bir KayKit modelini farklı animasyon anlarında yan yana çizip PNG kaydeder.
## Hangi animasyonun balık tutmaya uyduğunu, parçaların gizlendiğini ve dokuyu gözle denetlemek için.
##
## xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##   --audio-driver Dummy --resolution 1600x900 -s res://tools/character_sheet.gd -- --out=/mutlak/yol.png
## Seçenekler:
##   --model=res://.../Barbarian.glb  başka bir model (Dede ya da erkek balıkçı denemesi)
##   --raw                             dokuyu boyamadan ve parça gizlemeden çiz
##   --angler                          AnglerBody'yi (olta, şapka) oyundaki duruşlarla çiz
##   --elder                           Dede'yi (Elder: kasket, çay, balon) oyundaki duruşlarla, iskele
##                                     tahtasının kenarında oturtarak çiz (oturuş denetimi)
##   --nine                            Nine'yi (yazma, önlük, gözlük) oyundaki duruşlarla, ayakta çiz
## Zamanlama kare sayısıyla: --fixed-fps 30 ile çalıştır (tek seferlik hareketler tepe anında çizilsin).

## Sütun sayısı (--elder'de 3: Dede küçük kalmasın).
const COLUMNS := 6
const ELDER_COLUMNS := 3
## [etiket, animasyon, zaman oranı (0..1)].
const SPECS: Array[Array] = [
	["Idle", "Idle", 0.3], ["Walking_A", "Walking_A", 0.25], ["Throw 0", "Throw", 0.05],
	["Throw 0.35", "Throw", 0.35], ["Throw 0.55", "Throw", 0.55], ["Throw 0.8", "Throw", 0.8],
	["1H_Ranged_Aiming", "1H_Ranged_Aiming", 0.5], ["2H_Ranged_Aiming", "2H_Ranged_Aiming", 0.5],
	["Use_Item", "Use_Item", 0.5], ["Interact", "Interact", 0.5], ["Cheer 0.2", "Cheer", 0.2],
	["Block", "Blocking", 0.5], ["PickUp 0.4", "PickUp", 0.4], ["PickUp 0.8", "PickUp", 0.8],
	["Cheer", "Cheer", 0.4], ["Sit_Floor_Idle", "Sit_Floor_Idle", 0.5], ["Spellcast_Raise", "Spellcast_Raise", 0.6],
	["2H_Melee_Idle", "2H_Melee_Idle", 0.5], ["Unarmed_Pose", "Unarmed_Pose", 0.5], ["Idle_B", "Spellcasting", 0.5],
	["Walking_B", "Walking_B", 0.3], ["Walking_C", "Walking_C", 0.3], ["Jump_Idle", "Jump_Idle", 0.5],
	["Hit_A", "Hit_A", 0.3],
]
## --elder: Dede durumları [etiket, durum, hareketin çizimden kaç kare önce başlayacağı].
const ELDER_SPECS: Array[Array] = [
	["oturma", "sit", 0], ["sola bakış", "look_left", 0], ["sağa bakış", "look_right", 0],
	["konuşma", "say", 4], ["sevinç", "cheer", 15], ["yedek model", "toy", 0],
]
## --nine: Nine durumları (aynı biçim).
const NINE_SPECS: Array[Array] = [
	["bekleme", "idle", 0], ["sola bakış", "look_left", 0], ["sağa bakış", "look_right", 0],
	["selam", "greet", 14], ["sevinç", "cheer", 15], ["yedek model", "toy", 0],
]
## Dede'nin oturduğu tahtanın yüksekliği (iskele güvertesi).
const DECK := 0.4
const CAPTURE_FRAME := 40
## --angler: AnglerBody durumları [etiket, durum, gerilim].
const ANGLER_SPECS: Array[Array] = [
	["serbest", "free", 0.0], ["yürüme", "walk", 0.0], ["atış", "cast", 0.0], ["bekleme", "hold", 0.0],
	["çekme", "reel", 0.3], ["çekme (gergin)", "reel", 1.0], ["gösterme", "show", 0.0], ["sevinç", "cheer", 0.0],
]

var _out := "user://character_sheet.png"
var _model_path := AnglerBody.SCENE_PATH
var _raw: bool = false
var _angler: bool = false
var _elder: bool = false
var _nine: bool = false
var _players: Array[AnimationPlayer] = []
var _bodies: Array[AnglerBody] = []
var _elders: Array[Villager] = []
var _slots: Array[Vector3] = []
var _world: Node3D
var _camera: Camera3D
var _frames := 0
var _columns := COLUMNS


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--model="):
			_model_path = arg.substr(8)
		elif arg == "--raw":
			_raw = true
		elif arg == "--angler":
			_angler = true
		elif arg == "--elder":
			_elder = true
		elif arg == "--nine":
			_nine = true
	if _elder or _nine:
		_columns = ELDER_COLUMNS
	var world := Node3D.new()
	root.add_child(world)
	_world = world
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#a9d2ef")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#d4e4f7")
	env.environment.ambient_light_energy = 0.5
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.transform = Transform3D(Basis.looking_at(Vector3(-0.35, -1.0, -0.55)), Vector3.ZERO)
	world.add_child(sun)
	var specs := ANGLER_SPECS if _angler else (ELDER_SPECS if _elder else (NINE_SPECS if _nine else SPECS))
	for i in specs.size():
		var pos := Vector3((i % _columns - (_columns - 1) * 0.5) * 1.5, -floorf(i / float(_columns)) * 2.1, 0)
		if _elder:
			# Oturtma ilk karede (_ready'den sonra); tahta da orada konur.
			var elder := Elder.new()
			elder.use_toy = str(specs[i][1]) == "toy"
			world.add_child(elder)
			_elders.append(elder)
			_slots.append(pos)
		elif _nine:
			var nine := Nine.new()
			nine.use_toy = str(specs[i][1]) == "toy"
			world.add_child(nine)
			_elders.append(nine)
			_slots.append(pos)
		elif _angler:
			var body := AnglerBody.new()
			world.add_child(body)
			body.position = pos
			body.rotation.y = -PI * 0.5 + 0.35
			_bodies.append(body)
		else:
			var model := (load(_model_path) as PackedScene).instantiate() as Node3D
			model.scale = Vector3.ONE * AnglerBody.MODEL_SCALE
			world.add_child(model)
			model.position = pos
			model.rotation.y = PI * 0.5 - 0.6
			if not _raw:
				# Modelin kendi kıyafeti: Nine (Mage), Dede (Barbarian) ya da balıkçı.
				match _model_path:
					NineBody.SCENE_PATH:
						NineBody.dress(model)
					ElderBody.SCENE_PATH:
						ElderBody.dress(model)
					_:
						AnglerBody.dress(model)
			var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
			_players.append(player)
		var label := Label3D.new()
		label.text = str(specs[i][0])
		label.font_size = 40
		label.pixel_size = 0.005
		label.outline_size = 12
		label.position = pos + Vector3(0, -0.12, 0.6)
		world.add_child(label)
	# Dik izdüşüm: sıralar aynı boyda, üst üste binmez; sütunlar da sığsın.
	var rows := ceili(specs.size() / float(_columns))
	var camera := Camera3D.new()
	world.add_child(camera)
	_camera = camera
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	var aspect := float(root.size.x) / maxf(float(root.size.y), 1.0)
	camera.size = maxf(rows * 2.1 + 0.4, mini(specs.size(), _columns) * 1.5 / aspect + 0.2)
	var center_y := -(rows - 1) * 2.1 * 0.5 + 0.7
	camera.transform = Transform3D(Basis.looking_at(Vector3(0, -0.25, -1).normalized()), Vector3(0, center_y + 2.0, 8.0))


func _process(delta: float) -> bool:
	_frames += 1
	if _nine:
		for i in _elders.size():
			var spec: Array = NINE_SPECS[i]
			var nine := _elders[i] as Nine
			if _frames == 1:
				# Kameraya üçte bir dönük, bir tahtanın üstünde.
				nine.camera = _camera
				nine.stand(_slots[i] + Vector3(0, DECK, 0), Vector2(sin(0.6), cos(0.6)))
				Props.box(_world, Vector3(0.9, 0.08, 0.7), _slots[i] + Vector3(0, DECK - 0.04, 0), Color("#b07a4a"))
			var side := 0.0
			match str(spec[1]):
				"look_left":
					side = 1.0
				"look_right":
					side = -1.0
			nine.has_focus = side != 0.0
			nine.focus = nine.head_point() + nine.global_basis * Vector3(side * 2.0, -0.3, 0.8)
			if _frames == CAPTURE_FRAME - int(spec[2]):
				match str(spec[1]):
					"greet":
						nine.greet()
					"cheer":
						nine.cheer()
	elif _elder:
		for i in _elders.size():
			var spec: Array = ELDER_SPECS[i]
			var elder := _elders[i] as Elder
			if _frames == 1:
				# Kameraya üçte bir dönük; kenarı diz arkasında, üstü güverte hizasında bir tahta.
				var facing := Vector2(sin(0.6), cos(0.6))
				var edge := Vector2(_slots[i].x, _slots[i].z)
				elder.camera = _camera
				elder.seat(edge, facing, _slots[i].y + DECK)
				var deck := Props.box(_world, Vector3(0.9, 0.08, 0.7), Vector3.ZERO, Color("#b07a4a"))
				deck.global_transform = Transform3D(elder.global_basis, Vector3(edge.x, _slots[i].y + DECK - 0.04, edge.y)) \
						* Transform3D(Basis.IDENTITY, Vector3(0, 0, -0.35))
			var side := 0.0
			match str(spec[1]):
				"look_left":
					side = 1.0
				"look_right":
					side = -1.0
			# Dede'nin soluna (+x yerel) ya da sağına bir hedef.
			elder.has_focus = side != 0.0
			elder.focus = elder.head_point() + elder.global_basis * Vector3(side * 2.0, -0.3, 0.8)
			if _frames == CAPTURE_FRAME - int(spec[2]):
				match str(spec[1]):
					"say":
						elder.say()
					"cheer":
						elder.cheer()
	elif _angler:
		for i in _bodies.size():
			var spec: Array = ANGLER_SPECS[i]
			var state := str(spec[1])
			# -s modunda _ready ilk karede çalışır: olta ondan sonra takılır.
			if _frames == 1:
				var rod := RodModel.new()
				_bodies[i].rod_mount.add_child(rod)
				rod.bend = float(spec[2])
			if _frames == 2:
				match state:
					"cast":
						_bodies[i].play_cast()
					"cheer":
						_bodies[i].cheer()
					"show":
						_bodies[i].show_fish()
			var pose := "free" if state in ["walk", "free", "cast", "cheer", "show"] else state
			_bodies[i].animate(delta, 2.0 if state == "walk" else 0.0, pose, float(spec[2]))
	else:
		for i in _players.size():
			var spec: Array = SPECS[i]
			var player := _players[i]
			var anim := str(spec[1])
			if player != null and player.has_animation(anim):
				player.play(anim)
				player.seek(player.get_animation(anim).length * float(spec[2]), true)
				player.pause()
	if _frames < (CAPTURE_FRAME if _angler or _elder or _nine else 8):
		return false
	root.get_viewport().get_texture().get_image().save_png(_out)
	print("Kaydedildi: ", _out)
	return true
