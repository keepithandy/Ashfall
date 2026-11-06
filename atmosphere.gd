extends Node3D
## Quiet, spatial horror atmosphere. Runs only while the expedition is active.

var game: Node3D
var clock := 0.0
var cue_due := 11.0
var lamps: Array[Node] = []
var sounds: Array[AudioStreamPlayer3D] = []
var sound_rng := RandomNumberGenerator.new()

func _ready() -> void:
	name = "Atmosphere"
	sound_rng.seed = 1986
	lamps = get_tree().get_nodes_in_group("perimeter_lamps")
	for light in lamps:
		light.set_meta("steady_energy",light.light_energy)
	var mist := FogVolume.new()
	mist.name = "LowRoadMist"
	mist.position = Vector3(0,0.35,-14)
	mist.size = Vector3(9,1.8,46)
	var fog := FogMaterial.new()
	fog.density = 0.018
	fog.albedo = Color("879c9a")
	fog.edge_fade = 0.3
	fog.height_falloff = 0.8
	mist.material = fog
	add_child(mist)
	var positions := [Vector3(9,1.5,10),Vector3(-11,2,-31),Vector3(23,2,-15),Vector3(-49,2,7)]
	for i in range(positions.size()):
		var player := AudioStreamPlayer3D.new()
		player.name = "DistantCreak"+str(i)
		player.position = positions[i]
		player.stream = creak_clip(i)
		player.volume_db = -19
		player.unit_size = 5
		player.max_distance = 55
		player.attenuation_filter_cutoff_hz = 2400
		add_child(player)
		sounds.append(player)
	var village_mist := FogVolume.new()
	village_mist.name = "VillageGroundMist"
	village_mist.position = Vector3(-48,0.3,20)
	village_mist.size = Vector3(30,1.4,6)
	village_mist.material = fog
	add_child(village_mist)
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){float edge=smoothstep(0.28,0.76,length(UV-vec2(0.5))); COLOR=vec4(0.0,0.005,0.012,edge*0.25);}"
	var material := ShaderMaterial.new()
	material.shader = shader
	vignette.material = material
	layer.add_child(vignette)

func creak_clip(kind: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	var count := 22050
	data.resize(count*2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 330+kind
	var phase := 0.0
	var filtered := 0.0
	for i in range(count):
		var t := float(i)/22050
		phase += TAU*(145+kind*38+sin(t*8)*22)/22050
		filtered = filtered*0.9+noise.randf_range(-1,1)*0.1
		var envelope := sin(t*PI)*exp(-t*2)
		var value := (sin(phase)*0.11+sin(phase*2.03)*0.025+filtered*0.12)*envelope
		data.encode_s16(i*2,int(clampf(value,-0.22,0.22)*32767))
	wav.data = data
	return wav

func _process(delta: float) -> void:
	if not is_instance_valid(game.player) or not game.player.active:
		return
	clock += delta
	# Two lamps occasionally sag for half a second; no rapid flashing.
	for i in range(lamps.size()):
		if i != 1 and i != 3:
			continue
		var phase := fposmod(clock+i*3.4,13.0)
		var dip := sin((phase-8.0)/0.7*PI) if phase > 8.0 and phase < 8.7 else 0.0
		lamps[i].light_energy = float(lamps[i].get_meta("steady_energy"))*(1.0-dip*0.65)
	if clock >= cue_due:
		var selected := sound_rng.randi_range(0,sounds.size()-1)
		sounds[selected].pitch_scale = sound_rng.randf_range(0.78,1.03)
		sounds[selected].play()
		cue_due = clock+sound_rng.randf_range(13,24)
