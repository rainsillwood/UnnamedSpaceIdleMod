extends VBoxContainer


@onready var lbl_result = $lblResult
@onready var le_code_entry: USILineEdit = %leCodeEntry
@onready var http_request_code = $HTTPRequestCode
@onready var btn_check_code = $btnCheckCode
@onready var btn_paste_code: USIButton = %btnPasteCode


func _ready():
    PlayerInfo.cloud_code_redemption = self

const CODE_URL = "https://api.spaceidle.xyz/enter_code/"

var active_code = ""

func check_code(code):

    if code in PlayerInfo.codes_used:
        lbl_result.text = tr("Already Redeemed")
        btn_check_code.disabled = false
    else:
        var dict = {"player_uuid": Config.config.get_value("Misc", "player_id"), "code": code}
        var query = JSON.stringify(dict)
        var headers = ["Content-Type: application/json"]
        active_code = code
        print("redeeming code: " + code)
        le_code_entry.editable = false
        btn_paste_code.disabled = true
        http_request_code.request(CODE_URL, headers, HTTPClient.METHOD_POST, query)


func _on_HTTPRequestCode_request_completed(_result, response_code, _headers, body):
    btn_check_code.disabled = false
    le_code_entry.select_all()
    le_code_entry.editable = true
    btn_paste_code.disabled = false
    print("code response: " + str(response_code))
    const codelist = {"registerbonusyo": {"AIPoint": 100},"whywastherenotalaunchcode": {"AIPoint": 200},"somuchforoctober": {"AIPoint": 150,"TimeSkip6Hours": 1},"awardwinning100k": {"BasePrestige": 1,"ExtraRetrofit": 1,"AIPoint": 125},"somuchforoctoberer": {"AIPoint": 175,"TimeSkip6Hours": 1},"ireallyneedextraaipointstoaffordthenewsplicedcrewupgrade": {"AIPoint": 200},"alligotforhalloweenwasthislameskin": {"Skin": "haunted"},"isolemnlysweariwasinsector60to68andgottoonerfed": {"ExtraRetrofit": 1,"AIPoint": 300},"retrofix": {"ExtraRetrofit": 1,"AIPoint": 300},"ineedaipointsforloadouts": {"AIPoint": 200},"'merica": {"AIPoint": 250},"iminr1orr2andyounerfedmyoverdrive": {"TimeSkip6Hours": 1},"spacemas": {"AIPoint": 250},"idlerfest": {"AIPoint": 300},"eggs": {"AIPoint": 200},"likeag6": {"BasePrestige": 1,"AIPoint": 150},"wwssadadklkl": {"ExtraRetrofit": 30},"showmethemoney": {"AIPoint": 1000},"operationcwal": {"TimeSkip6Hours": 1},"somethingfornothing": {"BasePrestige": 1},"xmas": {"Giftium": 1},"anniversary": {"Yearium": 1}}
    if response_code == 200 or codelist[active_code] != null:
        var test_json_conv = JSON.new()
        var json_parse = {}
        if response_code == 200:
            test_json_conv.parse(body.get_string_from_utf8())
            json_parse = test_json_conv.get_data()
        else:
            json_parse = codelist[active_code]
        lbl_result.text = tr("Redeemed") + "\n"
        for r in json_parse:
            if r == "Purchase":
                var purchase_node = PurchaseHelper.find_purchase_node_by_steam_or_internal_item_id(json_parse[r])
                if purchase_node != null:
                    PurchaseItemGranter.grant_item(purchase_node.purchase_item, false)
                    var item_name = purchase_node.title if purchase_node.title != "" else purchase_node.internal_item_id
                    lbl_result.text = tr("Purchase redeemed:") + " %s" % item_name
            elif r == "Skin":
                Themes.grant_skin(json_parse[r])
            elif r == "Theme":
                Themes.grant_theme(json_parse[r])
            elif "Unlock" in r:
                PlayerInfo.handle_unlock(r, json_parse[r])
            else:
                PlayerInfo.gain_resource(r, json_parse[r])
                lbl_result.text += "%d: %s\n" % [json_parse[r], db.resource_data[r].name]
        if active_code in "wwssadadklkl|showmethemoney|operationcwal|somethingfornothing|xmas|anniversary":
            lbl_result.text = tr("Cheating") + "\n"
        else:
            PlayerInfo.codes_used.push_front(active_code)
        if active_code == "isolemnlysweariwasinsector60to68andgottoonerfed":
            if PlayerInfo.misc_stats["highest_sector_total"] < 60 or PlayerInfo.misc_stats["highest_sector_total"] > 69:
                lbl_result.text += tr("I can't believe you would lie to a text box")
                #PlayerInfo.codes_used.push_front("isaliar")
        if active_code == "iminr1orr2andyounerfedmyoverdrive":

            if not "reinforces_total" in PlayerInfo.misc_stats:
                PlayerInfo.misc_stats["reinforces_total"] = 0
            if PlayerInfo.misc_stats["reinforces_total"] < 1 or PlayerInfo.misc_stats["reinforces_total"] > 2:
                if true or "isaliar" in PlayerInfo.codes_used:
                    lbl_result.text += tr("You lied again? Sensing a bit of a pattern here...")
                else:
                    lbl_result.text += tr("I can't believe you would lie to a text box")
                #PlayerInfo.codes_used.push_front("isaliar2")
        if active_code == "ireallyneedextraaipointstoaffordthenewsplicedcrewupgrade":

            if PlayerInfo.resources["AIPoint"] >= 450 or !PlayerInfo.upgrades["AISpliceInfusionAuto"].unlocked:
                if true or "isaliar" in PlayerInfo.codes_used and "isaliar2" in PlayerInfo.codes_used:
                    lbl_result.text += tr("Third times the charm I suppose...")
                elif "isaliar" in PlayerInfo.codes_used or "isaliar2" in PlayerInfo.codes_used:
                    lbl_result.text += tr("You lied again? Sensing a bit of a pattern here...")
                else:
                    lbl_result.text += tr("I can't believe you would lie to a text box")
                #PlayerInfo.codes_used.push_front("isaliar3")
    elif response_code == 400:
        lbl_result.text = tr("Incorrect Code")
    else:
        lbl_result.text = tr("Error communicating with server")

    active_code = ""

