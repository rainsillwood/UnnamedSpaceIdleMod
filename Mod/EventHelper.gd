extends Node

var events = {}
var events_active = []
var purchaseables_reference = {}
var top_level_event_button
var check_interval = 30
var check_timer = 0
var event_panel = null
var skin_acquired_previous_event: Array = []

func _ready():
    add_to_group("after_load_setup")
    setup_events()

func after_load_setup():
    start_stop_events()

func _process(delta):
    check_timer += delta
    if check_timer >= check_interval:
        check_timer = 0
        if !SaveLoad.loading:
            start_stop_events()


func setup_events():
    events = {
        "spacemas":
            {
                "name": "Spacemas", 
                "version": 1, 
                "start_date":
                    {
                        "year": 2024, 
                        "month": Time.MONTH_DECEMBER, 
                        "day": 20, 
                        "hour": 0, 
                        "minute": 0, 
                    }, 
                "end_date":
                    {
                        "year": 2026, 
                        "month": Time.MONTH_JANUARY, 
                        "day": 5, 
                        "hour": 23, 
                        "minute": 59, 
                    }, 
                "panel": null, 
                "purchaseables":
                    ["SpacemasBundle", "SpacemasAIPoints"], 
                "resources":
                    ["Coalexium", "Giftium"], 
                "upgrade_groups":
                    ["spacemas", "spacemas_ac"], 
                "ship_design": "spacemas", 
                "key_nodes": {}
            }, 
        "spaceversary":
            {
                "name": "Spaceversary", 
                "version": 1, 
                "start_date":
                    {
                        "year": 2025, 
                        "month": Time.MONTH_JULY, 
                        "day": 26, 
                        "hour": 0, 
                        "minute": 0, 
                    }, 
                "end_date":
                    {
                        "year": 2025, 
                        "month": Time.MONTH_AUGUST, 
                        "day": 12, 
                        "hour": 23, 
                        "minute": 59, 
                    }, 
                "panel": null, 
                "purchaseables":
                    ["SpaceversaryBundle", "SpaceversaryAIPoints"], 
                "resources":
                    ["Yearium", "Versarite"], 
                "upgrade_groups":
                    ["spaceversary", "spaceversary_ac"], 
                "ship_design": "spaceversary", 
                "key_nodes": {}
            }
    }
    var event_name = events.keys()
    var during_day = 15
    var total_day = during_day * event_name.size()
    var event_start = floor(floor(Time.get_unix_time_from_system() / 86400) / total_day) * total_day
    for i in range(event_name.size()):
        var event = events[event_name[i]]
        event.start_date = Time.get_datetime_dict_from_unix_time((event_start + during_day * i) * 86400)
        event.end_date = Time.get_datetime_dict_from_unix_time((event_start + during_day * (i + 1)) * 86400 - 1)

func get_time_left(event_in):
    return Time.get_unix_time_from_datetime_dict(events[event_in].end_date) - Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
func get_time_to_day_reset():
    var now = Time.get_datetime_dict_from_system()
    var missing_hours = 23 - now.hour
    var missing_minutes = 59 - now.minute
    var missing_seconds = 59 - now.second
    var time_to_next_day = 0
    if missing_hours > 0:
        time_to_next_day += missing_hours * 60 * 60
    if missing_minutes > 0:
        time_to_next_day += missing_minutes * 60
    if missing_seconds > 0:
        time_to_next_day += missing_seconds

    return time_to_next_day



func check_events_active():
    var dt = Time.get_date_dict_from_system()
    events_active = []








    if "highest_sector_total" in PlayerInfo.misc_stats:
        if PlayerInfo.misc_stats["highest_sector_total"] >= 7:
            for e in events:
                var start_date = Time.get_unix_time_from_datetime_dict(events[e].start_date)
                var end_date = Time.get_unix_time_from_datetime_dict(events[e].end_date)
                var cur_date = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
                if cur_date >= start_date and cur_date <= end_date:
                    events_active.push_back(e)

