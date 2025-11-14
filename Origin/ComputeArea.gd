extends Panel

var available
var compute_label
var speed = 1
var allocation_amount = 1
var salvage_drain = 0
var salvage_drain_boost = 1
var auto_optimizing = false
var auto_salvaging = false
var auto_compute_powering = false
var max_reached = false

const MAX_GOAL: float = pow(10, 22)

@onready var salvage_speed_boost_active = $"%lblSalvageSpeedBoostActive"
@onready var chk_auto_optimize = $"%chkAutoOptimize"
@onready var chk_auto_compute_power = $"%chkAutoPowerPurchase"
@onready var chk_auto_salvage = $"%chkAutoSalvage"
@onready var btn_optimize = $"%btnOptimize"
@onready var btn_compute_power = $"%ComputeUpgrade"
@onready var salvage_challenge_holder = $"%VChallengeHolder"
@onready var btn_compute_maxed_bonus = $"%ComputeMaxedBonus"
@onready var basic_compute = $"%BasicCompute"
@onready var advanced_compute = $"%AdvancedCompute"
@onready var compute_fighters = $"%ComputeFighters"
@onready var compute_fighters_fighters = $"%Fighters"
@onready var lbl_capped_details = $"%lblCappedDetails"
@onready var compute_panels = $"%ComputePanelButtons"
@onready var compute_salvage_per_second = $"%ComputeSalvagePerSecond"
@onready var lbl_cap_info = $"%lblCapInfo"
@onready var lbl_damage_boost = $"%lblDamageBoost"
@onready var lbl_shield_boost = $"%lblShieldBoost"
@onready var boost_holder = $"%HBoostHolder"
@onready var cpb_holder: Control = $"%CPBHolder"
@onready var v_compute_speed: VBoxContainer = $"%VComputeSpeed"
@onready var v_salvage_speed_boost_area = $"%VSalvageSpeedBoostArea"
@onready var v_compute_power_upgrade_area = $"%VComputePowerUpgradeArea"
@onready var lbl_compute_salvage_speed_boost_maxed = $"%lblComputeSalvageSpeedBoostMaxed"
@onready var lbl_compute_vm_purchase_maxed = $"%lblComputeVMPurchaseMaxed"
@onready var v_compute_salvage_max = $"%VComputeSalvageMax"
@onready var v_compute_vm_max = $"%VComputeVMMax"

const FIGHTER_OPTIMIZE_ORDER = ["CFEfficiency", "CFDamage", "CFDurabtility", "CFWeaponRange", "CFManeuverability", "CFSpeed"]


func _ready():
    max_reached = false
    PlayerInfo.compute_area = self
    available = PlayerInfo.stats.compute_power
    btn_optimize.visible = false
    chk_auto_optimize.visible = false
    chk_auto_salvage.visible = false
    chk_auto_compute_power.visible = false


    v_compute_speed.size_flags_vertical = SIZE_SHRINK_END if PlatformHelper.is_mobile() else SIZE_SHRINK_CENTER
    add_to_group("compute_vm_salvage_max_upgrade_listener")
    add_to_group("after_load_setup")


func calc_available_compute():
    var compute_used = 0
    for pm in get_tree().get_nodes_in_group("compute_management"):
        compute_used += pm.compute_allocated

    for pm in get_tree().get_nodes_in_group("compute_consumption"):
        compute_used += pm.compute_allocated

    available = max(0, PlayerInfo.stats.compute_power - compute_used)

    if compute_label:
        compute_label.text = tr("Compute Power") + ": " + NumberUtils.format_number(floor(available), 2, 2) + "/" + NumberUtils.format_number(floor(PlayerInfo.stats.compute_power), 2, 2)
        var ttv = "LabelImportant" if floor(available) > 0 else ""
        Themes.set_theme_type_variation(compute_label, ttv)

