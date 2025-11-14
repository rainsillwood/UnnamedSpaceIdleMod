extends Node






signal purchase_initialization_completed_successfully()





signal purchase_initialization_completed_with_error(error, retryable)







signal item_details_loaded(item, title, description, price)




signal item_details_failed_to_load(item)






signal item_purchased_successfully(item, should_record)





signal item_failed_to_purchase(item, error)




signal request_in_progress_changed(in_progress)




signal recover_purchases_completed_successfully(result)





signal recover_purchases_failed(error, doing_purchase_version_adjustment)






signal error_occurred(title, message)






var _current: BasePurchaseHelper





func _ready() -> void :
    match PlatformHelper.platform:
        PlatformHelper.DESKTOP_STEAM:
            var mock_purchase: = MockPurchaseHelper.new()
            mock_purchase._is_testing_error_states = false
            _current = mock_purchase
        PlatformHelper.IOS:
            _current = IOSPurchaseHelper.new()
        PlatformHelper.ANDROID:
            _current = AndroidPurchaseHelper.new()
        _:
            _current = null

    if DebugUtils.get_use_mock_purchase():
        var mock_purchase: = MockPurchaseHelper.new()
        mock_purchase._is_testing_error_states = DebugUtils.get_simulate_mock_purchase_errors()
        _current = mock_purchase


    if _current != null:
        add_child(_current)
        _current.connect("retrieve_purchase_history_completed_successfully", Callable(self, "_on_purchase_helper_retrieve_purchase_history_completed_successfully"))






func has_purchase_support() -> bool:
    return _current != null




func initialize_purchase_helper() -> void :
    if _current == null:
        printerr("PurchaseHelper: initialize_purchase_helper - No PurchaseHelper implementation configured, aborting...")
        return
    _current.initialize_purchase_helper()




func is_successfully_initialized() -> bool:
    if _current == null:
        printerr("PurchaseHelper: is_successfully_initialized - No PurchaseHelper implementation configured, aborting...")
        return false
    return _current.is_successfully_initialized()





func get_item_details_with_cache(items: Array) -> void :
    if _current == null:
        printerr("PurchaseHelper: get_item_details_with_cache - No PurchaseHelper implementation configured, aborting...")
        return
    _current.get_item_details_with_cache(items)




func purchase(item: PurchaseItem) -> void :
    if _current == null:
        printerr("PurchaseHelper: purchase - No PurchaseHelper implementation configured, aborting...")
        return
    _current.purchase(item)





func recover_purchases(doing_purchase_version_adjustment: bool = false) -> void :
    if _current == null:
        printerr("PurchaseHelper: recover_purchases - No PurchaseHelper implementation configured, aborting...")
        return
    _current.recover_purchases(doing_purchase_version_adjustment)



func find_purchase_node(item: PurchaseItem) -> Purchaseable:
    for n in get_tree().get_nodes_in_group("purchaseable"):
        var purchaseable = n as Purchaseable
        if purchaseable == null:
            continue
        if purchaseable.purchase_item.internal_item_id == item.internal_item_id:
            return purchaseable
    push_warning("PurchaseHelper: find_purchase_node(): Unable to find purchase node for item %s" % item.internal_item_id)
    return null



func find_purchase_node_by_internal_id(internal_item_id: String) -> Purchaseable:
    for n in get_tree().get_nodes_in_group("purchaseable"):
        var purchaseable = n as Purchaseable
        if purchaseable == null:
            continue
        if purchaseable.purchase_item.internal_item_id == internal_item_id:
            return purchaseable
    push_warning("PurchaseHelper: find_purchase_node_by_internal_id(): Unable to find purchase node for id %s" % internal_item_id)
    return null



func find_purchase_node_by_steam_item_id(steam_item_id: int) -> Purchaseable:
    for n in get_tree().get_nodes_in_group("purchaseable"):
        var purchaseable = n as Purchaseable
        if purchaseable == null:
            continue
        if purchaseable.purchase_item.steam_item_id == steam_item_id:
            return purchaseable
    push_warning("PurchaseHelper: find_purchase_node_by_steam_item_id(): Unable to find purchase node for id %s" % steam_item_id)
    return null



func find_purchase_node_by_ios_item_id(ios_item_id: String) -> Purchaseable:
    for n in get_tree().get_nodes_in_group("purchaseable"):
        var purchaseable = n as Purchaseable
        if purchaseable == null:
            continue
        if purchaseable.purchase_item.ios_item_id == ios_item_id:
            return purchaseable
    push_warning("PurchaseHelper: find_purchase_node_by_ios_item_id(): Unable to find purchase node for id %s" % ios_item_id)
    return null



func find_purchase_node_by_android_item_id(android_item_id: String) -> Purchaseable:
    for n in get_tree().get_nodes_in_group("purchaseable"):
        var purchaseable = n as Purchaseable
        if purchaseable == null:
            continue
        if purchaseable.purchase_item.android_item_id == android_item_id:
            return purchaseable
    push_warning("PurchaseHelper: find_purchase_node_by_android_item_id(): Unable to find purchase node for id %s" % android_item_id)
    return null



func find_purchase_node_by_steam_or_internal_item_id(item_id) -> Purchaseable:
    var node
    var purchase_node


    if item_id is int or item_id is float:
        node = find_purchase_node_by_steam_item_id(int(item_id))
        purchase_node = node as Purchaseable
    else:
        node = find_purchase_node_by_internal_id(item_id)
        purchase_node = node as Purchaseable


        if purchase_node == null:
            var int_value = int(item_id)
            node = find_purchase_node_by_steam_item_id(int_value)
            purchase_node = node as Purchaseable
    return purchase_node














func _on_purchase_helper_retrieve_purchase_history_completed_successfully(
        dict: Dictionary, 
        doing_purchase_version_adjustment: bool) -> void :
    if doing_purchase_version_adjustment:
        _do_purchase_version_adjustment(dict)
    else:
        _do_purchase_recovery(dict)












func _do_purchase_version_adjustment(dict: Dictionary) -> void :
    for key in dict:
        var element = dict[key]
        var node = element.node as Purchaseable
        var item = element.item as PurchaseItem
        if item.only_one:
            continue
        node.purchased_amount = element.amount










func _do_purchase_recovery(dict: Dictionary) -> void :
    var actual_recover_list = {}
    for key in dict:
        var element = dict[key]
        var item = element.item as PurchaseItem
        var node = element.node as Purchaseable


        var title = node.title if node.title != "" else item.internal_item_id
        actual_recover_list[title] = 0
        if item.only_one:
            if !node.purchased:
                actual_recover_list[title] += 1
                PurchaseItemGranter.grant_item(item, false)
        else:
            while node.purchased_amount < element.amount:
                actual_recover_list[title] += 1
                PurchaseItemGranter.grant_item(item, false)

    var recover_list_message = ""
    for r in actual_recover_list:
        if actual_recover_list[r] > 0:
            if recover_list_message != "":
                recover_list_message += ", "
            recover_list_message += r + ": " + str(actual_recover_list[r]) + "x"
    if recover_list_message != "":
        recover_list_message = tr("Recovered") + " " + recover_list_message
    else:
        recover_list_message = tr("No uncredited purchases found.")

    emit_signal("recover_purchases_completed_successfully", recover_list_message)
