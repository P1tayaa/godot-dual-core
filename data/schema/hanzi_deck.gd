class_name HanziDeck
extends Resource
## A deck of cards. Written by tools/make_hanzi_deck.gd from data/hanzi/<id>.tsv; edit the TSV, not the .tres.

@export var id: StringName = &""
@export var title: String = ""
@export var cards: Array[HanziCard] = []
