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
    for sheet in data_cdb.sheets:
        if sheet.name == "resources":
            var injectRescource = {
					"id": "TimeFlux",
					"name": "Time",
					"type": "AI Point",
					"persist": true,
					"texture": "assets/cores/milestones/stopwatch.png",
					"bank": false,
					"tier": 1,
					"persist_layer_2": true
            }
            sheet.lines.append(injectRescource)
        if sheet.name == "upgrades":
            var addTimeFlux = {
                "cost_base": 0,
                "cost_growth": 0,
                "type": 1,
                "levels_to_increase": 0,
                "resource": "TimeFlux",
                "precise": false
            }
            for line in sheet.lines:
                if line.id in ["SpacemasMiniSkip","SpaceversaryMiniSkip"]:
                    line.effect.pop_back()
                    addTimeFlux.cost_base = -300000
                    line.cost.append(addTimeFlux.duplicate_deep())
                elif line.id in ["SpaceversaryResourceSkip", "SpaceversarySynthSkip", "SpaceversaryResearchSkip", "SpaceversaryBaseSkip", "SpaceversaryWarpSkip", "SpaceversaryCrewSkip", "SpaceversaryFuelSkip"]:
                    line.effect.pop_back()
                    addTimeFlux.cost_base = -1125000
                    line.cost.append(addTimeFlux.duplicate_deep())
            var injectArray = [
                {
                    "id": "AddTime",
                    "name": "6 Hour Time Skip",
                    "description": "6 Hour Time Skip to Time",
                    "type": "synth",
                    "cost": [
                        {
                            "cost_base": 1,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeSkip6Hours",
                            "precise": false
                        },
                        {
                            "cost_base": -21600000,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeFlux",
                            "precise": false
                        }
                    ],
                    "effect": [
                    ],
                    "speed_modifier": "",
                    "max_level": 0,
                    "unlock_message": "",
                    "persist": false,
                    "icon": "assets/interface/warp/stone-block.png",
                    "unlock_cost": [],
                    "unlock_persist": false,
                    "persist_layer_2": false,
                    "capital_only": false
                },
                {
                    "id": "UnlimitedTimeSkip",
                    "name": "Mini Skip",
                    "description": "10 Min. Time Skip",
                    "type": "synth",
                    "cost": [
                        {
                            "cost_base": 600000,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeFlux",
                            "precise": false
                        }
                    ],
                    "effect": [
                        {
                            "target": "All",
                            "base_effect": 600, 
                            "modifier_type": "TimeSkip",
                            "global_hook": "",
                            "self_multiplicative": false,
                            "expression_connections": [],
                            "direct_connection": "",
                            "direct_connection2": "",
                            "connection_type": "",
                            "expression": "",
                            "formula_mod": "",
                            "mod_target": ""
                        }
                    ],
                    "speed_modifier": "",
                    "max_level": 0,
                    "unlock_message": "",
                    "persist": false,
                    "icon": "assets/interface/warp/portal.png",
                    "unlock_cost": [],
                    "unlock_persist": false,
                    "persist_layer_2": false,
                    "capital_only": false
                },
                {
                    "id": "UnlimitedResourceSkip",
                    "name": "Resource Boost",
                    "description": "10 Min. Resource Skip",
                    "type": "synth",
                    "cost": [
                        {
                            "cost_base": 46875,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeFlux",
                            "precise": false
                        }
                    ],
                    "effect": [
                        {
                            "target": "Resources",
                            "base_effect": 600,
                            "modifier_type": "TimeSkip",
                            "global_hook": "",
                            "self_multiplicative": false,
                            "expression_connections": [],
                            "direct_connection": "",
                            "direct_connection2": "",
                            "connection_type": "",
                            "expression": "",
                            "formula_mod": "",
                            "mod_target": ""
                        }
                    ],
                    "speed_modifier": "",
                    "max_level": 0,
                    "unlock_message": "",
                    "persist": false,
                    "icon": "assets/interface/crew/cubeforce.png",
                    "unlock_cost": [],
                    "unlock_persist": false,
                    "persist_layer_2": false,
                    "capital_only": false
                },
                {
                    "id": "UnlimitedSynthSkip",
                    "name": "Synth Boost",
                    "description": "10 Min. Synth Skip",
                    "type": "synth",
                    "cost": [
                        {
                            "cost_base": 62500,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeFlux",
                            "precise": false
                        }
                    ],
                    "effect": [
                        {
                            "target": "Synth",
                            "base_effect": 600,
                            "modifier_type": "TimeSkip",
                            "global_hook": "",
                            "self_multiplicative": false,
                            "expression_connections": [],
                            "direct_connection": "",
                            "direct_connection2": "",
                            "connection_type": "",
                            "expression": "",
                            "formula_mod": "",
                            "mod_target": ""
                        }
                    ],
                    "speed_modifier": "",
                    "max_level": 0,
                    "unlock_message": "",
                    "persist": false,
                    "icon": "assets/interface/warp/overdrive.png",
                    "unlock_cost": [],
                    "unlock_persist": false,
                    "persist_layer_2": false,
                    "capital_only": false
                },
                {
                    "id": "UnlimitedResearchSkip",
                    "name": "Research Boost",
                    "description": "10 Min. Research Skip",
                    "type": "synth",
                    "cost": [
                        {
                            "cost_base": 75000,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeFlux",
                            "precise": false
                        }
                    ],
                    "effect": [
                        {
                            "target": "Research",
                            "base_effect": 600,
                            "modifier_type": "TimeSkip",
                            "global_hook": "",
                            "self_multiplicative": false,
                            "expression_connections": [],
                            "direct_connection": "",
                            "direct_connection2": "",
                            "connection_type": "",
                            "expression": "",
                            "formula_mod": "",
                            "mod_target": ""
                        }
                    ],
                    "speed_modifier": "",
                    "max_level": 0,
                    "unlock_message": "",
                    "persist": false,
                    "icon": "assets/interface/warp/erlenmeyer.png",
                    "unlock_cost": [],
                    "unlock_persist": false,
                    "persist_layer_2": false,
                    "capital_only": false
                },
                {
                    "id": "UnlimitedBaseSkip",
                    "name": "Base Boost",
                    "description": "10 Min. Base Skip",
                    "type": "synth",
                    "cost": [
                        {
                            "cost_base": 93750,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeFlux",
                            "precise": false
                        }
                    ],
                    "effect": [
                        {
                            "target": "Base",
                            "base_effect": 600,
                            "modifier_type": "TimeSkip",
                            "global_hook": "",
                            "self_multiplicative": false,
                            "expression_connections": [],
                            "direct_connection": "",
                            "direct_connection2": "",
                            "connection_type": "",
                            "expression": "",
                            "formula_mod": "",
                            "mod_target": ""
                        }
                    ],
                    "speed_modifier": "",
                    "max_level": 0,
                    "unlock_message": "",
                    "persist": false,
                    "icon": "assets/interface/warp/defense-satellite.png",
                    "unlock_cost": [],
                    "unlock_persist": false,
                    "persist_layer_2": false,
                    "capital_only": false
                },
                {
                    "id": "UnlimitedWarpSkip",
                    "name": "Warp Boost",
                    "description": "10 Min Warp Skip",
                    "type": "synth",
                    "cost": [
                        {
                            "cost_base": 93750,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeFlux",
                            "precise": false
                        }
                    ],
                    "effect": [
                        {
                            "target": "Warp",
                            "base_effect": 600,
                            "modifier_type": "TimeSkip",
                            "global_hook": "",
                            "self_multiplicative": false,
                            "expression_connections": [],
                            "direct_connection": "",
                            "direct_connection2": "",
                            "connection_type": "",
                            "expression": "",
                            "formula_mod": "",
                            "mod_target": ""
                        }
                    ],
                    "speed_modifier": "",
                    "max_level": 0,
                    "unlock_message": "",
                    "persist": false,
                    "icon": "assets/interface/warp/expanded-rays.png",
                    "unlock_cost": [],
                    "unlock_persist": false,
                    "persist_layer_2": false,
                    "capital_only": false
                },
                {
                    "id": "UnlimitedCrewSkip",
                    "name": "Crew Boost",
                    "description": "10 Min. Crew Skip",
                    "type": "synth",
                    "cost": [
                        {
                            "cost_base": 93750,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeFlux",
                            "precise": false
                        }
                    ],
                    "effect": [
                        {
                            "target": "Crew",
                            "base_effect": 600,
                            "modifier_type": "TimeSkip",
                            "global_hook": "",
                            "self_multiplicative": false,
                            "expression_connections": [],
                            "direct_connection": "",
                            "direct_connection2": "",
                            "connection_type": "",
                            "expression": "",
                            "formula_mod": "",
                            "mod_target": ""
                        }
                    ],
                    "speed_modifier": "",
                    "max_level": 0,
                    "unlock_message": "",
                    "persist": false,
                    "icon": "assets/interface/crew/three-friends.png",
                    "unlock_cost": [],
                    "unlock_persist": false,
                    "persist_layer_2": false,
                    "capital_only": false
                },
                {
                    "id": "UnlimitedFuelSkip",
                    "name": "Fuel Boost",
                    "description": "10 Min. Fuel Skip",
                    "type": "synth",
                    "cost": [
                        {
                            "cost_base": 125000,
                            "cost_growth": 0,
                            "type": 1,
                            "levels_to_increase": 0,
                            "resource": "TimeFlux",
                            "precise": false
                        }
                    ],
                    "effect": [
                        {
                            "target": "Fleet",
                            "base_effect": 600,
                            "modifier_type": "TimeSkip",
                            "global_hook": "",
                            "self_multiplicative": false,
                            "expression_connections": [],
                            "direct_connection": "",
                            "direct_connection2": "",
                            "connection_type": "",
                            "expression": "",
                            "formula_mod": "",
                            "mod_target": ""
                        }
                    ],
                    "speed_modifier": "",
                    "max_level": 0,
                    "unlock_message": "",
                    "persist": false,
                    "icon": "assets/interface/warp/sundial.png",
                    "unlock_cost": [],
                    "unlock_persist": false,
                    "persist_layer_2": false,
                    "capital_only": false
                }
            ]
            sheet.lines.append_array(injectArray)
        if sheet.name == "modules":
            var effect = {
                "target": "",
                "base_effect": 0,
                "modifier_type": "Multiplicative",
                "global_hook": "",
                "self_multiplicative": false,
                "direct_connection": "level",
                "connection_type": "Self",
                "expression": "",
                "direct_connection2": "",
                "soft_cap": 0,
                "formula_mod": "",
                "mod_target": "",
                "expression_connections": []
            }
            var data = {
                "LaserBoostAutoUse": {
                    "key": "LaserBoost_duration",
                    "number": 1.2
                },
                "VolleyAutoUse": {
                    "key": "KineticVolley_duration",
                    "number": 1.2
                },
                "ShieldBoostAutoUse": {
                    "key": "ShieldBoost_duration",
                    "number": 2.7
                }
            }
            for line in sheet["lines"]:
                if line.id in ["LaserBoostAutoUse", "VolleyAutoUse", "ShieldBoostAutoUse"]:
                    line.tiers[0].effect[1].expression = "[x]*.05"
                    effect.target = data[line.id].key
                    effect.expression = "-.1+([x]*" + str(data[line.id].number) + ")"
                    line.tiers[0].effect.append(effect.duplicate_deep())
                    line.tiers[1].effect[1].expression = ".15+([x]*.1)"
                    effect.expression = str(3 * data[line.id].number - 0.1)
                    line.tiers[1].effect.append(effect.duplicate_deep())
                    line.tiers[2].effect[1].expression = ".45+([x]*.15)"
                    line.tiers[2].effect.append(effect.duplicate_deep())
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
