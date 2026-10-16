class_name AimModifier
extends SkeletonModifier3D
## Animasyonun üstüne gövde eğimi ekler: kazılan blok aşağıdaysa Kazım öne eğilir, yukarıdaysa
## geriye yaslanır (hazır animasyon tek yöne vurur). Matkapta gövdeyi hafifçe titretir.
## Skeleton3D'nin çocuğu olmalı; AnimationTree'den sonra çalışır.

## Öne eğilme açısı (radyan, + öne). Omurga ve göğüs arasında paylaştırılır.
var pitch: float = 0.0
## Titreşim genliği (radyan).
var shake: float = 0.0

var _bones := PackedInt32Array()
var _time: float = 0.0


func _process_modification_with_delta(delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	_time += delta
	if _bones.is_empty():
		for bone_name: String in ["spine", "chest"]:
			_bones.append(skeleton.find_bone(bone_name))
	var amount := pitch + sin(_time * 63.0) * shake
	if absf(amount) < 0.0005:
		return
	for bone in _bones:
		if bone < 0:
			continue
		# Gövdenin yan ekseni (iskelet uzayında +X) üst kemiğin uzayına çevrilir: hazır duruş
		# kemikleri döndürmüş olsa da (nişan duruşu) eğilme yana değil öne-arkaya olur.
		var parent := skeleton.get_bone_parent(bone)
		var basis := skeleton.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
		var side := (basis.inverse() * Vector3.RIGHT).normalized()
		var rotation := skeleton.get_bone_pose_rotation(bone)
		skeleton.set_bone_pose_rotation(bone, Quaternion(side, amount * 0.5) * rotation)
