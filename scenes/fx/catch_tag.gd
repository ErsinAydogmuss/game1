class_name CatchTag
extends Control
## Yakalanan balığın etiketi (2B): nadirlik simgesi ve adı nadirlik renginde, altında boyu. Balığın
## üstünde hafifçe taşarak belirir, yükselir ve söner. Sahnenin ton eşlemesi ve sisi soldurmasın
## diye arayüz gibi çizilir; CatchFx her kare 3B noktayı ekrana taşır (anchor: etiketin alt ortası).
## Süreler _process(delta) toplamıyla.

const POP_TIME := 0.18

## Etiketin alt ortasının ekrandaki yeri (viewport birimi).
var anchor := Vector2.ZERO

var _box: VBoxContainer
var _age: float = -1.0
var _hold: float = 2.2


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## icon: GameIcon adı (nadirlik simgesi, "" = yok); hold: ekranda kalma süresi (sn).
func show_tag(title: String, size_text: String, color: Color, icon: String, hold: float) -> void:
	if _box != null:
		_box.queue_free()
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", -6)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(row)
	if not icon.is_empty():
		row.add_child(GameIcon.make(icon, 64, color))
	row.add_child(UiKit.title(title, 66, color.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER, 16))
	_box.add_child(UiKit.title(size_text, 50, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 14))
	_hold = hold
	_age = 0.0
	visible = true
	_place()


func is_showing() -> bool:
	return _age >= 0.0


func clear() -> void:
	_age = -1.0
	visible = false


func _process(delta: float) -> void:
	if _age < 0.0:
		return
	_age += delta
	var t := _age / _hold
	modulate.a = clampf((1.0 - t) * 3.0, 0.0, 1.0)
	var pop := clampf(_age / POP_TIME, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(1.3, 1.0, pop * pop)
	_place()
	if _age >= _hold:
		clear()


func _place() -> void:
	if _box == null:
		return
	var box_size := _box.get_combined_minimum_size()
	_box.size = box_size
	size = box_size
	pivot_offset = Vector2(box_size.x * 0.5, box_size.y)
	position = anchor - Vector2(box_size.x * 0.5, box_size.y)
