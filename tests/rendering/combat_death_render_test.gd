extends Node3D


func _ready() -> void:
	var world := SimulationWorld.new()

	var first_entity: int = (
		world.entities.create_entity(
			0,
			0,
			Vector3.ZERO,
			100.0,
			0.5,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0
		)
	)

	var second_entity: int = (
		world.entities.create_entity(
			0,
			0,
			Vector3(
				2.0,
				0.0,
				0.0
			),
			100.0,
			0.5,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0
		)
	)

	assert(
		EntityId.is_valid(first_entity)
		and EntityId.is_valid(second_entity),
		"Render death test entities should spawn."
	)

	world.rebuild_spatial_grid()

	var renderer := UnitMultiMeshRenderer.new()

	add_child(renderer)

	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		1.0,
		1.0,
		1.0
	)

	assert(
		renderer.register_prototype(
			0,
			mesh,
			mesh,
			0.5,
			100.0
		),
		"Test render prototype should register."
	)

	assert(
		renderer.build(world),
		"Renderer should build successfully."
	)

	assert(
		renderer.rendered_instance_count() == 2,
		"Both living entities should initially render."
	)

	var first_index: int = (
		world.entities.get_index_if_alive(
			first_entity
		)
	)

	var selected := PackedInt32Array()
	selected.append(first_index)

	assert(
		renderer.set_selected_entity_indices(
			selected
		) == 1,
		"First entity should be highlightable before death."
	)

	var damage_result: int = (
		world.apply_damage(
			first_entity,
			1000.0
		)
	)

	assert(
		damage_result
		== CombatSystem.DamageResult.DESTROYED,
		"First entity should be destroyed."
	)

	var destroyed_indices: PackedInt32Array = (
		world.consume_destroyed_entity_indices()
	)

	assert(
		destroyed_indices.size() == 1,
		"Exactly one destroyed entity should be queued."
	)

	assert(
		renderer.remove_destroyed_entity_indices(
			destroyed_indices
		) == 1,
		"Renderer should remove exactly one destroyed entity."
	)

	assert(
		renderer.rendered_instance_count() == 1,
		"Only the surviving entity should remain rendered."
	)

	assert(
		world.entities.alive_count() == 1,
		"Only one logical entity should remain alive."
	)

	assert(
		world.consume_destroyed_entity_indices().is_empty(),
		"Destroyed-entity queue should clear after consumption."
	)

	print(
		(
			"COMBAT DEATH RENDER PASS | "
			+ "2 rendered -> 1 rendered | "
			+ "2 alive -> 1 alive"
		)
	)
