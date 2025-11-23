extends Node

var loading = false

var default_save_file = "user://savegame.save"
var file_to_load = default_save_file
var encrypt = true
var confirm_old_dialog
var loading_old = false
var file_pending = ""
var pause_auto_save = false
var loading_scene = preload("res://LoadingScreen.tscn")
var loading_instance = null
var saved_timestamp = -1
var hold_calc = false
var saving = false
var auto_save_display

var _path_to_load: String = ""
var load_array: Array



signal save_completed_successfully
signal save_completed_with_error(error)


func _init() -> void :
    file_to_load = default_save_file
    var debug_save = DebugUtils.get_dev_save_path(true)
    if not debug_save.is_empty():
        print_rich("[color=yellow][b]WARNING: DEBUG SAVE SET.[/b][/color]")
        file_to_load = debug_save


func _ready():
    get_tree().set_auto_accept_quit(false)
    set_process(false)
    get_window().files_dropped.connect(_on_files_dropped)
    Signals.quit_requested.connect(_handle_quit_request)






func reset_and_load(path = default_save_file, encrypt_in = true):
    file_to_load = path
    encrypt = encrypt_in
    reload_game()


func check_if_new():
    var not_new_count = 1
    var count = 0
    var dir: = DirAccess.open("user://")
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if ".save" in file_name or file_name == "PrestigeSaves":
                count += 1
                if count >= not_new_count:
                    return false
            file_name = dir.get_next()
    return true

func check_make_extra_saves_folder():
    var dir: = DirAccess.open("user://")
    dir.make_dir("PrestigeSaves")
    dir.make_dir("SectorSaves")


func auto_save(also_cloud_save = false, quit_after_save: bool = false) -> Error:

    var dir: = DirAccess.open("user://")
    if dir.file_exists(default_save_file):
        dir.rename(default_save_file, default_save_file.replace(".save", "bk.save"))
    var save_result: = await save_game(default_save_file, true, also_cloud_save, quit_after_save)
    return save_result


func get_default_save_name() -> String:
    var time = Time.get_datetime_string_from_system().replace("/", "").replace(":", "").replace("-", "_")
    var prefix = "beta" if SaveLoad.default_save_file == "user://beta.save" else ""

    var reinforce = ""
    if "reinforces_total" in PlayerInfo.misc_stats and PlayerInfo.misc_stats["reinforces_total"] > 0:
        reinforce = "_R%03d" % [PlayerInfo.misc_stats["reinforces_total"]]

    var sector = "_S%03d" % [PlayerInfo.battle_area["Normal"].sector_number]

    return "%s%s%s%s_manual.save" % [prefix, time, reinforce, sector]


func generate_save_string():
    var save_array = PackedStringArray()

    save_array.append(JSON.stringify({"version": PlayerInfo.version}))
    save_array.append(JSON.stringify({"compatibility_version": PlayerInfo.compatibility_version}))
    save_array.append(JSON.stringify(Themes.get_save_data()))
    save_array.append(JSON.stringify(PlayerInfo.get_save_data()))
    save_array.append(JSON.stringify(Dialogue.get_save_data()))
    save_array.append(JSON.stringify(Crew.get_save_data()))
    save_array.append(JSON.stringify(Splice.get_save_data()))
    save_array.append(JSON.stringify(ReactorController.get_save_data()))
    save_array.append(JSON.stringify(EventHelper.get_save_data()))

    var save_nodes = get_tree().get_nodes_in_group("save_and_load")
    for i in save_nodes:
        var node_data = i.call("save");
        if len(node_data) != 0:
            save_array.append(JSON.stringify(node_data))

    save_array.append(JSON.stringify(Recipes.get_save_data()))
    save_array.append(JSON.stringify(Modules.get_save_data()))
    save_array.append(JSON.stringify(Warps.get_save_data()))
    save_array.append(JSON.stringify(Challenges.get_save_data()))
    save_array.append(JSON.stringify({"timestamp": Time.get_unix_time_from_system()}))

    var save_string = "\n".join(save_array)

    return save_string


