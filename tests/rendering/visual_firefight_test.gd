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
var _selection_controller: UnitSelectionController
var _move_command_controller: UnitMoveCommandController
var _hud_label: Label

var _metrics_elapsed: float = 0.0
var _total_shots: int = 0
var _battle_finished: bool = false
var _last_focus_order_count: int = 0
var _attack_mode_active: bool = false
var _manual_target_entity_id: int = EntityId.INVALID
var _manual_target_marker: MeshInstance3D


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
	_create_selection_controller()
	_create_command_controller()
	_create_manual_target_marker()
	_create_hud()

	print(
		(
			"VISUAL FIREFIGHT READY | "
			+ "%d vs %d infantry | "
			+ "automatic combat enabled | "
			+ "A = manual attack target"
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

	_update_manual_target_marker()

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

			_selection_controller.remove_destroyed_entity_indices(
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


func _create_selection_controller() -> void:
	_selection_controller = UnitSelectionController.new()
	_selection_controller.name = "UnitSelectionController"

	add_child(
		_selection_controller
	)

	assert(
		_selection_controller.configure(
			_simulation_world,
			_camera,
			TEAM_ZERO_OWNER
		),
		"Combat selection should configure."
	)

	_selection_controller.selection_changed.connect(
		_on_selection_changed
	)


func _create_command_controller() -> void:
	_move_command_controller = UnitMoveCommandController.new()
	_move_command_controller.name = "UnitMoveCommandController"

	add_child(
		_move_command_controller
	)

	assert(
		_move_command_controller.configure(
			_simulation_world,
			_camera,
			_selection_controller
		),
		"Combat command controller should configure."
	)

	_move_command_controller.attack_command_issued.connect(
		_on_attack_command_issued
	)

	_move_command_controller.command_issued.connect(
		_on_move_command_issued
	)

	_move_command_controller.attack_mode_changed.connect(
		_on_attack_mode_changed
	)


func _on_selection_changed(
	entity_indices: PackedInt32Array,
	_elapsed_milliseconds: float
) -> void:
	_renderer.set_selected_entity_indices(
		entity_indices
	)

	_update_hud()


func _on_attack_command_issued(
	accepted_count: int,
	target_entity_id: int
) -> void:
	_last_focus_order_count = accepted_count
	_manual_target_entity_id = target_entity_id
	_update_manual_target_marker()
	_update_hud()


func _on_move_command_issued(
	_accepted_count: int,
	_formation: bool,
	_planning_milliseconds: float,
	_dispatch_milliseconds: float,
	_path_length: float
) -> void:
	_clear_manual_target_marker()
	_update_hud()


func _on_attack_mode_changed(
	active: bool
) -> void:
	_attack_mode_active = active
	_update_hud()


func _create_manual_target_marker() -> void:
	_manual_target_marker = MeshInstance3D.new()
	_manual_target_marker.name = "ManualAttackTargetMarker"

	var marker_mesh := BoxMesh.new()

	marker_mesh.size = Vector3(
		0.9,
		0.9,
		0.9
	)

	var marker_material := StandardMaterial3D.new()

	marker_material.albedo_color = Color(
		0.15,
		1.0,
		1.0,
		1.0
	)

	marker_material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	marker_mesh.material = marker_material
	_manual_target_marker.mesh = marker_mesh
	_manual_target_marker.rotation_degrees = Vector3(
		35.0,
		45.0,
		0.0
	)
	_manual_target_marker.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	_manual_target_marker.visible = false

	add_child(
		_manual_target_marker
	)


func _update_manual_target_marker() -> void:
	if _manual_target_marker == null:
		return

	if not EntityId.is_valid(
		_manual_target_entity_id
	):
		_manual_target_marker.visible = false
		return

	var target_index: int = (
		_simulation_world.entities.get_index_if_alive(
			_manual_target_entity_id
		)
	)

	if target_index < 0:
		_clear_manual_target_marker()
		return

	var bob_offset: float = (
		sin(
			float(Time.get_ticks_msec())
			/ 180.0
		)
		* 0.18
	)

	_manual_target_marker.position = (
		_simulation_world.entities.positions[
			target_index
		]
		+ Vector3.UP * (2.2 + bob_offset)
	)

	_manual_target_marker.rotation.y += 0.05
	_manual_target_marker.visible = true


func _clear_manual_target_marker() -> void:
	_manual_target_entity_id = EntityId.INVALID

	if _manual_target_marker != null:
		_manual_target_marker.visible = false


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
		420.0,
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
	if _hud_label == null:
		return

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

	var selected_count: int = 0

	if _selection_controller != null:
		selected_count = (
			_selection_controller.selected_count()
		)

	var attack_mode_text: String = (
		"ARMED"
		if _attack_mode_active
		else "idle"
	)

	var focus_target_text: String = "none"

	if (
		EntityId.is_valid(
			_manual_target_entity_id
		)
		and _simulation_world.entities.is_alive(
			_manual_target_entity_id
		)
	):
		focus_target_text = "ACTIVE — cyan marker"

	_hud_label.text = (
		"DAWNFALL — INTERACTIVE FIREFIGHT\n"
		+ "Blue Army: %d / %d\n"
		+ "Red Army: %d / %d\n"
		+ "Total Alive: %d\n"
		+ "Total Shots: %d\n"
		+ "Combat: %.3f ms\n"
		+ "Rendered: %d\n"
		+ "FPS: %.1f\n"
		+ "Selected: %d\n"
		+ "Attack command: %s\n"
		+ "Manual focus target: %s\n"
		+ "Last focus order: %d units\n\n"
		+ "Left click/drag: select blue units\n"
		+ "A, then left click red unit: manual target\n"
		+ "Right click ground: move\n"
		+ "Right click drag: line formation\n"
		+ "Esc: cancel attack command\n"
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
		selected_count,
		attack_mode_text,
		focus_target_text,
		_last_focus_order_count,
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
