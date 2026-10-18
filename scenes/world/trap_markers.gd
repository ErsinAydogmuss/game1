class_name TrapMarkers
extends Node3D
## Kerevit tuzaklarının işaretleri (docs/gdd.md §10.3): her tuzak suyun üstünde turuncu bir şamandıra
## (kodla, tek ağ: tuzak başına tek çizim, gölgesiz; suyla iner kalkar) ve üstünde 2B dolma rozeti
## (TrapBadge "2/4"). Kayıttaki tuzaklardan kurulur (sync). Yeni bırakılan tuzak balıkçının elinden
## yay çizerek uçar (throw), suya düşünce landed; toplanınca bir dalıp çıkar (bounce). Dokunma
## denetimi hit: ekran noktası → tuzağın kimliği. Süreler _process(delta) toplamıyla.

signal landed(at: Vector2)

## Uçuşun süresi (sn) ve yayın yüksekliği (m); toplanınca dalıp çıkma süresi.
const THROW_TIME := 0.6
const THROW_HEIGHT := 1.5
const BOUNCE_TIME := 0.5
## Dokunma payı: şamandıranın ekrandaki yerine bu kadar yakın (1080 birimlik ekranda) ya da rozetin
## üstü.
const HIT_RADIUS := 70.0
## Rozet şamandıranın bu kadar üstünde (m); kameradan bundan uzaktaki tuzağın rozeti gizlenir.
const BADGE_HEIGHT := 0.6
const BADGE_FAR := 40.0
const ORANGE := Color("#ff7a1a")
const BAND := Color("#f4efe6")
const FLAG := Color("#e8442e")
const POLE := Color("#4a3322")

static var _mesh: ArrayMesh

## Kimlik → { node, badge, base, phase }.
var _marks: Dictionary = {}
var _clock: float = 0.0
## Uçan tuzağın kimliği (yoksa -1), çıktığı yer ve geçen süre.
var _flying: int = -1
var _fly_from := Vector3.ZERO
var _fly_age: float = 0.0
## Dalıp çıkan tuzaklar: kimlik → geçen süre.
var _bounce: Dictionary = {}


## Tuzağın şamandırası (paylaşılan ağ): gövdenin yarısı suyun altında (opak su örter), beyaz bant,
## yuvarlak tepe, sırık ve küçük bayrak.
static func float_mesh() -> ArrayMesh:
	if _mesh == null:
		var batch := MeshBatch.new()
		batch.cylinder(0.13, 0.11, 0.16, Vector3.ZERO, ORANGE, 12)
		batch.cylinder(0.134, 0.134, 0.04, Vector3(0.0, 0.055, 0.0), BAND, 12)
		batch.sphere(0.13, Vector3(0.0, 0.08, 0.0), ORANGE, Vector3(1.0, 0.55, 1.0), 12, 6)
		batch.cylinder(0.015, 0.015, 0.34, Vector3(0.0, 0.27, 0.0), POLE, 6)
		batch.box(Vector3(0.15, 0.09, 0.012), Vector3(0.075, 0.385, 0.0), FLAG)
		batch.sphere(0.024, Vector3(0.0, 0.445, 0.0), BAND, Vector3.ONE, 6, 4)
		_mesh = batch.mesh()
	return _mesh


## İşaretler kayıttaki tuzaklara uyar: yenisi eklenir, kalkanı silinir, rozetler dolmayı gösterir.
func sync(save: SaveData, rules: FishingRules) -> void:
	var seen := {}
	for t in save.traps:
		var id := int(t["id"])
		seen[id] = true
		if not _marks.has(id):
			_add(id, TrapSim.position(t))
		(_marks[id]["badge"] as TrapBadge).set_count(TrapSim.ready(rules, t), rules.trap_max)
	for id: int in _marks.keys():
		if not seen.has(id):
			_remove(id)


## Bütün işaretler silinir (kayıt değişti).
func clear() -> void:
	for id: int in _marks.keys():
		_remove(id)
	_flying = -1


func has_mark(id: int) -> bool:
	return _marks.has(id)


## Tuzağın şamandırasının üstü (dünya; botun dokunuşu için). Yoksa Vector3.INF.
func mark_point(id: int) -> Vector3:
	if not _marks.has(id):
		return Vector3.INF
	return (_marks[id]["node"] as Node3D).global_position + Vector3(0.0, 0.15, 0.0)


