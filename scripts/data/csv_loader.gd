# =========================================================
# 📦 CSV LOADER (Godot 4) - Version VERBOSE + logs emoji
# ---------------------------------------------------------
# Rôle :
#  - Charger un CSV (séparateur ;)
#  - Construire :
#     - rows : Array[Dictionary] (toutes les lignes)
#     - by_id : Dictionary[id] = row (accès rapide par ID)
#  - Appliquer un "schema" (types + champs requis)
#  - Afficher un max d'infos utiles dans la console
#
# Notes :
#  - LibreOffice exporte souvent des décimales avec "," -> on convertit.
#  - Si un nombre arrive en "5,00 %" -> on retire le % et on /100.
# =========================================================
extends RefCounted

# 🔊 VERBOSE : mets false si tu veux moins de prints
const VERBOSE := true

# 🔎 Limite d'exemples d'IDs affichés à la fin du chargement
const MAX_SAMPLE_IDS := 5

# 🧪 Limite de logs sur conversions (pour éviter le spam)
const MAX_CONVERSION_LOGS := 30

# Compteur global de logs de conversion (reset à chaque apply_schema)
static var _conversion_log_count: int = 0


# ---------------------------------------------------------
# 🧾 Helper : print conditionnel
# ---------------------------------------------------------
static func _log(msg: String) -> void:
	if VERBOSE:
		print(msg)


# ---------------------------------------------------------
# 🔢 Normaliser une chaîne numérique :
#  - " 1,25 " -> "1.25"
#  - "5,00%" ou "5,00 %" -> "5.00%"
# ---------------------------------------------------------
static func _norm_number_str(s: String) -> String:
	var t := s.strip_edges()
	if t == "":
		return ""

	# Enlève les espaces internes (ex: "5,00 %")
	t = t.replace(" ", "")

	# Décimales FR -> format float lisible
	t = t.replace(",", ".")

	return t


# ---------------------------------------------------------
# ✅ Convertir texte -> bool
# ---------------------------------------------------------
static func _to_bool(s: String) -> bool:
	var t := s.strip_edges().to_upper()
	return t in ["OUI", "YES", "TRUE", "1", "VRAI"]


# ---------------------------------------------------------
# 🎛 Coercer un texte en type demandé
# kind :
#  - "string"
#  - "int"
#  - "float"
#  - "bool"
#  - "number" (auto int/float, gère aussi %)
# ---------------------------------------------------------
static func _coerce(raw: String, kind: String) -> Variant:
	var s := raw.strip_edges()

	# Si vide -> null (permet de laisser un champ vide)
	if s == "":
		return null

	match kind:
		"string":
			return s

		"bool":
			return _to_bool(s)

		"int":
			var n := _norm_number_str(s)
			# Si "5%" (rare en int) : 5% => 0.05 => int(0.05) = 0
			# Donc en pratique on évite les % en int.
			if n.ends_with("%"):
				n = n.trim_suffix("%")
				return int(float(n) / 100.0)
			return int(float(n))

		"float":
			var n := _norm_number_str(s)
			# Si "5%" => 0.05
			if n.ends_with("%"):
				n = n.trim_suffix("%")
				return float(n) / 100.0
			return float(n)

		"number":
			var n := _norm_number_str(s)

			# Si "5%" => 0.05
			if n.ends_with("%"):
				n = n.trim_suffix("%")
				return float(n) / 100.0

			# Auto : si "." présent => float, sinon int
			if n.find(".") != -1:
				return float(n)
			return int(float(n))

		_:
			# Fallback : on garde string
			return s


