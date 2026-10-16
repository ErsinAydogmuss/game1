class_name InputRouter
extends Node
## Dokunma, fare ve klavye girdisini oyuna çevirir.
## - Olta suda değilken: karaya ya da iskeleye dokun → oraya yürü (kıyıda durur);
##   suya dokun → oraya at (main menzil dışındaysa önce yaklaştırır).
## - Olta sudayken ekranın her yeri eylem düğmesidir: parmak değdiği an action_pressed,
##   son parmak kalkınca action_released (çekişmede basılı tutunca sarılır).
## - Mac: tıkla (yürü, at), WASD / oklar (yürü), Space (eylem; basılıyken sar).
## "modal" grubundaki görünür paneller (ayarlar, balık kartı) açıkken dokunuşlar oyuna geçmez.
## Ekrandaki TouchButton'lar dokunuşu kendileri alır (set_input_as_handled), buraya gelmez.

signal walk_requested(target: Vector2)
signal cast_requested(target: Vector2)
signal action_pressed
signal action_released
## Klavyeyle yürüme yönü (dünya xz, uzunluğu 0..1).
signal walk_step(direction: Vector2)

## Fareyle basılı tutulan "parmak" ve Space tuşu.
const MOUSE_POINTER := -2
const KEY_POINTER := -3

## Ekran noktası → göl düzlemi (Vector2(x, z)); yoksa Dice.NO_POINT (Main.ground_point).
var ground_point: Callable
## Olta suda mı (FishingSession.line_out)?
var line_out: Callable
var lake: LakeShape
## Kameranın yatay açısı (WASD yönleri buna göre).
var view_yaw: float = FollowCamera.YAW
## true iken klavyeyle yürüme olur (olta suda değil, panel yok).
var walking_allowed: bool = true

var _down: Dictionary = {}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_pointer(touch.index, touch.position, touch.pressed)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.device == InputEvent.DEVICE_ID_EMULATION or mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		_pointer(MOUSE_POINTER, mouse.position, mouse.pressed)
	elif event.is_action(&"action") and not event.is_echo():
		_pointer(KEY_POINTER, Vector2.INF, event.is_pressed())


func _process(_delta: float) -> void:
	if blocked():
		release_all()
		return
	if not walking_allowed:
		return
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if input.length_squared() > 0.0001:
		var forward := Vector2(-sin(view_yaw), -cos(view_yaw))
		var right := Vector2(cos(view_yaw), -sin(view_yaw))
		walk_step.emit(right * input.x - forward * input.y)


## Açık bir panel var mı?
func blocked() -> bool:
	for node in get_tree().get_nodes_in_group("modal"):
		var modal := node as CanvasItem
		if modal != null and modal.is_visible_in_tree():
			return true
	return false


## Basılı parmakları bırakır (odak kaybı, panel açılışı).
func release_all() -> void:
	if not _down.is_empty():
		_down.clear()
		action_released.emit()


func _pointer(index: int, pos: Vector2, pressed: bool) -> void:
	if not pressed:
		if _down.erase(index) and _down.is_empty():
			action_released.emit()
		return
	if blocked():
		return
	if bool(line_out.call()) or index == KEY_POINTER:
		_down[index] = true
		action_pressed.emit()
		get_viewport().set_input_as_handled()
		return
	var p: Vector2 = ground_point.call(pos)
	if not Dice.is_point(p):
		return
	if lake.is_water(p) and not lake.on_dock(p):
		cast_requested.emit(p)
	else:
		walk_requested.emit(p)
	get_viewport().set_input_as_handled()
