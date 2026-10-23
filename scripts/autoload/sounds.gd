extends Node
## Oyunun sesleri (autoload "Sounds"): kısa efektler, döngüler (makara, gerilim), ortam sesi ve
## müzik. Ses dosyaları kodla üretilir (tools/make_sounds.py → assets/audio/); bir dosya yoksa
## o ses sessizce atlanır (ResourceLoader.exists). Kayıtla ilgisi olmayan sunum katmanıdır:
## scripts/core bu düğümü kullanmaz. (Kazı'nın ses motorundan uyarlandı.)
##
## Kanallar: "SFX" (efektler, döngüler, ortam) ve "Music". Ayarlar: "sfx", "music" (açık/kapalı).
## Efektlerin her biri birkaç çeşittir (ad_1, ad_2...): art arda aynısı çalmaz, perdesi de
## hafifçe oynar (kulağı yormasın). Aynı ses çok sık istenirse atlanır.

const SFX_DIR := "res://assets/audio/sfx/"
const LOOP_DIR := "res://assets/audio/loops/"
const AMBIENCE_DIR := "res://assets/audio/ambience/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL_SIZE := 12
## Aynı ses en az bu aralıkla (saniye) yeniden çalınır.
const MIN_GAP := 0.035
## Efektler: ad -> [ses (dB), perde çeşitlemesi (±oran), aynı anda en fazla].
const BANK := {
	"cast": [-8.0, 0.05, 1], "plop": [-7.0, 0.06, 2], "nibble": [-9.0, 0.08, 2],
	"bite": [-4.0, 0.03, 1], "hook": [-6.0, 0.04, 1], "warn": [-7.0, 0.03, 1],
	"snap": [-5.0, 0.04, 1], "escape": [-8.0, 0.04, 1], "splash": [-7.0, 0.06, 2],
	"step": [-18.0, 0.08, 2], "scare": [-11.0, 0.06, 1], "reel_in": [-10.0, 0.04, 1],
	"find_1": [-8.0, 0.0, 1], "find_2": [-7.0, 0.0, 1], "find_3": [-6.0, 0.0, 1], "find_4": [-5.0, 0.0, 1],
	"find_5": [-4.0, 0.0, 1], "record": [-8.0, 0.0, 1], "error": [-10.0, 0.0, 1],
	"ui_tap": [-12.0, 0.04, 2], "panel_open": [-11.0, 0.03, 1], "panel_close": [-12.0, 0.03, 1],
	"card": [-11.0, 0.05, 2], "hint": [-12.0, 0.0, 1],
	"coins": [-9.0, 0.0, 1], "buy": [-9.0, 0.0, 1], "equip": [-11.0, 0.04, 1], "sting": [-8.0, 0.0, 1],
	"rank_up": [-9.0, 0.0, 1], "travel": [-10.0, 0.0, 1],
	"lure": [-8.0, 0.06, 2], "strike": [-4.0, 0.03, 1], "snag": [-8.0, 0.0, 1], "bell": [-7.0, 0.05, 2],
	"rise": [-5.0, 0.08, 2], "trap_place": [-6.0, 0.05, 1], "trap_collect": [-7.0, 0.04, 1],
	# Dalga 4: Masalsı buluntu, fırtınada gök gürültüsü, Dede'yle çay, vakit değişimi, Nine'nin feneri, göl
	# sevgisinin seviyesi, çöp.
	"find_6": [-3.0, 0.0, 1], "thunder": [-7.0, 0.05, 1], "tea": [-9.0, 0.03, 1], "phase": [-12.0, 0.0, 1],
	"lantern": [-9.0, 0.0, 1], "love_up": [-8.0, 0.0, 1], "trash": [-8.0, 0.04, 1],
	# Gölün Sırrı: şişe alındı, mektup açıldı; final: Gölün Bekçisi dalıyor.
	"bottle": [-7.0, 0.03, 1], "paper": [-9.0, 0.05, 1], "dive": [-5.0, 0.04, 1],
}
## Döngüler: ad -> ses (dB).
const LOOPS := { "reel": -12.0, "strain": -14.0, "bell_run": -9.0 }
## Müzik parçaları (Dalga 4): dört vaktin sakin döngüleri, Nine'nin dükkânının valsi, Gölün Bekçisi'nin parçası
## (karşılaşma ve çekişme) ve bitişin parçası (bitiş filmi, jenerik) (music/<ad>.ogg).
const MUSIC := ["morning", "noon", "evening", "night", "shop", "keeper", "ending"]
## Ortam sesleri: göl (gündüz), gece (cırcır böceği, kurbağa), yağmur (ambience/<ad>.ogg).
const AMBIENCE := ["lake", "night", "rain"]
const MUSIC_DB := -15.0
const AMBIENCE_DB := -12.0
const FADE_TIME := 2.0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _playing_name: Dictionary = {}
var _last_variant: Dictionary = {}
var _last_time: Dictionary = {}
var _loops: Dictionary = {}
var _music: Array[AudioStreamPlayer] = []
var _music_current: int = 0
var _music_name: String = ""
var _ambience: Array[AudioStreamPlayer] = []
var _ambience_current: int = 0
var _ambience_name: String = ""
## Sürmekte olan müzik / ortam geçişleri: yenisi başlarken iptal edilir.
var _music_tween: Tween
var _ambience_tween: Tween
var _clock: float = 0.0
var _next_player: int = 0
## Ekransız (headless) çalışmada (testler, ana sahne denetimi) ses çalınmaz.
var _silent: bool = false
## stop_all'dan sonra (çıkış) hiçbir ses yeniden başlamaz: main her kare ortam sesini verir.
var _halted: bool = false
## Müzik parçalarının kaldığı yer (sn): dükkândan çıkınca vaktin müziği baştan başlamasın.
var _music_pos: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_silent = DisplayServer.get_name() == "headless"
	_make_bus("SFX")
	_make_bus("Music")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = &"Music"
		m.volume_db = -80.0
		add_child(m)
		_music.append(m)
		var a := AudioStreamPlayer.new()
		a.bus = &"SFX"
		a.volume_db = -80.0
		add_child(a)
		_ambience.append(a)
	for loop_name: String in LOOPS:
		var lp := AudioStreamPlayer.new()
		lp.bus = &"SFX"
		lp.stream = _load_loop(LOOP_DIR + loop_name + ".wav")
		lp.volume_db = -80.0
		add_child(lp)
		_loops[loop_name] = lp
	GameState.changed.connect(apply_settings)
	apply_settings()
	get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	_clock += delta


