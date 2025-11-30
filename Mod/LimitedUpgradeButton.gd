class_name LimitedUpgradeButton
extends Upgrade

enum STATE {DISABLED, AFFORDABLE, MAX}

var cost_label = ""
@export var description = ""
@export var report_this = false
@export var show_cost_icon = false
@export var uses_progress = false
var hide_when_locked = true
var controlling_parent
var style_none = StyleBoxFlat.new()
var style_partial = StyleBoxFlat.new()
var style_complete = StyleBoxFlat.new()
var controlling_max_hide = null
var show_affordable = false
var affordable_helper = null
var controlling_confirmation = null
var indicator_type = "OuterBox"
var notify_parent_on_click = false
var is_disabled = false
var progress = 0
var removed: bool = false
var prev_state: int = -1
var update_timer = 0.0

@onready var texture_rect = $Button/TextureRect
@onready var button = $Button
@onready var tooltip = %TooltipTrigger
@onready var tmr_hide_on_upgrade = $"%tmrHideOnUpgrade"


signal click_notify
signal upgrade_notify


var _is_tracking_press = false
var _prev_pos
var _ignore_next_release = false

func _ready() -> void:
    super ()
    if stats.max_level == 0:
        stats.max_level = 2147483647
    style_partial.set_border_color("#ffdc54")
    style_partial.set_border_width_all(4)
    style_complete.set_border_color("#3ac208")
    style_complete.set_border_width_all(4)
    style_none.set_border_color("#000000")
    style_none.set_border_width_all(4)
    add_to_group("theme_update_listener")
    if len(stats.cost) > 0:
        cost_label = stats.cost[0].resource

    if "icon" in stats:
        if stats.icon != "":
            texture_rect.texture = load("res://" + stats.icon)
    get_next_cost()
    update_labels()
    if "hide_on_upgrade" in stats and len(stats.hide_on_upgrade) > 0:
        add_to_group("after_load_setup")
        tmr_hide_on_upgrade.start()
    if (stats.unlock_message != "" and !UpgradeID in PlayerInfo.extra_things_unlocked) or stats.capital_only:
        self.visible = false
        unlocked = false

func set_custom_flat_cost(flat_cost: float, resource: String):
    stats.cost = []
    stats.cost.push_back(
        {
            "cost_base": flat_cost,
            "cost_growth": 0,
            "type": db.growth_type.LINEAR,
            "levels_to_increase": 0,
            "resource": resource,
            "precise": false
        }
    )

    cost_label = stats.cost[0].resource
    get_next_cost()
    update_labels()


func set_locked(lock_in):
    unlocked = !lock_in
    prev_state = -1
    if hide_when_locked:
        self.visible = unlocked

func set_disabled(disabled_in):
    is_disabled = disabled_in

func _process(_delta):
    if !self.visible:
        return
    update_timer += _delta
    if update_timer >= 0.25:
        update_timer = 0.0
        update_state()