func compute_sort(a, b):
    if a.stats.cost[0].levels_to_increase > 0:

        var a_need = (a.progress_needed * ceil((a.stats.cost[0].levels_to_increase - a.amount_have) / PlayerInfo.stats.compute_levels) - a.progress)
        var b_need = (b.progress_needed * ceil((b.stats.cost[0].levels_to_increase - b.amount_have) / PlayerInfo.stats.compute_levels) - b.progress)

        if is_equal_approx(a_need, b_need):
            return FIGHTER_OPTIMIZE_ORDER.find(a.UpgradeID) < FIGHTER_OPTIMIZE_ORDER.find(b.UpgradeID)
        else:
            return a_need < b_need
    else:
        return a.progress_needed < b.progress_needed

func compute_optimize_section(upgrades, pairing = true):
    var first_of_pair = true
    var maxing = true
    upgrades.sort_custom(compute_sort)
    for pm in upgrades:
        if !pm.unlocked:
            continue

        if first_of_pair and pairing:

            if pm.calc_compute_for_max() * 2 <= available:
                maxing = true
            else:
                maxing = false


            if maxing:
                pm.add_compute(pm.calc_compute_for_max())
            else:
                pm.add_compute(floor(available / 2))

            first_of_pair = false
        else:

            pm.add_compute(pm.calc_compute_for_max())
            first_of_pair = true


func split_compute_in_set(this_set):
    var maxing = false
    var amount_not_max = 0
    if len(this_set) < 1:
        return

    if this_set[0].calc_compute_for_max() * len(this_set) <= available:
        maxing = true
    else:
        amount_not_max = floor(available / len(this_set))
    for pm in this_set:
        if maxing:
            pm.add_compute(pm.calc_compute_for_max())
        else:
            pm.add_compute(amount_not_max)

func compute_optimize_fighter(upgrades):
    var maxing = true
    upgrades.sort_custom(compute_sort)

    var this_set = Array()
    var set_cost
    for pm in upgrades:
        if !pm.unlocked:
            continue

        if len(this_set) > 0:

            if pm.progress_needed / this_set[0].progress_needed < 1.1:
                this_set.push_front(pm)
            else:
                split_compute_in_set(this_set)
                this_set = Array()
        else:
            this_set.push_front(pm)


    split_compute_in_set(this_set)


func set_capital():
    if db.main_ship_data[PlayerInfo.ship].capital and !Challenges.check("compute_to_salvage"):
        set_max_reached()
        if btn_compute_maxed_bonus.amount_have != 1:
            grant_max_reached_upgrade()
        compute_fighters.show()
        compute_fighters_fighters.show()
        lbl_capped_details.hide()
    else:
        compute_fighters.hide()
        if max_reached:
            lbl_capped_details.show()
        else:
            cpb_holder.show()
            for c in basic_compute.get_children():
                c.check_and_disable_if_max()
            for c in advanced_compute.get_children():
                c.check_and_disable_if_max()

func compute_optimize():

    compute_reset()
    var first_of_pair = true
    var maxing = true
    var cus = basic_compute.get_children()
    if !max_reached or Challenges.check("compute_to_salvage"):
        compute_optimize_section(cus)
        if compute_panels.locked == false:
            cus = advanced_compute.get_children()
            compute_optimize_section(cus, false)

    if compute_fighters.visible:
        cus = Array()
        for c in compute_fighters_fighters.get_children():
            if "UpgradeID" in c:
                cus.push_back(c)
        compute_optimize_section(cus, false)






func compute_reset():
    for pm in get_tree().get_nodes_in_group("compute_management"):
        if pm.allow_removal:
            pm.set_compute(0)
    calc_available_compute()

func drain_salvage():
    if PlayerInfo.stats["compute_vm_salvage_max"] == 1:
        salvage_drain_boost = 1
        return
    if salvage_drain == 0:
        salvage_drain_boost = 1
        salvage_speed_boost_active.text = "Inactive"
        Themes.set_theme_type_variation(salvage_speed_boost_active, "LabelNegativeBright")
    elif PlayerInfo.resources["Salvage"] >= salvage_drain:
        PlayerInfo.resources["Salvage"] -= salvage_drain
        salvage_drain_boost = calc_salvage_drain_boost()
        salvage_speed_boost_active.text = "Active"
        Themes.set_theme_type_variation(salvage_speed_boost_active, "LabelPositiveBright")
    else:
        salvage_drain_boost = 1
        salvage_speed_boost_active.text = "Inactive"
        Themes.set_theme_type_variation(salvage_speed_boost_active, "LabelNegativeBright")

