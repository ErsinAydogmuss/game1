class_name AdNoticePanel
extends Dialog
## "Reklamlar hakkında" (Kazı'nın v0.14 kartı; KVKK aydınlatması): reklamlar ilk kez yüklenmeden önce bir kez (Ads:
## ısınmadan sonra, olta boşken): oyun neden reklam gösterir, reklamları kim sunar, hangi bilgiler gider, seçimler
## nereden değişir. ANLADIM ya da kapatınca main reklamları başlatır (Ads.start: AB'de Google'ın onay penceresi,
## iPhone'da izleme izni ondan sonra). GİZLİLİK POLİTİKASI sayfayı açar.
## Ayarlar'ın GİZLİLİK düğmesi aynı kartı bilgi olarak açar (open_info): ANLADIM yerine REKLAM SEÇİMLERİ (Google'ın
## formu; yalnızca gerektiğinde: Ads.privacy_options_required) ve LİSANSLAR (licenses_requested).

signal licenses_requested

const WIDTH := 1300.0
const ICON := 190.0
const BUTTON_H := 122.0

var ok_button: Button
var policy_button: Button
var choices_button: Button
var licenses_button: Button
## Ayarlar'dan bilgi olarak mı açıldı (kapanınca reklamlar başlamaz: zaten başlamış ya da kapalı).
var info: bool = false

var _text: Label


func _build() -> void:
	set_header(tr("UI_ADS_NOTICE_TITLE"), "ad", WIDTH)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	body.add_child(row)
	row.add_child(GameIcon.make("ad", ICON))
	_text = UiKit.ink("", UiKit.SIZE_SMALL + 2, UiKit.INK)
	_text.name = "Text"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size = Vector2(WIDTH - ICON - 140.0, 0)
	row.add_child(_text)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	body.add_child(buttons)
	policy_button = _button("Policy", UiKit.NEUTRAL, buttons)
	policy_button.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		OS.shell_open(Ads.PRIVACY_URL))
	choices_button = _button("Choices", UiKit.NEUTRAL, buttons)
	choices_button.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		Ads.show_privacy_options())
	licenses_button = _button("Licenses", UiKit.NEUTRAL, buttons)
	licenses_button.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		licenses_requested.emit())
	ok_button = _button("Ok", UiKit.SUCCESS, buttons)
	ok_button.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		close_panel())


func _button(id: String, color: Color, parent: HBoxContainer) -> Button:
	var b := UiKit.button("", color, UiKit.SIZE_SMALL, Vector2(0, BUTTON_H))
	b.name = id
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b


## İlk kez: ANLADIM'la (kapanınca main reklamları başlatır).
func open_notice() -> void:
	info = false
	open()


## Ayarlar'dan: gizlilik politikası, reklam seçimleri (gerekirse) ve lisanslar.
func open_info() -> void:
	info = true
	open()


func refresh() -> void:
	set_header(tr("UI_ADS_NOTICE_TITLE"), "ad", WIDTH)
	_text.text = tr("UI_ADS_NOTICE_BODY")
	policy_button.text = UiKit.upper(tr("UI_PRIVACY_POLICY"))
	choices_button.text = UiKit.upper(tr("UI_SET_PRIVACY_OPTIONS"))
	choices_button.visible = info and Ads.privacy_options_required()
	licenses_button.text = UiKit.upper(tr("UI_LICENSES"))
	licenses_button.visible = info
	ok_button.text = UiKit.upper(tr("UI_ADS_NOTICE_OK"))
	ok_button.visible = not info
