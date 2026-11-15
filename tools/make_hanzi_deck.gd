class_name MakeHanziDeck
extends SceneTree
## Turns every data/hanzi/<id>.tsv (hanzi, pinyin, meaning_en, meaning_fr) into data/hanzi/<id>.tres.
##   $GODOT_PATH --headless --path . --script res://tools/make_hanzi_deck.gd
## Then refresh the fonts: uv run --with fonttools --with brotli tools/subset_fonts.py <full fonts folder>

const DIR: String = "res://data/hanzi"


func _init() -> void:
	for file: String in DirAccess.get_files_at(DIR):
		if file.ends_with(".tsv"):
			_convert(DIR.path_join(file))
	quit()


func _convert(path: String) -> void:
	var deck: HanziDeck = HanziDeck.new()
	deck.id = StringName(path.get_file().get_basename())
	deck.title = String(deck.id).capitalize()
	var source: FileAccess = FileAccess.open(path, FileAccess.READ)
	source.get_line() # header
	while not source.eof_reached():
		var columns: PackedStringArray = source.get_line().split("\t")
		if columns.size() < 3:
			continue
		var card: HanziCard = HanziCard.new()
		card.hanzi = columns[0]
		card.pinyin = columns[1]
		card.meaning_en = columns[2]
		card.meaning_fr = columns[3] if columns.size() > 3 else ""
		deck.cards.append(card)
	var target: String = path.get_basename() + ".tres"
	ResourceSaver.save(deck, target)
	print("%s: %d cards" % [target, deck.cards.size()])
