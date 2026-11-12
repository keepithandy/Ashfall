extends Node3D
## Localized, intermittent environmental audio for Station 04.
## Original synthesized gust/rustle and existing procedural creak sources.
## No triggered horror jumpscares, objective changes or gameplay effects.

const SITES := [
    {"name": "PineWindWest", "at": Vector3(-61, 1.6, 21), "radius": 43.0},
    {"name": "PineWindEast", "at": Vector3(61, 1.5, -15), "radius": 43.0},
    {"name": "RailRattle", "at": Vector3(33, 2.3, -20), "radius": 34.0},
    {"name": "AbandonedCottage", "at": Vector3(-24, 1.6, 44), "radius": 34.0},
    {"name": "DistantPole", "at": Vector3(53, 1.8, -47), "radius": 39.0}
]

var game: Node3D
var cues: Array[AudioStreamPlayer3D] = []
var next_due: Array[float] = []
var rng := RandomNumberGenerator.new()
var clock := 0.0


func _ready() -> void:
    name = "Station04AmbientCues"
    rng.seed = 42022
    var atmosphere := game.get_node_or_null("Atmosphere") if is_instance_valid(game) else null
    var rustle := _rustle_clip()
    for i in range(SITES.size()):
        var place: Dictionary = SITES[i]
        var audio := AudioStreamPlayer3D.new()
        audio.name = place["name"]
        audio.position = place["at"]
        audio.bus = "Effects"
        audio.volume_db = -28.0
        audio.max_distance = float(place["radius"])
        audio.unit_size = 5.0
        audio.attenuation_filter_cutoff_hz = 2200
        audio.stream = atmosphere.creak_clip(i % 4) if i >= 2 and atmosphere != null else rustle
        add_child(audio)
        cues.append(audio)
        next_due.append(rng.randf_range(11.0, 27.0))


func _rustle_clip() -> AudioStreamWAV:
    var clip := AudioStreamWAV.new()
    clip.format = AudioStreamWAV.FORMAT_16_BITS
    clip.mix_rate = 22050
    var count := 33075
    var data := PackedByteArray()
    data.resize(count * 2)
    var filtered := 0.0
    var sound_rng := RandomNumberGenerator.new()
    sound_rng.seed = 42055
    for i in range(count):
        var t := float(i) / float(clip.mix_rate)
        filtered = filtered * 0.87 + sound_rng.randf_range(-1.0, 1.0) * 0.13
        var envelope := pow(maxf(0.0, sin(PI * t / 1.5)), 2.0)
        var flutter := 0.78 + 0.22 * sin(TAU * 12.0 * t)
        data.encode_s16(i * 2, int(clampf(filtered * envelope * flutter * 11000.0, -32767.0, 32767.0)))
    clip.data = data
    return clip


func _process(delta: float) -> void:
    if not is_instance_valid(game) or not game.started or not is_instance_valid(game.player) or not game.player.active:
        return
    if game.areas != null and game.areas.current != "perimeter":
        return
    clock += delta
    var player_at: Vector3 = game.player.global_position
    for i in range(cues.size()):
        if clock < next_due[i]:
            continue
        var site: Dictionary = SITES[i]
        var hearing := float(site["radius"])
        if player_at.distance_to(site["at"]) <= hearing:
            cues[i].pitch_scale = rng.randf_range(0.83, 1.11)
            cues[i].volume_db = rng.randf_range(-31.0, -26.0)
            if not cues[i].playing:
                cues[i].play()
        next_due[i] = clock + rng.randf_range(19.0, 42.0)
