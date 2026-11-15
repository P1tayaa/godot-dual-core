class_name HanziCard
extends Resource
## One flash card. Content, not UI text: no translation keys here.

@export var hanzi: String = ""
## One syllable per character, separated by spaces, with tone marks ("zhōng guó"). No mark = neutral tone.
@export var pinyin: String = ""
@export var meaning_en: String = ""
@export var meaning_fr: String = ""


## Meaning in the UI language (English when there is none for it).
func meaning(locale: String) -> String:
	return meaning_fr if locale.begins_with("fr") and meaning_fr != "" else meaning_en
