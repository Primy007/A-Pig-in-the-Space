extends ParallaxBackground

var scroll_speed = 50  # Regola la velocità

func _process(delta):
	scroll_offset.x -= scroll_speed * delta
