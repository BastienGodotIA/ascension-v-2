# =========================================================
# 🧾 DATA SCHEMAS
# ---------------------------------------------------------
# Chaque "schema" décrit :
#  - les colonnes attendues
#  - le type (string/int/float/bool/number)
#  - si c'est obligatoire ("required")
#
# Objectif :
#  - éviter les bugs silencieux (colonnes vides, mauvais types)
#  - logs clairs en console
# =========================================================
extends RefCounted

# ---------------------------------------------------------
# 📌 stats_economie.csv (ID est la clé)
# IMPORTANT :
#  - Valeur_Base peut être vide (ex: STAT_XP_001 etc.)
#  - donc required = false
# ---------------------------------------------------------
const STATS_ECONOMIE := {
	"ID": {"type":"string", "required": true},
	"Nom": {"type":"string", "required": true},
	"Type": {"type":"string", "required": true},
	"Description": {"type":"string", "required": false},
	"Persistant": {"type":"bool", "required": false},

	# Suivi (on garde pour debug, pas obligatoire)
	"Statut": {"type":"string", "required": false},
	"Notes_Tech": {"type":"string", "required": false},
	"Unite": {"type":"string", "required": false},

	# Data numeric
	"Valeur_Base": {"type":"float", "required": false}, # ✅ non requis
	"Min": {"type":"float", "required": false},
	"Max": {"type":"float", "required": false}
}

# ---------------------------------------------------------
# 📌 leveling.csv (ID est la clé)
# "Valeur" = number (auto int/float)
# ---------------------------------------------------------
const LEVELING := {
	"ID": {"type":"string", "required": true},
	"Paramètre": {"type":"string", "required": true},
	"Valeur": {"type":"number", "required": true},
	"Description": {"type":"string", "required": false},

	# Suivi
	"Statut": {"type":"string", "required": false}
}

# ---------------------------------------------------------
# 📌 equipement_slots.csv
# Clé = Code (mais on duplique aussi en row["ID"] via loader)
# ---------------------------------------------------------
const EQUIPEMENT_SLOTS := {
	"ID": {"type":"string", "required": true},   # Copie de Code par loader
	"Code": {"type":"string", "required": true},
	"Slot": {"type":"string", "required": true},
	"Type": {"type":"string", "required": true},

	"Visible_En_Run": {"type":"bool", "required": false},

	"Notes_UI": {"type":"string", "required": false},
	"Asset_Attache_Type": {"type":"string", "required": false},
	"Notes_Tech": {"type":"string", "required": false}
}

# ---------------------------------------------------------
# 📌 items_equipements.csv (ID est la clé)
# Valeur_Principale / Valeur_Secondaire = number (float/int)
# Prix_Or/Gemmes = int
# ---------------------------------------------------------
const ITEMS_EQUIPEMENTS := {
	"ID": {"type":"string", "required": true},
	"Nom": {"type":"string", "required": true},
	"Slot": {"type":"string", "required": true},
	"Rareté": {"type":"string", "required": true},
	"Niveau_Min": {"type":"int", "required": false},

	"Stat_Principale": {"type":"string", "required": false},
	"Valeur_Principale": {"type":"number", "required": false},

	"Stat_Secondaire": {"type":"string", "required": false},
	"Valeur_Secondaire": {"type":"number", "required": false},

	"Prix_Or": {"type":"int", "required": false},
	"Prix_Gemmes": {"type":"int", "required": false},

	"Description": {"type":"string", "required": false},

	"Asset_Icon_ID": {"type":"string", "required": false},
	"Asset_Sprite_ID": {"type":"string", "required": false},

	"Notes_Tech": {"type":"string", "required": false},
	"Statut": {"type":"string", "required": false},

	# Colonnes techniques ajoutées dans le GDD (ok à garder)
	"Stat_Principale_ID": {"type":"string", "required": false},
	"Stat_Secondaire_ID": {"type":"string", "required": false},
	"Slot_Code": {"type":"string", "required": false},
	"Rarete_Code": {"type":"string", "required": false},
	"Export_OK": {"type":"string", "required": false}
}
