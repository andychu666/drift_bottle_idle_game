extends Node

# 遊戲資源和狀態
var energy: int = 100
var max_energy: int = 100
var energy_recovery_rate: float = 1.0  # 每秒恢復的能量
var shells: int = 0  # 貝殼/金幣
var digging_level: int = 1
var storage_capacity: int = 5  # 漂流瓶存儲上限
var river_bottle_limit: int = 100  # 漂流河中的瓶子總數限制
var river_bottles = []  # 修改為存儲瓶子數據的數組

# 區域解鎖狀態
var unlocked_areas = {
	"beach": true,  # 初始區域
	"reef": false,
	"deep_sea": false,
	"island": false,
	"arctic": false
}

# 收藏的漂流瓶
var collected_bottles = []

# 當前持有的漂流瓶
var current_bottles = []

# 任務系統
var daily_tasks = []  # 每日任務列表
var achievements = []  # 成就列表
var total_bottles_written = 0  # 總共寫入的瓶子數
var total_bottles_collected = 0  # 總共收藏的瓶子數
var total_bottles_dug = 0  # 總共挖掘的瓶子數
var last_daily_reset = 0  # 上次每日任務重置時間

# 信號
signal energy_changed(current, maximum)
signal shells_changed(amount)
signal bottle_added(bottle)
signal bottle_collected(bottle)
signal bottle_discarded(bottle)  # 新增丟棄信號
signal area_unlocked(area_id)
signal river_bottles_changed(current)  # 新增漂流河瓶子數量變化信號
signal bottle_stats_changed  # 新增統計數據變化信號
signal task_updated(task_id, progress, completed)  # 新增任務更新信號
signal task_completed(task_id, reward)  # 新增任務完成信號
signal achievement_unlocked(achievement_id, reward)  # 新增成就解鎖信號

# 漂流瓶統計數據
var bottle_stats = {
	1: 0,  # 已寫入1次的瓶子數量
	2: 0,
	3: 0,
	4: 0,
	5: 0,
	6: 0,
	7: 0,
	8: 0,
	9: 0,
	10: 0
}

func _ready():
	# 初始化漂流河
	_init_river_bottles()
	
	# 初始化任務系統
	_init_task_system()
	
	# 啟動能量恢復計時器
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.one_shot = false
	timer.connect("timeout", Callable(self, "_on_energy_recovery_timer_timeout"))
	add_child(timer)
	
	# 添加調試輸出
	print("GameManager _ready - Energy: ", energy, "/", max_energy)
	print("GameManager _ready - Current bottles: ", current_bottles.size())
	print("GameManager _ready - Storage capacity: ", storage_capacity)
	print("GameManager _ready - River bottles: ", river_bottles.size(), "/", river_bottle_limit)

func _on_energy_recovery_timer_timeout():
	recover_energy(energy_recovery_rate)

# 恢復能量
func recover_energy(amount: float):
	energy = min(energy + int(amount), max_energy)
	emit_signal("energy_changed", energy, max_energy)

# 消耗能量
func consume_energy(amount: int) -> bool:
	if energy >= amount:
		energy -= amount
		emit_signal("energy_changed", energy, max_energy)
		return true
	return false

# 增加貝殼/金幣
func add_shells(amount: int):
	shells += amount
	emit_signal("shells_changed", shells)

# 消費貝殼/金幣
func spend_shells(amount: int) -> bool:
	if shells >= amount:
		shells -= amount
		emit_signal("shells_changed", shells)
		return true
	return false

# 挖掘漂流瓶
func dig_bottle() -> Dictionary:
	var energy_cost = 10
	
	if not consume_energy(energy_cost):
		return {}  # 能量不足
		
	if current_bottles.size() >= storage_capacity:
		return {}  # 存儲空間已滿
	
	if river_bottles.size() <= 0:
		print("GameManager dig_bottle - 漂流河中沒有漂流瓶了")
		return {}  # 漂流河中沒有瓶子
	
	# 從漂流河中隨機選擇一個瓶子
	var bottle_index = randi() % river_bottles.size()
	var bottle = river_bottles[bottle_index]
	
	# 將瓶子從漂流河移到當前瓶子列表
	river_bottles.remove_at(bottle_index)
	current_bottles.append(bottle)
	
	emit_signal("bottle_added", bottle)
	emit_signal("river_bottles_changed", river_bottles.size())
	
	# 更新統計數據
	update_bottle_stats()
	
	# 更新任務進度
	update_task_progress("dig")
	
	print("GameManager dig_bottle - 成功挖掘漂流瓶，剩餘漂流瓶: ", river_bottles.size())
	return bottle