func calc_salvage_drain_boost():
    if PlayerInfo.stats["compute_vm_salvage_max"] == 1:
        return 1
    if salvage_drain >= 1:
        return log(salvage_drain) / log(10) + 1
    else:
        return 1

func save():
    var save_data = {"save_name": get_name(), 
                    "auto_salvaging": auto_salvaging, 
                    "auto_optimizing": auto_optimizing, 
                    "auto_compute_powering": auto_compute_powering, 
                    "max_reached": max_reached}

    return save_data


func load_from_save(_load_dict):

    chk_auto_optimize.button_pressed = auto_optimizing
    chk_auto_salvage.button_pressed = auto_salvaging
    chk_auto_compute_power.button_pressed = auto_compute_powering
    if not "max_reached" in _load_dict:
        max_reached = false
    calc_available_compute()
    if max_reached:
        set_max_reached()
    else:
        btn_compute_maxed_bonus.reset()
    set_capital()

func after_load_setup():
    check_salvage_vm_upgrades_maxed()

    if max_reached:
        lbl_damage_boost.ok_to_show = false
        lbl_shield_boost.ok_to_show = false
    else:
        lbl_damage_boost.ok_to_show = true
        lbl_shield_boost.ok_to_show = true

func calc_offline_generation_compute_challenge(total_sec):
    var tier_count = 0
    var odd = false
    var salvage_amount = 0
    for c in basic_compute.get_children():
        var salvage_generated = pow(Challenges.check("compute_to_salvage"), tier_count) * PlayerInfo.stats["compute_levels"]
        var ticks = c.calc_recieve_offline_gains_ticks(total_sec)
        salvage_amount += salvage_generated * ticks
        if odd:
            tier_count = tier_count + 1
            odd = false
        else:
            odd = true
    for c in advanced_compute.get_children():
        var salvage_generated = pow(Challenges.check("compute_to_salvage"), tier_count) * PlayerInfo.stats["compute_levels"]
        var ticks = c.calc_recieve_offline_gains_ticks(total_sec)
        salvage_amount += salvage_generated * ticks
        tier_count = tier_count + 2

    return salvage_amount

func calc_offline_generation(s_sec, total_sec):

    var s_sec_og = s_sec
    s_sec -= salvage_drain
    salvage_drain_boost = calc_salvage_drain_boost()

    if s_sec < 0:
        var time_to_fail = PlayerInfo.resources["Salvage"] / abs(s_sec)
        if time_to_fail < total_sec:



            salvage_drain_boost = 1


    if auto_optimizing and compute_fighters.visible:

        var total_tiers = -1
        while total_sec > 0:
            compute_optimize()
            total_tiers += 1
            for c in compute_fighters_fighters.get_children():
                if c.compute_allocated > 0:
                    total_sec = c.calc_recieve_offline_gains_to_tier(total_sec)
                    break
        for c in compute_fighters_fighters.get_children():
            UpgradeHelper.process_upgrade(c, c.tier)
        return [s_sec, total_tiers, "Tiers"]
    else:

        var total_levels = 0
        for c in get_tree().get_nodes_in_group("compute_management"):

            if c.allow_removal:
                total_levels += c.calc_recieve_offline_gains(total_sec)

        return [s_sec, total_levels, "Levels"]

func check_ai_unlocks():
    if "AIComputeOptimize" in PlayerInfo.upgrades:
        if PlayerInfo.upgrades.AIComputeOptimize.amount_have > 0:
            btn_optimize.visible = true
        else:
            btn_optimize.visible = false

    if "AIComputePowerAuto" in PlayerInfo.upgrades:
        if PlayerInfo.upgrades.AIComputePowerAuto.amount_have > 0:
            chk_auto_compute_power.visible = true
        else:
            chk_auto_compute_power.visible = false

    if "AIComputeAuto" in PlayerInfo.upgrades:
        if PlayerInfo.upgrades.AIComputeAuto.amount_have > 0:
            chk_auto_optimize.visible = true
        else:
            chk_auto_optimize.visible = false

    if "AIComputeSalvageAuto" in PlayerInfo.upgrades:
        if PlayerInfo.upgrades.AIComputeSalvageAuto.amount_have > 0:
            chk_auto_salvage.visible = true
        else:
            chk_auto_salvage.visible = false


