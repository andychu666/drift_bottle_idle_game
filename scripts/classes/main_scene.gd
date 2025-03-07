extends Control
class_name MainScene

# 常量
const DIG_COST: float = 10.0  # 挖掘漂流瓶所需的能量

# UI 元素引用
@onready var energy_bar = $TopBar/EnergyBar
@onready var energy_label = $TopBar/EnergyLabel
@onready var shells_label = $TopBar/ShellsLabel
@onready var dig_button = $ControlPanel/DigButton
@onready var bottles_container = $BottlesContainer
@onready var write_dialog = $WriteDialog
@onready var area_selector = $ControlPanel/AreaSelector
@onready var upgrade_button = $ControlPanel/UpgradeButton
@onready var upgrade_panel = $UpgradePanel
@onready var river_bottles_label = $TopBar/RiverBottlesLabel
@onready var stats_panel = $StatsPanel
@onready var collection_button = $ControlPanel/CollectionButton
@onready var collection_panel = $CollectionPanel
@onready var collection_bottles_container = $CollectionPanel/VBoxContainer/ScrollContainer/BottlesContainer
@onready var task_button = $ControlPanel/TaskButton
@onready var task_panel = $TaskPanel

# 預加載場景
var bottle_ui_scene = preload("res://scenes/ui/bottle_ui.tscn")
var current_bottle_ui = null

# 當前選中的漂流瓶 ID
var selected_bottle_id: int = -1

func _ready():
	print("MainScene _ready - 開始初始化")
	
	# 確保 GameManager 已經初始化
	if not GameManager:
		push_error("GameManager not found!")
		return
	
	# 嘗試加載遊戲
	GameManager.load_game()
	
	# 連接信號
	GameManager.connect("energy_changed", Callable(self, "_on_energy_changed"))
	GameManager.connect("shells_changed", Callable(self, "_on_shells_changed"))
	GameManager.connect("bottle_added", Callable(self, "_on_bottle_added"))
	GameManager.connect("area_unlocked", Callable(self, "_on_area_unlocked"))
	GameManager.connect("river_bottles_changed", Callable(self, "_on_river_bottles_changed"))
	GameManager.connect("bottle_stats_changed", Callable(self, "_on_bottle_stats_updated"))
	GameManager.connect("task_completed", Callable(self, "_on_task_completed"))
	GameManager.connect("achievement_unlocked", Callable(self, "_on_achievement_unlocked"))
	
	print("MainScene _ready - 信號連接完成")
	
	dig_button.connect("pressed", Callable(self, "_on_dig_button_pressed"))
	write_dialog.connect("confirmed", Callable(self, "_on_write_dialog_confirmed"))
	
	# 檢查任務按鈕是否存在
	if task_button:
		task_button.connect("pressed", Callable(self, "_on_task_button_pressed"))
	else:
		push_warning("TaskButton 節點不存在，請在場景中添加此節點")
	
	print("MainScene _ready - 按鈕信號連接完成")
	
	# 初始化 UI
	_update_energy_ui(GameManager.energy, GameManager.max_energy)
	_update_shells_ui(GameManager.shells)
	_update_areas_ui()
	_update_river_bottles_ui(GameManager.river_bottles.size())
	_update_stats_ui()
	
	print("MainScene _ready - UI 初始化完成")
	
	# 加載現有漂流瓶
	_load_current_bottles()
	
	print("MainScene _ready - 漂流瓶加載完成")
	
	# 添加調試輸出
	print("Energy: ", GameManager.energy, "/", GameManager.max_energy)
	print("Current bottles: ", GameManager.current_bottles.size())
	print("Storage capacity: ", GameManager.storage_capacity)
	print("River bottles: ", GameManager.river_bottles)
	print("Dig button disabled: ", GameManager.energy < DIG_COST or GameManager.current_bottles.size() >= GameManager.storage_capacity)
	print("Unlocked areas: ", GameManager.unlocked_areas)
	
	print("MainScene _ready - 初始化完成")

