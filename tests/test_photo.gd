extends BaseTest
## Fotoğraf modu (Dalga 5): dünyadaki 2B yazılar (konuşma balonu, balığın etiketi, tuzak rozeti, zil) görünürlük
## katmanı PhotoMode.WORLD_LABELS'ta: fotoğraf modu o biti viewport'un canvas_cull_mask'ından çıkarır, yazılar
## fotoğrafa girmez (kendi _process'leri görünürlüğü geri açsa da). Çerçevelerin hepsinin kenarı var (yok hariç);
## fotoğrafın adı yerel tarihle.


func test_world_labels_use_the_photo_layer() -> void:
	var labels: Array[Control] = [SpeechBubble.new(), CatchTag.new(), TrapBadge.new(), BellMark.new()]
	for label in labels:
		var name := str((label.get_script() as Script).get_global_name())
		assert_eq(label.visibility_layer, PhotoMode.WORLD_LABELS, "%s fotoğrafa girmez" % name)
		assert_true(label.visibility_layer & 1 == 0, "%s varsayılan katmanda değil" % name)
		label.free()


func test_frames_have_borders() -> void:
	var rect := Rect2(0, 0, 1560, 720)
	assert_eq(PhotoFrame.KINDS[0], "none", "ilk çeşit çerçevesiz")
	assert_eq(PhotoFrame.border(rect, "none"), 0.0, "çerçevesizde kenar yok")
	for kind in PhotoFrame.KINDS.slice(1):
		var b := PhotoFrame.border(rect, kind)
		assert_true(b > 10.0 and b < rect.size.y * 0.1, "%s çerçevesinin kenarı (%.0f)" % [kind, b])


func test_photo_name_is_dated() -> void:
	var name := PhotoMode.photo_name(1_762_000_000)
	assert_true(name.begins_with("olta_2025") and name.ends_with(".png") and name.length() == "olta_20251101_123456.png".length(),
			"fotoğrafın adı olta_<yıl ay gün>_<saat>.png: " + name)
	assert_true(PhotoMode.photo_name(1_762_000_000) != PhotoMode.photo_name(1_762_000_001), "her saniye ayrı ad")
