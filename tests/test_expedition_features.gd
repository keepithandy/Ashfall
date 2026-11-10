extends SceneTree

var game: Node3D
var player: CharacterBody3D
var stalker: CharacterBody3D
var errors:=0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		errors+=1
		push_error("FEATURE_FAIL: "+message)

func frames(n: int) -> void:
	for i in range(n):
		await physics_frame

func run() -> void:
	game=load("res://scenes/legacy/main.tscn").instantiate()
	root.add_child(game)
	game.smoke_test=true
	game.resume_game()
	player=game.player
	stalker=game.get_node("VillageStalker")
	await frames(3)
	var caches:=[]
	for child in game.get_children():
		if child.get_meta("interaction", "")=="loot_container":
			caches.append(child)
	check(caches.size()==3,"Expected checkpoint and two village caches")
	if caches.size()==3:
		check(caches[1].contents.food_tin==2 and caches[2].contents.batteries==2,"Village caches have incorrect contents")
		for test in [[caches[1],Vector3(-46,0.19,10.7)],[caches[2],Vector3(-51.5,0.1,15)]]:
			player.position=test[1]
			player.velocity=Vector3.ZERO
			player.set_view_direction(test[0].global_position+Vector3(0,0.2,0)-player.camera.global_position)
			await frames(3)
			check(game.get_target()==test[0],"A village cache cannot be targeted from an accessible approach")
		var taken: Dictionary=caches[1].take_all()
		check(taken.food_tin==2 and caches[1].take_all().is_empty() and not caches[2].contents.is_empty(),"Caches must stay independent and empty after looting")
	game.inventory.food_tin=2
	player.stamina=20
	player.sprint_exhausted=true
	game.use_food()
	check(is_equal_approx(player.stamina,65) and game.inventory.food_tin==1 and not player.sprint_exhausted,"Food did not restore stamina")
	player.stamina=100
	game.use_food()
	check(game.inventory.food_tin==1,"Food was wasted at full stamina")
	game.inventory.batteries=2
	player.battery_charge=0
	player.torch.visible=false
	game.reload_battery()
	check(player.battery_charge==60 and game.inventory.batteries==1,"Battery did not charge light")
	var toggle:=InputEventKey.new()
	toggle.physical_keycode=KEY_F
	toggle.pressed=true
	player._unhandled_input(toggle)
	check(player.torch.visible,"Recharged light cannot be switched on")
	await frames(20)
	check(player.battery_charge<60,"Active flashlight is not draining")
	player.battery_charge=100
	game.reload_battery()
	check(game.inventory.batteries==1,"Battery wasted at full charge")
	player.battery_charge=0
	player.torch.visible=false
	player._unhandled_input(toggle)
	check(not player.torch.visible,"Empty flashlight switched on")
	player.battery_charge=100
	player.torch.visible=true
	player.position=Vector3(-70,0.1,45)
	player.set_view_direction(Vector3.FORWARD)
	await frames(20)
	Input.action_press("crouch")
	Input.action_press("move_forward")
	await frames(20)
	check(player.crouching and is_equal_approx(player.noise_radius,2.0),"Crouched movement is not quiet")
	Input.action_release("crouch")
	Input.action_press("sprint")
	await frames(20)
	check(not player.crouching and is_equal_approx(player.noise_radius,10.0),"Sprinting does not create the intended noise")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	player.position=Vector3(-70,0.1,45)
	player.velocity=Vector3.ZERO
	var near_wall:=StaticBody3D.new()
	var near_collision:=CollisionShape3D.new()
	var near_shape:=BoxShape3D.new()
	near_shape.size=Vector3(3,3,0.2)
	near_collision.shape=near_shape
	near_wall.position=Vector3(-70,1.5,44.35)
	near_wall.add_child(near_collision)
	game.add_child(near_wall)
	await frames(20)
	check(player.wall_retraction>0.1,"Held flashlight did not retract near a wall")
	near_wall.free()
	await frames(20)
	check(player.wall_retraction<0.05,"Held flashlight did not return after leaving a wall")
	player.position=Vector3(-70,0.1,45)
	player.velocity=Vector3.ZERO
	stalker.position=Vector3(-70,0.1,50)
	stalker.velocity=Vector3.ZERO
	stalker.rotation=Vector3.ZERO
	stalker.state="patrol"
	player.noise_radius=0
	await frames(3)
	stalker.rotation=Vector3.ZERO
	stalker.sense_player()
	check(stalker.state=="chase","Creature did not see a player in front")
	var old_position: Vector3=stalker.position
	await frames(20)
	check(stalker.position.distance_to(old_position)>0.2,"Creature did not move toward a seen player")
	stalker.position=Vector3(-70,0.1,50)
	stalker.velocity=Vector3.ZERO
	var wall:=StaticBody3D.new()
	var collider:=CollisionShape3D.new()
	var wall_shape:=BoxShape3D.new()
	wall_shape.size=Vector3(4,3,0.3)
	collider.shape=wall_shape
	wall.position=Vector3(-70,1.5,47.5)
	wall.add_child(collider)
	game.add_child(wall)
	await frames(2)
	stalker.state="patrol"
	player.noise_radius=0
	stalker.sense_player()
	check(stalker.state=="patrol", "Creature saw through a wall")
	player.position=Vector3(-70,0.1,47)
	await frames(1)
	player.noise_radius=10
	stalker.state="patrol"
	stalker.sense_player()
	check(stalker.state=="investigate", "Nearby sprint was not heard through a wall")
	player.noise_radius=2
	stalker.state="patrol"
	stalker.sense_player()
	check(stalker.state=="patrol", "Crouched player made too much noise through a wall")
	wall.free()
	player.position=stalker.position+Vector3(0,0,-1)
	player.health=100
	stalker.state="chase"
	stalker.attention=5
	stalker.attack_cooldown=0
	stalker.last_known=player.position
	await frames(3)
	check(player.health<100 and player.health>=82,"Creature attack or cooldown failed")
	var health_after: float=player.health
	await frames(25)
	check(player.health==health_after,"Creature attacked again too quickly")
	player.position=Vector3(-25,0.1,20)
	stalker.state="chase"
	stalker.attention=5
	await frames(2)
	check(stalker.state=="patrol", "Creature did not return after the player escaped the village")
	player.active=false
	var frozen: Vector3=stalker.position
	await frames(12)
	check(stalker.position.distance_to(frozen)<0.01 and stalker.breath.stream_paused,"Creature did not pause with the game")
	print("EXPEDITION_FEATURES: failures=",errors)
	quit(1 if errors else 0)
