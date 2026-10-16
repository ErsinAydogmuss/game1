class_name TimeProvider
extends RefCounted
## Zaman kaynağı. Offline kazanç gibi zamana bağlı sistemler saati buradan okur.
## İleride sunucu saatiyle değiştirilecek (cihaz saatini ileri alma hilesine karşı);
## testlerde fixed_unix ile sabit zaman verilebilir.

var fixed_unix: int = -1


func now_unix() -> int:
	if fixed_unix >= 0:
		return fixed_unix
	return int(Time.get_unix_time_from_system())
