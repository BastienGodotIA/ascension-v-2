# =========================================================
# 🧩 DATA SCHEMAS (Godot 4)
# =========================================================
class_name DataSchemas
extends RefCounted

const SCHEMAS: Dictionary = {
	"Stats_Economie": {
		"ID": {"type": "string", "required": true},
		"Nom": {"type": "string", "required": true},
		"Type": {"type": "string", "required": false},
		"Description": {"type": "string", "required": false},
		"Persistant": {"type": "bool", "required": false},
		"Statut": {"type": "string", "required": false},
		"Valeur_Base": {"type": "float", "required": false},
		"Min": {"type": "float", "required": false},
		"Max": {"type": "float", "required": false},
		"Unite": {"type": "string", "required": false},
		"Notes_Tech": {"type": "string", "required": false},
	},

	"Leveling": {
		"ID": {"type": "string", "required": true},
		"Paramètre": {"type": "string", "required": false},
		"Valeur": {"type": "number", "required": false},
		"Valeur_Type": {"type": "string", "required": false},
		"Description": {"type": "string", "required": false},
		"Statut": {"type": "string", "required": false},
	},

	"Equipement_Slots": {
		"Code": {"type": "string", "required": true},
		"Slot": {"type": "string", "required": false},
		"Type": {"type": "string", "required": false},
		"Visible_En_Run": {"type": "bool", "required": false},
		"Notes_UI": {"type": "string", "required": false},
		"Asset_Attache_Type": {"type": "string", "required": false},
		"Notes_Tech": {"type": "string", "required": false},
	},

	"Items_Equipements": {
		"ID": {"type": "string", "required": true},
		"Nom": {"type": "string", "required": true},
		"Slot": {"type": "string", "required": false},
		"Rareté": {"type": "string", "required": false},
		"Niveau_Min": {"type": "int", "required": false},
		"Stat_Principale": {"type": "string", "required": false},
		"Valeur_Principale": {"type": "float", "required": false},
		"Stat_Secondaire": {"type": "string", "required": false},
		"Valeur_Secondaire": {"type": "float", "required": false},
		"Prix_Or": {"type": "int", "required": false},
		"Prix_Gemmes": {"type": "int", "required": false},
		"Description": {"type": "string", "required": false},
		"Asset_Icon_ID": {"type": "string", "required": false},
		"Asset_Sprite_ID": {"type": "string", "required": false},
		"Notes_Tech": {"type": "string", "required": false},
		"Statut": {"type": "string", "required": false},
		"Stat_Principale_ID": {"type": "string", "required": false},
		"Stat_Secondaire_ID": {"type": "string", "required": false},
		"Slot_Code": {"type": "string", "required": false},
		"Rarete_Code": {"type": "string", "required": false},
		"Export_OK": {"type": "string", "required": false},
	},
}

static func get_schema(table_label: String) -> Dictionary:
	return SCHEMAS.get(table_label, {})
