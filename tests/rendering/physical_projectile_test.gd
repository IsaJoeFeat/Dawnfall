extends Node3D


const CONTENT_CATALOG: DefinitionCatalog = preload(
	"res://content/content_catalog.tres"
)

const SHOOTER_OWNER: int = 0
const TARGET_OWNER: int = 1
const SHOOTER_POSITION := Vector3(-75.0, 0.0, 0.0)
const TARGET_POSITION := Vector3(75.0, 0.0, 0.0)


var _simulation_world := SimulationWorld.new()
var _renderer: UnitMultiMeshRenderer
var _camera: RtsCameraController
var _hud_label: Label

var _projectile_multimesh: MultiMesh
var _projectile_preview: MultiMeshInstance3D

var _shooter_entity_id: int = EntityId.INVALID
var _target_entity_id: int = EntityId.INVALID

var _shots_fired: int = 0
var _last_fire_result: int = CombatSystem.FireResult.INVALID
var _finished: bool = false


func _ready() -> void:
	_create_environment()
	_create_ground()

	var registry := DefinitionRegistry.new()

	assert(
		CONTENT_CATALOG.load_into(registry),
		"Projectile test content catalog should load."
	)

	var tank: UnitDefinition = (
		registry.get_unit(
			&"unit_test_placeholder_tank"
		)
	)

	assert(
		tank != null,
		"Placeholder tank definition should exist."
	)

	assert(
		tank.weapons.size() >= 1,
		"Placeholder tank should have its cannon."
	)

	assert(
		tank.weapons[0].delivery_type
		== WeaponDefinition.DeliveryType.PROJECTILE,
		"Tank weapon slot 0 should be the projectile cannon."
	)

	assert(
		_simulation_world.set_owner_team(
			SHOOTER_OWNER,
			0
		)
	)

	assert(
		_simulation_world.set_owner_team(
			TARGET_OWNER,
			1
		)
	)

	_shooter_entity_id = (
		_simulation_world.spawn_unit(
			tank,
			0,
			SHOOTER_OWNER,
			SHOOTER_POSITION,
			-PI * 0.5
		)
	)

	_target_entity_id = (
		_simulation_world.spawn_unit(
			tank,
			0,
			TARGET_OWNER,
			TARGET_POSITION,
			PI * 0.5
		)
	)

	assert(
		EntityId.is_valid(_shooter_entity_id)
		and EntityId.is_valid(_target_entity_id),
		"Both projectile test tanks should spawn."
	)

	_simulation_world.rebuild_spatial_grid()

	_create_renderer()
	_create_projectile_preview()
	_create_camera()
	_create_hud()

	print(
		(
			"PHYSICAL PROJECTILE TEST READY | "
			+ "150 m shot | "
			+ "220 m/s shell | "
			+ "120 damage"
		)
	)


func _process(delta: float) -> void:
	if _finished:
		_sync_projectile_preview()
		return

	var completed_steps: int = (
		_simulation_world.advance(delta)
	)

	if completed_steps > 0:
		var destroyed_indices: PackedInt32Array = (
			_simulation_world.consume_destroyed_entity_indices()
		)

		if not destroyed_indices.is_empty():
			_renderer.remove_destroyed_entity_indices(
				destroyed_indices
			)

		var changed_indices: PackedInt32Array = (
			_simulation_world.consume_changed_transform_indices()
		)

		if not changed_indices.is_empty():
			_renderer.sync_changed_from_simulation(
				changed_indices
			)

	_try_fire_cannon()
	_sync_projectile_preview()
	_update_hud()

	if not _simulation_world.entities.is_alive(
		_target_entity_id
	):
		_finished = true

		print(
			(
				"PHYSICAL PROJECTILE PASS | "
				+ "%d shells fired | "
				+ "%d impacts | "
				+ "target destroyed"
			)
			% [
				_shots_fired,
				_simulation_world.total_projectile_impact_count,
			]
		)


func _try_fire_cannon() -> void:
	if not _simulation_world.entities.is_alive(
		_target_entity_id
	):
		return

	if _simulation_world.projectile_system.active_count() > 0:
		return

	_last_fire_result = (
		_simulation_world.fire_weapon(
			_shooter_entity_id,
			_target_entity_id,
			0
		)
	)

	if (
		_last_fire_result
		== CombatSystem.FireResult.FIRED
	):
		_shots_fired += 1


func _create_renderer() -> void:
	_renderer = UnitMultiMeshRenderer.new()
	_renderer.name = "TankRenderer"
	_renderer.render_chunk_size = 32.0
	add_child(_renderer)

	var near_material := StandardMaterial3D.new()

	near_material.albedo_color = Color.WHITE
	near_material.vertex_color_use_as_albedo = true
	near_material.roughness = 0.8

	var near_mesh := BoxMesh.new()

	near_mesh.size = Vector3(
		3.2,
		1.4,
		4.2
	)
	near_mesh.material = near_material

	var far_material := StandardMaterial3D.new()

	far_material.albedo_color = Color.WHITE
	far_material.vertex_color_use_as_albedo = true
	far_material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)
	far_material.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)

	var far_mesh := PlaneMesh.new()

	far_mesh.size = Vector2(
		1.2,
		1.6
	)
	far_mesh.material = far_material

	assert(
		_renderer.register_prototype(
			0,
			near_mesh,
			far_mesh,
			0.7,
			140.0
		),
		"Tank render prototype should register."
	)

	assert(
		_renderer.build(
			_simulation_world
		),
		"Tank renderer should build."
	)


