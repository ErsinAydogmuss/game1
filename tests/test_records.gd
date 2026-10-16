extends BaseTest
## Kayıt defteri: yeni tür, rekor, sayaç ve kart kuralı.


func test_new_species_then_records() -> void:
	var records := {}
	var first := Records.add(records, "carp", 40, 2, 1000)
	assert_true(first["new_species"], "ilk sazan yeni tür")
	assert_true(not first["new_record"], "yeni tür ayrıca rekor sayılmaz")
	assert_eq(int(records["carp"]["first_unix"]), 1000, "ilk yakalanma zamanı")
	var smaller := Records.add(records, "carp", 35, 3, 2000)
	assert_true(not smaller["new_species"] and not smaller["new_record"], "küçüğü rekor değil")
	assert_eq(int(records["carp"]["best_stars"]), 3, "en iyi yıldız tutulur")
	var bigger := Records.add(records, "carp", 70, 1, 3000)
	assert_true(bigger["new_record"], "büyüğü rekor")
	assert_eq(int(records["carp"]["count"]), 3, "sayaç")
	assert_eq(int(records["carp"]["best_cm"]), 70, "en büyük boy")
	assert_eq(int(records["carp"]["first_unix"]), 1000, "ilk zaman değişmez")
	assert_eq(Records.species_count(records), 1, "bir tür")


func test_card_rule() -> void:
	var repeat := { "new_species": false, "new_record": false }
	assert_true(Records.wants_card(0, { "new_species": true, "new_record": false }), "yeni tür: kart")
	assert_true(Records.wants_card(0, { "new_species": false, "new_record": true }), "rekor: kart")
	assert_true(not Records.wants_card(0, repeat), "sıradan tekrar: kısa bildirim")
	assert_true(not Records.wants_card(1, repeat), "güzel tekrar: kısa bildirim")
	assert_true(Records.wants_card(2, repeat), "nadir ve üstü: hep kart")


func test_records_survive_save_roundtrip() -> void:
	var s := SaveData.create_new(10)
	Records.add(s.records, "pike", 88, 4, 50)
	var back := SaveData.from_dict(s.to_dict())
	assert_eq(back.records, s.records, "kayıt defteri kayıtla gidip gelir")
