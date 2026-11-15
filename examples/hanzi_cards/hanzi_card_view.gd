class_name HanziCardView
extends Node2D
## One card in the physical world (units: millimetres). Front: the hanzi alone. Back: hanzi and pinyin coloured by
## tone (Pleco colours), meaning below. Fonts are MSDF, so text stays sharp at any zoom.

const SIZE_MM: Vector2 = Vector2(38.0, 48.0)
const TONE_COLORS: Array[Color] = [
	Color(0, 0, 0), # unused (tones are 1-5)
	Color(0.85, 0.22, 0.22), # 1 red
	Color(0.18, 0.6, 0.28), # 2 green
	Color(0.22, 0.42, 0.85), # 3 blue
	Color(0.55, 0.28, 0.75), # 4 purple
	Color(0.45, 0.45, 0.45), # 5 neutral
]
const PAPER: Color = Color(0.97, 0.94, 0.86)
const INK: Color = Color(0.12, 0.1, 0.16)
const BORDER: Color = Color(0.7, 0.55, 0.35)

var card: HanziCard
var face_up: bool = false
var hanzi_font: Font
var text_font: Font
var locale: String = "en"


func _init() -> void:
	# MSDF text must be sampled linearly; the viewports default to nearest for pixel art.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


## True when a point (world mm) is on the card (rotation ignored: cards are only slightly turned).
func has_point(world: Vector2) -> bool:
	return Rect2(global_position - SIZE_MM / 2.0, SIZE_MM).has_point(world)


## Turns the card over with a squash tween. Returns the tween so callers can wait for it.
func flip() -> Tween:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.09)
	tween.tween_callback(func() -> void: face_up = not face_up; queue_redraw())
	tween.tween_property(self, "scale:x", 1.0, 0.09)
	return tween


func _draw() -> void:
	var rect: Rect2 = Rect2(-SIZE_MM / 2.0, SIZE_MM)
	draw_rect(Rect2(rect.position + Vector2(1.2, 1.5), rect.size), Color(0, 0, 0, 0.35))
	draw_rect(rect, PAPER)
	draw_rect(rect.grow(-1.5), BORDER, false, 0.4)
	if card == null:
		return
	var tones: Array[int] = HanziRules.tones(card.pinyin)
	if not face_up:
		var size: int = 24 if card.hanzi.length() == 1 else 15
		_draw_hanzi(Vector2(0.0, size * 0.35), size, [] as Array[int])
		return
	_draw_hanzi(Vector2(0.0, -6.0), 13, tones)
	_draw_pinyin(Vector2(0.0, 7.0), 5, tones)
	draw_string(text_font, Vector2(rect.position.x + 2.0, 15.0), card.meaning(locale), HORIZONTAL_ALIGNMENT_CENTER,
			SIZE_MM.x - 4.0, 4, INK)


## Characters centred on `centre` (baseline), each coloured by its tone when `tones` is given.
func _draw_hanzi(centre: Vector2, size: int, tones: Array[int]) -> void:
	var width: float = hanzi_font.get_string_size(card.hanzi, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x: float = centre.x - width / 2.0
	for i: int in card.hanzi.length():
		var glyph: String = card.hanzi[i]
		var color: Color = TONE_COLORS[tones[i]] if i < tones.size() else INK
		draw_string(hanzi_font, Vector2(x, centre.y), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
		x += hanzi_font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


func _draw_pinyin(centre: Vector2, size: int, tones: Array[int]) -> void:
	var syllables: PackedStringArray = card.pinyin.split(" ", false)
	var space: float = text_font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var width: float = text_font.get_string_size(card.pinyin, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x: float = centre.x - width / 2.0
	for i: int in syllables.size():
		draw_string(text_font, Vector2(x, centre.y), syllables[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, TONE_COLORS[tones[i]])
		x += text_font.get_string_size(syllables[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + space
