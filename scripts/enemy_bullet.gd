extends Area2D

var speed = 600  # Velocità del proiettile
var direction = Vector2.ZERO  # Direzione predefinita (verrà sovrascritta)

@onready var anim_explosion = $Bullet_animation

func _ready():
	# Ruota lo sprite nella direzione del movimento
	rotation = direction.angle() + PI/2  # Aggiusta in base all'orientamento iniziale
	$Bullet_animation.visible = false

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("obstacles"):  #se entra nel gruppo oblstacles allora scompare
		speed = 0
		$Bullet_animation.visible = true
		$Sprite2D.visible = false
		anim_explosion.play("Bullet_explosion")
		await anim_explosion.animation_finished
		queue_free()
	elif body.is_in_group("player"):  #se entra nel gruppo player allora fa scomparire il body e scompare
		speed = 0
		$Bullet_animation.visible = true
		$Sprite2D.visible = false
		anim_explosion.play("Bullet_explosion")
		await anim_explosion.animation_finished
		queue_free()
	elif body.is_in_group("enemies"):  #se entra nel gruppo enemies allora fa scomparire il body e scompare
		speed = 0
		$Bullet_animation.visible = true
		$Sprite2D.visible = false
		anim_explosion.play("Bullet_explosion")
		await anim_explosion.animation_finished
		queue_free()
		

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()  # Distrugge il proiettile quando esce dallo schermo
