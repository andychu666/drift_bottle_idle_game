extends Window
class_name WriteDialog

# 信號
signal confirmed(text, author)

# UI 元素引用
@onready var text_edit = $VBoxContainer/TextEdit
@onready var author_edit = $VBoxContainer/HBoxContainer/AuthorEdit
@onready var confirm_button = $VBoxContainer/HBoxContainer/ConfirmButton
@onready var cancel_button = $VBoxContainer/HBoxContainer/CancelButton

func _ready():
	# 連接信號
	confirm_button.connect("pressed", Callable(self, "_on_confirm_button_pressed"))
	cancel_button.connect("pressed", Callable(self, "_on_cancel_button_pressed"))
	
	# 設置初始狀態
	text_edit.text = ""
	author_edit.text = "匿名"
	
	# 設置關閉請求處理
	connect("close_requested", Callable(self, "_on_close_requested"))

# 顯示對話框
func show_dialog():
	# 清空輸入
	text_edit.text = ""
	
	# 顯示窗口
	popup_centered()
	text_edit.grab_focus()

# 確認按鈕點擊
func _on_confirm_button_pressed():
	if text_edit.text.strip_edges().length() > 0:
		emit_signal("confirmed", text_edit.text.strip_edges(), author_edit.text.strip_edges())
		visible = false
	else:
		# 顯示錯誤提示
		OS.alert("請輸入內容", "錯誤")

# 取消按鈕點擊
func _on_cancel_button_pressed():
	visible = false

# 關閉請求
func _on_close_requested():
	visible = false 
