extends Node3D

@export var INTENSITY:float = 4.0;

func _ready() -> void:
	for pieces:RigidBody3D in $torott.get_children():
		pieces.apply_impulse( pieces.get_child(0).position*INTENSITY, self.global_position );

	await get_tree().create_timer(120).timeout;
	queue_free();