func save_game(path = default_save_file, encrypt_in = true, also_cloud_save = false, quit_after_save = false) -> Error:
    saving = true
    var save_game_file: FileAccess
    check_make_extra_saves_folder()
    encrypt = encrypt_in

    if encrypt:
        save_game_file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, "usig23")
    else:
        save_game_file = FileAccess.open(path, FileAccess.WRITE)
        if not save_game_file:
            await get_tree().create_timer(0.25).timeout
            save_game_file = FileAccess.open(path, FileAccess.WRITE)

    if not save_game_file:
        var error = FileAccess.get_open_error()
        push_error("SaveLoad:save_game - Failed to open file for save, error = %s. Encrypt? %s" % [error, encrypt_in])
        saving = false
        return error

    var save_string = generate_save_string()
    save_string = export_save(save_string)
    save_game_file.store_string(save_string)
    save_game_file.close()
    saving = false

    if also_cloud_save:
        cloud_save(quit_after_save, save_string)
    else:
        if quit_after_save:
            Engine.time_scale = 1
            await get_tree().create_timer(0.05).timeout
            Signals.quit_requested.emit()

    return OK





func do_manual_mobile_save(path = default_save_file, encrypt_in = true) -> void :
    saving = true
    await get_tree().create_timer(0.001).timeout
    var save_game_file: FileAccess
    check_make_extra_saves_folder()
    encrypt = encrypt_in

    if encrypt:
        save_game_file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, "usig23")
        if not save_game_file:
            await get_tree().create_timer(0.25).timeout
            save_game_file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, "usig23")
            if not save_game_file:
                saving = false
                var error: = FileAccess.get_open_error()
                emit_signal("save_completed_with_error", error)
                return
    else:
        save_game_file = FileAccess.open(path, FileAccess.WRITE)
        if not save_game_file:
            await get_tree().create_timer(0.25).timeout
            save_game_file = FileAccess.open(path, FileAccess.WRITE)
            if not save_game_file:
                saving = false
                var error: = FileAccess.get_open_error()
                emit_signal("save_completed_with_error", error)
                return

    save_game_file.store_string(export_save(generate_save_string()))
    save_game_file.close()
    saving = false
    emit_signal("save_completed_successfully")


func cloud_save(closing: bool = false, save_string = null):
    if Config.cloud.get_value("Cloud", "username") != "" and default_save_file != "user://beta.save":
        var req = get_tree().get_root().find_child("HTTPRequestSave", true, false)
        if is_instance_valid(req):
            if save_string == null:
                save_string = export_save(generate_save_string())
            req.do_cloud_save(save_string, closing)

func cloud_save_for_data():
    var req = get_tree().get_root().find_child("HTTPRequestSave", true, false)
    if is_instance_valid(req):
        req.do_cloud_save_data(export_save(generate_save_string()))

func export_save(save_string = null):
    var last_time = Time.get_ticks_usec()


    last_time = Time.get_ticks_usec()


    var bytes = var_to_bytes(save_string)
    bytes = bytes.compress(3)
    save_string = Marshalls.raw_to_base64(bytes)

    last_time = Time.get_ticks_usec()
    return save_string

func check_save_version_newer(version: String) -> bool:

    return !check_version_greater_equal(PlayerInfo.version, version)

func find_save_import_version_info(save_in: String) -> Dictionary:

    save_in = decompress_save(save_in).replace("\r\n", "\n")
    var save_split = save_in.split("\n")
    var test_json_conv_version = JSON.new()
    test_json_conv_version.parse(save_split[0])
    var version = test_json_conv_version.get_data()
    var test_json_conv = JSON.new()
    test_json_conv.parse(save_split[1])
    var compatibility_version = test_json_conv.get_data()
    if "compatibility_version" in compatibility_version:
        compatibility_version = compatibility_version["compatibility_version"]
    else:
        compatibility_version = 0
    return {"version": version["version"], "compatibility_version": compatibility_version}


func decompress_save(save_in) -> String:

    var try_decompress = Marshalls.base64_to_raw(save_in)
    try_decompress = try_decompress.decompress_dynamic(-1, 3)
    if !try_decompress.is_empty():

        save_in = bytes_to_var(try_decompress)
    else:
        var save_converted = Marshalls.base64_to_utf8(save_in)
        if len(save_converted) > 0:
            save_in = save_converted

    return save_in

