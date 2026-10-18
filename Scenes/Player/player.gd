extends CharacterBody3D

@export var _camera : Camera3D
@export var camera2 : Camera3D
@export var _camera_pivot : Node3D
@export var mesh_pivot : Node3D
@export var anim_player : AnimationPlayer
@export_range(0.0, 1.0) var mouse_sensitivity = 0.01
@export var tilt_limit = deg_to_rad(75)


const SPEED = 1
const JUMP_VELOCITY = 4.5


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("third person view"):
		_camera.current = false
		camera2.current = true
	
	if Input.is_action_just_pressed("first person view"):
		_camera.current = true
		camera2.current = false
		
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "behind")
	var camera_basis = _camera_pivot.global_transform.basis
	var direction := (camera_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0  # Stops the character from trying to move up into the sky
	direction = direction.normalized()
	if direction:
		velocity.z = move_toward(velocity.z , direction.z * SPEED, 0.5 * delta)
		velocity.x = move_toward(velocity.x , direction.x * SPEED, 0.5 * delta)
		mesh_pivot.look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, 0.5 * delta)
		velocity.z = move_toward(velocity.z, 0, 0.5 * delta)
	
	# 1. Check if the player is actually moving horizontally
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	
	var has_input = input_dir.length() > 0.1
	# 2. Let GDScript dictate exactly what happens based on current playback
	if anim_player:
		if has_input:
			# If we are standing still or coming out of a stop, start walking
			if anim_player.current_animation == "Global/walking_to_idle" or anim_player.current_animation == "" or anim_player.current_animation == "Global/idle" :
				anim_player.play("Global/idle_to_waliking",-1,1.0)
				anim_player.queue("Global/walking") # Queues the infinite walk loop
		else:
			# If we are walking or coming out of a start, start stopping
			if anim_player.current_animation == "Global/idle_to_waliking" or anim_player.current_animation == "Global/walking":
				anim_player.play("Global/walking_to_idle")
				anim_player.queue("Global/idle") # Queues the infinite idle loop

	move_and_slide()
func _unhandled_input(event: InputEvent) -> void:
	# Mouselook implemented using `screen_relative` for resolution-independent sensitivity.
	if event is InputEventMouseMotion:
		_camera_pivot.rotation.x -= event.screen_relative.y * mouse_sensitivity
		# Prevent the camera from rotating too far up or down.
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -tilt_limit, tilt_limit)
		_camera_pivot.rotation.y += -event.screen_relative.x * mouse_sensitivity
