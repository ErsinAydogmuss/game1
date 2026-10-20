class_name RodModel
extends Node3D
## Olta: sap, makara ve üç eklemli kamış. Kökü bu düğümün yerinde; kamış -Z'ye uzanır. Ucundaki
## işaretçiden (tip) misina çıkar. bend (0..1): gerilimle uca doğru artan bükülme; bekleyişte
## hafifçe esner. Kare başı hareket _process'te.
## Görünüş kamışın kimliğinden (gear_id → LOOKS; renkler dükkândaki resimlerden): boy, kalınlık,
## kamışın rengi (dip parçası ayrı olabilir), sargılar, halkalar, sap (mantar, EVA ya da sinekte
## uzun mantar), dip kapağı, bambuda boğumlar. Makara kuşanılan makaranın renginde (reel_id →
## REEL_LOOKS): sinek kamışında yuvarlak sinek makarası, ötekilerde çıkrık. Bilinmeyen kamışta
## tekniğin ilk kamışının görünüşü (style → STYLES). Hepsi build()'den (ağaca eklenince) önce verilir.
## Parçalar Props ile kurulur, MeshBatch ile birleşir: sabit kısım ve her eklem birer ağ (olta 4
## çizim; eklemler ayrı kaldığı için bükülme sürer).

## Tekniğe göre varsayılan görünüş (gear_id bilinmiyorsa): tekniğin ilk kamışı.
const STYLES := { "float": "rod_bamboo", "spin": "rod_spin_light", "bottom": "rod_carp_1", "fly": "rod_fly_1" }
## Kamışların görünüşü (gear.json kimliğiyle). technique: kamışın tekniği (test denetler); length (m),
## thick (kalınlık çarpanı); blank: kamış, butt: dip parçası (verilmezse blank); wrap: sargılar ve
## parça birleşimleri; guide: halkalar; grip: "cork", "eva" ya da "long_cork"; cap: dip kapağı ve
## makara yuvası; nodes: bambu boğumları.
const LOOKS := {
	"rod_bamboo": { "technique": "float", "length": 2.3, "thick": 1.0, "blank": "#d9963a", "wrap": "#a86424",
			"guide": "#3fb6c8", "grip": "cork", "cap": "#c9d2dc", "nodes": true },
	"rod_float_glass": { "technique": "float", "length": 2.4, "thick": 0.95, "blank": "#2e8fe6", "wrap": "#1d5fae",
			"guide": "#c9d2dc", "grip": "cork", "cap": "#2e8fe6" },
	"rod_float_carbon": { "technique": "float", "length": 2.5, "thick": 0.9, "blank": "#2a2d33", "wrap": "#e0a92a",
			"guide": "#e0a92a", "grip": "eva", "cap": "#e0a92a" },
	"rod_spin_light": { "technique": "spin", "length": 1.8, "thick": 0.85, "blank": "#5cbf34", "wrap": "#3a8a22",
			"guide": "#c9d2dc", "grip": "cork", "cap": "#5cbf34" },
	"rod_spin_medium": { "technique": "spin", "length": 1.9, "thick": 0.9, "blank": "#f07d24", "wrap": "#b85614",
			"guide": "#c9d2dc", "grip": "cork", "cap": "#f07d24" },
	"rod_spin_heavy": { "technique": "spin", "length": 2.0, "thick": 1.0, "blank": "#d42b2b", "butt": "#2a2d33",
			"wrap": "#2a2d33", "guide": "#c9d2dc", "grip": "eva", "cap": "#e0a92a" },
	"rod_carp_1": { "technique": "bottom", "length": 2.6, "thick": 1.15, "blank": "#6e8c2c", "wrap": "#4d6b1c",
			"guide": "#c9d2dc", "grip": "cork", "cap": "#5d7a26" },
	"rod_carp_2": { "technique": "bottom", "length": 2.7, "thick": 1.15, "blank": "#2c5a30", "wrap": "#e0a92a",
			"guide": "#e0a92a", "grip": "cork", "cap": "#2c5a30" },
	"rod_carp_3": { "technique": "bottom", "length": 2.8, "thick": 1.1, "blank": "#2a2d33", "wrap": "#e0a92a",
			"guide": "#e0a92a", "grip": "eva", "cap": "#e0a92a" },
	"rod_fly_1": { "technique": "fly", "length": 2.7, "thick": 0.75, "blank": "#b8682e", "wrap": "#7a3e18",
			"guide": "#c9d2dc", "grip": "long_cork", "cap": "#c9d2dc" },
	"rod_fly_2": { "technique": "fly", "length": 2.8, "thick": 0.72, "blank": "#2a63d6", "wrap": "#c9d2dc",
			"guide": "#c9d2dc", "grip": "long_cork", "cap": "#2a63d6" },
	"rod_fly_3": { "technique": "fly", "length": 2.9, "thick": 0.7, "blank": "#d48c2c", "wrap": "#e0a92a",
			"guide": "#e0a92a", "grip": "long_cork", "cap": "#e0a92a" },
}
## Makaraların renkleri (gear.json kimliğiyle): gövde, makara kafası, sarılı misina, kolun topuzu.
const REEL_LOOKS := {
	"reel_basic": { "body": "#c9d2dc", "spool": "#7d8794", "line": "#f4f2e8", "knob": "#3a3f47" },
	"reel_smooth": { "body": "#2e7fe0", "spool": "#1f5cb0", "line": "#ffd23f", "knob": "#3a3f47" },
	"reel_quick": { "body": "#3fae3a", "spool": "#e0a92a", "line": "#ffd23f", "knob": "#3a3f47" },
	"reel_strong": { "body": "#f07a22", "spool": "#2a2d33", "line": "#ffd23f", "knob": "#3a3f47" },
	"reel_pro": { "body": "#3a3f47", "spool": "#c9d2dc", "line": "#ffd23f", "knob": "#2a2d33" },
	"reel_master": { "body": "#ffc83a", "spool": "#2a2d33", "line": "#ffd23f", "knob": "#2a2d33" },
}
const DEFAULT_REEL := "reel_basic"
## Sapların rengi.
const CORK := Color("#c98a4b")
const EVA := Color("#2b2b30")
## Eklemlerin bükülme payı (kökten uca).
const BEND := [0.1, 0.22, 0.38]
## İlk eklemin yeri (kökten; sapın önü bunu biraz örter).
const JOINT0_Z := -0.08

