class_name SynthModuleArea
extends MarginContainer


enum SynthModuleLayout{SMALL, MEDIUM, LARGE}

const SYNTH_MODULE_SLOT = preload("res://interface/synth/SynthModuleSlot.tscn")
const COST_ICON = preload("res://interface/CostIconBig.tscn")

@onready var lbl_active_modules: Label = %lblActiveModules
@onready var grid_modules: GridContainer = %GridModules
@onready var v_unlocked: VBoxContainer = %VUnlocked
@onready var v_locked: VBoxContainer = %VLocked
@onready var btn_unlock_modules: USIButton = %btnUnlockModules
@onready var h_button_content: HBoxContainer = %HButtonContent
@onready var margin_container_scroll: MarginContainer = %MarginContainerScroll
@onready var btn_layout: USIButton = %btnLayout
@onready var chk_show_small_button: TFSetting = %chkShowSmallButton
@onready var c_rect_module_separator: ColorRect = %CRectModuleSeparator
@onready var chk_drag_drop: TFSetting = %chkDragDrop

var _queue_completed_this_tick: int = 0

var _num_modules_active = 0: set = _set_num_modules_active
var _module_nodes = {}

const _module_unlock_cost = {"resource": "Alloy", "amount": 10}
var _modules_locked = true
var module_order = []

var module_auto_crafting: String = ""
var resources_for_next_auto: Array = []

const extra_slot = 5


func _ready() -> void :
    set_slots()
    add_to_group("save_and_load")
    add_to_group("after_load_setup")
    add_to_group("max_active_module_slots_upgrade_listener")
    add_to_group("retrofit_listener")
    add_to_group("loadout_management")

    gui_input.connect(_on_gui_input)

    if _modules_locked:
        var ci = COST_ICON.instantiate() as CostIcon
        ci.amount = _module_unlock_cost.amount
        ci.resource = _module_unlock_cost.resource
        ci.show_amount_have = true
        ci.show_when_have = true
        ci.precision = 0
        ci.setup()
        h_button_content.add_child(ci)
        v_locked.show()
        v_unlocked.hide()
    else:
        v_locked.hide()
        v_unlocked.show()
        set_process(false)

    if PlatformHelper.is_mobile():
        margin_container_scroll.add_theme_constant_override("margin_bottom", 32)
    _update_layout_button()
    _update_grid_config()
    _update_show_small_visibility()
    chk_show_small_button.visible = !PlatformHelper.is_mobile()
    c_rect_module_separator.hide()
    mouse_exited.connect(c_rect_module_separator.hide)


func _process(_delta: float) -> void :
    var can_afford = (_module_unlock_cost.resource in PlayerInfo.resources) and ((PlayerInfo.resources[_module_unlock_cost.resource] >= _module_unlock_cost.amount) or _module_unlock_cost.resource in PlayerInfo.infinite_resources)
    ButtonHelper.enable_and_update_labels(btn_unlock_modules, can_afford)


func set_slots() -> void :
    for c in db.module_data:
        var s: = SYNTH_MODULE_SLOT.instantiate() as SynthModuleSlot
        s.move_requested.connect(_on_synth_module_slot_move_requested)
        s.set_texture(load(db.module_data[c].texture))
        s.module = c
        s.active = false
        s.stats = db.module_data[c].duplicate(true)
        s.stats["cost"] = []
        s.stats["effect"] = []
        s.get_next_cost()
        grid_modules.add_child(s)
        _module_nodes[c] = s
        s.activation_change_requested.connect(_on_synth_module_activation_change_requested.bind(s))
        s.popup_requested.connect(_on_synth_module_popup_requested.bind(s))
        s.set_ui_update_flag()
    update_slots()



func setup_queue_eligable_nodes():
    var nodes_for_queue: Array = []
    for m in _module_nodes:
        nodes_for_queue.push_back(_module_nodes[m])

    Modules.get_module_queue().create_node_ref_dict(nodes_for_queue)


func update_slots():
    if SaveLoad.loading:
        return
    for c in Modules.modules:
        if Modules.modules[c].locked or Modules.modules[c].removed:
            _module_nodes[c].visible = false
            _module_nodes[c].mouse_filter = MOUSE_FILTER_IGNORE
            _module_nodes[c].set_optional(false)
        else:
            _module_nodes[c].visible = true
            _module_nodes[c].mouse_filter = MOUSE_FILTER_PASS
            _module_nodes[c].set_optional(true)
            _module_nodes[c].set_ui_update_flag()


