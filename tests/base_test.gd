class_name BaseTest
extends RefCounted
## Basit test temel sınıfı. tests/test_*.gd dosyaları bundan türer; "test_" ile
## başlayan her metot ayrı bir testtir (her biri için yeni bir örnek oluşturulur).

static var _db: ContentDB

var failures: PackedStringArray = []


## Testler arasında paylaşılan içerik veritabanı (bir kez yüklenir).
static func content() -> ContentDB:
	if _db == null:
		_db = ContentDB.load_default()
	return _db


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		failures.append(message if not message.is_empty() else "koşul sağlanmadı")


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if not _equal(actual, expected):
		failures.append("%s (beklenen: %s, gelen: %s)" % [message, str(expected), str(actual)])


func assert_between(value: float, low: float, high: float, message: String = "") -> void:
	if value < low or value > high:
		failures.append("%s (%s, [%s, %s] aralığında değil)" % [message, str(value), str(low), str(high)])


static func _equal(a: Variant, b: Variant) -> bool:
	# İki tamsayı tam eşit olmalı (is_equal_approx büyük sayılarda 1e-5 oranında pay bırakır).
	if typeof(a) == TYPE_INT and typeof(b) == TYPE_INT:
		return a == b
	var numeric := [TYPE_INT, TYPE_FLOAT]
	if typeof(a) in numeric and typeof(b) in numeric:
		return is_equal_approx(float(a), float(b))
	if typeof(a) != typeof(b):
		return false
	return a == b
