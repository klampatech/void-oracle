# VoidRiftPeg.gd — Void Rift peg type
extends BasePeg

const GOLD_REWARD := 10


func _ready() -> void:
	peg_type = PegType.VOID_RIFT
	super._ready()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return

	# Queue free the ball (remove from physics)
	body.queue_free()

	# Add gold reward
	RunState.gold += GOLD_REWARD

	# Emit peg hit signal (for consistency with other pegs)
	hit_count += 1
	EventBus.peg_hit.emit(self, body)
