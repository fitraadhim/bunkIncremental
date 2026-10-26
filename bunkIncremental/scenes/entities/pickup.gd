extends Area2D
## Pickup — drop dari zombie. Ditarik ke arah pemain kalau sudah dekat,
## lalu masuk ke GameState saat tersentuh.

const TEKSTUR := {
	"minyak": preload("res://art/placeholder/pickup_minyak.png"),
	"logam": preload("res://art/placeholder/pickup_logam.png"),
	"obat": preload("res://art/placeholder/pickup_obat.png"),
}

const JARAK_MAGNET := 54.0
const KECEPATAN_MAGNET := 105.0
const UMUR_MAKS := 60.0

## Diisi sebelum add_child().
var jenis: String = "minyak"
var jumlah: int = 1

var _umur: float = UMUR_MAKS

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	if TEKSTUR.has(jenis):
		sprite.texture = TEKSTUR[jenis]
	_mulai_terapung()


func _process(delta: float) -> void:
	_umur -= delta
	if _umur <= 0.0:
		queue_free()
		return

	var pemain = get_tree().get_first_node_in_group("pemain")
	if pemain == null or not is_instance_valid(pemain):
		return

	var jarak: float = pemain.global_position.distance_to(global_position)
	if jarak > JARAK_MAGNET:
		return

	var arah: Vector2 = (pemain.global_position - global_position).normalized()
	var dorongan: float = 1.0 + (JARAK_MAGNET - jarak) / 24.0
	global_position += arah * KECEPATAN_MAGNET * dorongan * delta


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("pemain"):
		return
	GameState.tambah_resource(jenis, jumlah)
	queue_free()


func _mulai_terapung() -> void:
	var dasar := sprite.position.y
	var tw := create_tween().set_loops()
	tw.tween_property(sprite, "position:y", dasar - 1.5, 0.7)
	tw.tween_property(sprite, "position:y", dasar + 1.5, 0.7)
