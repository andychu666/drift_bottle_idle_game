extends Window
class_name UpgradePanel

# UI 元素引用
@onready var digging_level_label = $VBoxContainer/DiggingContainer/LevelLabel
@onready var digging_cost_label = $VBoxContainer/DiggingContainer/CostLabel
@onready var digging_upgrade_button = $VBoxContainer/DiggingContainer/UpgradeButton

@onready var storage_level_label = $VBoxContainer/StorageContainer/LevelLabel
@onready var storage_cost_label = $VBoxContainer/StorageContainer/CostLabel
@onready var storage_upgrade_button = $VBoxContainer/StorageContainer/UpgradeButton

@onready var area_container = $VBoxContainer/AreasContainer
@onready var close_button = $VBoxContainer/CloseButton

# 區域解鎖成本
var area_costs = {
	"reef": 500,
	"deep_sea": 2000,
	"island": 5000,
	"arctic": 10000
}

# 區域顯示名稱
var area_names = {
	"reef": "珊瑚礁",
	"deep_sea": "深海",
	"island": "孤島",
	"arctic": "極地"
}

var area_buttons = {}

func _ready():
	print("UpgradePanel _ready - 開始初始化")
	
	# 連接信號
	digging_upgrade_button.connect("pressed", Callable(self, "_on_digging_upgrade_pressed"))
	storage_upgrade_button.connect("pressed", Callable(self, "_on_storage_upgrade_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	
	# 檢查漂流瓶上限容器是否存在
	var bottle_limit_container = get_node_or_null("VBoxContainer/BottleLimitContainer")
	if bottle_limit_container:
		print("UpgradePanel _ready - 找到 BottleLimitContainer 節點")
		var upgrade_button = bottle_limit_container.get_node_or_null("UpgradeButton")
		if upgrade_button:
			upgrade_button.connect("pressed", Callable(self, "_on_bottle_limit_upgrade_pressed"))
			print("UpgradePanel _ready - 連接漂流瓶上限升級按鈕信號")
	else:
		print("UpgradePanel _ready - 未找到 BottleLimitContainer 節點，跳過連接漂流瓶上限升級按鈕信號")
	
	# 設置關閉請求處理
	connect("close_requested", Callable(self, "_on_close_requested"))
	
	print("UpgradePanel _ready - 初始化完成")

# 顯示面板
func show_panel():
	update_ui()
	popup_centered()

# 更新 UI
func update_ui():
	print("UpgradePanel update_ui - 開始更新 UI")
	
	# 更新挖掘等級
	digging_level_label.text = "等級: " + str(GameManager.digging_level)
	var digging_cost = 100 * GameManager.digging_level
	digging_cost_label.text = "成本: " + str(digging_cost) + " 貝殼"
	digging_upgrade_button.disabled = GameManager.shells < digging_cost
	
	# 更新存儲容量
	storage_level_label.text = "容量: " + str(GameManager.storage_capacity)
	var storage_cost = 200 * (GameManager.storage_capacity / 2.0)
	storage_cost_label.text = "成本: " + str(storage_cost) + " 貝殼"
	storage_upgrade_button.disabled = GameManager.shells < storage_cost
	
	# 更新漂流瓶上限 - 檢查節點是否存在
	var bottle_limit_container = get_node_or_null("VBoxContainer/BottleLimitContainer")
	if bottle_limit_container:
		print("UpgradePanel update_ui - 找到 BottleLimitContainer 節點")
		var level_label = bottle_limit_container.get_node_or_null("LevelLabel")
		if level_label:
			level_label.text = "上限: " + str(GameManager.river_bottle_limit)
	else:
		print("UpgradePanel update_ui - 未找到 BottleLimitContainer 節點，跳過更新漂流瓶上限")
	
	# 更新區域解鎖
	_update_areas_ui()
	
	print("UpgradePanel update_ui - UI 更新完成")

# 更新區域 UI
func _update_areas_ui():
	# 清空容器
	for child in area_container.get_children():
		child.queue_free()
	
	# 添加區域解鎖選項
	for area_id in area_costs.keys():
		if not GameManager.unlocked_areas[area_id]:
			var hbox = HBoxContainer.new()
			area_container.add_child(hbox)
			
			var name_label = Label.new()
			name_label.text = area_names[area_id]
			hbox.add_child(name_label)
			
			var cost_label = Label.new()
			cost_label.text = "成本: " + str(area_costs[area_id]) + " 貝殼"
			hbox.add_child(cost_label)
			
			var unlock_button = Button.new()
			unlock_button.text = "解鎖"
			unlock_button.disabled = GameManager.shells < area_costs[area_id]
			unlock_button.connect("pressed", Callable(self, "_on_area_unlock_pressed").bind(area_id))
			hbox.add_child(unlock_button)

# 挖掘升級按鈕點擊
func _on_digging_upgrade_pressed():
	var cost = 100 * GameManager.digging_level
	if GameManager.upgrade_digging(cost):
		update_ui()

# 存儲升級按鈕點擊
func _on_storage_upgrade_pressed():
	var cost = 200 * (GameManager.storage_capacity / 2.0)
	if GameManager.upgrade_storage(cost):
		update_ui()

# 區域解鎖按鈕點擊
func _on_area_unlock_pressed(area_id: String):
	if GameManager.unlock_area(area_id, area_costs[area_id]):
		update_ui()

# 關閉按鈕點擊
func _on_close_button_pressed():
	visible = false

# 關閉請求
func _on_close_requested():
	visible = false

# 漂流瓶上限升級按鈕點擊
func _on_bottle_limit_upgrade_pressed():
	print("UpgradePanel _on_bottle_limit_upgrade_pressed - 嘗試升級漂流瓶上限")
	
	var cost = 100
	if GameManager.spend_shells(cost):
		GameManager.river_bottle_limit += 10
		
		# 確保 river_bottles 是數組
		if typeof(GameManager.river_bottles) != TYPE_ARRAY:
			GameManager.river_bottles = []
		
		# 添加新的瓶子到河中
		var themes = ["夏日", "海洋", "回憶", "友情", "旅行"]
		for i in range(10):
			var bottle = {
				"id": randi(),
				"area": "beach",
				"theme": themes[randi() % themes.size()],
				"content": [],
				"max_entries": 10,
				"current_entries": 0,
				"created_at": Time.get_unix_time_from_system()
			}
			GameManager.river_bottles.append(bottle)
		
		GameManager.emit_signal("river_bottles_changed", GameManager.river_bottles.size())
		print("UpgradePanel _on_bottle_limit_upgrade_pressed - 漂流瓶上限升級成功，新上限: ", GameManager.river_bottle_limit)
		update_ui()
	else:
		print("UpgradePanel _on_bottle_limit_upgrade_pressed - 貝殼不足，無法升級") 
