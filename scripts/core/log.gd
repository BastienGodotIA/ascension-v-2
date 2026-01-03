extends Node
class_name Log

# ---------------------------------------------------------
# ⚙️ Réglages globaux
# ---------------------------------------------------------
static var DEBUG_ENABLED: bool = true
static var INFO_ENABLED: bool = true
static var OK_ENABLED: bool = true
static var WARN_ENABLED: bool = true
static var ERROR_ENABLED: bool = true

# Quand true, Godot ajoute souvent une pile d'appels (plus verbeux).
# Quand false, on garde juste une ligne propre.
static var WARN_WITH_STACK: bool = false
static var ERROR_WITH_STACK: bool = false

# ---------------------------------------------------------
# 🎯 Filtre par TAG (allowlist)
# - Si la liste est vide => tout est autorisé
# ---------------------------------------------------------
static var DEBUG_TAG_ALLOWLIST: Array[String] = ["STATS"]
static var INFO_TAG_ALLOWLIST: Array[String] = ["GAME", "RUN", "UI", "COMBAT", "DATA"]
static var OK_TAG_ALLOWLIST: Array[String] = ["GAME", "RUN", "UI", "COMBAT", "DATA"]
static var WARN_TAG_ALLOWLIST: Array[String] = []
static var ERROR_TAG_ALLOWLIST: Array[String] = []

# ---------------------------------------------------------
# 🔍 Helper : filtrage
# ---------------------------------------------------------
static func _tag_allowed(tag: String, allowlist: Array[String]) -> bool:
	if allowlist.size() == 0:
		return true
	return allowlist.has(tag)

static func _format_ctx(ctx: Dictionary) -> String:
	if ctx.is_empty():
		return ""
	var parts: Array[String] = []
	for k in ctx.keys():
		parts.append("%s=%s" % [str(k), str(ctx[k])])
	return " | " + " | ".join(parts)

# ---------------------------------------------------------
# 🧪 DEBUG
# ---------------------------------------------------------
static func d(tag: String, msg: String, ctx: Dictionary = {}) -> void:
	if not DEBUG_ENABLED:
		return
	if not _tag_allowed(tag, DEBUG_TAG_ALLOWLIST):
		return
	print("🧪 DEBUG [%s] %s%s" % [tag, msg, _format_ctx(ctx)])

# ---------------------------------------------------------
# 🚀 INFO
# ---------------------------------------------------------
static func i(tag: String, msg: String, ctx: Dictionary = {}) -> void:
	if not INFO_ENABLED:
		return
	if not _tag_allowed(tag, INFO_TAG_ALLOWLIST):
		return
	print("🚀 INFO [%s] %s%s" % [tag, msg, _format_ctx(ctx)])

# ---------------------------------------------------------
# ✅ OK
# ---------------------------------------------------------
static func ok(tag: String, msg: String, ctx: Dictionary = {}) -> void:
	if not OK_ENABLED:
		return
	if not _tag_allowed(tag, OK_TAG_ALLOWLIST):
		return
	print("✅ OK [%s] %s%s" % [tag, msg, _format_ctx(ctx)])

# ---------------------------------------------------------
# ⚠️ WARN
# ---------------------------------------------------------
static func w(tag: String, msg: String, ctx: Dictionary = {}) -> void:
	if not WARN_ENABLED:
		return
	if not _tag_allowed(tag, WARN_TAG_ALLOWLIST):
		return
	var line := "⚠️ WARN [%s] %s%s" % [tag, msg, _format_ctx(ctx)]
	if WARN_WITH_STACK:
		push_warning(line)
	else:
		print(line)

# ---------------------------------------------------------
# ❌ ERROR
# ---------------------------------------------------------
static func e(tag: String, msg: String, ctx: Dictionary = {}) -> void:
	if not ERROR_ENABLED:
		return
	if not _tag_allowed(tag, ERROR_TAG_ALLOWLIST):
		return
	var line := "❌ ERROR [%s] %s%s" % [tag, msg, _format_ctx(ctx)]
	if ERROR_WITH_STACK:
		push_error(line)
	else:
		print(line)
