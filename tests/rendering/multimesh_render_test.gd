extends Node3D


const CONTENT_CATALOG: DefinitionCatalog = preload(
	"res://content/content_catalog.tres"
)

const ENTITY_COUNT: int = 8000
const COMMANDED_ENTITY_COUNT: int = 2000


var _simulation_world := SimulationWorld.new()
var _renderer: UnitMultiMeshRenderer
var _camera: RtsCameraController
var _metrics_label: Label

var _metrics_elapsed: float = 0.0
var _last_simulation_milliseconds: float = 0.0
var _last_upload_milliseconds: float = 0.0
var _last_updated_instances: int = 0
var _last_lod_changes: int = 0


func _ready() -> void:
	var registry := DefinitionRegistry.new()

	if not CONTENT_CATALOG.load_into(registry):
		get_tree().quit(1)
		return

	var infantry: UnitDefinition = registry.get_unit(
		&"unit_test_placeholder_infantry"
	)
	var tank: UnitDefinition = registry.get_unit(
		&"unit_test_placeholder_tank"
	)

	if infantry == null or tank == null:
		push_error("Required rendering definitions were not loaded.")
		get_tree().quit(1)
		return

	_create_environment()
	_create_ground()
	_create_camera()
	_create_hud()

	var entity_ids := PackedInt64Array()
	var spawn_start: int = Time.get_ticks_usec()

	for index: int in range(ENTITY_COUNT):
		var definition: UnitDefinition
		var definition_index: int

		if index % 2 == 0:
			definition = infantry
			definition_index = 0
		else:
			definition = tank
			definition_index = 1

		var column: int = index % 100
		var row: int = floori(float(index) / 100.0)
		var entity_id: int = _simulation_world.spawn_unit(
			definition,
			definition_index,
			index % 4,
			Vector3(
				float(column) * 2.0,
				0.0,
				float(row) * 2.0
			)
		)

		assert(
			EntityId.is_valid(entity_id),
			"Every rendering-test entity should spawn."
		)

		entity_ids.append(entity_id)

	var spawn_milliseconds: float = (
		float(Time.get_ticks_usec() - spawn_start)
		/ 1000.0
	)

	_simulation_world.rebuild_spatial_grid()

	_renderer = UnitMultiMeshRenderer.new()
	_renderer.name = "UnitMultiMeshRenderer"
	_renderer.render_chunk_size = 32.0
	add_child(_renderer)

	var near_material := _create_near_unit_material()
	var far_material := _create_far_unit_material()

	var infantry_near_mesh := BoxMesh.new()
	infantry_near_mesh.size = Vector3(0.7, 1.4, 0.7)
	infantry_near_mesh.material = near_material

	var infantry_far_mesh := PlaneMesh.new()
	infantry_far_mesh.size = Vector2(0.35, 0.35)
	infantry_far_mesh.material = far_material

	var tank_near_mesh := BoxMesh.new()
	tank_near_mesh.size = Vector3(1.4, 0.7, 1.6)
	tank_near_mesh.material = near_material

	var tank_far_mesh := PlaneMesh.new()
	tank_far_mesh.size = Vector2(0.75, 1.0)
	tank_far_mesh.material = far_material

	assert(
		_renderer.register_prototype(
			0,
			infantry_near_mesh,
			infantry_far_mesh,
			0.7,
			95.0
		),
		"Infantry render prototype should register."
	)
	assert(
		_renderer.register_prototype(
			1,
			tank_near_mesh,
			tank_far_mesh,
			0.35,
			110.0
		),
		"Tank render prototype should register."
	)

	var build_start: int = Time.get_ticks_usec()

	assert(
		_renderer.build(_simulation_world),
		"Chunked MultiMesh renderer should build successfully."
	)

	_renderer.update_lod(_camera.global_position)

	var build_milliseconds: float = (
		float(Time.get_ticks_usec() - build_start)
		/ 1000.0
	)

	assert(
		_renderer.rendered_instance_count() == ENTITY_COUNT,
		"All 8,000 entities should have visual instances."
	)
	assert(
		_renderer.draw_group_count() > 2,
		"Spatial chunks should create multiple render groups."
	)

	var commanded_ids := PackedInt64Array()

	for index: int in range(COMMANDED_ENTITY_COUNT):
		commanded_ids.append(entity_ids[index])

	assert(
		_simulation_world.issue_move(
			commanded_ids,
			Vector3(100.0, 0.0, 140.0)
		) == COMMANDED_ENTITY_COUNT,
		"All 2,000 selected entities should accept movement."
	)

	print(
		(
			"Chunked MultiMesh test ready: "
			+ "%d logical entities, %d rendered instances, "
			+ "%d chunk groups, %d near, %d far, "
			+ "%.2f ms spawn, %.2f ms renderer build."
		)
		% [
			_simulation_world.entities.alive_count(),
			_renderer.rendered_instance_count(),
			_renderer.draw_group_count(),
			_renderer.near_lod_group_count(),
			_renderer.far_lod_group_count(),
			spawn_milliseconds,
			build_milliseconds,
		]
	)


