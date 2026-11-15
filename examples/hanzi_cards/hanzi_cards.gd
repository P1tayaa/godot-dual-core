class_name HanziCards
extends DualScene
## Flash cards in the physical world. The card lies on the bottom screen: tap (or A) to turn it over. Flick it up and
## it slides through the hinge gap onto the "known" pile on the top screen (Leitner box up). Flick it down or
## sideways and it leaves as "again" (box 0). A weak flick slides back. Gamepad: up = known, down = again,
## Y / C = hanzi font. Progress is saved per deck in user://hanzi_progress.cfg.
## Both screens are ON_CHANGE and switch to ALWAYS only while a card moves.

const PROGRESS_PATH: String = "user://hanzi_progress.cfg"
const FRICTION_MM_S2: float = 1200.0 # a card sliding on a table
const FLICK_MM_S: float = 250.0 # slower releases are a tap or a put-back
const PAD_THROW_MM_S: float = 650.0 # gamepad throws: enough to cross the gap
const PILE_KEEP: int = 6
const TAP_MAX_MOVE_MM: float = 2.0

enum Motion { IDLE, DRAGGING, SLIDING_UP, SLIDING_AWAY }

@export var deck: HanziDeck
## Fonts for the hanzi, switched with toggle_mode (first = default). Pinyin and meaning always use text_font.
@export var hanzi_fonts: Array[Font] = []
@export var text_font: Font

var _boxes: Array[int] = []
var _index: int = -1
var _card: HanziCardView
var _pile: Array[HanziCardView] = []
var _motion: Motion = Motion.IDLE
var _velocity: Vector2 = Vector2.ZERO
var _grab_offset: Vector2 = Vector2.ZERO
var _press_world: Vector2 = Vector2.ZERO
var _last_world: Vector2 = Vector2.ZERO
var _last_time: float = 0.0
var _font_index: int = 0
var _known: int = 0
var _again: int = 0
var _tweens_running: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _world: Node2D = %World
@onready var _stats: Label = %Stats
@onready var _boxes_label: Label = %Boxes


func _ready() -> void:
	super._ready()
	use_physical_world_2d()
	_rng.randomize()
	_load_progress()
	%BottomTouch.gui_input.connect(_on_touch)
	%FontButton.pressed.connect(_next_font)
	set_process(false)
	_deal()
	_refresh_labels()


func _unhandled_input(event: InputEvent) -> void:
	if _motion != Motion.IDLE or _card == null:
		return
	if event.is_action_pressed("ui_accept"):
		_flip()
	elif event.is_action_pressed("ui_up"):
		_launch(Vector2(0.0, -PAD_THROW_MM_S))
	elif event.is_action_pressed("ui_down"):
		_launch(Vector2(0.0, PAD_THROW_MM_S))
	elif event.is_action_pressed("toggle_mode"):
		_next_font()


func _process(delta: float) -> void:
	_card.position += _velocity * delta
	_card.rotation += _velocity.x * 0.00004
	_velocity = _velocity.move_toward(Vector2.ZERO, FRICTION_MM_S2 * delta)
	var top: Rect2 = Screens.profile.rect_mm(Screen.TOP)
	var bottom: Rect2 = Screens.profile.rect_mm(Screen.BOTTOM)
	if _motion == Motion.SLIDING_UP and _card.position.y < top.end.y - HanziCardView.SIZE_MM.y * 0.3:
		_land_on_pile()
	elif _motion == Motion.SLIDING_AWAY and not bottom.grow(HanziCardView.SIZE_MM.y * 0.6).has_point(_card.position):
		_resolve(false)
	elif _velocity == Vector2.ZERO:
		_put_back() # not thrown hard enough: it slides back to its place


func _on_touch(event: InputEvent) -> void:
	if _card == null or _motion in [Motion.SLIDING_UP, Motion.SLIDING_AWAY]:
		return
	var world: Vector2 = screen_to_world(Screen.BOTTOM, (event as InputEventFromWindow).position) \
		if event is InputEventFromWindow else Vector2.ZERO
	var now: float = Time.get_ticks_msec() / 1000.0
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed and _motion == Motion.IDLE and _card.has_point(world):
			_motion = Motion.DRAGGING
			_grab_offset = _card.position - world
			_press_world = world
			_velocity = Vector2.ZERO
			_set_animating(true)
		elif not touch.pressed and _motion == Motion.DRAGGING:
			_motion = Motion.IDLE
			if world.distance_to(_press_world) < TAP_MAX_MOVE_MM:
				_card.position = _home()
				_flip()
			else:
				_launch(_velocity)
	elif event is InputEventScreenDrag and _motion == Motion.DRAGGING:
		var dt: float = maxf(now - _last_time, 0.001)
		_velocity = _velocity.lerp((world - _last_world) / dt, 0.5)
		_card.position = world + _grab_offset
	_last_world = world
	_last_time = now