func _on_AITimer_timeout():
    if auto_salvaging:
        auto_set_salvage()
    if auto_optimizing:
        compute_optimize()
    if auto_compute_powering and chk_auto_compute_power.visible:
        auto_compute_power()

func auto_set_salvage():
    var amount = floor(float(PlayerInfo.resource_display_nodes["Salvage"].rps))
    amount = amount / 100
    compute_salvage_per_second._on_ComputeSalvagePerSecond_text_changed(NumberUtils.format_number(amount, 2))

func _on_btnOptimize_pressed():
    compute_optimize()


func _on_chkAutoOptimize_pressed():
    auto_optimizing = chk_auto_optimize.button_pressed
    if auto_optimizing:
        compute_optimize()

func _on_chkAutoSalvage_pressed():
    auto_salvaging = chk_auto_salvage.button_pressed
    if auto_salvaging:
        auto_set_salvage()

func calc_compute_upgrades():
    UpgradeHelper.wait_to_calc = true
    var tier_count = 0
    var odd = false
    if !Challenges.check("compute_to_salvage"):
        for c in basic_compute.get_children():
            UpgradeHelper.process_upgrade(c, c.amount_have)
        for c in advanced_compute.get_children():
            UpgradeHelper.process_upgrade(c, c.amount_have)
        UpgradeHelper.calc_pending()
    else:
        for c in basic_compute.get_children():
            var salvage_generated = pow(Challenges.check("compute_to_salvage"), tier_count) * PlayerInfo.stats["compute_levels"]
            c.salvage_generated = salvage_generated
            if c.levels_this_tick > 0.0:


                PlayerInfo.gain_resource("Salvage", salvage_generated * c.levels_this_tick)

                c.levels_this_tick = 0.0
            if odd:
                tier_count = tier_count + 1
                odd = false
            else:
                odd = true
        for c in advanced_compute.get_children():
            var salvage_generated = pow(Challenges.check("compute_to_salvage"), tier_count) * PlayerInfo.stats["compute_levels"]
            c.salvage_generated = salvage_generated
            if c.levels_this_tick > 0.0:

                PlayerInfo.gain_resource("Salvage", salvage_generated * c.levels_this_tick)
                c.salvage_generated = salvage_generated
                c.levels_this_tick = 0.0
            tier_count = tier_count + 3


func _on_TotalsTimer_timeout():
    var o_total: float = 1
    var d_total: float = 1
    if !max_reached or Challenges.check("compute_to_salvage"):
        calc_compute_upgrades()
        for c in basic_compute.get_children():
            if c.stats.effect[0].target == "damage":
                o_total += c.stats.effect[0].total_effect
            else:
                d_total += c.stats.effect[0].total_effect

        if o_total >= MAX_GOAL or d_total >= MAX_GOAL:
            o_total = MAX_GOAL
            d_total = MAX_GOAL
            PlayerInfo.handle_unlock("UnlockOther", "ComputeTransitionTracker")
            grant_max_reached_upgrade()
            set_max_reached()
        else:


            lbl_damage_boost.add_stat_tick(o_total)
            lbl_shield_boost.add_stat_tick(d_total)
            if o_total >= pow(10, 19) or d_total >= pow(10, 19):
                lbl_cap_info.text = tr("Permanently Caps At") + "\n" + NumberUtils.format_number(MAX_GOAL, 2, 2) + "x"
                lbl_cap_info.show()
            else:
                lbl_cap_info.hide()
        lbl_capped_details.hide()
    else:
        o_total = MAX_GOAL
        d_total = MAX_GOAL
        lbl_cap_info.text = tr("Permanently Capped")
        lbl_cap_info.show()
        lbl_capped_details.text = tr("Basic and Advanced Compute are capped.") + "\n" + tr("Capital Ship required for further Compute usage.")
        if !db.main_ship_data[PlayerInfo.ship].capital:
            lbl_capped_details.show()

    lbl_damage_boost.update_stat(o_total)
    lbl_shield_boost.update_stat(d_total)

