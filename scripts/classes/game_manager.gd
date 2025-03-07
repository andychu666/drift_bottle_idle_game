extends Node

# 靜態常量
const DIG_COST: float = 10.0  # 挖掘漂流瓶所需的能量

# 信號
signal energy_changed(current: float, maximum: float)
signal shells_changed(amount: int)
signal bottle_added(bottle: Dictionary)
signal bottle_discarded(bottle: Dictionary)
signal area_unlocked(area_id: String)
signal river_bottles_changed(amount: int)
signal bottle_stats_updated(stats: Dictionary)
signal task_updated(task_id: String, progress: int, completed: bool)
signal task_completed(task_id: String, reward: int)
signal achievement_unlocked(achievement_id: String, reward: int)

# 遊戲數據
var energy: float = 100.0
var max_energy: float = 100.0
var shells: int = 0
var storage_capacity: int = 5
var river_bottle_limit: int = 20
var digging_level: int = 1  # 新增：挖掘等級

# 漂流瓶數據
var current_bottles: Array = []
var river_bottles: Array = []
var collected_bottles: Array = []

# 區域數據
var areas = {
	"beach": {"name": "沙灘", "cost": 0},
	"reef": {"name": "珊瑚礁", "cost": 1000},
	"deep_sea": {"name": "深海", "cost": 5000},
	"island": {"name": "孤島", "cost": 10000},
	"arctic": {"name": "極地", "cost": 20000}
}

var unlocked_areas: Dictionary = {
	"beach": true,
	"reef": false,
	"deep_sea": false,
	"island": false,
	"arctic": false
}

# 任務系統數據
var daily_tasks: Array = []
var achievements: Array = []
var total_bottles_written: int = 0
var total_bottles_collected: int = 0
var total_bottles_dug: int = 0
var last_daily_reset: int = 0

func _ready():
	print("GameManager _ready - 開始初始化")
	
	# 強制設置初始能量為 100.0
	energy = 100.0
	max_energy = 100.0
	print("GameManager _ready - 初始能量設置為: ", energy, "/", max_energy)
	
	# 初始化漂流瓶
	_init_river_bottles()
	
	# 初始化任務系統
	_init_task_system()
	
	# 加載遊戲
	load_game()
	
	# 再次確保能量不低於 100.0
	if energy < 100.0:
		energy = 100.0
	if max_energy < 100.0:
		max_energy = 100.0
	
	print("GameManager _ready - 最終能量值: ", energy, "/", max_energy)
	
	# 發送所有信號，確保 UI 顯示正確
	emit_signal("energy_changed", energy, max_energy)
	emit_signal("shells_changed", shells)
	emit_signal("river_bottles_changed", river_bottles.size())
	_update_bottle_stats()
	
	print("GameManager _ready - 初始化完成")

func _init_river_bottles():
	# 確保 river_bottles 是數組
	if typeof(river_bottles) != TYPE_ARRAY:
		river_bottles = []
	
	# 清空現有瓶子
	river_bottles.clear()
	
	# 初始化河中的瓶子
	var themes = ["夏日", "海洋", "回憶", "友情", "旅行"]
	
	for i in range(river_bottle_limit):
		var bottle = {
			"id": randi(),
			"area": "beach",
			"theme": themes[randi() % themes.size()],
			"content": [],
			"max_entries": 10,
			"current_entries": 0,
			"created_at": Time.get_unix_time_from_system()
		}
		river_bottles.append(bottle)
	
	# 發送信號更新漂流河瓶子數量
	emit_signal("river_bottles_changed", river_bottles.size())

func dig_bottle() -> Dictionary:
	print("GameManager dig_bottle - 開始挖掘漂流瓶")
	print("GameManager dig_bottle - 當前能量: ", energy, " 當前瓶子數量: ", current_bottles.size())
	
	if river_bottles.is_empty():
		print("GameManager dig_bottle - 漂流河中沒有瓶子")
		return {}
	
	# 檢查存儲容量
	if current_bottles.size() >= storage_capacity:
		print("GameManager dig_bottle - 存儲空間已滿")
		return {}
	
	# 檢查能量
	if energy < DIG_COST:
		print("GameManager dig_bottle - 能量不足")
		return {}
	
	# 挖出瓶子
	var bottle = river_bottles.pop_back()
	current_bottles.append(bottle)
	
	print("GameManager dig_bottle - 成功挖掘漂流瓶，剩餘漂流瓶: ", river_bottles.size())
	print("GameManager dig_bottle - 當前持有瓶子: ", current_bottles)
	
	# 更新能量，確保不會變成負數
	energy = max(0.0, energy - DIG_COST)
	emit_signal("energy_changed", energy, max_energy)
	
	# 發送信號更新漂流河瓶子數量
	emit_signal("river_bottles_changed", river_bottles.size())
	
	# 更新任務進度
	update_task_progress("dig")
	
	return bottle