## Rozetin gösterdiği dolma (kerevit sayısı; yoksa -1).
func shown_count(id: int) -> int:
	return (_marks[id]["badge"] as TrapBadge).count if _marks.has(id) else -1


## Yeni bırakılan tuzak from'dan (balıkçının eli) yay çizerek yerine uçar; düşünce landed.
func throw(id: int, from: Vector3) -> void:
	if not _marks.has(id):
		return
	_flying = id
	_fly_from = from
	_fly_age = 0.0
	(_marks[id]["node"] as Node3D).position = from
	(_marks[id]["badge"] as TrapBadge).visible = false


func is_flying() -> bool:
	return _flying >= 0


## Toplanan tuzak bir dalıp çıkar.
func bounce(id: int) -> void:
	if _marks.has(id):
		_bounce[id] = 0.0


## Ekran noktasındaki tuzak (rozeti ya da şamandırası); yoksa -1.
func hit(view: Camera3D, screen: Vector2) -> int:
	if view == null or not is_inside_tree():
		return -1
	var scale := get_viewport().get_visible_rect().size.y / 1080.0
	var best := -1
	var best_d := HIT_RADIUS * scale
	for id: int in _marks:
		if id == _flying:
			continue
		var mark: Dictionary = _marks[id]
		var badge: TrapBadge = mark["badge"]
		if badge.visible and badge.get_rect().has_point(screen):
			return id
		var point := (mark["node"] as Node3D).global_position + Vector3(0.0, 0.15, 0.0)
		if view.is_position_behind(point):
			continue
		var d := view.unproject_position(point).distance_to(screen)
		if d <= best_d:
			best = id
			best_d = d
	return best


func _add(id: int, p: Vector2) -> void:
	var node := MeshInstance3D.new()
	node.name = "Trap_%d" % id
	node.mesh = float_mesh()
	node.material_override = MeshBatch.vertex_material()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var base := Vector3(p.x, 0.0, p.y)
	node.position = base
	node.rotation.y = float(id) * 2.4
	add_child(node)
	var badge := TrapBadge.new()
	badge.name = "Badge_%d" % id
	add_child(badge)
	_marks[id] = { "node": node, "badge": badge, "base": base, "phase": float(id) * 1.3 }


func _remove(id: int) -> void:
	var mark: Dictionary = _marks[id]
	(mark["node"] as Node).queue_free()
	(mark["badge"] as Node).queue_free()
	_marks.erase(id)
	_bounce.erase(id)
	if _flying == id:
		_flying = -1


func _process(delta: float) -> void:
	_clock += delta
	var view := get_viewport().get_camera_3d()
	for id: int in _marks:
		var mark: Dictionary = _marks[id]
		var node: Node3D = mark["node"]
		var base: Vector3 = mark["base"]
		var phase: float = mark["phase"]
		var badge: TrapBadge = mark["badge"]
		if id == _flying:
			_fly_age += delta
			var t := clampf(_fly_age / THROW_TIME, 0.0, 1.0)
			node.position = _fly_from.lerp(base, t) + Vector3(0.0, sin(t * PI) * THROW_HEIGHT, 0.0)
			node.rotation.z = (1.0 - t) * 5.0
			if t < 1.0:
				continue
			_flying = -1
			_bounce[id] = 0.0
			landed.emit(Vector2(base.x, base.z))
		var y := sin(_clock * 1.7 + phase) * 0.025
		if _bounce.has(id):
			var b: float = float(_bounce[id]) + delta
			_bounce[id] = b
			y -= 0.12 * sin(b / BOUNCE_TIME * TAU) * (1.0 - b / BOUNCE_TIME)
			if b >= BOUNCE_TIME:
				_bounce.erase(id)
		node.position = base + Vector3(0.0, y, 0.0)
		node.rotation.x = sin(_clock * 1.3 + phase) * 0.06
		node.rotation.z = sin(_clock * 1.1 + phase * 0.7) * 0.06
		var point := node.global_position + Vector3(0.0, BADGE_HEIGHT, 0.0)
		var shown := view != null and not view.is_position_behind(point) \
				and view.global_position.distance_to(point) < BADGE_FAR
		badge.visible = shown
		if shown:
			badge.anchor = view.unproject_position(point)