func check_and_activate(module_to_activate: SynthModuleSlot, activate: bool):

    if module_to_activate.active == activate:
        return

    if activate:

        if _num_modules_active < PlayerInfo.stats["max_active_module_slots"] + extra_slot and module_to_activate.level > 0:
            PlayerInfo.loadouts_area.update_equipped_loadout_status(Enums.SystemName.SYNTH)
            AudioManager.play_interface_sound("toggle_on")
            module_to_activate.active = activate
            _num_modules_active += 1
            Signals.synth.synth_module_activated.emit()
    else:
        PlayerInfo.loadouts_area.update_equipped_loadout_status(Enums.SystemName.SYNTH)
        AudioManager.play_interface_sound("toggle_off")
        module_to_activate.active = activate
        _num_modules_active -= 1
        Signals.synth.synth_module_deactivated.emit()


func _set_num_modules_active(new_value: int) -> void :
    _num_modules_active = new_value


func get_num_active_modules() -> int:
    return _num_modules_active


func _get_visible_modules() -> Array[SynthModuleSlot]:
    var result: Array[SynthModuleSlot] = []
    for child: SynthModuleSlot in grid_modules.get_children():
        if child.visible:
            result.append(child)
    return result


func _on_synth_module_popup_requested(synth_module: SynthModuleSlot) -> void :
    var popup: = PopupHelper.create(PopupHelper.Kind.SYNTH_MODULE_DETAILS) as SynthModulePopup
    add_child(popup)

    var can_activate_more = _num_modules_active < int(PlayerInfo.stats["max_active_module_slots"])
    var visible_index = _get_visible_index(synth_module)
    var can_move_left = visible_index > 0
    var can_move_right = visible_index < _get_visible_modules().size() - 1
    synth_module.prevent_tapping_module_for_popup(true)
    popup.configure(synth_module, can_activate_more, can_move_left, can_move_right, synth_module._can_afford_next_level)

    popup.activation_change_requested.connect(_on_synth_module_activation_change_requested.bind(synth_module))
    popup.upgrade_requested.connect(synth_module.upgrade_confirmed)
    popup.move_requested.connect(_on_synth_module_popup_move_requested.bind(synth_module, popup))

    if Signals.synth.synth_module_activated.is_connected(_reconfigure_popup):
        Signals.synth.synth_module_activated.disconnect(_reconfigure_popup)
    if Signals.synth.synth_module_deactivated.is_connected(_reconfigure_popup):
        Signals.synth.synth_module_deactivated.disconnect(_reconfigure_popup)

    Signals.synth.synth_module_activated.connect(_reconfigure_popup.bind(popup, synth_module))
    Signals.synth.synth_module_deactivated.connect(_reconfigure_popup.bind(popup, synth_module))
    popup.tree_exited.connect(_on_popup_tree_exited.bind(synth_module))

    popup.popup_using_scene_layout()


func _on_popup_tree_exited(synth_module: SynthModuleSlot) -> void :
    if Signals.synth.synth_module_activated.is_connected(_reconfigure_popup):
        Signals.synth.synth_module_activated.disconnect(_reconfigure_popup)
    if Signals.synth.synth_module_deactivated.is_connected(_reconfigure_popup):
        Signals.synth.synth_module_deactivated.disconnect(_reconfigure_popup)

    synth_module.prevent_tapping_module_for_popup(false)


func _reconfigure_popup(popup: SynthModulePopup, synth_module: SynthModuleSlot) -> void :
    var can_activate_more = _num_modules_active < int(PlayerInfo.stats["max_active_module_slots"])
    var visible_index = _get_visible_index(synth_module)
    var can_move_left = visible_index > 0
    var can_move_right = visible_index < _get_visible_modules().size() - 1
    popup.configure(synth_module, can_activate_more, can_move_left, can_move_right, synth_module._can_afford_next_level)


func _get_visible_index(synth_module: SynthModuleSlot) -> int:
    var visible_modules: = _get_visible_modules()
    for i in visible_modules.size():
        if visible_modules[i] == synth_module:
            return i
    return -1


