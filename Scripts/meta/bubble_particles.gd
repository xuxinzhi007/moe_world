extends Node2D

var bubbles: Array[Dictionary] = []
const BUBBLE_COUNT = 15
const MIN_SIZE = 20.0
const MAX_SIZE = 60.0
const MIN_SPEED = 20.0
const MAX_SPEED = 50.0
const WOBBLE_AMPLITUDE = 30.0
const WOBBLE_SPEED = 2.0

var anim_offset: float = 0.0


func _ready() -> void:
	_initialize_bubbles()


func _initialize_bubbles() -> void:
	var screen_size = get_viewport_rect().size
	for i in range(BUBBLE_COUNT):
		var bubble_size = randf_range(MIN_SIZE, MAX_SIZE)
		var bubble = {
			"x": randf_range(0, screen_size.x),
			"y": randf_range(screen_size.y * 0.3, screen_size.y * 1.2),
			"size": bubble_size,
			"speed": randf_range(MIN_SPEED, MAX_SPEED),
			"wobble_offset": randf() * TAU,
			"opacity": randf_range(0.3, 0.6)
		}
		bubbles.append(bubble)


func _process(delta: float) -> void:
	anim_offset += delta
	var screen_size = get_viewport_rect().size
	
	for bubble in bubbles:
		bubble.y -= bubble.speed * delta
		bubble.x += sin(anim_offset * WOBBLE_SPEED + bubble.wobble_offset) * WOBBLE_SPEED
		
		if bubble.y < -bubble.size * 2:
			bubble.y = screen_size.y + bubble.size
			bubble.x = randf_range(0, screen_size.x)
	
	queue_redraw()


func _draw() -> void:
	for bubble in bubbles:
		var wobble_x = sin(anim_offset * WOBBLE_SPEED + bubble.wobble_offset) * WOBBLE_AMPLITUDE
		var pos = Vector2(bubble.x + wobble_x, bubble.y)
		var color = Color(1.0, 0.85, 0.9, bubble.opacity)
		var highlight_color = Color(1.0, 1.0, 1.0, bubble.opacity * 0.5)
		
		draw_circle(pos, bubble.size, color)
		draw_arc(pos + Vector2(-bubble.size * 0.3, -bubble.size * 0.3), bubble.size * 0.2, TAU * 0.7, TAU * 0.9, 2.0, highlight_color)