func reset_layer_2():

    max_reached = false
    cpb_holder.show()
    lbl_capped_details.hide()
    lbl_damage_boost.ok_to_show = true
    lbl_shield_boost.ok_to_show = true


func grant_max_reached_upgrade():
    btn_compute_maxed_bonus.amount_have = 1
    btn_compute_maxed_bonus.amount_purchased = 1
    btn_compute_maxed_bonus.process_upgrade()

func set_max_reached():
    cpb_holder.hide()
    max_reached = true
    if !SaveLoad.loading:
        UpgradeHelper.wait_to_calc = true
    for c in basic_compute.get_children():
        c.check_and_disable_if_max()
    for c in advanced_compute.get_children():
        c.check_and_disable_if_max()
    if !SaveLoad.loading:
        UpgradeHelper.calc_pending()
    calc_available_compute()
    lbl_damage_boost.ok_to_show = false
    lbl_shield_boost.ok_to_show = false

func _on_chkAutoPowerPurchase_pressed():
    auto_compute_powering = chk_auto_compute_power.button_pressed
    if auto_compute_powering:
        auto_compute_power()


func auto_compute_power():
    var void_matter_override = PlayerInfo.resources["VoidMatter"] * 0.5
    var resource_override = {"VoidMatter": void_matter_override}
    var max_to_buy = UpgradeHelper.calc_max_buyable(btn_compute_power, btn_compute_power.amount_purchased, resource_override)


    if max_to_buy == 1:
        btn_compute_power.get_next_cost()
        if void_matter_override < btn_compute_power.next_cost[0].amount:
            max_to_buy = -1

    if max_to_buy > 0 and max_to_buy >= PlayerInfo.buy_size:
        if PlayerInfo.buy_size == -1:
            btn_compute_power.purchase_upgrade(max_to_buy, true)
        else:
            btn_compute_power.purchase_upgrade(PlayerInfo.buy_size, true)


func challenge_setup():
    if Challenges.check("compute_to_salvage"):
        boost_holder.hide()
        salvage_challenge_holder.show()
        cpb_holder.show()
        lbl_capped_details.hide()
        lbl_cap_info.hide()
        compute_fighters.hide()
        for c in basic_compute.get_children():
            c.check_and_disable_if_max()
        for c in advanced_compute.get_children():
            c.check_and_disable_if_max()
    else:
        set_capital()
        boost_holder.show()
        salvage_challenge_holder.hide()


func _on_btnResetComputation_pressed() -> void :
    compute_reset()


func check_salvage_vm_upgrades_maxed():
    if PlayerInfo.stats["compute_vm_salvage_max"] != 1:
        return


    v_salvage_speed_boost_area.hide()
    v_compute_power_upgrade_area.hide()
    v_compute_salvage_max.show()
    v_compute_vm_max.show()


    chk_auto_compute_power.button_pressed = false
    chk_auto_salvage.button_pressed = false
    auto_compute_powering = false
    auto_salvaging = false


    btn_compute_power.amount_have = 0
    btn_compute_power.amount_purchased = 0
    btn_compute_power.process_upgrade()

    compute_salvage_per_second.text = "0"
    compute_salvage_per_second.set_compute_salvage_drain()
    salvage_drain = 1


    lbl_compute_salvage_speed_boost_maxed.amount_have = 0
    lbl_compute_salvage_speed_boost_maxed.amount_purchased = 0
    lbl_compute_salvage_speed_boost_maxed.do_upgrade()
    lbl_compute_salvage_speed_boost_maxed.show()

    lbl_compute_vm_purchase_maxed.amount_have = 0
    lbl_compute_vm_purchase_maxed.amount_purchased = 0
    lbl_compute_vm_purchase_maxed.do_upgrade()
    lbl_compute_vm_purchase_maxed.show()


func process_upgrade():
    check_salvage_vm_upgrades_maxed()