func write_to_bottle(bottle_id: int, text: String, author: String):
	print("GameManager write_to_bottle - 開始寫入瓶子，ID: ", bottle_id)
	
	# 查找瓶子
	var bottle = null
	var bottle_index = -1
	
	for i in range(current_bottles.size()):
		var b = current_bottles[i]
		if str(b.id) == str(bottle_id):
			bottle = b
			bottle_index = i
			print("GameManager write_to_bottle - 找到匹配的瓶子! 索引: ", i)
			break
	
	if bottle:
		print("GameManager write_to_bottle - 找到瓶子: ", bottle)
		
		# 創建新條目
		var entry = {
			"text": text,
			"author": author,
			"timestamp": Time.get_unix_time_from_system()
		}
		
		# 檢查瓶子是否有 content 字段
		if not bottle.has("content"):
			bottle["content"] = []
		
		bottle.content.append(entry)
		
		# 更新 current_entries
		if not bottle.has("current_entries"):
			bottle["current_entries"] = 0
		bottle.current_entries += 1
		
		print("GameManager write_to_bottle - 瓶子寫入後: ", bottle)
		
		# 從當前瓶子列表中移除
		if bottle_index >= 0:
			var bottle_to_return = current_bottles[bottle_index]
			current_bottles.remove_at(bottle_index)
			print("GameManager write_to_bottle - 從當前瓶子列表中移除，剩餘: ", current_bottles)
		
			# 如果瓶子已滿，收集它
			if bottle_to_return.current_entries >= bottle_to_return.max_entries:
				print("GameManager write_to_bottle - 瓶子已滿，收集它")
				collected_bottles.append(bottle_to_return)
				
				# 獎勵貝殼
				var reward = bottle_to_return.current_entries * 10
				shells += reward
				emit_signal("shells_changed", shells)
				
				# 更新收集任務進度
				update_task_progress("collect")
			else:
				# 否則返回河中，保留所有內容
				print("GameManager write_to_bottle - 瓶子未滿，返回河中")
				river_bottles.append(bottle_to_return)
				emit_signal("river_bottles_changed", river_bottles.size())
		
		# 更新寫入任務進度
		update_task_progress("write")
		
		_update_bottle_stats()
		print("GameManager write_to_bottle - 寫入完成")
		return true
	else:
		print("GameManager write_to_bottle - 找不到瓶子 ID: ", bottle_id)
		return false

func return_bottle_to_river(bottle: Dictionary):
	print("GameManager return_bottle_to_river - 開始返回瓶子到河中")
	
	# 查找瓶子在當前列表中的索引
	var bottle_index = -1
	for i in range(current_bottles.size()):
		if current_bottles[i].id == bottle.id:
			bottle_index = i
			break
	
	# 如果找到瓶子，從當前列表中移除
	if bottle_index >= 0:
		var bottle_to_return = current_bottles[bottle_index]
		current_bottles.remove_at(bottle_index)
		
		# 將瓶子添加到河中，保留其內容
		river_bottles.append(bottle_to_return)
		print("GameManager return_bottle_to_river - 瓶子已返回河中，內容保留")
	else:
		# 如果沒有找到，直接添加到河中
		river_bottles.append(bottle)
		print("GameManager return_bottle_to_river - 瓶子直接添加到河中")
	
	# 發送信號更新 UI
	emit_signal("river_bottles_changed", river_bottles.size())
	print("GameManager return_bottle_to_river - 完成")

