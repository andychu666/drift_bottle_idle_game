extends Control
class_name BottleEntry

# UI 元素引用
@onready var author_label = $VBoxContainer/HBoxContainer/AuthorLabel
@onready var timestamp_label = $VBoxContainer/HBoxContainer/TimestampLabel
@onready var content_label = $VBoxContainer/ContentLabel

# 條目數據
var entry_data: Dictionary = {}

func _ready():
	pass

# 設置條目數據
func set_entry_data(data: Dictionary):
	entry_data = data
	update_ui()

# 更新 UI 顯示
func update_ui():
	if entry_data.is_empty():
		visible = false
		return
		
	visible = true
	
	# 更新標籤
	author_label.text = entry_data.author
	content_label.text = entry_data.text
	
	# 格式化時間戳
	var datetime = Time.get_datetime_dict_from_unix_time(entry_data.timestamp)
	timestamp_label.text = "%04d-%02d-%02d %02d:%02d" % [
		datetime.year,
		datetime.month,
		datetime.day,
		datetime.hour,
		datetime.minute
	]
