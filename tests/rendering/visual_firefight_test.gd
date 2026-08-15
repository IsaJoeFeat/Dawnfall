extends Node3D


const CONTENT_CATALOG: DefinitionCatalog = preload(
	"res://content/content_catalog.tres"
)

const UNITS_PER_TEAM: int = 128
const FORMATION_COLUMNS: int = 16
const UNIT_SPACING: float = 2.2
const TEAM_SEPARATION: float = 140.0

const TEAM_ZERO_OWNER: int = 0
const TEAM_ONE_OWNER: int = 1


var _simulation_world := SimulationWorld.new()
var _renderer: UnitMultiMeshRenderer
var _camera: RtsCameraController
var _hud_label: Label

var _metrics_elapsed: float = 0.0
var _total_shots: int = 0
var _battle_finished: bool = false


func _ready() -> void:
	_create_environment()
	_create_ground()

	var registry := DefinitionRegistry.new()

	assert(
		CONTENT_CATALOG.load_into(registry),
		"Combat visual test content catalog should load."
	)

	var infantry: UnitDefinition = (
		registry.get_unit(
			&"unit_test_placeholder_infantry"
		)
	)

	assert(
		infantry != null,
		"Placeholder infantry definition should exist."
	)

	assert(
		not infantry.weapons.is_empty(),
		"Placeholder infantry requires its test rifle."
	)

	assert(
		_simulation_world.set_owner_team(
			TEAM_ZERO_OWNER,
			0
		),
		"Owner 0 should join team 0."
	)

	assert(
		_simulation_world.set_owner_team(
			TEAM_ONE_OWNER,
			1
		),
		"Owner 1 should join team 1."
	)

	_simulation_world.automatic_combat_enabled = true

	_spawn_army(
		infantry,
		TEAM_ZERO_OWNER,
		-TEAM_SEPARATION * 0.5,
		1.0
	)

	_spawn_army(
		infantry,
		TEAM_ONE_OWNER,
		TEAM_SEPARATION * 0.5,
		-1.0
	)

	assert(
		_simulation_world.entities.alive_count()
		== UNITS_PER_TEAM * 2,
		"Both armies should spawn completely."
	)

	_simulation_world.rebuild_spatial_grid()

	_create_renderer()
	_create_camera()
	_create_hud()

	print(
		(
			"VISUAL FIREFIGHT READY | "
			+ "%d vs %d infantry | "
			+ "automatic combat enabled"
		)
		% [
			UNITS_PER_TEAM,
			UNITS_PER_TEAM,
		]
	)


func _process(delta: float) -> void:
	if _battle_finished:
		return

	_renderer.update_lod(
		_camera.global_position
	)

	var completed_steps: int = (
		_simulation_world.advance(delta)
	)

	if completed_steps > 0:
		_total_shots += (
			_simulation_world.last_auto_fire_count
		)

		var destroyed_indices: PackedInt32Array = (
			_simulation_world
			.consume_destroyed_entity_indices()
		)

		if not destroyed_indices.is_empty():
			_renderer.remove_destroyed_entity_indices(
				destroyed_indices
			)

		var changed_indices: PackedInt32Array = (
			_simulation_world
			.consume_changed_transform_indices()
		)

		if not changed_indices.is_empty():
			_renderer.sync_changed_from_simulation(
				changed_indices
			)

	_metrics_elapsed += delta

	if _metrics_elapsed >= 0.20:
		_metrics_elapsed = 0.0
		_update_hud()
		_check_battle_finished()


func _spawn_army(
	definition: UnitDefinition,
	owner_id: int,
	front_x: float,
	depth_direction: float
) -> void:
	for unit_index: int in range(
		UNITS_PER_TEAM
	):
		var column: int = (
			unit_index % FORMATION_COLUMNS
		)

		var row: int = floori(
			float(unit_index)
			/ float(FORMATION_COLUMNS)
		)

		var z_offset: float = (
			(
				float(column)
				- float(FORMATION_COLUMNS - 1) * 0.5
			)
			* UNIT_SPACING
		)

		var x_offset: float = (
			float(row)
			* UNIT_SPACING
			* depth_direction
		)

		var spawn_position := Vector3(
			front_x + x_offset,
			0.0,
			z_offset
		)

		var heading: float

		if owner_id == TEAM_ZERO_OWNER:
			heading = -PI * 0.5
		else:
			heading = PI * 0.5

		var entity_id: int = (
			_simulation_world.spawn_unit(
				definition,
				0,
				owner_id,
				spawn_position,
				heading
			)
		)

		assert(
			EntityId.is_valid(entity_id),
			"Every combat visual entity should spawn."
		)


