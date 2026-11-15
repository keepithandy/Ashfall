extends SceneTree
## Sample the collision-matched terrain, not just route control-point heights.
## This protects vehicle carriageways where a narrower footpath intersects.
const PROFILE = preload("res://scripts/briar_creek/briar_creek_profile.gd")
const SAMPLE_STEP := 2.0
const MAX_VEHICLE_GRADE := 0.15
const MAX_VEHICLE_CROSSFALL := 0.12

func _initialize() -> void:
    call_deferred("_verify")

func _height(profile, x: float, north: float) -> float:
    var world: Vector3 = profile.to_world(x, north)
    return profile.surface_height_at(world.x, world.z)

func _verify() -> void:
    var profile = PROFILE.new()
    var issues: Array[String] = []
    var vehicle_count := 0
    for route in PROFILE.ROUTES:
        if str(route["kind"]) != "vehicle":
            continue
        vehicle_count += 1
        var points: Array = route["points"]
        var half_width := float(route["width"]) * 0.5
        var max_grade := 0.0
        var max_crossfall := 0.0
        for i in range(points.size() - 1):
            var a: Vector3 = points[i]
            var b: Vector3 = points[i + 1]
            var start := Vector2(a.x, a.z)
            var delta := Vector2(b.x - a.x, b.z - a.z)
            var length := delta.length()
            if length < 0.001:
                issues.append("Zero-length road segment: " + str(route["id"]))
                continue
            var count := maxi(1, ceili(length / SAMPLE_STEP))
            var side := Vector2(-delta.y, delta.x).normalized()
            var prior := start
            var prior_h := _height(profile, prior.x, prior.y)
            for j in range(count + 1):
                var t := float(j) / float(count)
                var p := start + delta * t
                var h := _height(profile, p.x, p.y)
                if j > 0:
                    var local_grade := absf(h - prior_h) / maxf(p.distance_to(prior), 0.001)
                    max_grade = maxf(max_grade, local_grade)
                var left := p + side * half_width
                var right := p - side * half_width
                var crossfall := absf(_height(profile, left.x, left.y) - _height(profile, right.x, right.y)) / (half_width * 2.0)
                max_crossfall = maxf(max_crossfall, crossfall)
                prior = p
                prior_h = h
        print("%s physical centerline peak grade %.2f%%; peak crossfall %.2f%%" % [
            str(route["id"]), max_grade * 100.0, max_crossfall * 100.0
        ])
        if max_grade > MAX_VEHICLE_GRADE:
            issues.append("%s physical centerline grade exceeds %.0f%%: %.2f%%" % [
                str(route["id"]), MAX_VEHICLE_GRADE * 100.0, max_grade * 100.0
            ])
        if max_crossfall > MAX_VEHICLE_CROSSFALL:
            issues.append("%s physical crossfall exceeds %.0f%%: %.2f%%" % [
                str(route["id"]), MAX_VEHICLE_CROSSFALL * 100.0, max_crossfall * 100.0
            ])
    if vehicle_count != 3:
        issues.append("Expected three vehicle roads")
    if issues.is_empty():
        print("BRIAR CREEK VEHICLE ROAD GRADE: PASS (sampled terrain geometry; vehicle physics not certified)")
        quit(0)
    else:
        for issue in issues:
            push_error(issue)
        quit(1)