# 根據區域獲取隨機主題
func _get_random_theme_for_area(area: String) -> String:
	var themes = {
		"beach": ["回憶", "旅行", "友情", "夏日", "海洋"],
		"reef": ["冒險", "發現", "神秘", "海洋生物", "寶藏"],
		"deep_sea": ["恐懼", "未知", "黑暗", "奇幻生物", "科學"],
		"island": ["生存", "孤獨", "希望", "文明", "自然"],
		"arctic": ["寒冷", "堅持", "極限", "純淨", "科學探索"]
	}
	
	var area_themes = themes.get(area, ["一般"])
	return area_themes[randi() % area_themes.size()]

# 更新漂流瓶統計數據
func update_bottle_stats():
	# 重置統計數據
	for i in range(1, 11):
		bottle_stats[i] = 0
	
	# 統計當前漂流瓶
	for bottle in current_bottles:
		if bottle.current_entries > 0 and bottle.current_entries <= 10:
			bottle_stats[bottle.current_entries] += 1
	
	# 統計已收藏的漂流瓶
	for bottle in collected_bottles:
		if bottle.current_entries > 0 and bottle.current_entries <= 10:
			bottle_stats[bottle.current_entries] += 1
	
	# 統計河中的漂流瓶
	for bottle in river_bottles:
		if bottle.current_entries > 0 and bottle.current_entries <= 10:
			bottle_stats[bottle.current_entries] += 1
	
	# 添加調試輸出
	print("更新漂流瓶統計 - 當前統計: ", bottle_stats)
	print("河中瓶子數量: ", river_bottles.size())
	print("當前持有瓶子數量: ", current_bottles.size())
	print("已收藏瓶子數量: ", collected_bottles.size())
	
	emit_signal("bottle_stats_changed")

# 獲取漂流瓶統計數據
func get_bottle_stats() -> Dictionary:
	return bottle_stats

# 寫入漂流瓶
func write_to_bottle(bottle_id: int, content: String, author: String = "匿名") -> bool:
	for i in range(current_bottles.size()):
		if current_bottles[i].id == bottle_id:
			if current_bottles[i].current_entries < current_bottles[i].max_entries:
				current_bottles[i].content.append({
					"text": content,
					"author": author,
					"timestamp": Time.get_unix_time_from_system()
				})
				current_bottles[i].current_entries += 1
				
				# 添加調試輸出
				print("寫入漂流瓶 - 瓶子ID: ", bottle_id)
				print("寫入漂流瓶 - 當前寫入次數: ", current_bottles[i].current_entries)
				
				# 更新統計數據
				update_bottle_stats()
				
				# 更新任務進度
				update_task_progress("write")
				
				# 將瓶子放回漂流河
				var bottle = current_bottles[i]
				current_bottles.remove_at(i)
				river_bottles.append(bottle)  # 將瓶子放回漂流河
				emit_signal("river_bottles_changed", river_bottles.size())
				print("GameManager write_to_bottle - 寫入完成並放回漂流河")
				
				return true
	
	return false

# 收藏完成的漂流瓶
func _collect_completed_bottle(bottle_index: int):
	var bottle = current_bottles[bottle_index]
	collected_bottles.append(bottle)
	current_bottles.remove_at(bottle_index)
	emit_signal("bottle_collected", bottle)
	
	# 更新統計數據
	update_bottle_stats()
	
	# 更新任務進度
	update_task_progress("collect")
	
	# 給予獎勵 - 增加獎勵數量
	var reward = 100 + (digging_level * 20)  # 基礎獎勵 + 挖掘等級加成
	add_shells(reward)
	print("收藏瓶子獎勵: ", reward, " 貝殼")

# 丟棄漂流瓶
func discard_bottle(bottle_index: int):
	print("GameManager discard_bottle - 丟棄前 Current bottles: ", current_bottles.size())
	print("GameManager discard_bottle - 丟棄索引: ", bottle_index)
	
	if bottle_index >= 0 and bottle_index < current_bottles.size():
		var bottle = current_bottles[bottle_index]
		current_bottles.remove_at(bottle_index)
		river_bottles.append(bottle)  # 將瓶子放回漂流河
		emit_signal("bottle_discarded", bottle)
		emit_signal("river_bottles_changed", river_bottles.size())
		
		# 更新統計數據
		update_bottle_stats()
		
		# 給予少量獎勵或懲罰
		add_shells(5)  # 給予少量貝殼作為補償
		
		print("GameManager discard_bottle - 丟棄後 Current bottles: ", current_bottles.size())
		print("GameManager discard_bottle - 漂流河中的瓶子: ", river_bottles.size())
		return true
	
	print("GameManager discard_bottle - 丟棄失敗，索引無效")
	return false