func _exit_tree() -> void:
	stop_all()


## Bütün sesleri durdurur ve akışları bırakır. Çıkmadan bir iki kare önce çağrılırsa ses
## sunucusu çalanları bırakmaya fırsat bulur (yoksa motor çıkışta sızıntı uyarısı verir).
func stop_all() -> void:
	_halted = true
	for tween: Tween in [_music_tween, _ambience_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	_music_name = ""
	_ambience_name = ""
	for child in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
			(child as AudioStreamPlayer).stream = null


## Ayarlardaki ses ve müzik açma / kapamayı uygular.
func apply_settings() -> void:
	var settings := GameState.save.settings
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"SFX"), not bool(settings.get("sfx", true)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), not bool(settings.get("music", true)))


## Kısa bir efekt çalar. volume_db: BANK'taki sese eklenir; pitch: perde çarpanı.
func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not BANK.has(sound):
		push_warning("Bilinmeyen ses: " + sound)
		return
	if _silent or _halted:
		return
	var variants := _variants(sound)
	if variants.is_empty():
		return
	if _clock - float(_last_time.get(sound, -1.0)) < MIN_GAP:
		return
	var spec: Array = BANK[sound]
	if _count_playing(sound) >= int(spec[2]):
		return
	_last_time[sound] = _clock
	var index := randi() % variants.size()
	if variants.size() > 1 and index == int(_last_variant.get(sound, -1)):
		index = (index + 1) % variants.size()
	_last_variant[sound] = index
	var player := _free_player()
	player.stream = variants[index]
	player.volume_db = float(spec[0]) + volume_db
	var jitter := float(spec[1])
	player.pitch_scale = pitch * (1.0 + randf_range(-jitter, jitter))
	player.play()
	_playing_name[player] = sound


