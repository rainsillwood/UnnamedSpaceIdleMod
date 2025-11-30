extends Label




func _ready():
    pass



func _process(_delta):
    text = tr("Synth Points") + ": " + NumberUtils.format_number(PlayerInfo.resources["SynthPoint"], 2)
    text = text + "\n" + tr("Time Left") + ": "
    var arrayTimes = [1000, 60, 60, 1]
    var arrayUnit = ["", ".", ":", ":"]
    var numTime = int(PlayerInfo.resources["TimeString"])
    var strTime = ""
    for i in range(4):
        strTime = str(numTime % arrayTimes[i]) + arrayUnit[i] + strTime
        numTime = floor(numTime / arrayTimes[i])
    text = text + strTime