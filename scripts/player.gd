extends CharacterBody2D # definisce che lo script è associato a un nodo di tipo CharacterBody2D. Questo ti permette di usare tutte le funzionalità di CharacterBody2D, come move_and_slide(), velocity, e i metodi per rilevare collisioni.

@onready var spawn_point = get_node("SpawnPoint")

var speed = 500 #determina la velocita della navicella
var acceleration = 700 #determina l'accelerazione della navicella
var friction = 600 #determina la frizione della navicella (lo spazio necessario per fermarsi)
var rotation_speed = 3 #determina con che velocità la navicella si ruota nella direzione di input

@export var bullet_scene: PackedScene  # Assegna la scena del proiettile nell'editor
var can_shoot = true
var fire_rate = 0.2  # Secondi tra uno sparo e l'altro

func _physics_process(delta): #funzione che fa in modo che le seguenti azioni vengano svolte per ogni frame del gioco
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") #la variabile riceve l'input sopra,sotto... e ne crea un vettore
	
	if input_vector != Vector2.ZERO: #controlla che l'utente clicchi un pulsante che modifichi le cordinate del vettore e che quindi non siano (0,0) o .ZERO
		
		var target_angle = input_vector.angle() + PI/2  #la variabile prende il valore dell'input in vettore come angolo in radiante che parte da 0 verso destra (asse delle ascisse positivo). +PI/2 per correggere l'orientamento dato che la mia immaggine è verso l'alto
		
		# Rotazione graduale
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta) #lerp_angle interpola (muove gradualemente rotation (la rotazione alla quale si trova nel momento la navicella) per arrivare all'input di angolo cioè target_angle ad una velocita pari a rotation_speed * delta (cioè rotation_speed * tempo trascorso dall'ultimo frame)(delta è utilizzato per rendere la velocità indipendente dal frame rate)
		
		# Movimento con inerzia
		velocity = velocity.move_toward(input_vector.normalized() * speed, acceleration * delta) #velocity.move_toward Sposta gradualmente il vettore velocity verso il vettore target (in questo caso, input_vector.normalized() * speed) che quindi rapressenta il limite di velocità da raggiungere e lo fa ad un passo pari ad acceleration * delta
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta) #questa volta velocity.move_toward Sposta gradualmente il vettore velocity verso il fermarsi (Vector2.ZERO) ad una velocità pari a friction * delta
	
	move_and_slide() #funzione base di godot per gestire movimenti e collisioni come velocity
	
	if Input.is_action_pressed("fire") and can_shoot:
		shoot()
		can_shoot = false
		await get_tree().create_timer(fire_rate).timeout
		can_shoot = true
		
@export var muzzle_marker: Marker2D

func shoot():
	if bullet_scene && muzzle_marker:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle_marker.global_position
		bullet.direction = -muzzle_marker.global_transform.y
		get_tree().current_scene.add_child(bullet)
