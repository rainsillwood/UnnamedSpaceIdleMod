@tool
extends Node2D

var resource = "Power"
var amount = 1
var old_cursor_shape: int = Input.CURSOR_ARROW
var taken = false
signal has_despawned
var time_to_auto_click = -1

@export var mobile_collision_radius: float = 400: set = _set_mobile_collision_radius
@export var desktop_collision_radius: float = 270: set = _set_desktop_collision_radius


func _ready():
    PreviewHelper.connect("platform_changed", Callable(self, "_on_previewhelper_platform_changed"))
    _set_collision_radius()


func spawn():
    $AnimationPlayer.play("Spawn")
    $AnimationPlayerOscillate.play("Oscillate")
    if "EnergyVoid" in PlayerInfo.automation:
        if "enabled" in PlayerInfo.automation["EnergyVoid"]:
            if PlayerInfo.automation["EnergyVoid"]["enabled"]:
                var timer = Timer.new()
                add_child(timer)
                timer.autostart = true
                timer.wait_time = 5
                timer.start()
                timer.connect("timeout", Callable(self, "handle_click"))
    AudioManager.play_battle_pickup_sound("void_spawn")

func handle_click():
    if !taken:
        Input.set_default_cursor_shape(old_cursor_shape)
        if "ReactorArea" in PlayerInfo.unlocked_sections:
            PlayerInfo.resources["Power"] += PlayerInfo.stats.void_power_generation * PlayerInfo.stats["void_power_conversion_max"] * 3 * 60

        PlayerInfo.trigger_ability("VoidEnergyBoost", true)
        taken = true
        if $AnimationPlayer.is_playing():
            await $AnimationPlayer.animation_finished
        $AnimationPlayer.play("Despawn")

func _on_AnimationPlayer_animation_finished(anim_name):
    if (anim_name == "Despawn"):
        Input.set_default_cursor_shape(old_cursor_shape)
        emit_signal("has_despawned")
        queue_free()


func _on_Area2D_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            handle_click()


func _on_Area2D_mouse_entered():
    if !taken:
        old_cursor_shape = Input.get_current_cursor_shape()
        Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)



func _on_Area2D_mouse_exited():
    Input.set_default_cursor_shape(old_cursor_shape)



func _on_AnimationPlayer_animation_started(_anim_name):
    $Area2D.visible = true

func check_pos_overlap(pos):
    var r = $Area2D / CollisionShape2D.shape.radius
    return pos.distance_to(get_global_position()) < r * scale.x


func _set_mobile_collision_radius(value: float) -> void :
    mobile_collision_radius = value
    _set_preview_collision_radius()


func _set_desktop_collision_radius(value: float) -> void :
    desktop_collision_radius = value
    _set_preview_collision_radius()


func _set_collision_radius() -> void :
    var is_mobile = PlatformHelper.is_mobile()
    $Area2D / CollisionShape2D.shape.radius = mobile_collision_radius if is_mobile else desktop_collision_radius


func _set_preview_collision_radius() -> void :
    if Engine.is_editor_hint():
        _set_collision_radius()


func _on_previewhelper_platform_changed() -> void :
    _set_preview_collision_radius()