func _on_synth_module_popup_move_requested(move_left: bool, synth_module: SynthModuleSlot, popup: SynthModulePopup) -> void :
    var visible_modules: = _get_visible_modules()
    var visible_index: = _get_visible_index(synth_module)
    var new_visible_index: int
    if move_left:
        new_visible_index = visible_index - 1
    else:
        new_visible_index = visible_index + 1

    var module_at_new_visible_index: SynthModuleSlot = visible_modules[new_visible_index]
    var actual_index_to_move_to = module_at_new_visible_index.get_index()

    grid_modules.move_child(synth_module, actual_index_to_move_to)
    var can_move_left = new_visible_index > 0
    var can_move_right = new_visible_index < visible_modules.size() - 1
    popup.update_reorder_buttons(can_move_left, can_move_right)


func _on_synth_module_activation_change_requested(requested_state: bool, synth_module: SynthModuleSlot) -> void :
    check_and_activate(synth_module, requested_state)


func load_modules_from_save() -> void :
    var num_active = 0
    for m in Modules.modules:
        if m in _module_nodes:
            var synth_module_slot: = _module_nodes[m] as SynthModuleSlot
            synth_module_slot.level = Modules.modules[m].level
            synth_module_slot.active = Modules.modules[m].active
            if Modules.modules[m].tier > len(db.module_data[m].tiers):
                Modules.modules[m].tier = len(db.module_data[m].tiers)
            synth_module_slot.tier = Modules.modules[m].tier
            if Modules.modules[m].active:
                num_active += 1
            synth_module_slot.process_upgrade()
            synth_module_slot.active = Modules.modules[m].active
    _num_modules_active = num_active


func process_upgrade():
    if !SaveLoad.loading:
        if _num_modules_active > PlayerInfo.stats["max_active_module_slots"]:
            var num_to_deactivate = _num_modules_active - PlayerInfo.stats["max_active_module_slots"]
            for m in Modules.modules:
                if Modules.modules[m].active:
                    _module_nodes[m].active = false
                    _num_modules_active -= 1
                    num_to_deactivate -= 1
                    if num_to_deactivate <= 0:
                        break


func _on_ModuleQueue_start_queue():
    var next_module = Modules.get_module_queue().get_next_item()
    if next_module != null:
        PlayerInfo.synth_main_area.mark_use_module_queue(true)
        auto_craft_start(next_module.module, 1)



func auto_craft_start(module_to_craft: String, _amount: int):
    Modules.get_module_auto_overlay().auto_craft_start(_module_nodes[module_to_craft])
    module_auto_crafting = module_to_craft
    resources_for_next_auto = _module_nodes[module_auto_crafting].get_next_cost()
    auto_craft_next_step()




func auto_craft_synth_made_resource(resource: String) -> bool:

    if module_auto_crafting == "":
        return false
    if is_equal_approx(auto_craft_check_resource(resource), 0.0):
        auto_craft_next_step()
        return true

    return false



func auto_craft_next_step():
    var next_resource: String = ""
    for r in resources_for_next_auto:

        if not r.resource in PlayerInfo.infinite_resources or Challenges.check("no_synth_infinite"):
            if PlayerInfo.resources[r.resource] < r.amount:
                var rec = Recipes.resource_lookup[r.resource]
                if Recipes.recipes[rec].locked:

                    Modules.get_module_queue().remove_item(_module_nodes[module_auto_crafting])
                    _queue_completed_this_tick = 0
                    start_next_queued()
                    return
                else:

                    for c in Recipes.recipes[rec].cost:
                        if c.resource == "Time":
                            continue
                        if c.resource in Recipes.resource_lookup:
                            if Recipes.recipes[Recipes.resource_lookup[c.resource]].locked:
                                Modules.get_module_queue().remove_item(_module_nodes[module_auto_crafting])
                                _queue_completed_this_tick = 0
                                start_next_queued()
                                return

                for s in get_tree().get_nodes_in_group("synth"):
                    if !s.locked:
                        s.set_smart_recipe(r.resource)
                        s.recipe_selected(r.resource)
                        s.set_smart_craft_on()
                        s.on = true
                _queue_completed_this_tick = 0
                return
    _queue_completed_this_tick += 1

    if _queue_completed_this_tick >= 20:
        await get_tree().process_frame
        _queue_completed_this_tick = 0

    var module_slot: = _module_nodes[module_auto_crafting] as SynthModuleSlot
    module_slot.upgrade_confirmed(1)
    start_next_queued()


func start_next_queued():
    var module_queue = Modules.get_module_queue()



    var next_queue = null
    if module_auto_crafting.is_empty():
        if module_queue.has_entries():
            next_queue = module_queue.queue_list[0].ref_node
    else:
        next_queue = module_queue.finish_item_get_next(_module_nodes[module_auto_crafting])

    if next_queue != null:
        auto_craft_start(next_queue.module, 1)
    else:

        stop_queue()