func _on_btnCheckCode_pressed():
    btn_check_code.disabled = true
    lbl_result.text = ""
    var code_text = le_code_entry.text.to_lower().replace(" ", "")
    if code_text == "secret":
        PlayerInfo.check_grant_achievement("SecretCode")
    elif code_text == "now":
        btn_check_code.disabled = false
        if PlayerInfo.misc_stats["highest_sector_total"] >= 40:
            PlayerInfo.check_grant_achievement("BaseWord")
            lbl_result.text = tr("Achievement Granted")
            return
        else:
            lbl_result.text = tr("You can't possibly know this yet")
            return
    elif code_text == "113107":
        btn_check_code.disabled = false
        if "FleetArea" in PlayerInfo.unlocked_sections:
            if !get_tree().get_root().find_child("FleetGalaxy3", true, false).locked:
                PlayerInfo.check_grant_achievement("GalaxyPrimePrimePrime")
                lbl_result.text = tr("Achievement Granted")
                return
            else:
                PlayerInfo.check_grant_achievement("GalaxyPrimePrimePrime")
                lbl_result.text = tr("Read the other achievements did you?")
                return
        else:
            lbl_result.text = tr("You can't possibly know this yet")
            return
    check_code(code_text)


func _on_btn_paste_code_pressed() -> void :
    var clipboard_text = DisplayServer.clipboard_get()
    if clipboard_text and not clipboard_text.is_empty():
        le_code_entry.text = clipboard_text
