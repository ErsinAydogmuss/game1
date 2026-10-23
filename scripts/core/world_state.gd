class_name WorldState
extends RefCounted
## Gölün o anki koşulları (docs/gdd.md §10.5): vakit (DayClock), hava (Weather) ve göl sevgisinin
## seviyesi (LakeLove). Saf: hepsi kayıttan türer (saat, seed, sevgi, bayraklar). Oturum, defter,
## dükkân ve denge botu oranları aynı koşullarla hesaplar (CatchOdds.context): ekranda yazan oran
## gerçek orandır (gelir kuralı 10). Dede'yle çay (sonraki vakte geçilir) ve balığı göle bırakmak (göl
## sevgisi) da burada.


## { phase, weather, love } (love: seviye 1..10).
static func conditions(db: ContentDB, save: SaveData) -> Dictionary:
	var rules := db.rules
	return {
		"phase": DayClock.phase(rules, save.clock_s),
		"weather": Weather.at(rules, save),
		"love": LakeLove.level(rules, save.love),
	}


## Dede'yle çay içilebilir mi: son çaydan beri (ilk çaydan önce: oyunun başından beri) en az bir balık
## tutuldu. Vakit atlamak bir ritüel kalır; günler art arda atlanıp hava ve istekler çevrilemez. Çay
## ücretsizdir, parayla satılmaz (gelir kuralı 3: zaman atlama).
static func can_tea(save: SaveData) -> bool:
	return save.catches > maxi(save.tea_at, 0)


## Çay içilir: saat sonraki vaktin başına (DayClock.skip_phase), son çay şimdiki balık sayısı. Döner:
## vakit değişimi (DayClock.change); içilemezse boş sözlük (saat değişmez).
static func drink_tea(rules: FishingRules, save: SaveData) -> Dictionary:
	if not can_tea(save):
		return {}
	save.tea_at = save.catches
	return DayClock.skip_phase(rules, save)


## Bir balık göle bırakıldı (kovadan, karttan, kova dolu olduğu için ya da koruma altındaki tür): deftere
## (bırakılan sayısı), göl sevgisine (nadirliğine göre: rarities.json love) ve sayaca yazılır. Para
## vermez. Gölün Bekçisi bırakılınca final biter (Secret.release_keeper: geceler eski havasına döner). Döner:
## { love: eklenen, old_level, new_level } (seviye atladıysa bildirim).
static func release(db: ContentDB, save: SaveData, fish_id: String) -> Dictionary:
	Records.release(save.records, fish_id)
	if fish_id == Secret.KEEPER_ID:
		Secret.release_keeper(save, DayClock.day(db.rules, save.clock_s))
	var rarity := int(db.fish_by_id(fish_id).get("rarity", 0))
	var love := int(db.rarity_def(rarity).get("love", 0))
	var out := LakeLove.add(db.rules, save, love)
	out["love"] = love
	save.stats["released"] = int(save.stats.get("released", 0)) + 1
	return out
