class_name HanziRules
extends RefCounted
## Pinyin and spaced repetition. Numbers and strings in, result out.

const TONE_MARKS: Dictionary[String, int] = {
	"ā": 1, "ē": 1, "ī": 1, "ō": 1, "ū": 1, "ǖ": 1,
	"á": 2, "é": 2, "í": 2, "ó": 2, "ú": 2, "ǘ": 2,
	"ǎ": 3, "ě": 3, "ǐ": 3, "ǒ": 3, "ǔ": 3, "ǚ": 3,
	"à": 4, "è": 4, "ì": 4, "ò": 4, "ù": 4, "ǜ": 4,
}
## Leitner boxes 0..LAST_BOX. Box 0 = new or missed, LAST_BOX = known well.
const LAST_BOX: int = 4


## Tone of one pinyin syllable: 1-4 from its mark, 5 = neutral (no mark).
static func tone_of(syllable: String) -> int:
	for i: int in syllable.length():
		var letter: String = syllable[i].to_lower()
		if TONE_MARKS.has(letter):
			return TONE_MARKS[letter]
	return 5


## Tones of a spaced pinyin string, one per syllable ("zhōng guó" -> [1, 2]).
static func tones(pinyin: String) -> Array[int]:
	var out: Array[int] = []
	for syllable: String in pinyin.split(" ", false):
		out.append(tone_of(syllable))
	return out


static func promote(box: int) -> int:
	return mini(box + 1, LAST_BOX)


static func demote(_box: int) -> int:
	return 0


## Picks the next card: low boxes come back much more often (weight halves per box), never the same card twice in a
## row when there is a choice. `roll` is a random number in [0, 1).
static func next_card(boxes: Array[int], last: int, roll: float) -> int:
	var weights: Array[float] = []
	var total: float = 0.0
	for i: int in boxes.size():
		var weight: float = 0.0 if (i == last and boxes.size() > 1) else pow(2.0, LAST_BOX - boxes[i])
		weights.append(weight)
		total += weight
	var target: float = roll * total
	for i: int in weights.size():
		target -= weights[i]
		if target < 0.0:
			return i
	return weights.size() - 1
