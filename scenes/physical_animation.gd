extends Skeleton3D

@export var physical_bone_simulator: PhysicalBoneSimulator3D

@export var target_skeleton: Skeleton3D

@export var linear_spring_stiffness: float = 1200.0
@export var linear_spring_damping: float = 40.0
@export var max_linear_force: float = 9999.0

@export var angular_spring_stiffness: float = 4000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0

var physics_bones

var _delta: float = 1.0 / 60.0


func _ready():
	self.physical_bone_simulator.physical_bones_start_simulation()
	physics_bones = self.physical_bone_simulator.get_children().filter(
		func(x): return x is PhysicalBone3D
	)
	self.skeleton_updated.connect(self._on_skeleton_updated)


func _physics_process(delta):
	self._delta = delta


func hookes_law(
	displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float
) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)


func _on_skeleton_updated() -> void:
	for b in physics_bones:
		var target_transform: Transform3D = (
			target_skeleton.global_transform * target_skeleton.get_bone_global_pose(b.get_bone_id())
		)
		var current_transform: Transform3D = (
			global_transform * self.get_bone_global_pose(b.get_bone_id())
		)
		var rotation_difference: Basis = target_transform.basis * current_transform.basis.inverse()

		var position_difference: Vector3 = target_transform.origin - current_transform.origin

		if position_difference.length_squared() > 1.0:
			b.global_position = target_transform.origin
		else:
			var force: Vector3 = hookes_law(
				position_difference,
				b.linear_velocity,
				linear_spring_stiffness,
				linear_spring_damping
			)
			force = force.limit_length(max_linear_force)
			b.linear_velocity += (force * self._delta)

		var torque = hookes_law(
			rotation_difference.get_euler(),
			b.angular_velocity,
			angular_spring_stiffness,
			angular_spring_damping
		)
		torque = torque.limit_length(max_angular_force)

		b.angular_velocity += torque * self._delta