## Balık tutuldu (kart görünürken): nadirliğe göre (0 Sıradan .. 5 Masalsı → find_1..6).
func find(rarity: int) -> void:
	play("find_%d" % clampi(rarity + 1, 1, 6))


## Bir döngüyü (makara, gerilim) açar / kapatır; açıkken sesi ve perdesi değiştirilebilir.
func set_loop(loop_name: String, on: bool, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var player: AudioStreamPlayer = _loops.get(loop_name)
	if player == null or player.stream == null or _silent or _halted:
		return
	if on:
		player.volume_db = float(LOOPS[loop_name]) + volume_db
		player.pitch_scale = pitch
		if not player.playing:
			player.play()
	elif player.playing:
		player.stop()


## Ortam sesi (AMBIENCE: "lake", "night", "rain"): yumuşak geçişle değişir.
func set_ambience(track: String) -> void:
	if not _silent:
		_switch(_ambience, track, AMBIENCE_DIR, AMBIENCE_DB, false)


## Müzik (MUSIC: vaktin adı ya da "shop"): yumuşak geçişle değişir. Dosya yoksa sessiz kalır.
func set_music(track: String) -> void:
	if not _silent:
		_switch(_music, track, MUSIC_DIR, MUSIC_DB, true)


## Çalan müzik ve ortam sesi (bot denetimi; yoksa "").
func music_name() -> String:
	return _music_name


func ambience_name() -> String:
	return _ambience_name


## Titreşim (ayarlarda açıksa). amplitude 0..1 (destekleyen cihazlarda).
func haptic(ms: int, amplitude: float = -1.0) -> void:
	if bool(GameState.save.settings.get("vibration", true)):
		Input.vibrate_handheld(ms, amplitude)


# --- İç işler ----------------------------------------------------------------------

func _variants(sound: String) -> Array:
	if _streams.has(sound):
		return _streams[sound]
	var out: Array = []
	for i in range(1, 9):
		var path := "%s%s_%d.wav" % [SFX_DIR, sound, i]
		if not ResourceLoader.exists(path):
			break
		out.append(load(path))
	_streams[sound] = out
	return out


func _count_playing(sound: String) -> int:
	var count := 0
	for p: AudioStreamPlayer in _players:
		if p.playing and str(_playing_name.get(p, "")) == sound:
			count += 1
	return count


## Boştaki bir oynatıcı; hepsi doluysa sırayla en eskisi.
func _free_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _players:
		if not p.playing:
			return p
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	return p


## İki oynatıcıyla yumuşak geçiş: yeni parça yükselirken eskisi söner.
func _switch(pair: Array[AudioStreamPlayer], track: String, dir: String, volume_db: float, music: bool) -> void:
	var current_name := _music_name if music else _ambience_name
	if track == current_name or _halted:
		return
	var stream := _load_loop(dir + track + ".ogg")
	if stream == null:
		return
	var index := _music_current if music else _ambience_current
	var old := pair[index]
	var fresh := pair[1 - index]
	if music:
		_music_name = track
		_music_current = 1 - index
	else:
		_ambience_name = track
		_ambience_current = 1 - index
	var previous := _music_tween if music else _ambience_tween
	if previous != null and previous.is_valid():
		previous.kill()
	fresh.stream = stream
	fresh.volume_db = -60.0
	# Müzik kaldığı yerden sürer (dükkândan dönünce vaktin müziği baştan başlamaz); ortam sesi baştan.
	if music and old.playing and not current_name.is_empty():
		_music_pos[current_name] = old.get_playback_position()
	fresh.play(float(_music_pos.get(track, 0.0)) if music else 0.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fresh, "volume_db", volume_db, FADE_TIME).set_trans(Tween.TRANS_SINE)
	if old.playing:
		tween.tween_property(old, "volume_db", -60.0, FADE_TIME).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_callback(old.stop)
	if music:
		_music_tween = tween
	else:
		_ambience_tween = tween


## Döngü olarak çalınacak ses (ogg ya da wav); yoksa null.
func _load_loop(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(round(wav.get_length() * wav.mix_rate))
	return stream


func _make_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")


## Arayüzdeki her düğmeye basınca hafif bir tık (TouchButton kendi tıkını çalar).
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(func() -> void: play("ui_tap"))