# ---------------------------------------------------------
# 📥 Charger un CSV et produire rows/by_id
#
# id_col :
#  - colonne servant de clé unique
#  - par défaut "ID"
#  - ex: equipement_slots.csv utilise "Code"
#
# Bonus :
#  - si id_col != "ID", on copie la valeur dans row["ID"]
#    (ça standardise l'accès côté code)
# ---------------------------------------------------------
static func load_table(path: String, delimiter: String = ";", id_col: String = "ID") -> Dictionary:
	_log("🟦📥 [CSV] Chargement : %s (id_col=%s, sep=%s)" % [path, id_col, delimiter])

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
		push_error(msg)
		return out

	# Lire entêtes (gère les guillemets)
	var headers := f.get_csv_line(delimiter)

	# Nettoyage entêtes
	for i in range(headers.size()):
		headers[i] = headers[i].strip_edges()

	out["headers"] = headers
	_log("🧾 [CSV] Colonnes (%d) : %s" % [headers.size(), str(headers)])

	# Vérification de la colonne ID demandée
	if not headers.has(id_col):
		var msg2 := "❌ [CSV] Colonne '%s' manquante dans %s" % [id_col, path]
		out["errors"].append(msg2)
		push_error(msg2)
		return out

	var line_num := 1
	while not f.eof_reached():
		var cols := f.get_csv_line(delimiter)
		line_num += 1

		# Détecter ligne totalement vide
		var has_any := false
		for c in cols:
			if str(c).strip_edges() != "":
				has_any = true
				break
		if not has_any:
			continue

		# Construire dictionnaire ligne
		var row := {}
		for i in range(headers.size()):
			var key := headers[i]
			if key == "":
				continue
			var val := str(cols[i]) if i < cols.size() else ""
			row[key] = val.strip_edges()

		# Garder numéro source (debug)
		row["_src_line"] = line_num

		# Lire ID (via id_col)
		var id := str(row.get(id_col, "")).strip_edges()

		# Ignore les lignes sans ID (souvent séparateurs)
		if id == "":
			continue

		# Standardise : si pas "ID", on crée aussi row["ID"]
		if id_col != "ID" and (not row.has("ID") or str(row["ID"]).strip_edges() == ""):
			row["ID"] = id

		# Vérifier duplicats
		if out["by_id"].has(id):
			var msg3 := "❌ [CSV] ID dupliqué '%s' dans %s (ligne %d)" % [id, path, line_num]
			out["errors"].append(msg3)
			push_error(msg3)
			continue

		out["rows"].append(row)
		out["by_id"][id] = row

	# Résumé
	var count: int = int(out["by_id"].size())
	_log("✅📦 [CSV] OK : %s -> %d lignes (avec ID)" % [path, count])

	# Afficher quelques IDs exemples
	var sample := []
	var i2 := 0
	for k in out["by_id"].keys():
		sample.append(k)
		i2 += 1
		if i2 >= MAX_SAMPLE_IDS:
			break
	_log("🔎 [CSV] Exemples IDs : %s" % str(sample))

	return out


# ---------------------------------------------------------
# 🧩 Appliquer un schema (types + required)
#
# schema format :
#  {
#    "Colonne": {"type":"float|int|bool|string|number", "required":true/false}
#  }
# ---------------------------------------------------------
static func apply_schema(table: Dictionary, schema: Dictionary, label: String = "") -> Dictionary:
	_conversion_log_count = 0

	var errors: Array = table.get("errors", [])
	var rows: Array = table.get("rows", [])

	var lab := label if label != "" else str(table.get("path", "TABLE"))
	_log("🟨🧩 [SCHEMA] Application schema sur : %s (rows=%d)" % [lab, rows.size()])

	# Pour chaque ligne
	for row in rows:
		# Pour chaque règle du schema
		for key in schema.keys():
			var rule: Dictionary = schema[key]
			var required := bool(rule.get("required", false))
			var kind := str(rule.get("type", "string"))

			# 1) Champ requis manquant
			if required and (not row.has(key) or str(row.get(key, "")).strip_edges() == ""):
				var msg := "❌ Champ requis manquant '%s' (ID=%s, ligne %s)" % [
					key,
					str(row.get("ID", "?")),
					str(row.get("_src_line", "?"))
				]
				errors.append(msg)
				push_error(msg)
				continue

			# 2) Conversion si champ présent
			if row.has(key):
				var raw := str(row[key])

				# Convertir vers le type demandé
				var coerced: Variant = _coerce(raw, kind)

				# Si vide -> null (on laisse)
				if coerced == null:
					continue

				# Log conversion (limité)
				if VERBOSE and _conversion_log_count < MAX_CONVERSION_LOGS and raw != str(coerced):
					_log("🧪 [CAST] %s | ID=%s | %s: '%s' -> %s" % [
						lab, str(row.get("ID", "?")), key, raw, str(coerced)
					])
					_conversion_log_count += 1

				row[key] = coerced

	table["errors"] = errors

	# Résumé erreurs
	if errors.size() > 0:
		_log("⚠️ [SCHEMA] %s : %d erreur(s)" % [lab, errors.size()])
	else:
		_log("✅ [SCHEMA] %s : aucune erreur" % lab)

	return table