func import_save(save_in):
    if save_in != "":
        save_in = decompress_save(save_in)

        var save_game_file = FileAccess.open_encrypted_with_pass("user://import.save", FileAccess.WRITE, "usig23")
        save_game_file.store_string(save_in)
        save_game_file.close()

        reset_and_load("user://import.save")

func check_save_exists(path = default_save_file):
    if not FileAccess.file_exists(path):
        if FileAccess.file_exists(path.replace(".save", "bk.save")):
            file_to_load = path.replace(".save", "bk.save")
            return true
        return false
    else:
        return true

func check_save_not_corrupt(path = default_save_file):
    if FileAccess.file_exists(path):
        var save_game_file: = _load_save_as_g3_or_g4(path, encrypt)
        var test_json_conv = JSON.new()
        test_json_conv.parse(save_game_file.get_line())
        var version = test_json_conv.get_data()
        if version == null:

            var save_in = save_game_file.get_as_text()
            version = decompress_save(save_in)
        save_game_file.close()
        if "version" in version:
            return true
        else:
            return false

    return true

func confirm_load_old():
    loading_old = true
    file_to_load = file_pending
    reload_game()

func abort_load_old():

    if file_pending == default_save_file:
        file_pending = ""
        DirAccess.rename_absolute(default_save_file, "user://savegamePREVERSION01.save")
        call_deferred("_deferred_goto_scene", "res://StartScene.tscn")
    file_pending = ""

func decrypt_file(path):
    if not FileAccess.file_exists(path):
        return false


    var load_file: = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, "usig23")
    if not load_file:
        load_file = FileAccess.open(path, FileAccess.READ)
    var save_array: PackedStringArray = decompress_save(load_file.get_as_text(true)).split("\n")

    var lines = Array()
    for save_line in save_array:
        var test_json_conv = JSON.new()
        test_json_conv.parse(save_line)
        var current_line = test_json_conv.get_data()
        lines.push_back(current_line)


    load_file.close()


    var save_game_file: = FileAccess.open(path, FileAccess.WRITE)


    for l in lines:
        save_game_file.store_line(JSON.stringify(l))

    save_game_file.close()