# 更新能量 UI
func _update_energy_ui(current: float, maximum: float):
	energy_bar.max_value = maximum
	energy_bar.value = current
	energy_label.text = "能量: %.0f/%.0f" % [current, maximum]
	
	# 如果能量不足，禁用挖掘按鈕
	dig_button.disabled = current < DIG_COST or GameManager.current_bottles.size() >= GameManager.storage_capacity
	
	# 添加調試輸出
	print("更新能量 UI - Energy: ", current, "/", maximum)
	print("更新能量 UI - Current bottles: ", GameManager.current_bottles.size())
	print("更新能量 UI - Storage capacity: ", GameManager.storage_capacity)
	print("更新能量 UI - Dig button disabled: ", current < DIG_COST or GameManager.current_bottles.size() >= GameManager.storage_capacity)

# 更新貝殼 UI
func _update_shells_ui(amount: int):
	shells_label.text = str(amount)

# 更新區域 UI
func _update_areas_ui():
	area_selector.clear()
	
	for area_id in GameManager.unlocked_areas:
		if GameManager.unlocked_areas[area_id]:
			var area_name = _get_area_display_name(area_id)
			area_selector.add_item(area_name, area_id.hash())

# 加載當前漂流瓶
func _load_current_bottles():
	# 清空容器
	for child in bottles_container.get_children():
		child.queue_free()
	
	# 添加當前漂流瓶
	for bottle in GameManager.current_bottles:
		_add_bottle_ui(bottle)
	
	# 添加調試輸出
	print("加載當前漂流瓶 - Current bottles: ", GameManager.current_bottles.size())

# 添加漂流瓶 UI
func _add_bottle_ui(bottle_data: Dictionary):
	print("添加瓶子 UI，瓶子數據: ", bottle_data)
	
	var bottle_ui = bottle_ui_scene.instantiate()
	bottles_container.add_child(bottle_ui)
	
	# 確保瓶子有 ID
	if not bottle_data.has("id"):
		bottle_data["id"] = randi()
		print("瓶子沒有 ID，生成新 ID: ", bottle_data.id)
	
	print("設置瓶子 UI，ID: ", bottle_data.id, " 類型: ", typeof(bottle_data.id))
	bottle_ui.setup(bottle_data)
	bottle_ui.connect("write_requested", Callable(self, "_on_write_requested"))
	bottle_ui.connect("skip_requested", Callable(self, "_on_skip_requested"))

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

# 挖掘按鈕點擊
func _on_dig_button_pressed():
	print("點擊挖掘按鈕")
	print("當前能量: ", GameManager.energy, " 當前瓶子數量: ", GameManager.current_bottles.size())
	
	# 檢查是否有足夠的能量和空間
	if GameManager.energy < DIG_COST or GameManager.current_bottles.size() >= GameManager.storage_capacity:
		print("能量不足或存儲空間已滿，無法挖掘")
		return
	
	# 挖出一個瓶子
	var bottle = GameManager.dig_bottle()
	if bottle.is_empty():
		print("挖掘失敗，沒有瓶子")
		return
	
	print("成功挖掘瓶子: ", bottle)
	
	# 更新瓶子 UI
	_load_current_bottles()
	
	# 更新能量顯示
	energy_label.text = "能量: %.0f/%.0f" % [GameManager.energy, GameManager.max_energy]
	
	# 更新漂流河瓶子數量
	river_bottles_label.text = "漂流河瓶子: %d/%d" % [GameManager.river_bottles.size(), GameManager.river_bottle_limit]
	
	print("挖掘完成，當前瓶子: ", GameManager.current_bottles)
	print("漂流河瓶子: ", GameManager.river_bottles.size())

# 播放挖掘動畫
func _play_dig_animation():
	# 這裡可以添加挖掘動畫
	# 簡單起見，我們只是延遲一下
	await get_tree().create_timer(0.5).timeout
	
	# 更新 UI
	_update_energy_ui(GameManager.energy, GameManager.max_energy)
	_load_current_bottles()

# 寫入請求
func _on_write_requested(bottle_id: int):
	print("收到寫入請求，瓶子 ID: ", bottle_id)
	print("當前持有的瓶子: ", GameManager.current_bottles)
	
	# 檢查瓶子 ID 是否存在
	var bottle_found = false
	for bottle in GameManager.current_bottles:
		print("檢查瓶子: ", bottle.id, " 類型: ", typeof(bottle.id))
		if bottle.id == bottle_id:
			bottle_found = true
			print("找到匹配的瓶子!")
			break
	
	if not bottle_found:
		print("警告: 找不到 ID 為 ", bottle_id, " 的瓶子，類型: ", typeof(bottle_id))
	
	selected_bottle_id = bottle_id
	write_dialog.show_dialog()

