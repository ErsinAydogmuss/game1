class_name AdOfferPanel
extends Dialog
## Ödüllü reklamın teklif kartı (reklamlar, A2; Ersin'in kararı 4 Kasım 2026): oyunun bir anında çıkan küçük kart.
## İki yerde: kaçan Nadir+ balığı kurtarma (AdRules.RESCUE: balığın resmi, nadirlik rozeti, adı) ve Dede'nin
## isteğinin ödülünü 2 katına çıkarma (AdRules.REQUEST). Solda resim, sağda yazı; altta HAYIR ve teklif düğmesi
## (AdOffer). Teklif düğmesi Ads.show_rewarded'ı bekler (reklam açıkken oyun durur): sonuna kadar izlendiyse kart
## kapanır ve rewarded yayılır (ödülü main verir); yarıda kaldıysa ödül yok (Ads.reward_missed: main söyler).
## Kart açıkken oyun donar (Dialog): kaçan balık beklerken kaçmaz. Satışın ve akvaryum kutusunun teklifi kendi
## panellerinde (ShopPanel, AquariumPanel).

## Sonuna kadar izlenen reklamın yeri (kart kapandıktan sonra).
signal rewarded(place: String)

const WIDTH := 1200.0
const ART := 220.0
const BUTTON_H := 122.0
const NO_W := 300.0

var offer_button: Button
var no_button: Button
## Açık teklifin yeri (AdRules.RESCUE, AdRules.REQUEST).
var place: String = ""

var _art: GameIcon
var _badge: HBoxContainer
var _text: Label
var _title_key: String = ""
## Yazılar her açılışta o anki dilde kurulur (Callable → String).
var _text_of: Callable
var _button_of: Callable
var _art_kind: String = "ad"
var _rarity: int = -1
## Reklam açık (düğmeler pasif: ikinci dokunuş ikinci reklam açmasın).
var _busy: bool = false


func _build() -> void:
	set_header("", "ad", WIDTH)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	body.add_child(row)
	_art = GameIcon.make("ad", ART)
	_art.name = "Art"
	row.add_child(_art)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	row.add_child(column)
	_badge = HBoxContainer.new()
	column.add_child(_badge)
	_text = UiKit.ink("", UiKit.SIZE_BODY, UiKit.INK)
	_text.name = "Text"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(WIDTH - ART - 170.0, 0)
	column.add_child(_text)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	body.add_child(buttons)
	no_button = UiKit.button("", UiKit.NEUTRAL, UiKit.SIZE_BODY, Vector2(NO_W, BUTTON_H))
	no_button.name = "No"
	no_button.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		close_panel())
	buttons.add_child(no_button)
	offer_button = AdOffer.button("", Vector2(0, BUTTON_H), UiKit.SIZE_BODY)
	offer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_button.pressed.connect(_watch)
	buttons.add_child(offer_button)


## Teklifi açar. where: AdRules yeri; title_key: başlık; text_of, button_of: yazıyı ve düğmenin yazısını veren
## Callable'lar (o anki dilde); art: solda resim (GameIcon: "fish:<tür>", "requests"); rarity ≥ 0 ise yazının
## üstünde nadirlik rozeti.
func offer(where: String, title_key: String, text_of: Callable, button_of: Callable, art: String,
		rarity: int = -1) -> void:
	place = where
	_title_key = title_key
	_text_of = text_of
	_button_of = button_of
	_art_kind = art
	_rarity = rarity
	_busy = false
	open()


func refresh() -> void:
	set_header(tr(_title_key), "ad", WIDTH)
	_art.kind = _art_kind
	_text.text = str(_text_of.call()) if _text_of.is_valid() else ""
	Dialog.clear(_badge)
	_badge.visible = _rarity >= 0
	if _rarity >= 0:
		_badge.add_child(UiKit.rarity_badge(GameState.db, _rarity))
	no_button.text = UiKit.upper(tr("UI_AD_NO"))
	offer_button.text = UiKit.upper(str(_button_of.call())) if _button_of.is_valid() else ""
	_sync_buttons()


func close_panel() -> void:
	# Reklam açıkken kapanmaz (X'e reklamdan önce basılan dokunuş): sonuç gelince kapanır.
	if _busy:
		return
	super.close_panel()


func _sync_buttons() -> void:
	offer_button.disabled = _busy
	no_button.disabled = _busy
	close_button.disabled = _busy


func _watch() -> void:
	if _busy or not visible:
		return
	_busy = true
	_sync_buttons()
	Sounds.play("ui_tap")
	var where := place
	var earned := await Ads.show_rewarded(where)
	_busy = false
	_sync_buttons()
	close_panel()
	if earned:
		rewarded.emit(where)
