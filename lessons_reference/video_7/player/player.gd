extends CharacterBody3D

@export var move_speed: float = 5.5
@export var gravity: float = 20.0
@export var jump_speed: float = 10.0
@export var reload_scene_delay: float = 0.6  # หน่วงก่อนรีโหลดฉาก (วินาที)

signal died

var _alive := true

func _ready() -> void:
	# ซ่อนเมาส์ตั้งแต่เริ่ม (ถ้าอยาก)
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# ต่อสัญญาณชนจาก Area3D ชื่อ "HurtBox"
	if has_node("HurtBox"):
		$HurtBox.body_entered.connect(_on_hurtbox_body_entered)
	else:
		push_warning("ไม่พบโหนด HurtBox (Area3D) ใต้ Player — โปรดสร้าง Area3D+CollisionShape3D แล้วตั้งชื่อ HurtBox")

func _unhandled_input(event: InputEvent) -> void:
	if not _alive:
		return

	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * 0.5
		%Camera3D.rotation_degrees.x -= event.relative.y * 0.2
		%Camera3D.rotation_degrees.x = clamp(%Camera3D.rotation_degrees.x, -60.0, 60.0)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if not _alive:
		return

	var input_direction_2D := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_direction_3D := Vector3(input_direction_2D.x, 0.0, input_direction_2D.y)
	var direction := transform.basis * input_direction_3D

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	# แรงโน้มถ่วง + กระโดด
	velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_speed
	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y = 0.0

	move_and_slide()

	# ยิงกระสุน (เหมือนเดิม)
	if Input.is_action_pressed("shoot") and %Timer.is_stopped():
		shoot_bullet()

func shoot_bullet() -> void:
	const BULLET_3D = preload("bullet_3d.tscn")
	var new_bullet := BULLET_3D.instantiate()
	%Marker3D.add_child(new_bullet)
	new_bullet.global_transform = %Marker3D.global_transform
	%Timer.start()

# =========================
# ชน Mob แล้วให้ผู้เล่นตาย
# =========================
func _on_hurtbox_body_entered(body: Node) -> void:
	if body.is_in_group("Mob"):
		die()

func die() -> void:
	if not _alive:
		return
	_alive = false

	# ปิดการประมวลผลการขยับ/อินพุต
	set_physics_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# ถ้ามีแอนิเมชัน/เอฟเฟกต์ตาย สามารถเล่นได้ที่นี่ เช่น:
	# if has_node("AnimationPlayer"): $AnimationPlayer.play("die")

	emit_signal("died")

	# รีโหลดฉากหลังหน่วงเล็กน้อย
	await get_tree().create_timer(reload_scene_delay).timeout
	get_tree().reload_current_scene()