func collect_bottle(bottle: Dictionary):
	print("GameManager collect_bottle - 開始收集瓶子")
	
	# 查找瓶子在當前列表中的索引
	var bottle_index = -1
	for i in range(current_bottles.size()):
		if current_bottles[i].id == bottle.id:
			bottle_index = i
			break
	
	# 如果找到瓶子，從當前列表中移除
	if bottle_index >= 0:
		var bottle_to_collect = current_bottles[bottle_index]
		current_bottles.remove_at(bottle_index)
		
		# 將瓶子添加到收集列表
		collected_bottles.append(bottle_to_collect)
		print("GameManager collect_bottle - 瓶子已添加到收集列表")
		
		# 獎勵貝殼
		var entries_count = bottle_to_collect.current_entries if bottle_to_collect.has("current_entries") else (bottle_to_collect.content.size() if bottle_to_collect.has("content") else 0)
		var reward = entries_count * 10
		shells += reward
		print("GameManager collect_bottle - 獎勵貝殼: ", reward, " 總貝殼: ", shells)
	else:
		# 如果沒有找到，直接添加到收集列表
		collected_bottles.append(bottle)
		
		# 獎勵貝殼
		var entries_count = bottle.current_entries if bottle.has("current_entries") else (bottle.content.size() if bottle.has("content") else 0)
		var reward = entries_count * 10
		shells += reward
		print("GameManager collect_bottle - 直接收集瓶子，獎勵貝殼: ", reward, " 總貝殼: ", shells)
	
	# 更新任務進度
	update_task_progress("collect")
	
	# 發送信號更新 UI
	emit_signal("shells_changed", shells)
	print("GameManager collect_bottle - 完成")

func unlock_area(area_id: String, cost: int = 0) -> bool:
	print("GameManager unlock_area - 嘗試解鎖區域: ", area_id, " 成本: ", cost)
	
	if not areas.has(area_id) or unlocked_areas[area_id]:
		print("GameManager unlock_area - 區域不存在或已解鎖")
		return false
	
	# 如果沒有提供成本，使用預設成本
	if cost <= 0:
		cost = areas[area_id].cost
	
	if shells >= cost:
		shells -= cost
		unlocked_areas[area_id] = true
		emit_signal("area_unlocked", area_id)
		emit_signal("shells_changed", shells)
		print("GameManager unlock_area - 成功解鎖區域: ", area_id)
		return true
	
	print("GameManager unlock_area - 貝殼不足，無法解鎖")
	return false

func _update_bottle_stats():
	var stats = {}
	for i in range(1, 11):
		stats[i] = 0
	
	# 統計河中的瓶子
	for bottle in river_bottles:
		if bottle.has("content") and not bottle.content.is_empty():
			var entry_count = bottle.content.size()
			if entry_count > 0 and entry_count <= 10:
				stats[entry_count] += 1
		elif bottle.has("current_entries") and bottle.current_entries > 0:
			var entry_count = bottle.current_entries
			if entry_count <= 10:
				stats[entry_count] += 1
	
	# 統計當前持有的瓶子
	for bottle in current_bottles:
		if bottle.has("content") and not bottle.content.is_empty():
			var entry_count = bottle.content.size()
			if entry_count > 0 and entry_count <= 10:
				stats[entry_count] += 1
		elif bottle.has("current_entries") and bottle.current_entries > 0:
			var entry_count = bottle.current_entries
			if entry_count <= 10:
				stats[entry_count] += 1
	
	emit_signal("bottle_stats_updated", stats)

func get_bottle_stats() -> Dictionary:
	print("GameManager get_bottle_stats - 開始獲取瓶子統計")
	var stats = {}
	for i in range(1, 11):
		stats[i] = 0
	
	# 統計河中的瓶子
	for bottle in river_bottles:
		if bottle.has("content") and not bottle.content.is_empty():
			var entry_count = bottle.content.size()
			if entry_count > 0 and entry_count <= 10:
				stats[entry_count] += 1
				print("GameManager get_bottle_stats - 河中瓶子 ID: ", bottle.id, " 條目數: ", entry_count)
		elif bottle.has("current_entries") and bottle.current_entries > 0:
			var entry_count = bottle.current_entries
			if entry_count <= 10:
				stats[entry_count] += 1
				print("GameManager get_bottle_stats - 河中瓶子 ID: ", bottle.id, " 條目數: ", entry_count)
	
	# 統計當前持有的瓶子
	for bottle in current_bottles:
		if bottle.has("content") and not bottle.content.is_empty():
			var entry_count = bottle.content.size()
			if entry_count > 0 and entry_count <= 10:
				stats[entry_count] += 1
				print("GameManager get_bottle_stats - 當前持有瓶子 ID: ", bottle.id, " 條目數: ", entry_count)
		elif bottle.has("current_entries") and bottle.current_entries > 0:
			var entry_count = bottle.current_entries
			if entry_count <= 10:
				stats[entry_count] += 1
				print("GameManager get_bottle_stats - 當前持有瓶子 ID: ", bottle.id, " 條目數: ", entry_count)
	
	# 統計已收集的瓶子
	for bottle in collected_bottles:
		if bottle.has("content") and not bottle.content.is_empty():
			var entry_count = bottle.content.size()
			if entry_count > 0 and entry_count <= 10:
				stats[entry_count] += 1
				print("GameManager get_bottle_stats - 已收集瓶子 ID: ", bottle.id, " 條目數: ", entry_count)
		elif bottle.has("current_entries") and bottle.current_entries > 0:
			var entry_count = bottle.current_entries
			if entry_count <= 10:
				stats[entry_count] += 1
				print("GameManager get_bottle_stats - 已收集瓶子 ID: ", bottle.id, " 條目數: ", entry_count)
	
	print("GameManager get_bottle_stats - 統計結果: ", stats)
	return stats