func _create_renderer() -> void:
	_renderer = UnitMultiMeshRenderer.new()
	_renderer.name = "UnitMultiMeshRenderer"
	_renderer.render_chunk_size = 32.0

	add_child(_renderer)

	var material := StandardMaterial3D.new()

	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.85

	var near_mesh := BoxMesh.new()

	near_mesh.size = Vector3(
		0.7,
		1.4,
		0.7
	)

	near_mesh.material = material

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
		0.35,
		0.35
	)

	far_mesh.material = far_material

	assert(
		_renderer.register_prototype(
			0,
			near_mesh,
			far_mesh,
			0.7,
			120.0
		),
		"Infantry render prototype should register."
	)

	assert(
		_renderer.build(
			_simulation_world
		),
		"Combat renderer should build."
	)

	assert(
		_renderer.rendered_instance_count()
		== UNITS_PER_TEAM * 2,
		"Every combat entity should render."
	)


func _create_camera() -> void:
	_camera = RtsCameraController.new()

	_camera.name = "RtsCameraController"
	_camera.minimum_distance = 20.0
	_camera.maximum_distance = 300.0

	add_child(_camera)

	_camera.configure(
		Vector3.ZERO,
		150.0
	)


func _create_hud() -> void:
	var canvas := CanvasLayer.new()

	canvas.name = "CombatHUD"
	canvas.layer = 50

	add_child(canvas)

	var panel := PanelContainer.new()

	panel.position = Vector2(
		16.0,
		16.0
	)

	panel.custom_minimum_size = Vector2(
		360.0,
		0.0
	)

	canvas.add_child(panel)

	_hud_label = Label.new()

	_hud_label.text = (
		"DAWNFALL — FIRST VISUAL FIREFIGHT"
	)

	panel.add_child(_hud_label)

	_update_hud()


func _update_hud() -> void:
	var team_zero_alive: int = 0
	var team_one_alive: int = 0

	for entity_index: int in range(
		_simulation_world.entities.capacity()
	):
		if not _simulation_world.entities.is_index_alive(
			entity_index
		):
			continue

		match _simulation_world.entities.owner_ids[
			entity_index
		]:
			TEAM_ZERO_OWNER:
				team_zero_alive += 1

			TEAM_ONE_OWNER:
				team_one_alive += 1

	_hud_label.text = (
		"DAWNFALL — FIRST VISUAL FIREFIGHT\n"
		+ "Blue Army: %d / %d\n"
		+ "Red Army: %d / %d\n"
		+ "Total Alive: %d\n"
		+ "Total Shots: %d\n"
		+ "Combat: %.3f ms\n"
		+ "Rendered: %d\n"
		+ "FPS: %.1f\n\n"
		+ "Mouse wheel: zoom\n"
		+ "MMB: pan\n"
		+ "ALT + MMB: rotate"
	) % [
		team_zero_alive,
		UNITS_PER_TEAM,
		team_one_alive,
		UNITS_PER_TEAM,
		team_zero_alive + team_one_alive,
		_total_shots,
		_simulation_world.last_combat_milliseconds,
		_renderer.rendered_instance_count(),
		Engine.get_frames_per_second(),
	]


func _check_battle_finished() -> void:
	var team_zero_alive: int = 0
	var team_one_alive: int = 0

	for entity_index: int in range(
		_simulation_world.entities.capacity()
	):
		if not _simulation_world.entities.is_index_alive(
			entity_index
		):
			continue

		var owner_id: int = (
			_simulation_world.entities.owner_ids[
				entity_index
			]
		)

		if owner_id == TEAM_ZERO_OWNER:
			team_zero_alive += 1

		elif owner_id == TEAM_ONE_OWNER:
			team_one_alive += 1

	if (
		team_zero_alive > 0
		and team_one_alive > 0
	):
		return

	_battle_finished = true
	_update_hud()

	print(
		(
			"VISUAL FIREFIGHT COMPLETE | "
			+ "Blue %d alive | "
			+ "Red %d alive | "
			+ "%d total shots"
		)
		% [
			team_zero_alive,
			team_one_alive,
			_total_shots,
		]
	)


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
		240.0,
		160.0
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