## Gerilim (0 = gevşek, 1 = çok gergin).
var bend: float = 0.0
var tip: Node3D
## Tekniği (STYLES), kamışın ve makaranın kimliği (LOOKS, REEL_LOOKS); build()'den önce verilir.
var style: String = "float"
var gear_id: String = ""
var reel_id: String = ""

var _joints: Array[Node3D] = []
var _clock: float = 0.0


## Kamışın görünüşü: kimliğin görünüşü, yoksa tekniğin ilk kamışınınki.
static func look_of(rod_id: String, technique: String) -> Dictionary:
	if LOOKS.has(rod_id):
		return LOOKS[rod_id]
	return LOOKS[str(STYLES.get(technique, STYLES["float"]))]


static func reel_look_of(id: String) -> Dictionary:
	return REEL_LOOKS.get(id, REEL_LOOKS[DEFAULT_REEL])


func _ready() -> void:
	if tip == null:
		build()


## Parçaları kurar ve birleştirir (bir kez; _ready kurar, testler doğrudan çağırabilir).
func build() -> void:
	if tip != null:
		return
	var look := look_of(gear_id, style)
	var reel := reel_look_of(reel_id)
	var long_grip := str(look["grip"]) == "long_cork"
	var grip := EVA if str(look["grip"]) == "eva" else CORK
	var cap := Color(str(look["cap"]))
	var x90 := Vector3(deg_to_rad(90.0), 0, 0)
	if long_grip:
		# Sinek: uzun mantar sap, arkasında makara yuvası ve dip kapağı.
		Props.cylinder(self, 0.025, 0.027, 0.34, Vector3(0, 0, 0.03), grip, 7, x90)
		Props.cylinder(self, 0.022, 0.022, 0.08, Vector3(0, 0, 0.24), cap, 6, x90)
		Props.cylinder(self, 0.026, 0.026, 0.03, Vector3(0, 0, 0.295), cap, 6, x90)
		_fly_reel(reel, 0.24)
	else:
		# Ön sap, makara yuvası, arka sap ve dip kapağı; makara elin arkasında, yuvanın altında.
		Props.cylinder(self, 0.024, 0.026, 0.1, Vector3(0, 0, -0.07), grip, 7, x90)
		Props.cylinder(self, 0.021, 0.021, 0.1, Vector3(0, 0, 0.03), cap, 6, x90)
		Props.cylinder(self, 0.028, 0.03, 0.25, Vector3(0, 0, 0.205), grip, 7, x90)
		Props.cylinder(self, 0.031, 0.031, 0.025, Vector3(0, 0, 0.3425), cap, 7, x90)
		_spinning_reel(reel, 0.03)
	MeshBatch.merge(self)
	var parent: Node3D = self
	var segment := float(look["length"]) / 3.0
	var thick := float(look["thick"])
	var blank := Color(str(look["blank"]))
	var wrap := Color(str(look["wrap"]))
	var guide := Color(str(look["guide"]))
	for i in 3:
		var joint := Props.pivot(parent, Vector3(0, 0, JOINT0_Z if i == 0 else -segment), "Joint%d" % i)
		var r0 := (0.022 - 0.006 * i) * thick
		var r1 := maxf(r0 - 0.006 * thick, 0.005)
		var color := Color(str(look.get("butt", look["blank"]))) if i == 0 else blank
		Props.cylinder(joint, r1, r0, segment, Vector3(0, 0, -segment * 0.5), color, 6, -x90)
		# Parçaların birleşimi.
		if i < 2:
			Props.cylinder(joint, r1 + 0.004, r1 + 0.004, 0.024, Vector3(0, 0, -segment), wrap, 6, -x90)
		# Bambunun boğumları.
		if bool(look.get("nodes", false)):
			for f: float in [0.34, 0.68]:
				var r := lerpf(r0, r1, f) + 0.003
				Props.cylinder(joint, r, r, 0.014, Vector3(0, 0, -segment * f), wrap, 6, -x90)
		# Halkalar: altında küçük halka, üstünde sargı (uçta tepe halkası).
		for f: float in ([0.5, 0.92] if i < 2 else [0.45, 0.8]):
			var r := lerpf(r0, r1, f)
			Props.cylinder(joint, r + 0.003, r + 0.003, 0.018, Vector3(0, 0, -segment * f), wrap, 6, -x90)
			var ring := 0.013 - 0.003 * i
			Props.cylinder(joint, ring, ring, 0.004, Vector3(0, -(r + ring + 0.004), -segment * f), guide, 7, -x90)
		if i == 2:
			Props.cylinder(joint, r1 + 0.004, r1 + 0.004, 0.014, Vector3(0, 0, -segment + 0.007), guide, 6, -x90)
		_joints.append(joint)
		parent = joint
	tip = Props.pivot(parent, Vector3(0, 0, -segment), "Tip")
	for joint in _joints:
		MeshBatch.merge(joint)
	# Olta gölge haritasının bir pikselinden ince: gölgesi görünmez, gölge çizimi boşa gider.
	for node in find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Çıkrık (şamandıra, spin, dip): yuvanın altında ayağı, gövdesi, misina sarılı kafası ve yanda kolu.
