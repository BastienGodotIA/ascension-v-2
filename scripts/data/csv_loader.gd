# =========================================================
# 📦 CSV LOADER (Godot 4) - Version PROPRE (logs via Log.gd)
# =========================================================
class_name CSVLoader
extends RefCounted

const LOG = preload("res://scripts/core/log.gd")

# 🔊 VERBOSE : mets true si tu veux des logs CSV détaillés
static var VERBOSE: bool = false

const MAX_SAMPLE_IDS := 5
const MAX_CONVERSION_LOGS := 30
static var _conversion_log_count: int = 0


static func _v(msg: String, level: String = "d") -> void:
	if not VERBOSE:
		return
	match level:
		"i":
			LOG.i("DATA", msg)
		"ok":
			LOG.ok("DATA", msg)
		"w":
			LOG.w("DATA", msg)
		"e":
			LOG.e("DATA", msg)
		_:
			LOG.d("DATA", msg)


static func _norm_number_str(s: String) -> String:
	var t := s.strip_edges()
	if t == "":
		return ""
	t = t.replace(" ", "")
	t = t.replace(",", ".")
	return t


static func _to_bool(s: String) -> bool:
	var t := s.strip_edges().to_upper()
	return t in ["OUI", "YES", "TRUE", "1", "VRAI"]


static func _coerce(raw: String, kind: String) -> Variant:
	var s := raw.strip_edges()
	if s == "":
		return null

	match kind:
		"string":
			return s
		"bool":
			return _to_bool(s)
		"int":
			var n := _norm_number_str(s)
			if n.ends_with("%"):
				n = n.trim_suffix("%")
				return int(float(n) / 100.0)
			return int(float(n))
		"float":
			var n := _norm_number_str(s)
			if n.ends_with("%"):
				n = n.trim_suffix("%")
				return float(n) / 100.0
			return float(n)
		"number":
			var n := _norm_number_str(s)
			if n.ends_with("%"):
				n = n.trim_suffix("%")
				return float(n) / 100.0
			if n.find(".") != -1:
				return float(n)
			return int(float(n))
		_:
			return s


static func load_table(path: String, delimiter: String = ";", id_col: String = "ID") -> Dictionary:
	_v("🟦📥 [CSV] Chargement : %s (id_col=%s, sep=%s)" % [path, id_col, delimiter], "i")

	var out := {
		"headers": PackedStringArray(),
		"rows": [],
		"by_id": {},
		"errors": [],
		"path": path,
		"id_col": id_col
	}

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		var msg := "❌ [CSV] Impossible d'ouvrir: %s" % path
		out["errors"].append(msg)
		LOG.e("DATA", msg)
		push_error(msg)
		return out

	var headers := f.get_csv_line(delimiter)
	for i in range(headers.size()):
		headers[i] = headers[i].strip_edges()

	out["headers"] = headers
	_v("🧾 [CSV] Colonnes (%d) : %s" % [headers.size(), str(headers)], "d")

	if not headers.has(id_col):
		var msg2 := "❌ [CSV] Colonne '%s' manquante dans %s" % [id_col, path]
		out["errors"].append(msg2)
		LOG.e("DATA", msg2)
		push_error(msg2)
		return out

	var line_num := 1
	while not f.eof_reached():
		var cols := f.get_csv_line(delimiter)
		line_num += 1

		var has_any := false
		for c in cols:
			if str(c).strip_edges() != "":
				has_any = true
				break
		if not has_any:
			continue

		var row := {}
		for i in range(headers.size()):
			var key := headers[i]
			if key == "":
				continue
			var val := str(cols[i]) if i < cols.size() else ""
			row[key] = val.strip_edges()

		row["_src_line"] = line_num

		var id := str(row.get(id_col, "")).strip_edges()
		if id == "":
			continue

		if id_col != "ID" and (not row.has("ID") or str(row["ID"]).strip_edges() == ""):
			row["ID"] = id

		if out["by_id"].has(id):
			var msg3 := "❌ [CSV] ID dupliqué '%s' dans %s (ligne %d)" % [id, path, line_num]
			out["errors"].append(msg3)
			LOG.e("DATA", msg3)
			push_error(msg3)
			continue

		out["rows"].append(row)
		out["by_id"][id] = row

	var count: int = int(out["by_id"].size())
	_v("✅📦 [CSV] OK : %s -> %d lignes (avec ID)" % [path, count], "ok")

	if VERBOSE:
		var sample := []
		var i2 := 0
		for k in out["by_id"].keys():
			sample.append(k)
			i2 += 1
			if i2 >= MAX_SAMPLE_IDS:
				break
		_v("🔎 [CSV] Exemples IDs : %s" % str(sample), "d")

	return out


static func apply_schema(table: Dictionary, schema: Dictionary, label: String = "") -> Dictionary:
	_conversion_log_count = 0

	var errors: Array = table.get("errors", [])
	var rows: Array = table.get("rows", [])

	var lab := label if label != "" else str(table.get("path", "TABLE"))
	_v("🟨🧩 [SCHEMA] Application schema sur : %s (rows=%d)" % [lab, rows.size()], "d")

	for row in rows:
		for key in schema.keys():
			var rule: Dictionary = schema[key]
			var required := bool(rule.get("required", false))
			var kind := str(rule.get("type", "string"))

			if required and (not row.has(key) or str(row.get(key, "")).strip_edges() == ""):
				var msg := "❌ Champ requis manquant '%s' (ID=%s, ligne %s)" % [
					key,
					str(row.get("ID", "?")),
					str(row.get("_src_line", "?"))
				]
				errors.append(msg)
				LOG.e("DATA", msg)
				push_error(msg)
				continue

			if row.has(key):
				var raw := str(row[key])
				var coerced: Variant = _coerce(raw, kind)

				if coerced == null:
					continue

				if VERBOSE and _conversion_log_count < MAX_CONVERSION_LOGS and raw != str(coerced):
					_v("🧪 [CAST] %s | ID=%s | %s: '%s' -> %s" % [
						lab, str(row.get("ID", "?")), key, raw, str(coerced)
					], "d")
					_conversion_log_count += 1

				row[key] = coerced

	table["errors"] = errors

	if VERBOSE:
		if errors.size() > 0:
			_v("⚠️ [SCHEMA] %s : %d erreur(s)" % [lab, errors.size()], "w")
		else:
			_v("✅ [SCHEMA] %s : aucune erreur" % lab, "ok")

	return table
