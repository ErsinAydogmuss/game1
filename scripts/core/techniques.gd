class_name Techniques
extends RefCounted
## Teknik kimliğinden strateji kurar (FishingSession). Kurulamayan (henüz yazılmamış ya da
## bilinmeyen) kimlik şamandıra olur.

## Kurulabilen teknikler (Dalga 3'te sırayla eklenir).
const KNOWN: Array[String] = ["float", "spin"]


## Bu kimlikle kurulacak tekniğin kimliği.
static func resolve(id: String) -> String:
	return id if id in KNOWN else "float"


static func make(id: String, rules: FishingRules) -> Technique:
	match resolve(id):
		"spin":
			return SpinTechnique.new(rules)
		_:
			return FloatTechnique.new(rules)