func _spinning_reel(reel: Dictionary, z: float) -> void:
	var body := Color(str(reel["body"]))
	var forward := Vector3(deg_to_rad(-90.0), 0, 0)
	var side := Vector3(0, 0, deg_to_rad(90.0))
	Props.cylinder(self, 0.007, 0.009, 0.05, Vector3(0, -0.035, z), body, 5)
	Props.cylinder(self, 0.028, 0.032, 0.05, Vector3(0, -0.078, z + 0.012), body, 8, forward)
	Props.cylinder(self, 0.034, 0.034, 0.03, Vector3(0, -0.078, z - 0.028), Color(str(reel["line"])), 8, forward)
	Props.cylinder(self, 0.038, 0.038, 0.008, Vector3(0, -0.078, z - 0.046), Color(str(reel["spool"])), 8, forward)
	Props.cylinder(self, 0.005, 0.005, 0.06, Vector3(0.045, -0.078, z + 0.016), body, 5, side)
	Props.cylinder(self, 0.011, 0.011, 0.024, Vector3(0.082, -0.094, z + 0.016), Color(str(reel["knob"])), 6, side)


## Sinek makarası: sapın arkasında, yanı kameraya dönük yuvarlak makara (gövde, kafa, topuz).
func _fly_reel(reel: Dictionary, z: float) -> void:
	var side := Vector3(0, 0, deg_to_rad(90.0))
	Props.cylinder(self, 0.006, 0.006, 0.03, Vector3(0, -0.028, z), Color(str(reel["body"])), 5)
	Props.cylinder(self, 0.05, 0.05, 0.024, Vector3(0, -0.07, z), Color(str(reel["body"])), 12, side)
	Props.cylinder(self, 0.038, 0.038, 0.028, Vector3(0, -0.07, z), Color(str(reel["spool"])), 12, side)
	Props.cylinder(self, 0.007, 0.007, 0.022, Vector3(0.024, -0.05, z), Color(str(reel["knob"])), 5, side)


func _process(delta: float) -> void:
	_clock += delta
	# Bekleyişte hafif esneme; gerilimde aşağı (balığa doğru) bükülme ve titreme.
	var sway := sin(_clock * 1.7) * 0.015 * (1.0 - clampf(bend, 0.0, 1.0))
	var shiver := sin(_clock * 37.0) * 0.012 * clampf(bend - 0.6, 0.0, 1.0)
	for i in _joints.size():
		var amount: float = BEND[i]
		_joints[i].rotation.x = -(bend * amount) + sway * (i + 1) + shiver