func save_game():
	var save_data = {
		"energy": energy,
		"max_energy": max_energy,
		"shells": shells,
		"storage_capacity": storage_capacity,
		"river_bottle_limit": river_bottle_limit,
		"current_bottles": current_bottles,
		"river_bottles": river_bottles,
		"collected_bottles": collected_bottles,
		"unlocked_areas": unlocked_areas,
		"digging_level": digging_level,
		# 任務系統數據
		"daily_tasks": daily_tasks,
		"achievements": achievements,
		"total_bottles_written": total_bottles_written,
		"total_bottles_collected": total_bottles_collected,
		"total_bottles_dug": total_bottles_dug,
		"last_daily_reset": last_daily_reset
	}
	
	var save_file = FileAccess.open("user://save.json", FileAccess.WRITE)
	save_file.store_string(JSON.stringify(save_data))

func load_game():
	if not FileAccess.file_exists("user://save.json"):
		print("GameManager load_game - 沒有找到存檔文件，使用默認值")
		# 如果是新遊戲，不需要重新設置能量，因為 _ready 已經設置過了
		return
	
	print("GameManager load_game - 找到存檔文件，開始加載")
	var save_file = FileAccess.open("user://save.json", FileAccess.READ)
	var json_string = save_file.get_as_text()
	var save_data = JSON.parse_string(json_string)
	
	if save_data:
		print("GameManager load_game - 成功解析存檔數據")
		# 加載能量，確保不低於 100
		energy = max(100.0, save_data.get("energy", 100.0))
		max_energy = max(100.0, save_data.get("max_energy", 100.0))
		print("GameManager load_game - 加載能量: ", energy, "/", max_energy)
		
		# 加載其他數據
		shells = save_data.get("shells", 0)
		storage_capacity = save_data.get("storage_capacity", 5)
		river_bottle_limit = save_data.get("river_bottle_limit", 20)
		current_bottles = save_data.get("current_bottles", [])
		river_bottles = save_data.get("river_bottles", [])
		collected_bottles = save_data.get("collected_bottles", [])
		unlocked_areas = save_data.get("unlocked_areas", {
			"beach": true,
			"reef": false,
			"deep_sea": false,
			"island": false,
			"arctic": false
		})
		digging_level = save_data.get("digging_level", 1)
		
		# 如果河中的瓶子為空，重新初始化
		if typeof(river_bottles) != TYPE_ARRAY or river_bottles.is_empty():
			print("GameManager load_game - 河中瓶子為空，重新初始化")
			_init_river_bottles()
		
		# 加載任務系統數據
		daily_tasks = save_data.get("daily_tasks", [])
		achievements = save_data.get("achievements", [])
		total_bottles_written = save_data.get("total_bottles_written", 0)
		total_bottles_collected = save_data.get("total_bottles_collected", 0)
		total_bottles_dug = save_data.get("total_bottles_dug", 0)
		last_daily_reset = save_data.get("last_daily_reset", 0)
		
		# 檢查是否需要重置每日任務
		var current_time = Time.get_unix_time_from_system()
		var day_seconds = 86400  # 一天的秒數
		if current_time - last_daily_reset > day_seconds:
			print("GameManager load_game - 需要重置每日任務")
			_reset_daily_tasks()
			last_daily_reset = current_time
		
		# 不在這裡發送信號，統一在 _ready 的最後發送
		print("GameManager load_game - 加載完成")
	else:
		print("GameManager load_game - 解析存檔數據失敗")