func _process(delta: float) -> void:
	_last_lod_changes = _renderer.update_lod(
		_camera.global_position
	)

	var simulation_start: int = Time.get_ticks_usec()
	var completed_steps: int = _simulation_world.advance(delta)
	var measured_simulation_milliseconds: float = (
		float(Time.get_ticks_usec() - simulation_start)
		/ 1000.0
	)

	if completed_steps > 0:
		_last_simulation_milliseconds = (
			measured_simulation_milliseconds
		)

		var changed_transform_indices: PackedInt32Array = (
			_simulation_world.consume_changed_transform_indices()
		)
		var upload_start: int = Time.get_ticks_usec()

		_last_updated_instances = (
			_renderer.sync_changed_from_simulation(
				changed_transform_indices
			)
		)

		assert(
			_last_updated_instances
			== changed_transform_indices.size(),
			"Every changed transform should update one render instance."
		)
		assert(
			_last_updated_instances <= COMMANDED_ENTITY_COUNT,
			"Static entities should not receive transform uploads."
		)

		_last_upload_milliseconds = (
			float(Time.get_ticks_usec() - upload_start)
			/ 1000.0
		)

	_metrics_elapsed += delta

	if _metrics_elapsed >= 0.5:
		_metrics_elapsed = 0.0
		_update_metrics()


func _create_near_unit_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()

	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.85
	material.metallic = 0.0

	return material


func _create_far_unit_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()

	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	return material


func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.055, 0.075, 0.095)
	environment.ambient_light_source = (
		Environment.AMBIENT_SOURCE_COLOR
	)
	environment.ambient_light_color = Color(0.75, 0.8, 0.9)
	environment.ambient_light_energy = 0.75

	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()

	sunlight.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sunlight.light_color = Color(1.0, 0.93, 0.82)
	sunlight.light_energy = 1.1
	sunlight.shadow_enabled = false

	add_child(sunlight)


func _create_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var material := StandardMaterial3D.new()

	plane.size = Vector2(240.0, 200.0)

	material.albedo_color = Color(0.18, 0.24, 0.16)
	material.roughness = 1.0

	plane.material = material
	ground.mesh = plane
	ground.position = Vector3(99.0, -0.05, 79.0)

	add_child(ground)


func _create_camera() -> void:
	_camera = RtsCameraController.new()
	_camera.name = "RtsCamera"

	add_child(_camera)

	_camera.configure(
		Vector3(99.0, 0.0, 79.0),
		180.0
	)


func _create_hud() -> void:
	var canvas := CanvasLayer.new()

	canvas.name = "PerformanceHud"
	add_child(canvas)

	var panel := ColorRect.new()

	panel.position = Vector2(12.0, 12.0)
	panel.size = Vector2(560.0, 205.0)
	panel.color = Color(0.02, 0.025, 0.035, 0.88)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(panel)

	_metrics_label = Label.new()
	_metrics_label.position = Vector2(14.0, 12.0)
	_metrics_label.size = Vector2(530.0, 180.0)
	_metrics_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)
	_metrics_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)
	_metrics_label.add_theme_constant_override(
		"outline_size",
		4
	)

	panel.add_child(_metrics_label)
	_update_metrics()


func _update_metrics() -> void:
	if _metrics_label == null:
		return

	var frames_per_second: float = Performance.get_monitor(
		Performance.TIME_FPS
	)
	var frame_milliseconds: float = (
		1000.0 / maxf(frames_per_second, 1.0)
	)
	var draw_calls: int = int(
		Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
		)
	)
	var video_memory_megabytes: float = (
		Performance.get_monitor(
			Performance.RENDER_VIDEO_MEM_USED
		)
		/ (1024.0 * 1024.0)
	)

	var render_groups: int = 0
	var near_groups: int = 0
	var far_groups: int = 0

	if _renderer != null:
		render_groups = _renderer.draw_group_count()
		near_groups = _renderer.near_lod_group_count()
		far_groups = _renderer.far_lod_group_count()

	_metrics_label.text = (
		"Dawnfall Partial MultiMesh Upload Test\n"
		+ "8,000 units | %d chunk groups | Near %d | Far %d\n"
		+ "FPS: %.1f | Approx. frame: %.2f ms | Draw calls: %d\n"
		+ "Last completed simulation tick: %.2f ms\n"
		+ "Last transform upload: %.2f ms (%d instances)\n"
		+ "LOD groups changed this frame: %d\n"
		+ "Reported video memory: %.1f MB\n"
		+ "Move and zoom camera to test chunk culling and LOD"
	) % [
		render_groups,
		near_groups,
		far_groups,
		frames_per_second,
		frame_milliseconds,
		draw_calls,
		_last_simulation_milliseconds,
		_last_upload_milliseconds,
		_last_updated_instances,
		_last_lod_changes,
		video_memory_megabytes,
	]
