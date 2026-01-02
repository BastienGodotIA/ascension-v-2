# res://scripts/core/log.gd
# =========================================================
# 🪵 Log.gd - Logger projet Ascension
# ---------------------------------------------------------
# Objectif :
# - Standardiser les prints (emoji + niveau + tag + kv)
# - Pouvoir réduire/augmenter le niveau de debug
# =========================================================
extends RefCounted

# 🔧 Active/désactive certains niveaux (à ton goût)
const ENABLE_DEBUG := true
const ENABLE_TRACE := false

# ---------------------------------------------------------
# 🔧 Format standard :
# "<emoji> <NIVEAU> [TAG] Message | k=v | k=v"
# ---------------------------------------------------------
static func _fmt(tag: String, msg: String, kv: Dictionary) -> String:
	var parts: Array[String] = []
	for k in kv.keys():
		parts.append("%s=%s" % [str(k), str(kv[k])])

	var suffix := ""
	if parts.size() > 0:
		suffix = " | " + " | ".join(parts)

	return "[%s] %s%s" % [tag, msg, suffix]

# ---------------------------------------------------------
# 🚀 INFO
# ---------------------------------------------------------
static func i(tag: String, msg: String, kv: Dictionary = {}) -> void:
	print("🚀 INFO " + _fmt(tag, msg, kv))

# ---------------------------------------------------------
# ✅ OK
# ---------------------------------------------------------
static func ok(tag: String, msg: String, kv: Dictionary = {}) -> void:
	print("✅ OK " + _fmt(tag, msg, kv))

# ---------------------------------------------------------
# ⚠️ WARN
# ---------------------------------------------------------
static func w(tag: String, msg: String, kv: Dictionary = {}) -> void:
	push_warning("⚠️ WARN " + _fmt(tag, msg, kv))

# ---------------------------------------------------------
# ❌ ERR
# ---------------------------------------------------------
static func e(tag: String, msg: String, kv: Dictionary = {}) -> void:
	push_error("❌ ERR " + _fmt(tag, msg, kv))

# ---------------------------------------------------------
# 🧪 DEBUG (limitable)
# ---------------------------------------------------------
static func d(tag: String, msg: String, kv: Dictionary = {}) -> void:
	if ENABLE_DEBUG:
		print("🧪 DEBUG " + _fmt(tag, msg, kv))

# ---------------------------------------------------------
# 🔎 TRACE (ultra verbeux)
# ---------------------------------------------------------
static func t(tag: String, msg: String, kv: Dictionary = {}) -> void:
	if ENABLE_TRACE:
		print("🔎 TRACE " + _fmt(tag, msg, kv))
