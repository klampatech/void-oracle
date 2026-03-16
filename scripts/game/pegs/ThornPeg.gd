# ThornPeg.gd — Enemy-placed thorn peg that deflects balls sideways
extends BasePeg

## Deflect angle in degrees
var _deflect_angle: float = 30.0


func _ready() -> void:
	peg_type = PegType.THORN
	super._ready()

	# Add to enemy pegs group (cannot be removed by player)
	add_to_group("enemy_peg")

	# Load deflect angle from data
	var peg_key := _get_peg_key()
	if _peg_data.has(peg_key):
		_deflect_angle = _peg_data[peg_key].get("deflect_angle", 30.0)


func _get_peg_key() -> String:
	return "thorn"


## Override to add deflect behavior on ball hit
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return

	hit_count += 1
	EventBus.peg_hit.emit(self, body)

	# Apply deflect to the ball
	_apply_deflect(body)


## Apply sideways deflection to the ball
func _apply_deflect(ball: Node2D) -> void:
	if not ball.has_method("apply_deflect"):
		return

	# Randomly choose left or right deflection
	var direction := 1 if randf() > 0.5 else -1
	ball.apply_deflect(_deflect_angle * direction)


## Override to prevent removal - thorn pegs are permanent
func can_be_removed() -> bool:
	return false
