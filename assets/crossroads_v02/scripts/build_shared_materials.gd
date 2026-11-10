## Optional Godot EditorScript: Script > Run in Godot editor.
## Generates non-destructive shared material resources for the EXISTING v0.1 meshes.
## For generated v0.2 GLBs, materials are already embedded.
@tool
extends EditorScript

const BASE := "res://assets/crossroads_v02/"

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASE + "materials"))
    for surface in ["concrete", "steel", "roof"]:
        var material := ORMMaterial3D.new()
        material.resource_name = "Ashfall V02 " + surface.capitalize()
        material.albedo_texture = load(BASE + "textures/" + surface + "_albedo.png")
        material.normal_enabled = true
        material.normal_texture = load(BASE + "textures/" + surface + "_normal.png")
        material.orm_texture = load(BASE + "textures/" + surface + "_orm.png")
        material.roughness = 1.0
        material.metallic = 1.0
        var save_path := BASE + "materials/" + surface + "_v02.tres"
        var result := ResourceSaver.save(material, save_path)
        if result != OK:
            push_error("Could not save: " + save_path)
        else:
            print("Created: " + save_path)
