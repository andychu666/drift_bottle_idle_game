extends Control
class_name TaskItem

# UI 元素引用
@onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var progress_bar = $PanelContainer/MarginContainer/VBoxContainer/ProgressBar
@onready var progress_label = $PanelContainer/MarginContainer/VBoxContainer/ProgressLabel
@onready var reward_label = $PanelContainer/MarginContainer/VBoxContainer/RewardLabel
@onready var claim_button = $PanelContainer/MarginContainer/VBoxContainer/ClaimButton

# 任務數據
var task_data = {}

# 信號
signal claim_requested(task_id)

func _ready():
	claim_button.connect("pressed", Callable(self, "_on_claim_button_pressed"))

# 設置任務數據
func setup(data: Dictionary):
	task_data = data
	
	title_label.text = data.title
	description_label.text = data.description
	
	update_progress(data.progress, data.completed)
	
	reward_label.text = "獎勵: " + str(data.reward) + " 貝殼"
	
	# 如果已領取獎勵，禁用領取按鈕
	claim_button.disabled = not data.completed or data.claimed
	claim_button.text = "領取獎勵" if not data.claimed else "已領取"
	
	# 由於我們現在自動領取獎勵，可以隱藏已領取的任務的按鈕
	if data.claimed:
		claim_button.visible = false

# 更新進度
func update_progress(progress: int, completed: bool):
	task_data.progress = progress
	task_data.completed = completed
	
	progress_bar.max_value = task_data.target
	progress_bar.value = progress
	progress_label.text = str(progress) + "/" + str(task_data.target)
	
	# 如果已完成但未領取，啟用領取按鈕
	claim_button.disabled = not completed or task_data.claimed
	claim_button.text = "領取獎勵" if not task_data.claimed else "已領取"
	
	# 由於我們現在自動領取獎勵，可以隱藏已領取的任務的按鈕
	if task_data.claimed:
		claim_button.visible = false

# 領取按鈕點擊處理
func _on_claim_button_pressed():
	emit_signal("claim_requested", task_data.id) 