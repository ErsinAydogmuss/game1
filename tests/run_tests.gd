extends SceneTree
## Headless test koşucusu.
##   godot --headless --path . -s res://tests/run_tests.gd
## tests/test_*.gd dosyalarındaki test_* metotlarını çalıştırır. Bir test başarısız olursa
## ya da çalışırken motor/script hatası üretirse çıkış kodu 1 olur.


class ErrorCatcher:
	extends Logger

	var count: int = 0
	var last: String = ""
	var _mutex := Mutex.new()

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		count += 1
		last = "%s:%d %s %s" % [file, line, code, rationale]
		_mutex.unlock()


func _initialize() -> void:
	var catcher := ErrorCatcher.new()
	OS.add_logger(catcher)
	var total := 0
	var failed := 0
	var files := Array(DirAccess.get_files_at("res://tests"))
	files.sort()
	for file: String in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load("res://tests/" + file)
		if script == null or not script.can_instantiate():
			# Ayrıştırma hatası olan test dosyası sessizce atlanmasın.
			total += 1
			failed += 1
			printerr("  HATA  %s :: yüklenemedi (ayrıştırma hatası?) — %s" % [file, catcher.last])
			continue
		for method: Dictionary in script.get_script_method_list():
			var method_name := str(method["name"])
			if not method_name.begins_with("test_"):
				continue
			total += 1
			var test: BaseTest = script.new()
			var errors_before := catcher.count
			test.call(method_name)
			if catcher.count > errors_before:
				test.failures.append("çalışma hatası: " + catcher.last)
			if test.failures.is_empty():
				print("  ok    %s :: %s" % [file, method_name])
			else:
				failed += 1
				for line in test.failures:
					printerr("  HATA  %s :: %s — %s" % [file, method_name, line])
	OS.remove_logger(catcher)
	print("%d test, %d başarısız" % [total, failed])
	quit(1 if failed > 0 or total == 0 else 0)