# 升級相關函數
func upgrade_digging(cost: int) -> bool:
	print("GameManager upgrade_digging - 嘗試升級挖掘等級，當前等級: ", digging_level, " 成本: ", cost, " 當前貝殼: ", shells)
	
	if shells >= cost:
		shells -= cost
		digging_level += 1
		# 增加最大能量
		max_energy += 20.0
		# 恢復能量
		energy = max_energy
		
		print("GameManager upgrade_digging - 升級成功，新等級: ", digging_level, " 新能量: ", energy, "/", max_energy, " 剩餘貝殼: ", shells)
		
		# 檢查升級成就
		for achievement in achievements:
			if achievement.type == "digging_level" and digging_level >= achievement.target and not achievement.completed:
				achievement.progress = digging_level
				achievement.completed = true
				emit_signal("achievement_unlocked", achievement.id, achievement.reward)
				print("GameManager upgrade_digging - 成就解鎖: ", achievement.title)
				emit_signal("task_updated", achievement.id, achievement.progress, achievement.completed)
		
		emit_signal("shells_changed", shells)
		emit_signal("energy_changed", energy, max_energy)
		return true
	
	print("GameManager upgrade_digging - 貝殼不足，無法升級")
	return false

func upgrade_storage(cost: int) -> bool:
	print("GameManager upgrade_storage - 嘗試升級存儲容量，當前容量: ", storage_capacity, " 成本: ", cost, " 當前貝殼: ", shells)
	
	if shells >= cost:
		shells -= cost
		storage_capacity += 2
		
		print("GameManager upgrade_storage - 升級成功，新容量: ", storage_capacity, " 剩餘貝殼: ", shells)
		
		emit_signal("shells_changed", shells)
		return true
	
	print("GameManager upgrade_storage - 貝殼不足，無法升級")
	return false

func spend_shells(amount: int) -> bool:
	if shells >= amount:
		shells -= amount
		emit_signal("shells_changed", shells)
		return true
	return false

# 通過 ID 獲取瓶子
func get_bottle_by_id(bottle_id: int) -> Dictionary:
	# 在當前持有的瓶子中查找
	for bottle in current_bottles:
		if bottle.id == bottle_id:
			return bottle
	
	# 在河中的瓶子中查找
	for bottle in river_bottles:
		if bottle.id == bottle_id:
			return bottle
	
	# 在已收集的瓶子中查找
	for bottle in collected_bottles:
		if bottle.id == bottle_id:
			return bottle
	
	return {}

# 任務系統相關函數

# 初始化任務系統
func _init_task_system():
	print("GameManager _init_task_system - 開始初始化任務系統")
	
	# 檢查是否需要重置每日任務
	var current_time = Time.get_unix_time_from_system()
	var day_seconds = 86400  # 一天的秒數
	
	if current_time - last_daily_reset > day_seconds:
		_reset_daily_tasks()
		last_daily_reset = current_time
	
	# 如果任務列表為空，初始化任務
	if daily_tasks.is_empty():
		_create_daily_tasks()
	
	# 如果成就列表為空，初始化成就
	if achievements.is_empty():
		_create_achievements()
	
	print("GameManager _init_task_system - 任務系統初始化完成")

# 重置每日任務
func _reset_daily_tasks():
	print("GameManager _reset_daily_tasks - 重置每日任務")
	daily_tasks.clear()
	_create_daily_tasks()

# 創建每日任務
func _create_daily_tasks():
	print("GameManager _create_daily_tasks - 創建每日任務")
	
	# 任務1：寫入漂流瓶
	daily_tasks.append({
		"id": "daily_write",
		"title": "每日寫入",
		"description": "今天寫入 3 次漂流瓶",
		"type": "write",
		"target": 3,
		"progress": 0,
		"completed": false,
		"claimed": false,
		"reward": 50  # 獎勵貝殼數量
	})
	
	# 任務2：挖掘漂流瓶
	daily_tasks.append({
		"id": "daily_dig",
		"title": "每日挖掘",
		"description": "今天挖掘 5 個漂流瓶",
		"type": "dig",
		"target": 5,
		"progress": 0,
		"completed": false,
		"claimed": false,
		"reward": 30
	})
	
	# 任務3：收藏漂流瓶
	daily_tasks.append({
		"id": "daily_collect",
		"title": "每日收藏",
		"description": "今天收藏 1 個漂流瓶",
		"type": "collect",
		"target": 1,
		"progress": 0,
		"completed": false,
		"claimed": false,
		"reward": 100
	})

