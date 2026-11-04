extends BaseTest
## Reklam kuralları (AdRules; Ersin'in kararı 4 Kasım 2026): ısınma, günlük sınırlar, bekleme süreleri, gün değişimi,
## kurtarılmaya değer balık, geçiş reklamının 20 ve 8 dakika kuralları, bildirim.

const DAY := 20261104
const WARM := AdRules.WARMUP_CATCHES


func _fresh() -> Dictionary:
	var settings := {}
	return AdRules.state(settings)


func test_state_lives_in_settings() -> void:
	var settings := {}
	var st := AdRules.state(settings)
	assert_true(settings.has("ads"), "durum ayarların içinde")
	assert_true(AdRules.state(settings) == st, "aynı sözlük döner")
	assert_eq(AdRules.play_time(st), 0.0, "oyun süresi sıfırdan")
	assert_true(not AdRules.notice_seen(st), "bildirim görülmedi")
	AdRules.mark_notice_seen(st)
	assert_true(AdRules.notice_seen(settings["ads"]), "bildirim kaydedildi")


## Kayıttan (JSON) gelen ayarlarda sayılar float: kurallar yine çalışır.
func test_state_survives_json() -> void:
	var settings := {}
	var st := AdRules.state(settings)
	AdRules.add_play(st, 700.0)
	AdRules.record_reward(st, AdRules.SELL, DAY)
	var back: Dictionary = JSON.parse_string(JSON.stringify(settings))
	var st2 := AdRules.state(back)
	assert_eq(AdRules.count(st2, AdRules.SELL, DAY), 1, "sayaç JSON'dan sonra da 1")
	assert_true(not AdRules.can_offer(st2, AdRules.SELL, DAY, WARM), "bekleme JSON'dan sonra da sürüyor")


func test_offers_need_warm_up() -> void:
	var st := _fresh()
	for place in AdRules.PLACES:
		assert_true(not AdRules.can_offer(st, place, DAY, WARM - 1), "ısınma bitmeden teklif yok: " + place)
		assert_true(AdRules.can_offer(st, place, DAY, WARM), "ısınmadan sonra teklif var: " + place)
	assert_true(not AdRules.can_offer(st, "bilinmeyen", DAY, WARM), "bilinmeyen yerde teklif yok")


func test_daily_caps_and_new_day() -> void:
	for place: String in [AdRules.RESCUE, AdRules.REQUEST]:
		var st := _fresh()
		var cap := int(AdRules.DAILY_CAP[place])
		for i in cap:
			assert_true(AdRules.can_offer(st, place, DAY, WARM), "%s: sınırın altında (%d)" % [place, i])
			AdRules.record_reward(st, place, DAY)
		assert_true(not AdRules.can_offer(st, place, DAY, WARM), place + ": günlük sınır doldu")
		assert_true(AdRules.can_offer(st, place, DAY + 1, WARM), place + ": ertesi gün sayaç sıfırlanır")
		assert_eq(AdRules.count(st, place, DAY + 1), 0, place + ": yeni günün sayacı 0")


func test_sell_and_aquarium_cooldowns() -> void:
	var st := _fresh()
	assert_true(AdRules.can_offer(st, AdRules.SELL, DAY, WARM), "ilk satış teklifi")
	AdRules.record_reward(st, AdRules.SELL, DAY)
	assert_true(not AdRules.can_offer(st, AdRules.SELL, DAY, WARM), "hemen ardından yok")
	assert_true(AdRules.can_offer(st, AdRules.AQUARIUM, DAY, WARM), "satış beklemesi akvaryumu etkilemez")
	assert_true(AdRules.can_offer(st, AdRules.REQUEST, DAY, WARM), "satış beklemesi isteği etkilemez")
	AdRules.add_play(st, AdRules.SELL_COOLDOWN - 1.0)
	assert_true(not AdRules.can_offer(st, AdRules.SELL, DAY, WARM), "bekleme bitmeden yok")
	AdRules.add_play(st, 1.0)
	assert_true(AdRules.can_offer(st, AdRules.SELL, DAY, WARM), "bekleme bitince var")
	AdRules.record_reward(st, AdRules.AQUARIUM, DAY)
	AdRules.add_play(st, AdRules.AQUARIUM_COOLDOWN - 1.0)
	assert_true(not AdRules.can_offer(st, AdRules.AQUARIUM, DAY, WARM), "akvaryumda bekleme bitmeden yok")
	AdRules.add_play(st, 1.0)
	assert_true(AdRules.can_offer(st, AdRules.AQUARIUM, DAY, WARM), "akvaryumda bekleme bitince var")
	assert_true(not AdRules.sale_worth_offer(AdRules.SELL_MIN - 1), "küçük satışa teklif yok")
	assert_true(AdRules.sale_worth_offer(AdRules.SELL_MIN), "yeterli satışa teklif var")
	assert_true(not AdRules.box_worth_offer(AdRules.AQUARIUM_MIN - 1), "az dolu kutuya teklif yok")
	assert_true(AdRules.box_worth_offer(AdRules.AQUARIUM_MIN), "dolu kutuya teklif var")


func test_rescue_worth_offer() -> void:
	var rare := 2
	assert_true(AdRules.rescue_worth_offer(rare, rare, false, 0), "Nadir balık kurtarılır")
	assert_true(AdRules.rescue_worth_offer(rare + 2, rare, false, 0), "Efsanevi balık kurtarılır")
	assert_true(not AdRules.rescue_worth_offer(rare - 1, rare, false, 0), "Güzel balık kurtarılmaz")
	assert_true(not AdRules.rescue_worth_offer(rare + 3, rare, true, 0), "Gölün Bekçisi kurtarılmaz")
	assert_true(not AdRules.rescue_worth_offer(rare + 1, rare, false, 4), "takımın taşıyamadığı iri balık kurtarılmaz")


func test_interstitial_grace_gap_and_warm_up() -> void:
	var st := _fresh()
	AdRules.add_play(st, AdRules.INTERSTITIAL_GRACE - 1.0)
	assert_true(not AdRules.interstitial_due(st, WARM), "ilk 20 dakikada yok")
	AdRules.add_play(st, 1.0)
	assert_true(AdRules.interstitial_due(st, WARM), "20 dakikadan sonra çıkar")
	assert_true(not AdRules.interstitial_due(st, WARM - 1), "ısınma bitmeden yok")
	AdRules.record_interstitial(st, DAY)
	assert_eq(AdRules.count(st, AdRules.INTERSTITIAL, DAY), 1, "geçiş sayacı")
	AdRules.add_play(st, AdRules.INTERSTITIAL_GAP - 1.0)
	assert_true(not AdRules.interstitial_due(st, WARM), "8 dakika dolmadan yok")
	AdRules.add_play(st, 1.0)
	assert_true(AdRules.interstitial_due(st, WARM), "8 dakika sonra yine")
	AdRules.record_reward(st, AdRules.RESCUE, DAY)
	assert_true(not AdRules.interstitial_due(st, WARM), "ödüllü reklam izleyene 8 dakika geçiş yok")
	AdRules.add_play(st, AdRules.INTERSTITIAL_GAP)
	assert_true(AdRules.interstitial_due(st, WARM), "ödüllüden 8 dakika sonra yine")


func test_day_key() -> void:
	assert_eq(AdRules.day_key({ "year": 2026, "month": 11, "day": 4 }), 20261104, "yyyymmdd")
	assert_eq(AdRules.day_key({ "year": 2027.0, "month": 1.0, "day": 9.0 }), 20270109, "float alanlar da")
