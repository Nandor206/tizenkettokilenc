extends Node3D

@export var broken_model: PackedScene

func _ready() -> void:
	# Jel figyelése az ütközésre
	$Area3D.body_entered.connect(_on_body_entered);

func _on_body_entered(body: Node) -> void:
	# Ellenőrizzük, hogy a repülővel történt-e az ütközés
	if body.name == "Repcsi":  # Azonosítsd a repülőt a nevével vagy egy csoporttal
		print("Breaking")
		
		var broken_model_inst: Node3D = broken_model.instantiate()
		
		get_parent().add_child(broken_model_inst)
		broken_model_inst.transform = self.transform
		
		self.queue_free()
