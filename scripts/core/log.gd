extends Node
class_name Log

# ===== Toggles =====
static var DEBUG_ENABLED: bool = true
static var INFO_ENABLED: bool = true
static var OK_ENABLED: bool = true
static var WARN_ENABLED: bool = true
static var ERROR_ENABLED: bool = true

# ===== Allowlists (vide = tout autoriser) =====
static var DEBUG_TAG_ALLOWLIST: Array[String] = ["UI", "COMBAT"]
static var INFO_TAG_ALLOWLIST: Array[String] = ["GAME", "RUN", "UI", "COMBAT"]
static var OK_TAG_ALLOWLIST: Array[String] = ["GAME", "RUN", "UI", "COMBAT"]
static var WARN_TAG_ALLOWLIST: Array[String] = []
static var ERROR_TAG_ALLOWLIST: Array[String] = []

# Optionnel : tags toujours interdits (tous niveaux)
static var TAG_BLOCKLIST: Array[String] = []

# ===== Public API =====
static func d(tag: String, msg: String, data: Dictionary = {}) -> void:
	if not DEBUG_ENABLED:
		return
	if not _tag_allowed(tag, DEBUG_TAG_ALLOWLIST):
		return
	_print_line("🧪", "DEBUG", tag, msg, data)

static func i(tag: String, msg: String, data: Dictionary = {}) -> void:
	if not INFO_ENABLED:
		return
	if not _tag_allowed(tag, INFO_TAG_ALLOWLIST):
		return
	_print_line("🚀", "INFO", tag, msg, data)

static func ok(tag: String, msg: String, data: Dictionary = {}) -> void:
	if not OK_ENABLED:
		return
	if not _tag_allowed(tag, OK_TAG_ALLOWLIST):
		return
	_print_line("✅", "OK", tag, msg, data)

static func w(tag: String, msg: String, data: Dictionary = {}) -> void:
	if not WARN_ENABLED:
		return
	if not _tag_allowed(tag, WARN_TAG_ALLOWLIST):
		return
	var line := _format("⚠️", "WARN", tag, msg, data)
	push_warning(line)
	print(line)

static func e(tag: String, msg: String, data: Dictionary = {}) -> void:
	if not ERROR_ENABLED:
		return
	if not _tag_allowed(tag, ERROR_TAG_ALLOWLIST):
		return
	var line := _format("🛑", "ERROR", tag, msg, data)
	push_error(line)
	print(line)

# ===== Internals =====
static func _tag_allowed(tag: String, allow: Array[String]) -> bool:
	if TAG_BLOCKLIST.has(tag):
		return false
	return allow.is_empty() or allow.has(tag)

static func _format(prefix_emoji: String, level: String, tag: String, msg: String, data: Dictionary) -> String:
	var kv := _fmt_kv(data)
	return "%s %s [%s] %s%s" % [prefix_emoji, level, tag, msg, kv]

static func _print_line(prefix_emoji: String, level: String, tag: String, msg: String, data: Dictionary) -> void:
	print(_format(prefix_emoji, level, tag, msg, data))

static func _fmt_kv(data: Dictionary) -> String:
	if data.is_empty():
		return ""
	var keys := data.keys()
	keys.sort_custom(func(a, b): return str(a) < str(b))
	var parts: Array[String] = []
	for k in keys:
		parts.append("%s=%s" % [str(k), str(data[k])])
	return " | " + " | ".join(parts)