# 創建成就
func _create_achievements():
	print("GameManager _create_achievements - 創建成就")
	
	# 成就1：寫入達人
	achievements.append({
		"id": "achievement_write_master",
		"title": "寫入達人",
		"description": "總共寫入 50 次漂流瓶",
		"type": "write",
		"target": 50,
		"progress": total_bottles_written,
		"completed": total_bottles_written >= 50,
		"claimed": false,
		"reward": 500
	})
	
	# 成就2：挖掘專家
	achievements.append({
		"id": "achievement_dig_expert",
		"title": "挖掘專家",
		"description": "總共挖掘 100 個漂流瓶",
		"type": "dig",
		"target": 100,
		"progress": total_bottles_dug,
		"completed": total_bottles_dug >= 100,
		"claimed": false,
		"reward": 300
	})
	
	# 成就3：收藏家
	achievements.append({
		"id": "achievement_collector",
		"title": "收藏家",
		"description": "總共收藏 20 個漂流瓶",
		"type": "collect",
		"target": 20,
		"progress": total_bottles_collected,
		"completed": total_bottles_collected >= 20,
		"claimed": false,
		"reward": 1000
	})
	
	# 成就4：升級達人
	achievements.append({
		"id": "achievement_upgrade_master",
		"title": "升級達人",
		"description": "將挖掘等級提升到 5",
		"type": "digging_level",
		"target": 5,
		"progress": digging_level,
		"completed": digging_level >= 5,
		"claimed": false,
		"reward": 2000
	})

# 更新任務進度
func update_task_progress(task_type: String, amount: int = 1):
	print("GameManager update_task_progress - 更新任務進度: ", task_type, " 增加: ", amount)
	
	# 更新總計數
	match task_type:
		"write":
			total_bottles_written += amount
		"dig":
			total_bottles_dug += amount
		"collect":
			total_bottles_collected += amount
	
	# 更新每日任務
	for task in daily_tasks:
		if task.type == task_type and not task.completed:
			task.progress += amount
			if task.progress >= task.target:
				task.progress = task.target
				task.completed = true
				# 自動領取獎勵
				task.claimed = true
				shells += task.reward
				emit_signal("shells_changed", shells)
				emit_signal("task_completed", task.id, task.reward)
				print("GameManager update_task_progress - 每日任務完成並自動領取獎勵: ", task.title, " 獎勵: ", task.reward)
			emit_signal("task_updated", task.id, task.progress, task.completed)
	
	# 更新成就
	for achievement in achievements:
		if achievement.type == task_type and not achievement.completed:
			achievement.progress += amount
			if achievement.progress >= achievement.target:
				achievement.progress = achievement.target
				achievement.completed = true
				# 自動領取獎勵
				achievement.claimed = true
				shells += achievement.reward
				emit_signal("shells_changed", shells)
				emit_signal("achievement_unlocked", achievement.id, achievement.reward)
				print("GameManager update_task_progress - 成就解鎖並自動領取獎勵: ", achievement.title, " 獎勵: ", achievement.reward)
			emit_signal("task_updated", achievement.id, achievement.progress, achievement.completed)
		elif achievement.type == "digging_level" and digging_level >= achievement.target and not achievement.completed:
			achievement.progress = digging_level
			achievement.completed = true
			# 自動領取獎勵
			achievement.claimed = true
			shells += achievement.reward
			emit_signal("shells_changed", shells)
			emit_signal("achievement_unlocked", achievement.id, achievement.reward)
			print("GameManager update_task_progress - 成就解鎖並自動領取獎勵: ", achievement.title, " 獎勵: ", achievement.reward)
			emit_signal("task_updated", achievement.id, achievement.progress, achievement.completed)

# 領取任務獎勵
func claim_task_reward(task_id: String) -> bool:
	print("GameManager claim_task_reward - 嘗試領取任務獎勵: ", task_id)
	
	# 檢查每日任務
	for task in daily_tasks:
		if task.id == task_id and task.completed and not task.claimed:
			task.claimed = true
			shells += task.reward
			emit_signal("shells_changed", shells)
			print("GameManager claim_task_reward - 領取每日任務獎勵成功: ", task.reward, " 貝殼")
			return true
	
	# 檢查成就
	for achievement in achievements:
		if achievement.id == task_id and achievement.completed and not achievement.claimed:
			achievement.claimed = true
			shells += achievement.reward
			emit_signal("shells_changed", shells)
			print("GameManager claim_task_reward - 領取成就獎勵成功: ", achievement.reward, " 貝殼")
			return true
	
	print("GameManager claim_task_reward - 領取任務獎勵失敗: 任務不存在或未完成或已領取")
	return false

# 獲取所有每日任務
func get_daily_tasks() -> Array:
	return daily_tasks

# 獲取所有成就
func get_achievements() -> Array:
	return achievements 