# 寫入對話框確認
func _on_write_dialog_confirmed(text: String, author: String):
	if selected_bottle_id >= 0:
		print("寫入瓶子 ID: ", selected_bottle_id, " 類型: ", typeof(selected_bottle_id))
		
		# 直接調用 GameManager 的 write_to_bottle 函數
		var success = GameManager.write_to_bottle(selected_bottle_id, text, author)
		
		if success:
			print("寫入成功")
			# 更新 UI
			_load_current_bottles()
		else:
			print("寫入失敗，找不到瓶子 ID: ", selected_bottle_id)
			# 打印所有瓶子 ID
			var all_ids = []
			for b in GameManager.current_bottles:
				all_ids.append(b.id)
			print("所有瓶子 ID: ", all_ids)
		
		selected_bottle_id = -1

# 能量變化信號處理
func _on_energy_changed(current: float, maximum: float):
	_update_energy_ui(current, maximum)

# 貝殼變化信號處理
func _on_shells_changed(amount: int):
	_update_shells_ui(amount)

# 漂流瓶添加信號處理
func _on_bottle_added(_bottle: Dictionary):
	_load_current_bottles()

# 區域解鎖信號處理
func _on_area_unlocked(_area_id: String):
	_update_areas_ui()

# 打開收藏面板
func _on_collection_button_pressed():
	collection_panel.show()
	_update_collection_panel()

# 更新收藏面板
func _update_collection_panel():
	# 清空現有瓶子
	for child in collection_bottles_container.get_children():
		child.queue_free()
	
	# 添加已收集的瓶子
	if GameManager.collected_bottles.is_empty():
		var empty_label = Label.new()
		empty_label.text = "尚未收藏任何瓶子"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		collection_bottles_container.add_child(empty_label)
	else:
		for bottle in GameManager.collected_bottles:
			var bottle_ui = bottle_ui_scene.instantiate()
			collection_bottles_container.add_child(bottle_ui)
			bottle_ui.setup(bottle)
			bottle_ui.set_read_only(true)  # 設置為只讀模式

# 更新漂流河瓶子數量 UI
func _update_river_bottles_ui(amount: int):
	river_bottles_label.text = "漂流河: " + str(amount) + "/" + str(GameManager.river_bottle_limit)
	# 如果漂流河中沒有瓶子，禁用挖掘按鈕
	dig_button.disabled = amount <= 0 or GameManager.energy < DIG_COST or GameManager.current_bottles.size() >= GameManager.storage_capacity

# 漂流河瓶子數量變化信號處理
func _on_river_bottles_changed(amount: int):
	_update_river_bottles_ui(amount)

# 更新統計數據 UI
func _update_stats_ui():
	print("MainScene _update_stats_ui - 開始更新統計 UI")
	var stats = GameManager.get_bottle_stats()
	print("MainScene _update_stats_ui - 獲取到的統計數據: ", stats)
	
	var stats_text = "漂流瓶統計:\n"
	
	for i in range(1, 11):
		stats_text += "寫入 %d 次: %d 個\n" % [i, stats[i]]
	
	stats_panel.text = stats_text
	print("MainScene _update_stats_ui - 更新完成")

# 統計數據變化信號處理
func _on_bottle_stats_updated():
	print("MainScene _on_bottle_stats_updated - 收到統計數據變化信號")
	_update_stats_ui()

# 保存按鈕點擊處理
func _on_save_button_pressed():
	GameManager.save_game()
	print("遊戲已保存")

# 升級按鈕點擊處理
func _on_upgrade_button_pressed():
	print("MainScene _on_upgrade_button_pressed - 打開升級面板")
	upgrade_panel.show_panel()  # 調用 show_panel 方法而不是 show

