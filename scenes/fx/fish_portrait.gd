class_name FishPortrait
extends RefCounted
## Balık portreleri: her türün FishMesh'i açılışta bir kez, saydam arka planlı küçük bir
## görüntüye çizilir (PortraitStudio); ItemArt.register_fish_portrait ile kartlara ve ikonlara
## verilir. Ersin'in balık görselleri gelince onlar kullanılır (ItemArt önce dosyaya bakar).
## Ekransız çalışmada (testler, headless) çizim olmaz; yer tutucu madalyon kalır.

const SIZE := 256


## Bütün balıkların portresini çizer (birkaç kare sürer; await ile beklenir).
static func render_all(parent: Node, db: ContentDB) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for f in db.fish:
		await render(parent, f)


static func render(parent: Node, def: Dictionary) -> void:
	var fish := FishMesh.make(def, 1.0)
	fish.set_wiggle(0.0, 0.0)
	# Hafifçe eğik: hem yandan hem biraz yukarıdan.
	fish.rotation = Vector3(deg_to_rad(-12.0), deg_to_rad(-18.0), deg_to_rad(8.0))
	var texture := await PortraitStudio.shoot(parent, fish, Vector3(0.0, 0.25, 3.0), Vector3.ZERO, 1.15, SIZE)
	if texture != null:
		ItemArt.register_fish_portrait(str(def["id"]), texture)
