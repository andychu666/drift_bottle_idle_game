extends Window
class_name CollectionPanel

# UI 元素引用
@onready var collection_list = $VBoxContainer/ScrollContainer/CollectionList
@onready var bottle_details = $VBoxContainer/BottleDetails
@onready var theme_label = $VBoxContainer/BottleDetails/ThemeLabel
@onready var area_label = $VBoxContainer/BottleDetails/AreaLabel
@onready var content_text = $VBoxContainer/BottleDetails/ContentText
@onready var close_button = $VBoxContainer/CloseButton

# 當前選中的漂流瓶索引
var selected_bottle_index: int = -1

func _ready():
	# 連接信號
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	
	# 設置關閉請求處理
	connect("close_requested", Callable(self, "_on_close_requested"))
	
	# 初始化詳情面板
	bottle_details.visible = false

# 顯示面板
func show_panel():
	update_ui()
	popup_centered()

# 更新 UI
func update_ui():
	# 清空列表
	for child in collection_list.get_children():
		child.queue_free()
	
	# 添加收藏的漂流瓶
	for i in range(GameManager.collected_bottles.size()):
		var bottle = GameManager.collected_bottles[i]
		
		var button = Button.new()
		button.text = bottle.theme + " (" + _get_area_display_name(bottle.area) + ")"
		button.connect("pressed", Callable(self, "_on_bottle_selected").bind(i))
		collection_list.add_child(button)
	
	# 如果沒有收藏的漂流瓶，顯示提示
	if GameManager.collected_bottles.size() == 0:
		var label = Label.new()
		label.text = "還沒有收藏的漂流瓶"
		collection_list.add_child(label)

# 獲取區域顯示名稱
func _get_area_display_name(area_id: String) -> String:
	var area_names = {
		"beach": "沙灘",
		"reef": "珊瑚礁",
		"deep_sea": "深海",
		"island": "孤島",
		"arctic": "極地"
	}
	
	return area_names.get(area_id, "未知區域")

# 漂流瓶選中
func _on_bottle_selected(index: int):
	selected_bottle_index = index
	_show_bottle_details()

# 顯示漂流瓶詳情
func _show_bottle_details():
	if selected_bottle_index >= 0 and selected_bottle_index < GameManager.collected_bottles.size():
		var bottle = GameManager.collected_bottles[selected_bottle_index]
		
		theme_label.text = "主題: " + bottle.theme
		area_label.text = "來自: " + _get_area_display_name(bottle.area)
		
		# 構建內容文本
		var full_text = ""
		for entry in bottle.content:
			full_text += entry.author + ":\n"
			full_text += entry.text + "\n\n"
		
		content_text.text = full_text
		
		bottle_details.visible = true
	else:
		bottle_details.visible = false

# 關閉按鈕點擊
func _on_close_button_pressed():
	visible = false

# 關閉請求
func _on_close_requested():
	visible = false 
