class_name TestHanziRules
extends TestCase


func test_tone_marks() -> void:
	eq(HanziRules.tone_of("mā"), 1, "first")
	eq(HanziRules.tone_of("guó"), 2, "second")
	eq(HanziRules.tone_of("wǒ"), 3, "third")
	eq(HanziRules.tone_of("bù"), 4, "fourth")
	eq(HanziRules.tone_of("you"), 5, "neutral")
	eq(HanziRules.tone_of("lǜ"), 4, "u with umlaut")


func test_tones_of_word() -> void:
	eq(HanziRules.tones("zhōng guó"), [1, 2] as Array[int], "China")
	eq(HanziRules.tones("xiè xie"), [4, 5] as Array[int], "thank you")


func test_leitner_boxes() -> void:
	eq(HanziRules.promote(0), 1, "up one")
	eq(HanziRules.promote(HanziRules.LAST_BOX), HanziRules.LAST_BOX, "capped")
	eq(HanziRules.demote(3), 0, "missed goes back to 0")


func test_next_card_prefers_low_boxes_and_skips_last() -> void:
	var boxes: Array[int] = [0, 4, 4]
	# Weights 16, 1, 1: most rolls land on card 0.
	eq(HanziRules.next_card(boxes, -1, 0.5), 0, "low box wins")
	eq(HanziRules.next_card(boxes, 0, 0.25), 1, "not the same card twice (weights 0, 1, 1)")
	eq(HanziRules.next_card([2] as Array[int], 0, 0.5), 0, "single card repeats")


func test_deck_loads_with_tones_per_character() -> void:
	var deck: HanziDeck = load("res://data/hanzi/hsk1_starter.tres") as HanziDeck
	ok(deck.cards.size() >= 30, "deck has cards")
	for card: HanziCard in deck.cards:
		eq(HanziRules.tones(card.pinyin).size(), card.hanzi.length(), "%s: one syllable per character" % card.hanzi)