func auto_craft_check_resource(resource: String) -> float:
    for r in resources_for_next_auto:
        if r.resource == resource:

            if r.resource in PlayerInfo.infinite_resources:
                return 0.0
            return max(r.amount - PlayerInfo.resources[resource], 0.0)
    return -1.0

func stop_queue():
    PlayerInfo.synth_main_area.mark_use_module_queue(false)
    Modules.get_module_auto_overlay().stop_queue()
    module_auto_crafting = ""
    resources_for_next_auto = []


func check_level_fully_infinite():
    if !Challenges.check("no_synth_infinite"):
        for m in _module_nodes.values():
            m.check_and_craft_if_infinite()


func reset(reset_alien: bool = false):
    for m in Modules.modules:


        if db.module_data[m].alien and !reset_alien:
            continue

        var was_active = Modules.modules[m].active
        var module_slot: SynthModuleSlot = _module_nodes[m]
        if was_active:
            module_slot.active = false
            _num_modules_active -= 1
        module_slot.reset()
        if was_active and module_slot.level > 0 and _num_modules_active < PlayerInfo.stats["max_active_module_slots"]:
            module_slot.active = true
            _num_modules_active += 1


        _module_nodes[m].set_texture_color()


    var num_active: = 0
    for m in Modules.modules:
        var module_slot: SynthModuleSlot = _module_nodes[m]
        if module_slot.active:
            num_active += 1
    _num_modules_active = num_active

    update_slots()


func turn_all_off():
    for m in Modules.modules:
        if Modules.modules[m].active:
            var module_slot: SynthModuleSlot = _module_nodes[m]
            module_slot.active = false
    _num_modules_active = 0


func set_module_removed(m, removed: bool = true):
    var module_slot: SynthModuleSlot = _module_nodes[m]
    if Modules.modules[m].active and removed:
        module_slot.active = false
        _num_modules_active -= 1
    Modules.modules[m].removed = removed
    module_slot.visible = !removed
    module_slot.mouse_filter = MOUSE_FILTER_IGNORE if removed else MOUSE_FILTER_STOP
    module_slot.set_optional( !removed)


func do_retrofit() -> void :
    process_upgrade()


func save_loadout():
    var load_dict = {}
    for m in Modules.modules:
        if Modules.modules[m].active:
            load_dict[m] = true
    return load_dict


func load_loadout(load_dict):
    var active_nodes = Array()
    var num_active = 0

    for m in load_dict:
        active_nodes.push_back(m)


    for m in _module_nodes:
        var synth_module_slot: = _module_nodes[m] as SynthModuleSlot
        if m in active_nodes and !Modules.modules[m].locked and !Modules.modules[m].removed and Modules.modules[m].level > 0 and num_active < PlayerInfo.stats["max_active_module_slots"]:
            num_active += 1
            synth_module_slot.active = true
        else:
            synth_module_slot.active = false

    _num_modules_active = num_active


func save():
    module_order = []
    for s: SynthModuleSlot in grid_modules.get_children():
        module_order.append(s.module)

    var save_data = {
        "save_name": get_name(), 
        "module_order": module_order, 
        "module_auto_crafting": module_auto_crafting, 
        "_modules_locked": _modules_locked
        }
    return save_data


func load_from_save(_load_dict):
    var on_which = 0
    for m in module_order:
        if m in _module_nodes:
            grid_modules.move_child(_module_nodes[m], on_which)
        on_which += 1


func after_load_setup():

    _num_modules_active = _num_modules_active
    if not _modules_locked:
        unlock_modules()


func _on_btn_unlock_modules_pressed() -> void :
    unlock_modules()
    Dialogue.check_play_dialogue("ModuleArea_first_click")
    PlayerInfo.handle_unlock("UnlockModule", "Offense1")
    PlayerInfo.handle_unlock("UnlockModule", "Defense1")



func unlock_modules() -> void :
    v_locked.hide()
    v_unlocked.show()
    _modules_locked = false
    set_process(false)


func are_modules_locked() -> bool:
    return _modules_locked


func _update_layout_button() -> void :
    match Config.config.get_value("Synth", "module_layout"):
        SynthModuleLayout.SMALL:
            btn_layout.text = "Small"
        SynthModuleLayout.MEDIUM:
            btn_layout.text = "Medium"
        SynthModuleLayout.LARGE:
            btn_layout.text = "Large"


