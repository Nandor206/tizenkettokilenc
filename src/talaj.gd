extends MeshInstance3D

func _ready():
	# Létrehozunk egy új anyagot, ha még nincs
	var mat = material_override
	if mat == null:
		mat = StandardMaterial3D.new()
		material_override = mat
	
	# Szín beállítása
	#mat.albedo_color = Color(1.0, 0.0, 0.0)  # Piros szín
