class_name SaveStore
extends RefCounted
## Kaydı JSON olarak diske yazar/okur. Yazma önce .tmp dosyasına yapılır, sonra
## asıl dosyanın yerine taşınır; böylece yarıda kalan yazma kaydı bozmaz.


static func write(save: SaveData, path: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Kayıt yazılamadı: %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	var ok := f.store_string(JSON.stringify(save.to_dict(), "\t"))
	f.close()
	if not ok:
		push_error("Kayıt yazılamadı: " + tmp)
		return false
	var abs_tmp := ProjectSettings.globalize_path(tmp)
	var abs_path := ProjectSettings.globalize_path(path)
	if DirAccess.rename_absolute(abs_tmp, abs_path) != OK:
		DirAccess.remove_absolute(abs_path)
		if DirAccess.rename_absolute(abs_tmp, abs_path) != OK:
			push_error("Kayıt dosyası yerine taşınamadı: " + path)
			return false
	return true


## Dosya yoksa ya da okunamıyorsa null döner; çağıran yeni kayıt açar ve yazar. Bu yüzden
## okunamayan dosya önce kenara alınır, üstüne yazılmaz: bozuksa "<ad>.corrupt", daha yeni bir
## sürümün kaydıysa (eski bir yapı yüklendiyse) "<ad>.newer".
static func read(path: String) -> SaveData:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		_set_aside(path, ".corrupt")
		return null
	var data: Dictionary = json.data
	if SaveData.is_newer(data):
		_set_aside(path, ".newer")
		return null
	var save := SaveData.from_dict(data)
	if save == null:
		_set_aside(path, ".corrupt")
	return save


static func _set_aside(path: String, suffix: String) -> void:
	var abs_path := ProjectSettings.globalize_path(path)
	var backup := abs_path + suffix
	DirAccess.remove_absolute(backup)
	DirAccess.rename_absolute(abs_path, backup)
	push_warning("Okunamayan kayıt kenara alındı: " + backup)
