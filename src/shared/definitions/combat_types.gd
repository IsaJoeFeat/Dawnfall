class_name CombatTypes
extends RefCounted


enum TargetCategory {
	INFANTRY = 1 << 0,
	VEHICLE = 1 << 1,
	AIRCRAFT = 1 << 2,
	NAVAL = 1 << 3,
	STRUCTURE = 1 << 4,
}
