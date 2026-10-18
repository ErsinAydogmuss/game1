class_name BellMark
extends Control
## Dipte koşu: sehpanın üstünde sallanan 2B zil (Ersin'in zil görseli; yoksa kodla pirinç zil).
## Sahnenin ton eşlemesi soldurmasın diye arayüz gibi çizilir; sehpa (RodStand) her kare 3B noktayı
## ekrana taşır (anchor: zilin alt ortası). Süreler _process(delta) toplamıyla.

## Zilin boyu (viewport birimi) ve beliriş süresi (sn).
const SIZE := 104.0
const POP_TIME := 0.18
const BRASS := Color("#e0ac45")

## Zilin alt ortasının ekrandaki yeri.
var anchor := Vector2.ZERO

var _art: Texture2D
var _clock: float = 0.0
var _age: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(SIZE, SIZE)
	# Tepesinden asılı gibi sallanır.
	pivot_offset = Vector2(SIZE * 0.5, SIZE * 0.08)
	_art = ItemArt.gear("bell")
	visible = false


func show_mark(on: bool) -> void:
	if on and not visible:
		_age = 0.0
	visible = on


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	_age += delta
	var pop := clampf(_age / POP_TIME, 0.0, 1.0)
	rotation = sin(_clock * 19.0) * 0.32
	scale = Vector2.ONE * lerpf(1.4, 1.0, pop * pop) * (1.0 + 0.05 * sin(_clock * 9.0))
	position = anchor - Vector2(SIZE * 0.5, SIZE)


func _draw() -> void:
	if _art != null:
		draw_texture_rect(_art, Rect2(Vector2.ZERO, size), false)
		return
	# Yedek: koyu kenarlı pirinç kubbe, ağzı ve tokmağı.
	var c := Vector2(SIZE * 0.5, SIZE * 0.48)
	draw_circle(c, SIZE * 0.34, BRASS.darkened(0.45))
	draw_circle(c, SIZE * 0.3, BRASS)
	draw_rect(Rect2(SIZE * 0.12, SIZE * 0.56, SIZE * 0.76, SIZE * 0.16), BRASS.darkened(0.2))
	draw_circle(Vector2(SIZE * 0.5, SIZE * 0.82), SIZE * 0.1, BRASS.darkened(0.45))
	draw_circle(c + Vector2(-SIZE * 0.1, -SIZE * 0.1), SIZE * 0.07, Color(1, 1, 1, 0.55))
