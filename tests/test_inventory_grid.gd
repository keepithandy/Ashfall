extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("INVENTORY_GRID_FAIL: " + message)
    else:
        print("PASS: ", message)
func run() -> void:
    var game=load("res://scenes/ashfall_editable.tscn").instantiate()
    root.add_child(game)
    game.smoke_test=true
    game.resume_game()
    check(game.open_inventory() and not game.player.active, "main game opens inventory and pauses movement")
    var pack=game.hud.inventory_screen
    check(pack.find_child("Slots",true,false).get_child_count()==27, "grid contains 27 slots")
    check(pack.item_buttons.size()==8 and pack.item_buttons.food_tin.icon!=null, "owned items have icons")
    pack.select_item("bandage")
    game.player.health=60
    game.inventory.bandage=1
    pack.refresh()
    check(pack.count_labels.bandage.text=="1", "stack quantity is displayed")
    pack.use_button.pressed.emit()
    check(game.player.health==95 and game.inventory.bandage==0, "use button applies item effect")
    check(pack.item_buttons.bandage.disabled and pack.item_buttons.bandage.icon==null and pack.count_labels.bandage.text.is_empty(), "used-up stack becomes an empty slot")
    game.inventory.bandage=2
    pack.refresh()
    check(not pack.item_buttons.bandage.disabled and pack.count_labels.bandage.text=="2", "newly acquired stack reappears")
    pack.select_item("water_bottle")
    pack.equip_button.pressed.emit()
    check(game.equipped_item_id=="water_bottle", "carry button equips selected item")
    pack.stow_button.pressed.emit()
    check(game.equipped_item_id.is_empty(), "stow button empties hand")
    var tab:=InputEventKey.new()
    tab.physical_keycode=KEY_TAB
    tab.pressed=true
    game._input(tab)
    check(not game.inventory_open and game.player.active, "Tab closes inventory and resumes movement")
    game.queue_free()
    await process_frame
    print("INVENTORY_GRID: ",failures," failure(s)")
    quit(1 if failures else 0)
