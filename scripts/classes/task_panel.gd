extends Control
class_name TaskPanel

# UI 元素引用
@onready var daily_tasks_container = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/DailyTasks/ScrollContainer/VBoxContainer
@onready var achievements_container = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Achievements/ScrollContainer/VBoxContainer

# 場景引用
var task_item_scene = null

func _ready():
	print("TaskPanel _ready - 開始初始化")
	
	# 動態加載場景
	task_item_scene = load("res://scenes/ui/task_item.tscn")
	if not task_item_scene:
		push_error("無法加載 task_item.tscn 場景")
		return
	
	# 連接信號
	GameManager.connect("task_updated", Callable(self, "_on_task_updated"))
	GameManager.connect("task_completed", Callable(self, "_on_task_completed"))
	GameManager.connect("achievement_unlocked", Callable(self, "_on_achievement_unlocked"))
	
	# 加載任務和成就
	_load_daily_tasks()
	_load_achievements()
	
	print("TaskPanel _ready - 初始化完成")

# 顯示面板
func show_panel():
	visible = true
	_load_daily_tasks()
	_load_achievements()

# 隱藏面板
func hide_panel():
	visible = false

# 加載每日任務
func _load_daily_tasks():
	print("TaskPanel _load_daily_tasks - 開始加載每日任務")
	
	# 清空容器
	for child in daily_tasks_container.get_children():
		child.queue_free()
	
	# 添加每日任務
	var daily_tasks = GameManager.get_daily_tasks()
	if daily_tasks.is_empty():
		var empty_label = Label.new()
		empty_label.text = "今天沒有任務"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		daily_tasks_container.add_child(empty_label)
	else:
		for task in daily_tasks:
			var task_item = task_item_scene.instantiate()
			daily_tasks_container.add_child(task_item)
			task_item.setup(task)
			task_item.connect("claim_requested", Callable(self, "_on_claim_requested"))
			
			# 設置任務項目的大小
			task_item.custom_minimum_size = Vector2(700, 150)
	
	print("TaskPanel _load_daily_tasks - 加載完成")

# 加載成就
func _load_achievements():
	print("TaskPanel _load_achievements - 開始加載成就")
	
	# 清空容器
	for child in achievements_container.get_children():
		child.queue_free()
	
	# 添加成就
	var achievements = GameManager.get_achievements()
	if achievements.is_empty():
		var empty_label = Label.new()
		empty_label.text = "沒有可用的成就"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		achievements_container.add_child(empty_label)
	else:
		for achievement in achievements:
			var achievement_item = task_item_scene.instantiate()
			achievements_container.add_child(achievement_item)
			achievement_item.setup(achievement)
			achievement_item.connect("claim_requested", Callable(self, "_on_claim_requested"))
			
			# 設置成就項目的大小
			achievement_item.custom_minimum_size = Vector2(700, 150)
	
	print("TaskPanel _load_achievements - 加載完成")

# 任務更新信號處理
func _on_task_updated(task_id: String, progress: int, completed: bool):
	print("TaskPanel _on_task_updated - 任務更新: ", task_id, " 進度: ", progress, " 完成: ", completed)
	
	# 更新任務項目
	for child in daily_tasks_container.get_children():
		if child is TaskItem and child.task_data.id == task_id:
			child.update_progress(progress, completed)
			return
	
	# 更新成就項目
	for child in achievements_container.get_children():
		if child is TaskItem and child.task_data.id == task_id:
			child.update_progress(progress, completed)
			return
	
	# 如果找不到對應的項目，重新加載
	_load_daily_tasks()
	_load_achievements()

# 任務完成信號處理
func _on_task_completed(task_id: String, reward: int):
	print("TaskPanel _on_task_completed - 任務完成: ", task_id, " 獎勵: ", reward)
	
	# 顯示完成提示
	var task_name = ""
	for task in GameManager.get_daily_tasks():
		if task.id == task_id:
			task_name = task.title
			break
	
	if task_name:
		# 這裡可以添加任務完成的動畫或提示
		print("任務完成: ", task_name, " 獎勵: ", reward, " 貝殼")

# 成就解鎖信號處理
func _on_achievement_unlocked(achievement_id: String, reward: int):
	print("TaskPanel _on_achievement_unlocked - 成就解鎖: ", achievement_id, " 獎勵: ", reward)
	
	# 顯示解鎖提示
	var achievement_name = ""
	for achievement in GameManager.get_achievements():
		if achievement.id == achievement_id:
			achievement_name = achievement.title
			break
	
	if achievement_name:
		# 這裡可以添加成就解鎖的動畫或提示
		print("成就解鎖: ", achievement_name, " 獎勵: ", reward, " 貝殼")

# 領取獎勵請求處理
func _on_claim_requested(task_id: String):
	print("TaskPanel _on_claim_requested - 領取獎勵: ", task_id)
	
	if GameManager.claim_task_reward(task_id):
		# 更新 UI
		_load_daily_tasks()
		_load_achievements()
		print("獎勵領取成功")
	else:
		print("獎勵領取失敗")

# 關閉按鈕點擊處理
func _on_close_button_pressed():
	hide_panel() 