func _create_projectile_preview() -> void:
	var shell_mesh := SphereMesh.new()

	shell_mesh.radius = 0.55
	shell_mesh.height = 1.1

	var shell_material := StandardMaterial3D.new()

	shell_material.albedo_color = Color(
		1.0,
		0.72,
		0.18
	)
	shell_material.emission_enabled = true
	shell_material.emission = Color(
		1.0,
		0.45,
		0.08
	)
	shell_material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	shell_mesh.material = shell_material

	_projectile_multimesh = MultiMesh.new()
	_projectile_multimesh.transform_format = (
		MultiMesh.TRANSFORM_3D
	)
	_projectile_multimesh.mesh = shell_mesh
	_projectile_multimesh.instance_count = 0

	_projectile_preview = MultiMeshInstance3D.new()
	_projectile_preview.name = "ProjectilePreview"
	_projectile_preview.multimesh = (
		_projectile_multimesh
	)
	_projectile_preview.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)

	add_child(_projectile_preview)


func _sync_projectile_preview() -> void:
	var projectile_count: int = (
		_simulation_world.projectile_system.active_count()
	)

	_projectile_multimesh.instance_count = (
		projectile_count
	)

	for projectile_index: int in range(
		projectile_count
	):
		_projectile_multimesh.set_instance_transform(
			projectile_index,
			Transform3D(
				Basis.IDENTITY,
				_simulation_world.projectile_system.positions[
					projectile_index
				]
			)
		)


func _create_camera() -> void:
	_camera = RtsCameraController.new()
	_camera.name = "RtsCameraController"
	_camera.minimum_distance = 20.0
	_camera.maximum_distance = 300.0
	add_child(_camera)

	_camera.configure(
		Vector3.ZERO,
		170.0
	)


func _create_hud() -> void:
	var canvas := CanvasLayer.new()

	canvas.name = "ProjectileHUD"
	canvas.layer = 50
	add_child(canvas)

	var panel := PanelContainer.new()

	panel.position = Vector2(
		16.0,
		16.0
	)
	panel.custom_minimum_size = Vector2(
		390.0,
		0.0
	)
	canvas.add_child(panel)

	_hud_label = Label.new()
	panel.add_child(_hud_label)

	_update_hud()


func _update_hud() -> void:
	var target_health: float = 0.0
	var target_alive: bool = (
		_simulation_world.entities.is_alive(
			_target_entity_id
		)
	)

	if target_alive:
		var target_index: int = (
			_simulation_world.entities.get_index_if_alive(
				_target_entity_id
			)
		)

		target_health = (
			_simulation_world.entities.current_health[
				target_index
			]
		)

	_hud_label.text = (
		"DAWNFALL — PHYSICAL PROJECTILE PROOF\n"
		+ "Tank cannon: 120 damage / 4.5 s reload\n"
		+ "Projectile speed: 220 m/s\n"
		+ "Shot distance: 150 m\n\n"
		+ "Target HP: %.0f\n"
		+ "Shells active: %d\n"
		+ "Shells fired: %d\n"
		+ "Shell impacts: %d\n"
		+ "Projectile simulation: %.3f ms\n\n"
		+ "Watch the orange shell cross the battlefield."
	) % [
		target_health,
		_simulation_world.projectile_system.active_count(),
		_shots_fired,
		_simulation_world.total_projectile_impact_count,
		_simulation_world.last_projectile_milliseconds,
	]


func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = (
		Environment.BG_COLOR
	)
	environment.background_color = Color(
		0.055,
		0.075,
		0.095
	)
	environment.ambient_light_source = (
		Environment.AMBIENT_SOURCE_COLOR
	)
	environment.ambient_light_color = Color(
		0.75,
		0.8,
		0.9
	)
	environment.ambient_light_energy = 0.75

	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()

	sunlight.rotation_degrees = Vector3(
		-55.0,
		-35.0,
		0.0
	)
	sunlight.light_color = Color(
		1.0,
		0.93,
		0.82
	)
	sunlight.light_energy = 1.1
	sunlight.shadow_enabled = false
	add_child(sunlight)


func _create_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var material := StandardMaterial3D.new()

	plane.size = Vector2(
		220.0,
		120.0
	)
	material.albedo_color = Color(
		0.18,
		0.24,
		0.16
	)
	material.roughness = 1.0

	plane.material = material
	ground.mesh = plane
	ground.position = Vector3(
		0.0,
		-0.05,
		0.0
	)
	add_child(ground)
