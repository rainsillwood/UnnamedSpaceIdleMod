extends Node

var core_data = {}
var weapon_data = {}
var upgrade_data = {}
var resource_data = {}
var recipe_data = {}
var module_data = {}
var ability_data = {}
var ship_data = {}
var core_milestones_data = {}
var stat_data = {}
var main_ship_data = {}
var sector_data = {}
var dialogue_data = {}
var data_unlocks = {}
var power_boosts = {}
var void_shards = {}
var full_data = {}
var achievement_data = {}
var research_data = {}
var forward_base_data = {}
var building_data = {}
var warp_data = {}
var challenge_data = {}
var crew_data = {}
var crew_group_data = {}
var combat_base_data = {}
var reinforce_data = {}
var conquest_data = {}
var reactor_overdrives = {}
var fleet_abilities = {}
var fleet_ships = {}
var fleet_mods = {}
var fleet_galaxies = {}
var fleet_events = {}
var splicing = {}
var unstable_transit = {}
var overdrive_powercells = {}

enum growth_type{EXP, LINEAR, LEVEL_LINEAR, LEVEL_EXP}
enum modifier_type{FLAT, ADDITIVE, MULTIPLICATIVE}
enum target_type{SELF, CLASS, ENEMY, ENEMY_RADIUS, FRIENDLY, FRIENDLY_RADIUS}

var edited_data = {}

func _ready():
    set_data()
    _ships_add_calculated_enemy_sprite_field()


func set_data():
    edited_data = {}
    var data_read = FileAccess.open("res://game_data.cdb", FileAccess.READ)
    var test_json_conv = JSON.new()
    test_json_conv.parse(data_read.get_as_text())
    var data_cdb = test_json_conv.get_data()
    data_read.close()
    full_data = data_cdb
    for sheet in data_cdb["sheets"]:
        if sheet["name"] == "cores":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                core_data[entry["id"]] = new_entry
        elif sheet["name"] == "core_milestones":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                new_entry.erase("id")
                core_milestones_data[entry["id"]] = new_entry
        elif sheet["name"] == "weapons":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                new_entry.erase("id")
                weapon_data[entry["id"]] = new_entry
        elif sheet["name"] == "resources":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                new_entry.erase("id")
                resource_data[entry["id"]] = new_entry
        elif sheet["name"] == "upgrades" or sheet["name"] == "upgrades2":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                new_entry.erase("id")
                upgrade_data[entry["id"]] = new_entry
        elif sheet["name"] == "recipes":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                new_entry.erase("id")
                recipe_data[entry["id"]] = new_entry
        elif sheet["name"] == "modules":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                new_entry.erase("id")
                module_data[entry["id"]] = new_entry
        elif sheet["name"] == "abilities":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                ability_data[entry["id"]] = new_entry
        elif sheet["name"] == "ships":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                ship_data[entry["id"]] = new_entry
        elif sheet["name"] == "stats":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                new_entry.erase("id")
                stat_data[entry["id"]] = new_entry
        elif sheet["name"] == "main_ships":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                main_ship_data[entry["id"]] = new_entry
        elif sheet["name"] == "sectors":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                sector_data[entry["id"]] = new_entry
        elif sheet["name"] == "ai_dialogue":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                dialogue_data[entry["id"]] = new_entry
        elif sheet["name"] == "data_unlocks":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                data_unlocks[entry["id"]] = new_entry
        elif sheet["name"] == "power_boosts":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                power_boosts[entry["id"]] = new_entry
        elif sheet["name"] == "void_shards":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                void_shards[entry["id"]] = new_entry
        elif sheet["name"] == "achievements":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                achievement_data[entry["id"]] = new_entry
        elif sheet["name"] == "research":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                research_data[entry["id"]] = new_entry
        elif sheet["name"] == "forward_bases":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                forward_base_data[entry["id"]] = new_entry
        elif sheet["name"] == "base_buildings":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                building_data[entry["id"]] = new_entry
        elif sheet["name"] == "warps":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                warp_data[entry["id"]] = new_entry
        elif sheet["name"] == "challenges":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                challenge_data[entry["id"]] = new_entry
        elif sheet["name"] == "crew":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                crew_data[entry["id"]] = new_entry
        elif sheet["name"] == "crew_group":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                crew_group_data[entry["id"]] = new_entry
        elif sheet["name"] == "combat_bases":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                combat_base_data[entry["id"]] = new_entry
        elif sheet["name"] == "reinforce":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                reinforce_data[entry["id"]] = new_entry
        elif sheet["name"] == "conquest":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                conquest_data[entry["id"]] = new_entry
        elif sheet["name"] == "reactor_overdrives":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                reactor_overdrives[entry["id"]] = new_entry
        elif sheet["name"] == "fleet_abilities":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                fleet_abilities[entry["id"]] = new_entry
        elif sheet["name"] == "fleet_ships":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                fleet_ships[entry["id"]] = new_entry
        elif sheet["name"] == "fleet_galaxies":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                fleet_galaxies[entry["id"]] = new_entry
        elif sheet["name"] == "fleet_events":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                fleet_events[entry["id"]] = new_entry
        elif sheet["name"] == "fleet_mods":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                fleet_mods[entry["id"]] = new_entry
        elif sheet["name"] == "splicing":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                splicing[entry["id"]] = new_entry
        elif sheet["name"] == "unstable_transit":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                unstable_transit[entry["id"]] = new_entry
        elif sheet["name"] == "overdrive_powercells":
            for entry in sheet["lines"]:
                var new_entry = entry.duplicate()
                overdrive_powercells[entry["id"]] = new_entry




func _ships_add_calculated_enemy_sprite_field():
    for ship in db.ship_data.values():

        if "enemies" in ship.select_sprite and !ship.capital:

            if ship.barrier > 0:
                ship.select_sprite = _ships_replace_sprite_text(ship.select_sprite, "Purple")
            elif ship.phase_jump > 0:

                if ship.shield_ratio > 0:
                    ship.select_sprite = _ships_replace_sprite_text(ship.select_sprite, "Pink")

                else:
                    ship.select_sprite = _ships_replace_sprite_text(ship.select_sprite, "DeepRed")
            elif ship.armored:

                if ship.shield_ratio > 0:
                    ship.select_sprite = _ships_replace_sprite_text(ship.select_sprite, "Green")

                else:
                    ship.select_sprite = _ships_replace_sprite_text(ship.select_sprite, "Red")
            elif ship.shield_ratio > 0:

                if ship.shield_regen_delay < 0.5 and ship.shield_regen_delay > 0 and ship.shield_regen_rate >= 0.1:
                    ship.select_sprite = _ships_replace_sprite_text(ship.select_sprite, "Teal")

                else:
                    ship.select_sprite = _ships_replace_sprite_text(ship.select_sprite, "Blue")

            else:
                ship.select_sprite = _ships_replace_sprite_text(ship.select_sprite, "Black")




func _ships_replace_sprite_text(target: String, replacement: String) -> String:

    var swaps = ["Black", "Blue", "DeepRed", "Green", "Pink", "Purple", "Red", "Teal"]
    for s in swaps:
        if s in target:
            return target.replace(s, replacement)

    return target
