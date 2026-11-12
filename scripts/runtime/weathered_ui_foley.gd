extends Node
## Low-output original UI handling noises, synthesized at startup.
## Cloth, paper and old metal instead of digital confirmation beeps.
const SAMPLE_RATE := 22050
var player: AudioStreamPlayer
var sounds: Array[AudioStreamWAV] = []


func _ready() -> void:
    name = "OldGearSounds"
    player = AudioStreamPlayer.new()
    player.bus = "Effects"
    player.volume_db = -26.0
    add_child(player)
    for kind in range(3):
        sounds.append(_make_sound(kind))


func _make_sound(kind: int) -> AudioStreamWAV:
    var clip := AudioStreamWAV.new()
    clip.format = AudioStreamWAV.FORMAT_16_BITS
    clip.mix_rate = SAMPLE_RATE
    var duration := 0.32 if kind == 0 else (0.38 if kind == 1 else 0.17)
    var count := int(duration * SAMPLE_RATE)
    var data := PackedByteArray()
    data.resize(count * 2)
    var random := RandomNumberGenerator.new()
    random.seed = 2348 + kind * 61
    var low := 0.0
    var scratch := 0.0
    for i in range(count):
        var t := float(i) / float(SAMPLE_RATE)
        var f := float(i) / float(count)
        low = low * (0.68 if kind == 2 else 0.89) + random.randf_range(-1.0, 1.0) * (0.32 if kind == 2 else 0.11)
        scratch = scratch * 0.5 + random.randf_range(-1.0, 1.0) * 0.5
        var envelope := pow(maxf(0.0, sin(f * PI)), 1.4) * (1.0 - f * 0.23)
        var flakes := 0.65 + 0.35 * sin(TAU * (17.0 if kind == 0 else 11.0) * t)
        var tone := 0.11 * sin(TAU * 475.0 * t) if kind == 2 else 0.0
        var sample_value := (low * 0.77 + scratch * 0.14 * flakes + tone) * envelope
        data.encode_s16(i * 2, int(clampf(sample_value * 11000.0, -32000.0, 32000.0)))
    clip.data = data
    return clip


func paper() -> void:
    _play(0)


func cloth() -> void:
    _play(1)


func latch() -> void:
    _play(2)


func _play(kind: int) -> void:
    if not is_instance_valid(player) or sounds.size() != 3:
        return
    player.stop()
    player.stream = sounds[kind]
    player.play()