func load_game():

    if len(load_array) <= 0:
        loading = false
        return false
    saved_timestamp = -1
    var load_version = ""
    var last_time = Time.get_ticks_usec()
    var start_time = last_time

    loading = true
    hold_calc = true
    print("Loading")


    PlayerInfo.combat_researches_running = 0
    Challenges.reset()

    PlayerInfo.reset()
    Fleet.reset()
    Recipes.reset_for_load()
    Fleet.reset_for_load()



    UpgradeHelper.wait_to_calc = true
    PlayerInfo.battle_area["Normal"].reset()
    var warp_cores = []
    var load_times = {}
    load_times["to_start"] = Time.get_ticks_usec() - last_time
    var save_nodes = {}
    last_time = Time.get_ticks_usec()
    var how_many_find_childs: int = 0

    for n in get_tree().get_nodes_in_group("save_and_load"):
        save_nodes[n.get_name()] = n
        n.remove_from_group("one_time_setup")

    for current_line in load_array:


        if current_line and "save_name" in current_line and "WarpCore" in current_line.save_name and "progress" in current_line:
            warp_cores.push_front(current_line)
        elif current_line and "save_name" in current_line:
            var new_object = null



            if current_line.save_name in save_nodes and save_nodes[current_line.save_name].get_name() == current_line.save_name:
                new_object = save_nodes[current_line.save_name]
            else:
                new_object = get_tree().get_root().find_child(current_line.save_name, true, false)
                how_many_find_childs += 1
                if new_object == null:
                    print("not found at all %s" % current_line.save_name)
            if new_object != null:
                var start_t = Time.get_ticks_usec()
                for i in current_line.keys():
                    if i == "save_name" or i == "parent" or i == "pos_x" or i == "pos_y":
                        continue
                    new_object.set(i, current_line[i])

                new_object.load_from_save(current_line)
                var time_load = Time.get_ticks_usec() - start_t
                if time_load >= 1000:
                    print("LONG LOAD %s %s" % [current_line["save_name"], time_load])
        elif current_line and "timestamp" in current_line:
            saved_timestamp = current_line["timestamp"]
        elif current_line and "version" in current_line:
            load_version = current_line["version"]


    print("had to lookup %s nodes in tree" % how_many_find_childs)
    load_times["load_nodes"] = Time.get_ticks_usec() - last_time
    if load_version != PlayerInfo.version:
        PlayerInfo.queue_version = true
        do_version_stuff(load_version, load_array)

    last_time = Time.get_ticks_usec()
    Recipes.after_load_setup()
    PlayerInfo.after_load_setup()
    PlayerInfo.research_area.check_and_unlock()
    PlayerInfo.research_area.update_hide_completed()

    load_times["research_stuff"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()

    PlayerInfo.forward_base_area.check_and_unlock()

    load_times["forward_base_stuff"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()




    PlayerInfo.reinforce_area.after_load_setup()
    UpgradeHelper.wait_to_process = true
    for u in PlayerInfo.upgrades:

        if is_instance_valid(PlayerInfo.upgrades[u]):
            if PlayerInfo.upgrades[u].amount_have != 0:
                PlayerInfo.upgrades[u].process_upgrade()
    UpgradeHelper.process_pending()
    load_times["process_upgrades"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()
    hold_calc = false

    PlayerInfo.reactor_area.lbl_power_generation.calculate_power_gain()


    UpgradeHelper.wait_to_calc = false


    UpgradeHelper.calc_all_upgrades()


    load_times["calc_all_upgrades"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()



    Crew.after_load_setup()
    Splice.after_load_setup()
    load_times["crew_stuff"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()

    Warps.after_load_setup()
    Warps.normal_warp_area.warp_cores.update_cores_available()

    for wc in warp_cores:
        var new_object = get_tree().get_root().find_child(wc.save_name, true, false)
        if new_object != null:
            for i in wc.keys():
                if i == "save_name" or i == "parent" or i == "pos_x" or i == "pos_y":
                    continue
                new_object.set(i, wc[i])
            new_object.load_from_save(wc)
    Warps.normal_warp_area.warp_cores.sort_warp_cores()
    Warps.tether_warp_area.set_tether_target(Warps.tether_target)
    load_times["warp_stuff"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()

    PlayerInfo.set_misc_stat("shards_maxed", len(PlayerInfo.void_device_area.completed_shards))
    Challenges.challenge_area.check_and_unlock()
    Challenges.setup_challenge_areas()
    Challenges.challenge_area.set_challenges_completed()


    if not "DataUnlock14" in PlayerInfo.data_unlock_area.unlocks_gotten:
        PlayerInfo.cores_info["MissileLauncher"].locked = true
    load_times["load_finish_0"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()
    UpgradeHelper.calc_all_upgrades()
    load_times["load_finish_1"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()

    PlayerInfo.cloud_account_area.check_cloud_save()
    if saved_timestamp != -1 and saved_timestamp < Time.get_unix_time_from_system() - 30:
        PlayerInfo.do_offline_resources(Time.get_unix_time_from_system() - saved_timestamp)
    elif PlayerInfo.queue_version:
        get_tree().get_root().find_child("Main", true, false)._on_btnVersion_pressed()
        PlayerInfo.queue_version = false
        for n in get_tree().get_nodes_in_group("offline_adjust"):
            n.offline_adjust(false)
    else:
        for n in get_tree().get_nodes_in_group("offline_adjust"):
            n.offline_adjust(false)

    if PlatformHelper.has_steam_support():
        SteamAPI.update_all_achievements()
    load_times["load_finish_2"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()



    file_pending = ""
    loading = false

    load_times["load_finish_3"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()
    Crew.update_crew_amount()
    load_times["load_finish_35"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()
    loading_old = false
    for n in get_tree().get_nodes_in_group("after_load_setup"):
        var t = Time.get_ticks_usec()
        n.after_load_setup()
        t = Time.get_ticks_usec() - t
        if t >= 1000:
            print("long after load %s %s" % [n.get_name(), t])



    loading = true
    Crew.update_all_crew()
    loading = false
    PlayerInfo.calc_upgrade("crew_skill")
    for n in get_tree().get_nodes_in_group("crew_skill_upgrade_listener"):
        n.process_upgrade()
    Warps.normal_warp_area.jump_locations.update_reward_labels()
    load_times["load_finish_4"] = Time.get_ticks_usec() - last_time
    last_time = Time.get_ticks_usec()
    for l in load_times:
        if load_times[l] > 5000:
            print("LONG LOAD " + l + ": " + str(load_times[l]))

    print("total load: " + str(Time.get_ticks_usec() - start_time))

    print("Done Loading")
    load_array.clear()

    return true


func reload_game():


    if !read_file_and_prep_load() and ".txt" in file_to_load:
        return
    print("%s reload game start" % Time.get_ticks_msec())

    if not check_save_not_corrupt(file_to_load) and !loading_old:
        if confirm_old_dialog != null:
            file_pending = file_to_load
            confirm_old_dialog.popup_centered()
            return
    PlayerInfo.reset()
    PlayerInfo.set_stats_to_base()


    Fleet.reset()
    Warps.reset_for_load()
    print("%s reload game end" % Time.get_ticks_msec())

    call_deferred("_deferred_goto_scene", "res://Game.tscn")




func read_file_and_prep_load(path = file_to_load) -> bool:
    var start_time = Time.get_ticks_usec()
    if not FileAccess.file_exists(path):
        loading = false
        return false

    var save_game_file: FileAccess
    if ".txt" in path:
        save_game_file = FileAccess.open(path, FileAccess.READ)
        import_save(save_game_file.get_as_text())
        return false

    save_game_file = _load_save_as_g3_or_g4(path, encrypt)
    var load_text = "[" + decompress_save(save_game_file.get_as_text(true)).replace("\n", ",") + "]"
    var parse_whole_thing = JSON.new()
    var err = parse_whole_thing.parse(load_text)
    load_array = parse_whole_thing.get_data()

    var current_line = load_array[2]

    Themes.reset()
    Themes.load_from_save_before_others(current_line)
    save_game_file.close()
    return true




func copy_save_to_clipboard(file_path) -> Error:
    if not FileAccess.file_exists(file_path):
        return Error.ERR_FILE_NOT_FOUND

    var save_game_file: = _load_save_as_g3_or_g4(file_path, encrypt)
    if not save_game_file:
        return Error.ERR_FILE_CANT_OPEN

    var save_game_text = save_game_file.get_as_text(true)
    DisplayServer.clipboard_set(save_game_text)

    return Error.OK


func load_intro():
    call_deferred("_deferred_goto_scene", "res://IntroSceneNoImage.tscn")

func load_save_recovery_check():
    call_deferred("_deferred_goto_scene", "res://SaveRecoveryCheck.tscn")

func load_compatible_check():
    call_deferred("_deferred_goto_scene", "res://OldSaveConfirmStandalone.tscn")

func hard_reset():
    DirAccess.remove_absolute(default_save_file)
    DirAccess.remove_absolute(default_save_file.replace(".save", "bk.save"))
    get_tree().quit()

func _deferred_goto_scene(path):


    Engine.time_scale = 1
    print("%s deferred goto scene" % Time.get_ticks_msec())

    print("scene load start")
    if path != "res://IntroScene.tscn":
        Crew.reset_for_load()
        Splice.reset_for_load()
        ReactorController.reset_for_load()
        loading = true
    var root = get_tree().get_root()
    var current_scene = root.get_child(root.get_child_count() - 1)
    current_scene.free()
    loading_instance = loading_scene.instantiate()
    print("%s deferred adding child" % Time.get_ticks_msec())
    root.call_deferred("add_child", loading_instance)

    _path_to_load = path
    var load_result: = ResourceLoader.load_threaded_request(path)
    if load_result != OK:

        return
    print("%s deferred await" % Time.get_ticks_msec())
    await get_tree().create_timer(0.1).timeout
    set_process(true)
    print("%s deferred end" % Time.get_ticks_msec())


func start_new_scene(s):
    print("%s start new scene" % Time.get_ticks_msec())
    loading_instance.queue_free()
    var current_scene = s.instantiate()
    Challenges.challenge_active = false

    var last_time = Time.get_ticks_usec()
    print("%s start pre add" % Time.get_ticks_msec())
    get_tree().get_root().add_child(current_scene)


    get_tree().set_current_scene(current_scene)
    print("%s done" % Time.get_ticks_msec())
    print("time taken %s" % (Time.get_ticks_usec() - last_time))
    print("scene loaded")

func _process(_delta):
    if _path_to_load.is_empty():

        set_process(false)
        return
    if loading_instance == null:
        return

    var progress = []
    var load_status: = ResourceLoader.load_threaded_get_status(_path_to_load, progress)

    match load_status:
        ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            _path_to_load = ""
            return
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:

            update_progress(progress[0] * 100.0)
        ResourceLoader.THREAD_LOAD_FAILED:
            _path_to_load = ""
            return
        ResourceLoader.THREAD_LOAD_LOADED:
            var resource = ResourceLoader.load_threaded_get(_path_to_load)
            _path_to_load = ""
            print("%s saveload process" % Time.get_ticks_msec())
            call_deferred("start_new_scene", resource)


func update_progress(progress_percent):
    if loading_instance == null:
        return
    if progress_percent >= 90:
        progress_percent = 100
        loading_instance.lbl_save_loading.show()
        loading_instance.lbl_loading.text = tr("Game Loaded")
    loading_instance.progress_bar.value = progress_percent


func _on_files_dropped(files: PackedStringArray):
    if ".save" in files[0]:
        if check_save_not_corrupt(files[0]):
            reset_and_load(files[0])


func do_version_stuff(p_old_version_in: String, save_array):
    var old_version_in = p_old_version_in.to_lower()
    if !check_version_greater_equal(old_version_in, "0.53.0"):
        Crew.check_mastery_points()
    if !check_version_greater_equal(old_version_in, "0.30.2"):
        Challenges.version_0302_fix()
    if !check_version_greater_equal(old_version_in, "0.50.1"):
        Crew.check_mastery_points()
    if !check_version_greater_equal(old_version_in, "0.50.6"):
        PlayerInfo.void_device_area.already_completed_shards_first_time_setup()
    if !check_version_greater_equal(old_version_in, "0.51.3"):
        Crew.turn_off_auto_reprints()
    if !check_version_greater_equal(old_version_in, "0.51.4"):
        if PurchaseHelper.has_purchase_support():
            PurchaseHelper.recover_purchases(true)
    if !check_version_greater_equal(old_version_in, "0.51.5.4"):
        PlayerInfo.fix_reinforce_count()
    if !check_version_greater_equal(old_version_in, "0.53.0"):
        check_grant_adaptium_compute_spec_upgrades()
    if !check_version_greater_equal(old_version_in, "0.60.0"):
        update_fleet_power_and_reinforces()
        get_tree().get_root().find_child("Data", true, false).set_next_unlock()
        var misc_stats_to_check = ["overdrive_tiers_this_reinforce", "specimen_research_levels_total", "compute_tiers"]
        for s in misc_stats_to_check:
            for n in get_tree().get_nodes_in_group(s + "_achievement_listener"):
                n.check_and_grant()
    if !check_version_greater_equal(old_version_in, "0.60.1.2"):
        remove_boss_battle_bcds_and_flag_active_galaxy()
    if !check_version_greater_equal(old_version_in, "0.60.2.5"):

        if PlayerInfo.upgrades["SpacemasPurchaseUpgrade"].amount_have == 0:
            var node = PurchaseHelper.find_purchase_node_by_steam_item_id(410)
            if node != null and node.purchased_amount == 1:
                PurchaseItemGranter.grant_item(node.purchase_item, false)
    if !check_version_greater_equal(old_version_in, "0.61.0.0"):

        get_tree().get_root().find_child("AIAutoAdvance", true, false).do_upgrade()
    if !check_version_greater_equal(old_version_in, "0.61.0.3"):
        get_tree().get_root().find_child("FleetUniqueNodes213", true, false).check_and_grant()
    if !check_version_greater_equal(old_version_in, "0.62.0.0"):
        Challenges.version_0620_fix()

        if !Fleet.galaxy_nodes["galaxy2"].locked:
            Themes.grant_skin("advanced")
    if !check_version_greater_equal(old_version_in, "0.62.0.2"):
        Challenges.version_06202_fix()
    if !check_version_greater_equal(old_version_in, "0.62.0.3"):
        Challenges.version_06203_fix()
    if !check_version_greater_equal(old_version_in, "0.62.0.8"):
        Config.version_06208_fix()
    if !check_version_greater_equal(old_version_in, "0.62.2.0"):
        Fleet.version_0622_fix()
    if !check_version_greater_equal(old_version_in, "0.63.0.0"):
        PlayerInfo.warp_upgrade_area.version_0630_fix()
    if !check_version_greater_equal(old_version_in, "0.63.4.0"):

        if PlayerInfo.upgrades["SpaceversaryPurchaseUpgrade"].amount_have == 0:
            var node = PurchaseHelper.find_purchase_node_by_steam_item_id(420)
            if node != null and node.purchased_amount == 1:
                PurchaseItemGranter.grant_item(node.purchase_item, false)

    if !check_version_greater_equal(old_version_in, "0.70.0.0"):
        _handle_migration_to_4_4(save_array)
        PlayerInfo.reinforce_area.v07_reinforce_upgardes_fix()
        recount_fleet_unique_node_completions()
        PlayerInfo.resource_display_area.version_07_fix()

    if !check_version_greater_equal(old_version_in, "0.70.1.0"):
        EventHelper.fix_skins_for_070100_update()

    if !check_version_greater_equal(old_version_in, "0.71.0.0"):
        Splice.v071clawback_flag = true

    if !check_version_greater_equal(old_version_in, "0.71.0.6"):
        fix_prestige_unlocks()

    if !check_version_greater_equal(old_version_in, "0.71.1.0"):
        if PlayerInfo.misc_stats["highest_sector_total"] >= 75:
            PlayerInfo.unlock_upgrade("AIFighterSpecPointLoadouts")

    if !check_version_greater_equal(old_version_in, "0.71.1.4"):
        recount_fleet_unique_node_completions()


func _handle_migration_to_4_4(_save_array) -> void :
    var highest_sector_reached = -1
    if "highest_sector" in PlayerInfo.misc_stats:
        highest_sector_reached = PlayerInfo.misc_stats["highest_sector"]


    if highest_sector_reached >= 76:
        PlayerInfo.synth_main_area._fixtures_locked = false


    if highest_sector_reached >= 2:
        Modules.get_module_area().unlock_modules()



func recount_fleet_unique_node_completions():
    var galaxy_id_list = ["galaxy1", "galaxy2", "galaxy3", "galaxy4", "galaxy5", "galaxy6", "galaxy7", "galaxy8"]
    var num_nodes_completed = 0
    for g in galaxy_id_list:
        var fes = Fleet.galaxy_nodes[g].galaxy_map.get_fleet_events()
        for fe in fes:
            if fe.finished_first_time:
                num_nodes_completed += 1

    PlayerInfo.set_misc_stat("fleet_unique_nodes_completed", num_nodes_completed)

func remove_boss_battle_bcds_and_flag_active_galaxy():

    var galaxy_id_list = ["galaxy1", "galaxy2", "galaxy3", "galaxy4"]
    for g in galaxy_id_list:

        Fleet.galaxy_nodes[g].last_completion_order = []
        Fleet.galaxy_nodes[g].completion_order = []
        var fes = Fleet.galaxy_nodes[g].galaxy_map.get_fleet_events()
        for fe in fes:
            if fe.type == Fleet.EventType.BATTLE and fe.command_ship_health_left > 0:

                fe.finished_battle_details = []
        if Fleet.galaxy_nodes[g].in_galaxy:
            Fleet.galaxy_nodes[g].do_special_history_conversion()

    if Fleet.galaxy_exploring != "":
        Fleet.galaxy_nodes[Fleet.galaxy_exploring].do_special_history_conversion()

func check_grant_adaptium_compute_spec_upgrades():
    if "highest_sector_this_reinforce" in PlayerInfo.misc_stats:
        if PlayerInfo.misc_stats["highest_sector_this_reinforce"] >= 82:
            PlayerInfo.handle_unlock("UnlockUpgrade", "FSHangarBayDamage")
            PlayerInfo.handle_unlock("UnlockUpgrade", "FSAdaptiumFocus")


func update_fleet_power_and_reinforces():

    if PlayerInfo.resources["FleetPower"] < 1:
        return
    elif PlayerInfo.resources["FleetPower"] >= 1085:
        PlayerInfo.highest_reinforce_sector = 95
        PlayerInfo.misc_stats["reinforces_total"] = 4
    elif PlayerInfo.resources["FleetPower"] >= 98:
        PlayerInfo.highest_reinforce_sector = 90
        PlayerInfo.misc_stats["reinforces_total"] = 3
    elif PlayerInfo.resources["FleetPower"] >= 9:
        PlayerInfo.highest_reinforce_sector = 85
        PlayerInfo.misc_stats["reinforces_total"] = 2
    elif PlayerInfo.resources["FleetPower"] >= 1:
        PlayerInfo.highest_reinforce_sector = 80
        PlayerInfo.misc_stats["reinforces_total"] = 1
    PlayerInfo.resources["FleetPower"] = 0
    if "fleet_power" in PlayerInfo.misc_stats:
        PlayerInfo.misc_stats.erase("fleet_power")
    if "fleet_power_total" in PlayerInfo.misc_stats:
        PlayerInfo.misc_stats.erase("fleet_power_total")
    if "fleet_power_this_reinforce" in PlayerInfo.misc_stats:
        PlayerInfo.misc_stats.erase("fleet_power_this_reinforce")


func check_version_greater_equal(v_in, target_in):
    var v = []
    var target = []
    for s in v_in.split("."):
        v.push_back(int(s))
    for s in target_in.split("."):
        target.push_back(int(s))

    for i in range(0, len(target)):
        if len(v) <= i:
            return false
        if v[i] < target[i]:
            return false
        elif v[i] > target[i]:
            return true

    return true

func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _handle_quit_request()
    elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
        if Config.config.get_value("Performance", "throttle_fps_background"):
            Engine.max_fps = 10
    elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
        Engine.max_fps = Config.config.get_value("Misc", "fps_cap")





func _load_save_as_g3_or_g4(original_path: String, p_encrypt: bool) -> FileAccess:
    var path_to_load = original_path
    var loaded_file: FileAccess
    if p_encrypt:

        if CryptGodot3.is_encrypted_godot3_file(original_path):
            var backup_path = original_path.replace(".save", ".OLDENGINEsave")
            DirAccess.rename_absolute(original_path, backup_path)

            var reencrypt_result = CryptGodot3.reencrypt_with_pass(backup_path, "usig23", original_path)
            if reencrypt_result != OK:
                push_error("SaveLoad: Failed to reencrypt file %s to G4 format, error = %s" % [original_path, reencrypt_result])
                if reencrypt_result == ERR_FILE_NOT_FOUND and PlatformHelper.is_mobile() and original_path.contains("res://"):
                    push_error("SaveLoad: Unable to reencrypt & save file to res:// folder on mobile. Reencrypt on PC and try again.")
                return null


        loaded_file = FileAccess.open_encrypted_with_pass(path_to_load, FileAccess.READ, "usig23")
        if not loaded_file:
            loaded_file = FileAccess.open(path_to_load, FileAccess.READ)
    else:
        loaded_file = FileAccess.open(path_to_load, FileAccess.READ)

    return loaded_file


func _handle_quit_request() -> void :
    Config.config.set_value("Display", "window_screen", get_window().get_current_screen())
    if !Config.config.get_value("Display", "borderless_fullscreen"):

        Config.config.set_value("Display", "window_width", get_window().size.x)
        Config.config.set_value("Display", "window_height", get_window().size.y)
        Config.config.set_value("Display", "window_maximized", (get_window().mode == Window.MODE_MAXIMIZED))
        Config.save()
    if saving:
        await get_tree().create_timer(1).timeout
    get_tree().quit()




func has_failed_to_load_too_many_times() -> bool:
    if DebugUtils.get_prevent_save_recovery():
        return false
    return Config.config.get_value("Misc", "game_start_attempts") > 3






func increment_game_start_attempts() -> void :
    var next_game_start_attempts = Config.config.get_value("Misc", "game_start_attempts") + 1
    Config.config.set_value("Misc", "game_start_attempts", next_game_start_attempts)
    Config.save()




func reset_game_start_attempts() -> void :
    Config.config.set_value("Misc", "game_start_attempts", 0)
    Config.save()


func fix_prestige_unlocks() -> void :
    PlayerInfo.data_unlock_area.reset_data_unlocks_to_sector()