func update_state() -> void:
    if !self.visible:
        return

    if stats.cost[0].resource == "Time":
        if is_disabled:
            button.disabled = true
            if prev_state != STATE.DISABLED:
                texture_rect.modulate = Color(1, 1, 1, 0.5)
                prev_state = STATE.DISABLED
            return
        if amount_have >= stats.max_level:
            button.disabled = true
            if prev_state != STATE.MAX:
                texture_rect.modulate = Color(1, 1, 1, 0.5)
                prev_state = STATE.MAX
        else:
            if prev_state != STATE.AFFORDABLE:
                texture_rect.modulate = Color(1, 1, 1, 1)
                prev_state = STATE.AFFORDABLE
            button.disabled = false
        return

    if indicator_type == "OuterBox":
        if amount_have >= stats.max_level:
            if prev_state != STATE.MAX:
                button.disabled = true
                texture_rect.modulate = Color(1, 1, 1, 0.5)
                prev_state = STATE.MAX
        elif stats.cost[0].resource != "Time" and PlayerInfo.resources[stats.cost[0].resource] >= next_cost[0].amount and unlocked:
            if prev_state != STATE.AFFORDABLE:
                button.disabled = false
                texture_rect.modulate = Color(1, 1, 1, 1)
                prev_state = STATE.AFFORDABLE
        else:
            if prev_state != STATE.DISABLED:
                texture_rect.modulate = Color(1, 1, 1, 0.5)
                prev_state = STATE.DISABLED
                button.disabled = true
    else:
        if amount_have >= stats.max_level and stats.max_level > 0:
            button.disabled = true
            if prev_state != STATE.MAX:
                texture_rect.modulate = Color(1, 1, 1, 1)
                texture_rect.modulate = texture_rect.get_theme_color("font_color", "LabelActive")
                prev_state = STATE.MAX
        elif PlayerInfo.resources[stats.cost[0].resource] >= next_cost[0].amount and unlocked:
            button.disabled = false
            if prev_state != STATE.AFFORDABLE or texture_rect.modulate != Color(1, 1, 1, 1):
                texture_rect.modulate = Color(1, 1, 1, 1)
                prev_state = STATE.AFFORDABLE
        else:
            if prev_state != STATE.DISABLED or texture_rect.modulate != Color(1, 1, 1, 0.5):
                texture_rect.modulate = Color(1, 1, 1, 0.5)
                prev_state = STATE.DISABLED
            button.disabled = true


func update_theme():
    prev_state = -1
    update_labels()


func update_labels():
    if indicator_type == "OuterBox":
        if amount_have >= stats.max_level:
            self.set("theme_override_styles/panel", style_complete)
        elif amount_have > 0:
            self.set("theme_override_styles/panel", style_partial)
        else:
            self.set("theme_override_styles/panel", style_none)
    else:
        self.set("theme_override_styles/panel", style_none)
        if amount_have >= stats.max_level and stats.max_level > 0:
            texture_rect.modulate = texture_rect.get_theme_color("font_color", "LabelActive")
        else:
            texture_rect.modulate = Color(1, 1, 1, 1)


func reset():
    var stats_to_reset = super.reset()
    update_labels()
    return stats_to_reset

func set_capital():
    if removed:
        self.visible = false
        return
    if stats.capital_only:
        if !db.main_ship_data[PlayerInfo.ship].capital:
            unlocked = false
            self.visible = false
        else:
            unlocked = true
            check_hide_maxed()

func check_hide_maxed():
    if amount_have >= stats.max_level and controlling_max_hide != null and unlocked:
        var tf_controlling := controlling_max_hide as TFSetting
        if tf_controlling:
            if tf_controlling.is_pressed():
                self.visible = false
                return
        else:
            if controlling_max_hide.button_pressed:
                self.visible = false
                return
    if unlocked and !removed:
        self.visible = true


func _on_Button_gui_input(event):
    if $Button.disabled:
        return

    if PlatformHelper.is_mobile():
        var threshold = clamp($Button.size.y, 5, 30)
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                if !_is_tracking_press and $Button.get_global_rect().has_point(event.global_position):
                    _is_tracking_press = true
                    _prev_pos = event.global_position
            elif !event.pressed and _is_tracking_press:
                _is_tracking_press = false
                if $Button.get_global_rect().has_point(event.global_position) and event.global_position.distance_to(_prev_pos) <= threshold:
                    if not _ignore_next_release:
                        _handle_press_action(event)
                        if $Button.toggle_mode:
                            $Button.button_pressed = true
                _ignore_next_release = false
                _prev_pos = null
        elif event is InputEventMouseMotion:
            if _is_tracking_press:
                if event.global_position.distance_to(_prev_pos) >= threshold:
                    _ignore_next_release = true
    else:
        if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and event.pressed:
            _handle_press_action(event)


