extends Resource
class_name BottleResource

@export var id: int
@export var area: String
@export var theme: String
@export var content: Array = []
@export var max_entries: int = 10
@export var current_entries: int = 0
@export var created_at: int

# 添加新內容
func add_entry(text: String, author: String = "匿名") -> bool:
	if current_entries < max_entries:
		content.append({
			"text": text,
			"author": author,
			"timestamp": Time.get_unix_time_from_system()
		})
		current_entries += 1
		return true
	return false

# 檢查是否已完成
func is_completed() -> bool:
	return current_entries >= max_entries

# 獲取最後一個條目
func get_last_entry() -> Dictionary:
	if content.size() > 0:
		return content[content.size() - 1]
	return {}

# 獲取所有內容的文本
func get_full_text() -> String:
	var full_text = ""
	for entry in content:
		full_text += entry.text + "\n\n"
	return full_text

# 從字典創建資源
static func from_dictionary(dict: Dictionary) -> BottleResource:
	var bottle = BottleResource.new()
	bottle.id = dict.id
	bottle.area = dict.area
	bottle.theme = dict.theme
	bottle.content = dict.content
	bottle.max_entries = dict.max_entries
	bottle.current_entries = dict.current_entries
	bottle.created_at = dict.created_at
	return bottle

# 轉換為字典
func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"area": area,
		"theme": theme,
		"content": content,
		"max_entries": max_entries,
		"current_entries": current_entries,
		"created_at": created_at
	} 