extends Control
class_name BottleUI

# 信號
signal write_requested(bottle_id: int)
signal skip_requested(bottle_id: int)

# 漂流瓶數據
var bottle_data: Dictionary = {}
var is_read_only: bool = false

# UI 元素引用
@onready var theme_label = $MainContainer/ThemeLabel
@onready var area_label = $MainContainer/AreaLabel
@onready var content_container = $MainContainer/ScrollContainer/ContentContainer
@onready var write_button = $MainContainer/ButtonsContainer/WriteButton
@onready var skip_button = $MainContainer/ButtonsContainer/SkipButton
@onready var progress_label = $MainContainer/ProgressLabel
@onready var last_message_label = $MainContainer/LastMessageLabel

# 預加載內容條目場景
var entry_scene = preload("res://scenes/ui/bottle_entry.tscn")

func _ready():
	print("BottleUI _ready - 初始化按鈕")
	print("BottleUI _ready - write_button: ", write_button)
	
	write_button.connect("pressed", Callable(self, "_on_write_button_pressed"))
	skip_button.connect("pressed", Callable(self, "_on_skip_button_pressed"))
	
	print("BottleUI _ready - 按鈕初始化完成")

# 設置漂流瓶數據
func setup(data: Dictionary):
	bottle_data = data
	_update_ui()

func set_read_only(read_only: bool):
	is_read_only = read_only
	_update_ui()

# 更新 UI 顯示
func _update_ui():
	if bottle_data.is_empty():
		visible = false
		return
		
	visible = true
	
	# 更新標籤
	theme_label.text = "主題: " + bottle_data.theme
	area_label.text = "區域: " + _get_area_display_name(bottle_data.area)
	
	# 更新內容顯示
	# 清空內容容器
	for child in content_container.get_children():
		child.queue_free()
	
	# 添加新內容
	for entry in bottle_data.content:
		var label = Label.new()
		label.text = entry.text + "\n- " + entry.author
		content_container.add_child(label)
	
	# 更新按鈕狀態
	write_button.disabled = is_read_only or bottle_data.current_entries >= bottle_data.max_entries
	
	# 更新進度標籤
	progress_label.text = "進度: " + str(bottle_data.current_entries) + "/" + str(bottle_data.max_entries)
	
	# 顯示最後一條訊息
	if bottle_data.content.size() > 0:
		var last_entry = bottle_data.content[bottle_data.content.size() - 1]
		last_message_label.text = "最後訊息: %s" % last_entry.text
	else:
		last_message_label.text = "尚未寫入訊息"
	
	print("BottleUI update_ui - 更新完成")
	print("BottleUI update_ui - write_button.disabled: ", write_button.disabled)
	print("BottleUI update_ui - current_entries: ", bottle_data.current_entries)
	print("BottleUI update_ui - max_entries: ", bottle_data.max_entries)

# 添加新條目
func add_entry(entry_data: Dictionary):
	if bottle_data.content.size() < bottle_data.max_entries:
		bottle_data.content.append(entry_data)
		bottle_data.current_entries += 1
		_update_ui()

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

# 寫入按鈕點擊
func _on_write_button_pressed():
	if not is_read_only:
		emit_signal("write_requested", bottle_data.id)

# 跳過按鈕點擊
func _on_skip_button_pressed():
	if not is_read_only:
		emit_signal("skip_requested", bottle_data.id)