# 解鎖新區域
func unlock_area(area_id: String, cost: int) -> bool:
	if unlocked_areas.has(area_id) and not unlocked_areas[area_id]:
		if spend_shells(cost):
			unlocked_areas[area_id] = true
			emit_signal("area_unlocked", area_id)
			return true
	
	return false

# 升級挖掘等級
func upgrade_digging(cost: int) -> bool:
	if spend_shells(cost):
		digging_level += 1
		
		# 檢查升級成就
		for achievement in achievements:
			if achievement.type == "digging_level" and digging_level >= achievement.target and not achievement.completed:
				achievement.progress = digging_level
				achievement.completed = true
				# 自動領取獎勵
				achievement.claimed = true
				shells += achievement.reward
				emit_signal("shells_changed", shells)
				emit_signal("achievement_unlocked", achievement.id, achievement.reward)
				print("成就解鎖並自動領取獎勵: ", achievement.title, " 獎勵: ", achievement.reward)
				emit_signal("task_updated", achievement.id, achievement.progress, achievement.completed)
		
		return true
	
	return false

# 擴充存儲容量
func upgrade_storage(cost: int) -> bool:
	if spend_shells(cost):
		storage_capacity += 2
		return true
	
	return false

# 初始化漂流河
func _init_river_bottles():
	# 確保 river_bottles 是數組
	if typeof(river_bottles) != TYPE_ARRAY:
		river_bottles = []
	
	# 清空現有瓶子
	while river_bottles.size() > 0:
		river_bottles.pop_back()
	
	# 添加新瓶子
	for i in range(river_bottle_limit):
		var bottle = {
			"id": randi(),
			"area": "beach",  # 初始區域
			"theme": _get_random_theme_for_area("beach"),
			"content": [],
			"max_entries": 10,
			"current_entries": 0,
			"created_at": Time.get_unix_time_from_system()
		}
		river_bottles.append(bottle)
	
	# 更新統計數據
	update_bottle_stats()

# 保存遊戲數據
func save_game():
	var save_data = {
		"energy": energy,
		"max_energy": max_energy,
		"energy_recovery_rate": energy_recovery_rate,
		"shells": shells,
		"digging_level": digging_level,
		"storage_capacity": storage_capacity,
		"unlocked_areas": unlocked_areas,
		"collected_bottles": collected_bottles,
		"current_bottles": current_bottles,
		"river_bottles": river_bottles,  # 保存漂流河中的瓶子
		"bottle_stats": bottle_stats,
		# 任務系統數據
		"daily_tasks": daily_tasks,
		"achievements": achievements,
		"total_bottles_written": total_bottles_written,
		"total_bottles_collected": total_bottles_collected,
		"total_bottles_dug": total_bottles_dug,
		"last_daily_reset": last_daily_reset
	}
	
	var save_file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	save_file.store_var(save_data)
	save_file.close()

# 加載遊戲數據
func load_game() -> bool:
	if not FileAccess.file_exists("user://save_game.dat"):
		_init_river_bottles()  # 如果沒有存檔，初始化漂流河
		_init_task_system()    # 初始化任務系統
		return false
		
	var save_file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	var save_data = save_file.get_var()
	save_file.close()
	
	if save_data:
		energy = save_data.energy
		max_energy = save_data.max_energy
		energy_recovery_rate = save_data.energy_recovery_rate
		shells = save_data.shells
		digging_level = save_data.digging_level
		storage_capacity = save_data.storage_capacity
		unlocked_areas = save_data.unlocked_areas
		collected_bottles = save_data.collected_bottles
		current_bottles = save_data.current_bottles
		
		# 確保 river_bottles 是數組
		if save_data.has("river_bottles"):
			river_bottles = save_data.river_bottles
		else:
			river_bottles = []
		
		# 如果漂流河為空或不是數組，初始化它
		if typeof(river_bottles) != TYPE_ARRAY or river_bottles.size() == 0:
			_init_river_bottles()
		
		bottle_stats = save_data.get("bottle_stats", bottle_stats)
		
		# 加載任務系統數據
		if save_data.has("daily_tasks"):
			daily_tasks = save_data.daily_tasks
		if save_data.has("achievements"):
			achievements = save_data.achievements
		if save_data.has("total_bottles_written"):
			total_bottles_written = save_data.total_bottles_written
		if save_data.has("total_bottles_collected"):
			total_bottles_collected = save_data.total_bottles_collected
		if save_data.has("total_bottles_dug"):
			total_bottles_dug = save_data.total_bottles_dug
		if save_data.has("last_daily_reset"):
			last_daily_reset = save_data.last_daily_reset
		
		# 檢查是否需要重置每日任務
		var current_time = Time.get_unix_time_from_system()
		var day_seconds = 86400  # 一天的秒數
		if current_time - last_daily_reset > day_seconds:
			_reset_daily_tasks()
			last_daily_reset = current_time
		
		# 更新統計數據
		update_bottle_stats()
		
		emit_signal("energy_changed", energy, max_energy)
		emit_signal("shells_changed", shells)
		emit_signal("river_bottles_changed", river_bottles.size())
		emit_signal("bottle_stats_changed")
		
		# 發送任務更新信號
		for task in daily_tasks:
			emit_signal("task_updated", task.id, task.progress, task.completed)
		for achievement in achievements:
			emit_signal("task_updated", achievement.id, achievement.progress, achievement.completed)
		
		print("GameManager load_game - 加載後 Current bottles: ", current_bottles.size())
		print("GameManager load_game - 加載後 Storage capacity: ", storage_capacity)
		print("GameManager load_game - 加載後 River bottles: ", river_bottles.size())
		print("GameManager load_game - 加載後 Bottle stats: ", bottle_stats)
		print("GameManager load_game - 加載後 Daily tasks: ", daily_tasks)
		print("GameManager load_game - 加載後 Achievements: ", achievements)
		
		return true
	
	return false

