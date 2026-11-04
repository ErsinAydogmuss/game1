class_name AdOffer
extends RefCounted
## Ödüllü reklamın teklif düğmesi (Kazı'nın v0.14 düğmesi): solunda oynat üçgenli küçük ekran (GameIcon "ad"), her
## yerde aynı renkte (oyuncu reklam tekliflerini tanısın), yazısı "Reklam izle: ...". Görünürlüğünü çağıran verir
## (Ads.offer_ok); basınca çağıran Ads.show_rewarded'ı bekler, ödül yalnızca sonuna kadar izlenince.

## Teklif rengi (paletin düğme görsellerinde yok: kodla çizilir; Hud.warm_styles açılışta ısıtır).
const COLOR := Color("#1fa38f")


static func button(text: String, min_size: Vector2 = Vector2(0, 122), font_size: int = UiKit.SIZE_SMALL) -> Button:
	var b := UiKit.button(text, COLOR, font_size, min_size)
	b.name = "AdOffer"
	var side := clampf(min_size.y * 0.6, 44.0, 76.0)
	# Yazı ikonun sağında: her hâlin stili kopyalanır (parlak doku önbellekte paylaşılıyor).
	for state: String in UiKit.BUTTON_STATES:
		var sb := b.get_theme_stylebox(state).duplicate() as StyleBox
		sb.content_margin_left = side + 34.0
		sb.content_margin_right = 22.0
		b.add_theme_stylebox_override(state, sb)
	# İkon sol kenarda, düğmenin boyu ne olursa olsun dikeyde ortada (altta düğmenin kalınlığı: biraz yukarıda).
	var icon := GameIcon.make("ad", side)
	icon.anchor_top = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = 18.0
	icon.offset_right = 18.0 + side
	icon.offset_top = -side * 0.5 - 4.0
	icon.offset_bottom = side * 0.5 - 4.0
	b.add_child(icon)
	return b
