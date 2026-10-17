class_name Fade
extends ColorRect
## Ekran kararıp açılır (haritadan hızlı geçiş): TIME sn'de kararır, tam karanlıkta verilen iş
## yapılır (balıkçı yeni yerine geçer, kamera gelir), HOLD sn karanlık kalır, TIME sn'de açılır.
## Sürerken dokunuşlar oyuna geçmez ("modal" grubu). Süre _process(delta) toplamıyla ölçülür.

const TIME := 0.25
const HOLD := 0.1
const DARK := Color(0.02, 0.03, 0.06)

var _clock: float = -1.0
var _job: Callable
var _done: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(DARK, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("modal")
	hide()


## Kararır, iş yapılır, açılır. Sürmekte olan bir geçiş varsa yenisi başlamaz (false).
func play(job: Callable) -> bool:
	if busy():
		return false
	_job = job
	_clock = 0.0
	_done = false
	color = Color(DARK, 0.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	return true


func busy() -> bool:
	return _clock >= 0.0


func _process(delta: float) -> void:
	if _clock < 0.0:
		return
	_clock += delta
	if _clock < TIME:
		color.a = _clock / TIME
		return
	if not _done:
		# Tam karanlık: iş bu karede yapılır (ekran açılmadan önce bir kare karanlık kalır).
		_done = true
		color.a = 1.0
		_clock = TIME
		if _job.is_valid():
			_job.call()
		return
	var light := _clock - TIME - HOLD
	if light < 0.0:
		return
	color.a = 1.0 - clampf(light / TIME, 0.0, 1.0)
	if light >= TIME:
		_clock = -1.0
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		hide()
