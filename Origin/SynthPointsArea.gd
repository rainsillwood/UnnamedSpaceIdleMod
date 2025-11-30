extends Label




func _ready():
    pass



func _process(_delta):
    text = tr("Synth Points") + ": " + NumberUtils.format_number(PlayerInfo.resources["SynthPoint"], 2)
