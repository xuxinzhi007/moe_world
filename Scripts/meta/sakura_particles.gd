extends Node2D

var particle_count: int = 30
var particles: Array = []
var texture: Texture2D

func _ready() -> void:
	_create_sakura_texture()
	_spawn_particles()

func _create_sakura_texture() -> void:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var center = Vector2(16, 16)
	var colors = [
		Color8(255, 182, 193),
		Color8(255, 192, 203),
		Color8(255, 170, 185),
		Color8(255, 160, 180)
	]
	
	for i in range(5):
		var angle = deg_to_rad(i * 72 - 90)
		var petal_length = 12.0 + randf() * 3.0
		var petal_width = 8.0 + randf() * 2.0
		
		for x in range(32):
			for y in range(32):
				var pos = Vector2(x, y)
				var rel_pos = pos - center
				
				var rotated = rel_pos.rotated(-angle)
				
				if abs(rotated.x) < petal_width and rotated.y > 0 and rotated.y < petal_length:
					var dist = rotated.y / petal_length
					var color_idx = randi() % colors.size()
					var alpha = 1.0 - dist * 0.5
					img.set_pixel(x, y, colors[color_idx] * Color(1, 1, 1, alpha))
	
	texture = ImageTexture.create_from_image(img)

func _spawn_particles() -> void:
	for i in range(particle_count):
		var particle = Sprite2D.new()
		particle.texture = texture
		particle.modulate.a = 0.6 + randf() * 0.4
		particle.scale = Vector2(0.5 + randf() * 0.8, 0.5 + randf() * 0.8)
		particle.position = Vector2(randf() * get_viewport_rect().size.x, randf() * get_viewport_rect().size.y)
		
		var data = {
			"sprite": particle,
			"speed": 30.0 + randf() * 50.0,
			"wobble_speed": 1.0 + randf() * 2.0,
			"wobble_amount": 20.0 + randf() * 30.0,
			"rotation_speed": (randf() - 0.5) * 2.0,
			"start_x": particle.position.x,
			"time": randf() * 10.0
		}
		
		particles.append(data)
		add_child(particle)

func _process(delta: float) -> void:
	var viewport_size = get_viewport_rect().size
	
	for data in particles:
		data["time"] += delta
		var sprite = data["sprite"] as Sprite2D
		
		sprite.position.y += data["speed"] * delta
		
		sprite.position.x = data["start_x"] + sin(data["time"] * data["wobble_speed"]) * data["wobble_amount"]
		
		sprite.rotation += data["rotation_speed"] * delta
		
		if sprite.position.y > viewport_size.y + 50:
			sprite.position.y = -50
			sprite.position.x = randf() * viewport_size.x
			data["start_x"] = sprite.position.x
