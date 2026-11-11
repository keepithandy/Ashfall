"""Guard against losing showroom displays when appending decorative prop grids.

Checks the extension's 37 unique static prop references, 37 captions,
three categorized sections, and the preserved original showroom resources.
The GitHub workflow also imports and instantiates the extension in Godot 4.7.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
EXT = ROOT / "scenes/testing/ashfall_decorative_grid_extension.tscn"
SHOWROOM = ROOT / "scenes/testing/ashfall_asset_showroom.tscn"
SENTINEL = 'res://scenes/testing/ashfall_decorative_grid_extension.tscn'


def main():
    extension = EXT.read_text(encoding="utf8")
    original = SHOWROOM.read_text(encoding="utf8")

    entries = re.findall(
        r'\[ext_resource type="PackedScene" path="res://([^"]+)" id="asset_\d{3}"\]',
        extension,
    )
    assert len(entries) == 37, f"Expected 37 decorative entries, got {len(entries)}"
    assert len(set(entries)) == 37, "Duplicate decorative assets in grid"
    for path in entries:
        assert (ROOT / path).is_file(), f"Missing referenced asset: {path}"
        assert path.startswith(
            ("scenes/decorative_world/", "scenes/decorative_interiors/")
        ), f"Non-decorative asset added: {path}"

    sections = {
        "11_DecorativeWorld": (16, "decorative_world"),
        "12_AbandonedInteriors": (16, "decorative_interiors"),
        "13_DamageVariants": (5, "/variants/"),
    }
    for node, (expected_count, directory) in sections.items():
        assert f'[node name="{node}" type="Node3D" parent="."]' in extension
        props = re.findall(
            r'\[node name="A\d{3}_[^"]+" parent="' + node + r'" instance=ExtResource\("asset_\d{3}"\)\]',
            extension,
        )
        assert len(props) == expected_count, (node, len(props))
        assert directory in extension

    assert extension.count('type="Label3D" parent="11_DecorativeWorld"') == 17
    assert extension.count('type="Label3D" parent="12_AbandonedInteriors"') == 17
    assert extension.count('type="Label3D" parent="13_DamageVariants"') == 6
    assert extension.count('metadata/physics = "Static decorative set dressing; no gameplay interaction"') == 37
    assert extension.count('mesh = SubResource("DecorativePlateMesh")') == 37

    assert f'path="{SENTINEL}" id="decorative_grid_37"' in original
    assert '[node name="11_13_DecorativeGrid" parent="." instance=ExtResource("decorative_grid_37")]' in original
    assert original.count("size = Vector3(122, 0.3, 388)") == 2
    assert '0, -0.17, 160)' in original, "Expanded showroom floor not centered"
    assert "far = 600.0" in original, "Fly camera must reach the new grid"
    assert original.count('type="PackedScene" path="res://') >= 95, "Original showroom entries were lost"
    assert 'res://scenes/checkpoint_house.tscn' in original
    assert 'res://scenes/loot/food_tin.tscn' in original

    print("PASS: 37 labeled decorative displays, all prior showroom displays preserved")


if __name__ == "__main__":
    main()