# 收藏漂流瓶
func collect_bottle(bottle_id: int) -> bool:
	print("GameManager collect_bottle - 收藏前 Current bottles: ", current_bottles.size())
	print("GameManager collect_bottle - 目標 Bottle ID: ", bottle_id)
	
	for i in range(current_bottles.size()):
		if current_bottles[i].id == bottle_id:
			if current_bottles[i].current_entries >= current_bottles[i].max_entries:
				_collect_completed_bottle(i)
				print("GameManager collect_bottle - 收藏成功")
				return true
			else:
				print("GameManager collect_bottle - 漂流瓶尚未完成")
				return false
	
	print("GameManager collect_bottle - 未找到指定的漂流瓶")
	return false

# 初始化任務系統
func _init_task_system():
	print("初始化任務系統")
	
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
	
	print("任務系統初始化完成")
	print("每日任務: ", daily_tasks)
	print("成就: ", achievements)

# 重置每日任務
func _reset_daily_tasks():
	print("重置每日任務")
	daily_tasks.clear()
	_create_daily_tasks()

# 創建每日任務
func _create_daily_tasks():
	print("創建每日任務")
	
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
	print("創建成就")
	
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
	print("更新任務進度: ", task_type, " 增加: ", amount)
	
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
				print("每日任務完成並自動領取獎勵: ", task.title, " 獎勵: ", task.reward)
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
				print("成就解鎖並自動領取獎勵: ", achievement.title, " 獎勵: ", achievement.reward)
			emit_signal("task_updated", achievement.id, achievement.progress, achievement.completed)
		elif achievement.type == "digging_level" and digging_level >= achievement.target and not achievement.completed:
			achievement.progress = digging_level
			achievement.completed = true
			# 自動領取獎勵
			achievement.claimed = true
			shells += achievement.reward
			emit_signal("shells_changed", shells)
			emit_signal("achievement_unlocked", achievement.id, achievement.reward)
			print("成就解鎖並自動領取獎勵: ", achievement.title, " 獎勵: ", achievement.reward)
			emit_signal("task_updated", achievement.id, achievement.progress, achievement.completed)

# 領取任務獎勵
func claim_task_reward(task_id: String) -> bool:
	print("嘗試領取任務獎勵: ", task_id)
	
	# 檢查每日任務
	for task in daily_tasks:
		if task.id == task_id and task.completed and not task.claimed:
			task.claimed = true
			add_shells(task.reward)
			print("領取每日任務獎勵成功: ", task.reward, " 貝殼")
			return true
	
	# 檢查成就
	for achievement in achievements:
		if achievement.id == task_id and achievement.completed and not achievement.claimed:
			achievement.claimed = true
			add_shells(achievement.reward)
			print("領取成就獎勵成功: ", achievement.reward, " 貝殼")
			return true
	
	print("領取任務獎勵失敗: 任務不存在或未完成或已領取")
	return false

# 獲取所有每日任務
func get_daily_tasks() -> Array:
	return daily_tasks

# 獲取所有成就
func get_achievements() -> Array:
	return achievements