func _update_grid_config() -> void :
    grid_modules.begin_bulk_theme_override()
    match Config.config.get_value("Synth", "module_layout"):
        SynthModuleLayout.SMALL:
            grid_modules.add_theme_constant_override("h_separation", 6)
            grid_modules.add_theme_constant_override("v_separation", 6)
            grid_modules.columns = 12 if PlatformHelper.is_mobile() else 13
        SynthModuleLayout.MEDIUM:
            grid_modules.add_theme_constant_override("h_separation", 14)
            grid_modules.add_theme_constant_override("v_separation", 14)
            grid_modules.columns = 10 if PlatformHelper.is_mobile() else 11
        SynthModuleLayout.LARGE:
            grid_modules.add_theme_constant_override("h_separation", 16)
            grid_modules.add_theme_constant_override("v_separation", 16)
            grid_modules.columns = 7
    grid_modules.end_bulk_theme_override()


func _update_show_small_visibility() -> void :
    var should_show = Config.config.get_value("Synth", "module_layout") == SynthModuleLayout.SMALL
    chk_show_small_button.modulate.a = 1 if should_show else 0
    chk_show_small_button.mouse_filter = Control.MOUSE_FILTER_STOP if should_show else Control.MOUSE_FILTER_IGNORE


func _on_gui_input(event: InputEvent) -> void :
    var mouse_event = event as InputEventMouseMotion
    if not mouse_event:
        return

    var viewport: Viewport = get_tree().get_root()
    var is_dragging = viewport.gui_is_dragging()
    if not is_dragging:
        return

    var drag_data = viewport.gui_get_drag_data()
    if not "type" in drag_data or not "index" in drag_data or drag_data["type"] != "synth_module_slot":
        return

    var moused_over_slot: SynthModuleSlot
    for child in grid_modules.get_children():
        if not child.visible:
            continue

        if child.get_global_rect().has_point(mouse_event.global_position):
            moused_over_slot = child
            break

    if not moused_over_slot:
        c_rect_module_separator.hide()
        return

    c_rect_module_separator.custom_minimum_size.y = moused_over_slot.size.y
    c_rect_module_separator.size.y = 0

    var padding = grid_modules.get_theme_constant("h_separation") / 2.0

    if mouse_event.global_position.x < moused_over_slot.global_position.x + (moused_over_slot.size.x / 2):
        c_rect_module_separator.global_position = moused_over_slot.global_position
        c_rect_module_separator.global_position.x -= padding
    else:
        c_rect_module_separator.global_position = moused_over_slot.global_position
        c_rect_module_separator.global_position.x += moused_over_slot.size.x + padding
    c_rect_module_separator.show()


func _on_btn_layout_gui_input(event: InputEvent) -> void :
    var mouse_event: = ButtonHelper.convert_event_to_mouse_button(event, btn_layout)
    if not mouse_event:
        return

    var new_value = Config.config.get_value("Synth", "module_layout")
    if mouse_event.button_index == MOUSE_BUTTON_LEFT:
        new_value += 1
    else:
        new_value += len(SynthModuleLayout) - 1

    new_value %= len(SynthModuleLayout)

    Config.config.set_value("Synth", "module_layout", new_value)
    Config.save()

    _update_layout_button()
    _update_grid_config()
    _update_show_small_visibility()
    Signals.synth.synth_layout_changed.emit()


func _on_synth_module_slot_move_requested(item_to_move_index: int, sibling_index: int, move_to_left_of_sibling: bool) -> void :

    if item_to_move_index < 0 or sibling_index < 0:
        return

    var move_to_index: int = sibling_index


    if move_to_left_of_sibling and item_to_move_index < sibling_index:
        move_to_index -= 1

    elif !move_to_left_of_sibling and item_to_move_index > sibling_index:
        move_to_index += 1


    if move_to_index == item_to_move_index:
        return

    var existing_item = grid_modules.get_child(item_to_move_index)
    grid_modules.move_child(existing_item, move_to_index)


func _notification(what: int) -> void :
    match what:
        NOTIFICATION_DRAG_END:
            c_rect_module_separator.hide()


func check_ai_unlocks() -> void :
    if "AIModuleOrganize" in PlayerInfo.upgrades:
        if PlayerInfo.upgrades.AIModuleOrganize.amount_have > 0:
            chk_drag_drop.visible = true
        else:
            chk_drag_drop.visible = false