## Starts a slide. Up and fast enough: towards the top pile. Fast in another direction: away. Else back home.
func _launch(velocity: Vector2) -> void:
	_velocity = velocity
	if velocity.length() < FLICK_MM_S:
		_put_back()
		return
	_motion = Motion.SLIDING_UP if -velocity.y > absf(velocity.x) else Motion.SLIDING_AWAY
	_set_animating(true)
	set_process(true)


func _land_on_pile() -> void:
	set_process(false)
	_motion = Motion.IDLE
	var landed: HanziCardView = _card
	_card = null
	var top: Rect2 = Screens.profile.rect_mm(Screen.TOP)
	var spot: Vector2 = top.get_center() + Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-3.0, 3.0))
	var tween: Tween = _track(landed.create_tween().set_parallel())
	tween.tween_property(landed, "position", spot, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(landed, "rotation", _rng.randf_range(-0.2, 0.2), 0.25)
	_pile.append(landed)
	if _pile.size() > PILE_KEEP:
		_pile.pop_front().queue_free()
	Input.vibrate_handheld(30)
	_resolve(true)


func _put_back() -> void:
	set_process(false)
	_motion = Motion.IDLE
	_velocity = Vector2.ZERO
	var tween: Tween = _track(_card.create_tween().set_parallel())
	tween.tween_property(_card, "position", _home(), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_card, "rotation", 0.0, 0.2)


## Records the answer, saves, deals the next card.
func _resolve(known: bool) -> void:
	set_process(false)
	_motion = Motion.IDLE
	_boxes[_index] = HanziRules.promote(_boxes[_index]) if known else HanziRules.demote(_boxes[_index])
	if known:
		_known += 1
	else:
		_again += 1
		if _card != null:
			_card.queue_free()
			_card = null
	_save_progress()
	_refresh_labels()
	_deal()


## Next card slides in from below the bottom screen, face down.
func _deal() -> void:
	_index = HanziRules.next_card(_boxes, _index, _rng.randf())
	_card = HanziCardView.new()
	_card.card = deck.cards[_index]
	_card.hanzi_font = hanzi_fonts[_font_index]
	_card.text_font = text_font
	_card.locale = TranslationServer.get_locale()
	_card.position = _home() + Vector2(0.0, 70.0)
	_world.add_child(_card)
	var tween: Tween = _track(_card.create_tween())
	tween.tween_property(_card, "position", _home(), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _flip() -> void:
	_track(_card.flip())


func _next_font() -> void:
	_font_index = (_font_index + 1) % hanzi_fonts.size()
	for view: HanziCardView in _pile + ([_card] if _card != null else []):
		view.hanzi_font = hanzi_fonts[_font_index]
		view.queue_redraw()
	request_redraw(Screen.TOP)
	request_redraw(Screen.BOTTOM)


func _home() -> Vector2:
	return Screens.profile.rect_mm(Screen.BOTTOM).get_center() + Vector2(0.0, 2.0)


## Keeps both screens drawing every frame while a tween runs, then back to ON_CHANGE.
func _track(tween: Tween) -> Tween:
	_tweens_running += 1
	_set_animating(true)
	tween.finished.connect(func() -> void:
		_tweens_running -= 1
		if _tweens_running == 0 and _motion == Motion.IDLE:
			_set_animating(false))
	return tween


func _set_animating(on: bool) -> void:
	var mode: Redraw = Redraw.ALWAYS if on else Redraw.ON_CHANGE
	set_redraw(Screen.TOP, mode)
	set_redraw(Screen.BOTTOM, mode)


func _refresh_labels() -> void:
	_stats.text = tr("HANZI_STATS") % [_known, _again]
	var counts: Array[int] = [0, 0, 0, 0, 0]
	for box: int in _boxes:
		counts[box] += 1
	_boxes_label.text = tr("HANZI_BOXES") % counts
	request_redraw(Screen.TOP)
	request_redraw(Screen.BOTTOM)


func _load_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(PROGRESS_PATH)
	for card: HanziCard in deck.cards:
		_boxes.append(int(config.get_value(String(deck.id), card.hanzi, 0)))


func _save_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(PROGRESS_PATH)
	for i: int in deck.cards.size():
		config.set_value(String(deck.id), deck.cards[i].hanzi, _boxes[i])
	config.save(PROGRESS_PATH)