func start_stop_events():
    check_events_active()


    for e in events:
        if not e in events_active:
            for r in events[e].resources:
                PlayerInfo.resources[r] = 0
                PlayerInfo.resource_totals_gained[r] = 0
            for u in events[e].upgrade_groups:
                var ups = get_tree().get_nodes_in_group("upgrade_group_" + u)
                for upg in ups:
                    if "amount_have" in upg and upg.amount_have > 0:
                        upg.amount_have = 0
                        if "amount_purchased" in upg:
                            upg.amount_purchased = 0
                        upg.process_upgrade()
                        if upg.has_method("update_progress"):
                            upg.update_progress()

                    var temp_boost_parent = upg.get_parent().get_parent()
                    if "active_duration_left" in temp_boost_parent:
                        temp_boost_parent.active_duration_left = 0
            for p in events[e].purchaseables:

                var pur
                if not p in purchaseables_reference:
                    purchaseables_reference[p] = PlayerInfo.purchases_area.find_child(p, true, false)
                pur = purchaseables_reference[p]
                if is_instance_valid(pur):
                    pur.hide()



            if is_instance_valid(events[e].panel):
                events[e].panel.check_and_enable()


                if Themes.skins[events[e].ship_design].owned:
                    if not e in skin_acquired_previous_event:
                        skin_acquired_previous_event.push_back(e)
    if is_instance_valid(PlayerInfo.purchases_area):
        PlayerInfo.purchases_area.setup_event_purchases()
    if len(events_active) == 0:
        if !EventHelper.top_level_event_button.disabled:
            EventHelper.top_level_event_button.reset_layer_2()
        PlayerInfo.set_panel_flashing("btnEvents", "Green", false)
    for e in events_active:
        if is_instance_valid(events[e].panel):
            events[e].panel.check_and_enable()

func do_offline_time(secs):
    for e in events_active:
        events[e].panel.do_offline_time(secs)

func get_event_active_range(event_in):
    var sd = events[event_in].start_date.duplicate()
    var ed = events[event_in].end_date.duplicate()
    ed.hour = "0"
    ed.minute = "0"
    var start = Time.get_datetime_string_from_datetime_dict(sd, true)
    var end = Time.get_datetime_string_from_datetime_dict(ed, true)
    return start.replace("00:00:00", "").replace(" ", "") + " " + tr("to") + " " + end.replace("00:00:00", "").replace(" ", "")


func check_waveclear_drop():
    check_events_active()
    for e in events_active:
        match e:
            "spacemas":
                var rng = RandomNumberGenerator.new()
                rng.randomize()
                var amount = rng.randi_range(1, 3)
                amount = events[e].panel.check_gain_coalexium(amount)
                if amount > 0:
                    PlayerInfo.gain_resource("Coalexium", amount, false)


func check_dialogue():
    PlayerInfo.set_panel_flashing("btnEvents", "Green", false)
    for e in events_active:
        Dialogue.check_play_dialogue("%s%s_first_click" % [e, EventHelper.events[e].version])
        break


func jump_to_ship_design():
    var button = get_tree().get_root().find_child("btnSkin", true, false)
    button.button_pressed = true
    ButtonHelper.emit_pressed_signal(button)
    await get_tree().create_timer(0.02).timeout
    button = get_tree().get_root().find_child("btnPrestige", true, false)
    button.button_pressed = true
    ButtonHelper.emit_pressed_signal(button)


func jump_to_event_purchase():
    var button = get_tree().get_root().find_child("btnEventsPurchases", true, false)
    button.button_pressed = true
    ButtonHelper.emit_pressed_signal(button)
    await get_tree().create_timer(0.02).timeout
    button = get_tree().get_root().find_child("btnAIPurchase", true, false)
    button.button_pressed = true
    ButtonHelper.emit_pressed_signal(button)
    await get_tree().create_timer(0.02).timeout
    button = get_tree().get_root().find_child("btnAI", true, false)
    button.button_pressed = true
    ButtonHelper.emit_pressed_signal(button)



func get_events_active_without_level_requirement() -> Array:
    var events_can_activate: Array = []
    var dt = Time.get_date_dict_from_system()
    for e in events:
        var start_date = Time.get_unix_time_from_datetime_dict(events[e].start_date)
        var end_date = Time.get_unix_time_from_datetime_dict(events[e].end_date)
        var cur_date = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
        if cur_date >= start_date and cur_date <= end_date:
            events_can_activate.push_back(e)
    return events_can_activate

func get_save_data():
    var events_save = {}
    var save_data = {"save_name": get_name(), 
                    "skin_acquired_previous_event": skin_acquired_previous_event, 
                    }

    return save_data

func load_from_save(_load_dict):
    pass

func fix_skins_for_070100_update():
    for e in events:
        if Themes.skins[events[e].ship_design].owned:
            if not e in skin_acquired_previous_event:
                skin_acquired_previous_event.push_back(e)