func _handle_press_action(event) -> void:
    get_next_cost()
    if _check_mastery_special_confirmation():
        controlling_parent.show_confirmation(self, stats.name, true)
        return
    if notify_parent_on_click:
        emit_signal("click_notify")
        return

    if controlling_confirmation != null:
        var tf_controlling := controlling_confirmation as TFSetting
        if tf_controlling:
            if tf_controlling.is_pressed():
                controlling_parent.show_confirmation(self, stats.name)
                return
        else:
            if controlling_confirmation.button_pressed:
                controlling_parent.show_confirmation(self, stats.name)
                return

    if PlayerInfo.resources[stats.cost[0].resource] >= next_cost[0].amount and (amount_have < stats.max_level or stats.max_level == 0):
        if PlatformHelper.is_mobile():
            upgrade_confirmed()
        else:
            if Input.is_key_pressed(KEY_SHIFT) or event.button_index == MOUSE_BUTTON_RIGHT:
                upgrade_confirmed(10)
            else:
                upgrade_confirmed()


func _check_mastery_special_confirmation() -> bool:
    var upgrades_wanted: Array = ["MasterySleeves", "MasteryEngineering", "MasteryAcumen", "MasteryProficiency", "MasteryIngenuity"]

    if stats.type != "crew_mastery":
        return false

    if UpgradeID in upgrades_wanted:
        return false

    for u in upgrades_wanted:
        if PlayerInfo.upgrades[u].amount_have == 0:
            return true

    return false


func upgrade_confirmed(amount = 1, play_sound = true):
    var sound_played = false
    get_next_cost()
    for i in range(0, amount):
        if PlayerInfo.resources[stats.cost[0].resource] >= next_cost[0].amount and (amount_have < stats.max_level or stats.max_level == 0):
            if play_sound and not sound_played:
                AudioManager.play_interface_sound("upgrade_click")
                sound_played = true
            PlayerInfo.deduct_cost(next_cost)
            if stats.max_level = 2147483647:
                amount_have = 0
            do_upgrade()
            get_next_cost()
            check_hide_maxed()
            if controlling_parent != null:
                if controlling_parent.has_method("on_child_purchased"):
                    controlling_parent.on_child_purchased()
            if report_this:
                PlayerInfo.record_activity("Unlock", UpgradeID)
            if stats.effect[0].target == "retrofits":
                if PlayerInfo.retrofit_button != null:
                    PlayerInfo.retrofits_available += 1
                    PlayerInfo.retrofit_button.update()
        else:
            break
    if tooltip.actual_scene != null:
        tooltip.actual_scene.shifted = false
        if tooltip.actual_scene.visible:
            tooltip.actual_scene.configure()
    emit_signal("upgrade_notify")

func do_upgrade(_buy_amount = 1):
    super.do_upgrade()
    get_next_cost()
    update_labels()

func save():
    var save_dict = super.save()
    save_dict["save_name"] = get_name()
    if uses_progress:
        save_dict["progress"] = progress
    return save_dict

func load_from_save(_load_dict):
    var load_amount = amount_have
    amount_have = 0
    amount_purchased = 0
    while amount_have < load_amount:
        if stats.max_level > 0 and amount_have >= stats.max_level:
            break
        do_upgrade()
    set_locked(!unlocked)


    if UpgradeID == "SynthDamage3":
        set_locked(false)

    check_hide_maxed()
    set_capital()


func reset_layer_2():
    if "crew_mastery" in stats.type:
        if PlayerInfo.stats.crew_keep_supremacy >= 1:
            return
    if uses_progress:
        progress = 0
    reset()


func tooltip_showing(tooltip_in: Node):
    tooltip_in.shifted = false
    tooltip_in.configure()


func handle_hide_on_upgrade():
    var has_all: bool = true
    if super.check_hide_on_upgrade():
        removed = true
        self.visible = false
    else:
        removed = false

        set_capital()


func _on_tmrHideOnUpgrade_timeout():
    if !SaveLoad.loading:
        handle_hide_on_upgrade()


func after_load_setup():
    handle_hide_on_upgrade()
