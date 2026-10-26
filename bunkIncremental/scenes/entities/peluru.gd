extends Node2D
## Peluru — bergerak lurus dan memakai raycast per frame, bukan Area2D.
##
## Alasannya: Area2D bisa "menembus" zombie kalau peluru bergerak cepat
## dan framerate turun. Raycast selalu mendeteksi apa pun yang dilewati.

@export var kecepatan: float = 520.0

var arah: Vector2 = Vector2.RIGHT
var damage: float = 10.0

var _umur: float = 1.4


func _ready() -> void:
	rotation = arah.angle()


func _physics_process(delta: float) -> void:
	var asal := global_position
	var tujuan := asal + arah * kecepatan * delta

	# Mask 4 = layer 3 (Zombie) saja.
	var kueri := PhysicsRayQueryParameters2D.create(asal, tujuan, 4)
	var hasil := get_world_2d().direct_space_state.intersect_ray(kueri)

	if not hasil.is_empty():
		var target = hasil.get("collider")
		if target != null and target.has_method("terima_damage"):
			target.terima_damage(damage)
		queue_free()
		return

	global_position = tujuan
	_umur -= delta
	if _umur <= 0.0 or global_position.x < -30.0 or global_position.x > 720.0:
		queue_free()
