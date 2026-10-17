extends SceneTree
## Altın testin (test_golden.gd) beklenen değerlerini yeniden üretir. Yalnızca gölge ya da oturum
## davranışı bilerek değiştirildiğinde çalıştır ve farkı commit mesajında açıkla.
##   godot --headless --path . -s res://tests/make_golden.gd


func _initialize() -> void:
	var golden: GDScript = load("res://tests/test_golden.gd")
	var data: Dictionary = golden.call("snapshot", ContentDB.load_default())
	var f := FileAccess.open(golden.get("FIXTURE") if golden.get("FIXTURE") != null else "res://tests/fixtures/golden_home_lake.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	var lines := 0
	for key: String in data:
		lines += (data[key] as PackedStringArray).size()
	print("altın dosya yazıldı: %d anahtar, %d satır" % [data.size(), lines])
	quit()