# 跳過請求
func _on_skip_requested(bottle_id: int):
	if bottle_id >= 0:
		print("跳過瓶子 ID: ", bottle_id, " 類型: ", typeof(bottle_id))
		print("當前持有的瓶子: ", GameManager.current_bottles)
		
		# 查找瓶子
		var bottle = null
		var bottle_index = -1
		
		for i in range(GameManager.current_bottles.size()):
			var b = GameManager.current_bottles[i]
			print("檢查瓶子: ", b.id, " 類型: ", typeof(b.id))
			# 嘗試不同的比較方式
			if str(b.id) == str(bottle_id):
				bottle = b
				bottle_index = i
				print("找到匹配的瓶子! (字符串比較) 索引: ", i)
				break
		
		if bottle:
			print("找到瓶子: ", bottle)
			
			# 從當前瓶子列表中移除
			if bottle_index >= 0:
				# 保存瓶子的引用，而不是移除後再添加新的
				var bottle_to_return = GameManager.current_bottles[bottle_index]
				GameManager.current_bottles.remove_at(bottle_index)
				print("從當前瓶子列表中移除，剩餘: ", GameManager.current_bottles)
			
				# 返回河中，保留所有內容
				print("瓶子跳過，返回河中")
				GameManager.river_bottles.append(bottle_to_return)
				GameManager.emit_signal("river_bottles_changed", GameManager.river_bottles.size())
				
				# 更新統計數據
				GameManager.update_bottle_stats()
			
			# 更新 UI
			_load_current_bottles()
			
			print("跳過完成，當前瓶子: ", GameManager.current_bottles)
			print("漂流河瓶子: ", GameManager.river_bottles.size())
		else:
			print("找不到瓶子 ID: ", bottle_id)
			# 打印所有瓶子 ID
			var all_ids = []
			for b in GameManager.current_bottles:
				all_ids.append(b.id)
			print("所有瓶子 ID: ", all_ids)
		
		selected_bottle_id = -1

# 更新單個瓶子 UI
func _update_bottle_ui(bottle_id_or_bottle):
	var bottle = null
	
	# 檢查參數類型
	if typeof(bottle_id_or_bottle) == TYPE_INT:
		# 如果是整數 ID，通過 ID 獲取瓶子
		for b in GameManager.current_bottles:
			if str(b.id) == str(bottle_id_or_bottle):
				bottle = b
				break
	elif typeof(bottle_id_or_bottle) == TYPE_DICTIONARY:
		# 如果是字典，直接使用
		bottle = bottle_id_or_bottle
	
	if not bottle or bottle.is_empty():
		if typeof(bottle_id_or_bottle) == TYPE_INT:
			_remove_bottle_ui(bottle_id_or_bottle)
		return
	
	# 更新或創建瓶子 UI
	var bottle_ui = _get_bottle_ui_by_id(bottle.id)
	if bottle_ui:
		bottle_ui.setup(bottle)
	else:
		_add_bottle_ui(bottle)

# 移除單個瓶子 UI
func _remove_bottle_ui(bottle_id: int):
	var bottle_ui = _get_bottle_ui_by_id(bottle_id)
	if bottle_ui:
		bottle_ui.queue_free()

# 通過 ID 獲取瓶子 UI
func _get_bottle_ui_by_id(bottle_id) -> Node:
	for child in bottles_container.get_children():
		if child is BottleUI and str(child.bottle_data.id) == str(bottle_id):
			return child
	return null

# 任務按鈕點擊處理
func _on_task_button_pressed():
	print("MainScene _on_task_button_pressed - 打開任務面板")
	if task_panel:
		task_panel.show_panel()
	else:
		push_warning("TaskPanel 節點不存在，請在場景中添加此節點")
		print("請在 main_scene.tscn 中添加 TaskPanel 節點")

# 任務完成信號處理
func _on_task_completed(task_id: String, reward: int):
	print("MainScene _on_task_completed - 任務完成: ", task_id, " 獎勵: ", reward)
	
	# 顯示任務完成提示
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
	print("MainScene _on_achievement_unlocked - 成就解鎖: ", achievement_id, " 獎勵: ", reward)
	
	# 顯示成就解鎖提示
	var achievement_name = ""
	for achievement in GameManager.get_achievements():
		if achievement.id == achievement_id:
			achievement_name = achievement.title
			break
	
	if achievement_name:
		# 這裡可以添加成就解鎖的動畫或提示
		print("成就解鎖: ", achievement_name, " 獎勵: ", reward, " 貝殼")
