class_name SpriteStress
extends DualScene
## Device bench for the second-screen transports. Both screens animate SPRITE_COUNT sprites.
## Bottom buttons: switch transport (Android), switch bottom redraw mode. Labels: fps per screen, once a second.
## Logs every second line to logcat/stdout as "BENCH ..." so results can be read with adb.

const SPRITE_COUNT: int = 40
const SPEED: float = 60.0

var _top_sprites: Array[Sprite2D] = []
var _bottom_sprites: Array[Sprite2D] = []
var _velocities: Array[Vector2] = []
var _last_shown: int = 0
var _last_sent: int = 0
var _last_frames: int = 0

@onready var _top_label: Label = %TopLabel
@onready var _bottom_label: Label = %BottomLabel
@onready var _transport_button: Button = %TransportButton
@onready var _redraw_button: Button = %RedrawButton
@onready var _touch_dot: ColorRect = %TouchDot


func _ready() -> void:
	super._ready()
	var texture: ImageTexture = _make_texture()
	var base: Vector2 = Vector2(Screens.screen_size(Screen.TOP))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in SPRITE_COUNT:
		var start: Vector2 = Vector2(rng.randf() * base.x, rng.randf() * base.y)
		_velocities.append(Vector2.from_angle(rng.randf() * TAU) * SPEED)
		_top_sprites.append(_add_sprite(%TopSprites, texture, start))
		_bottom_sprites.append(_add_sprite(%BottomSprites, texture, base - start))
	_transport_button.pressed.connect(_on_transport_pressed)
	_redraw_button.pressed.connect(_on_redraw_pressed)
	%TouchArea.gui_input.connect(_on_touch_area_input.bind(_touch_dot))
	%TopTouchArea.gui_input.connect(_on_touch_area_input.bind(%TopTouchDot))
	%SecondTimer.timeout.connect(_on_second)
	_update_buttons()


func _process(delta: float) -> void:
	var base: Vector2 = Vector2(Screens.screen_size(Screen.TOP))
	for i: int in SPRITE_COUNT:
		var p: Vector2 = _top_sprites[i].position + _velocities[i] * delta
		if p.x < 0.0 or p.x > base.x:
			_velocities[i].x = -_velocities[i].x
		if p.y < 0.0 or p.y > base.y:
			_velocities[i].y = -_velocities[i].y
		_top_sprites[i].position = p.clamp(Vector2.ZERO, base)
		_bottom_sprites[i].position = base - _top_sprites[i].position


func _on_second() -> void:
	var display: AndroidDisplay = Screens.get_node_or_null("AndroidDisplay") as AndroidDisplay
	var frames: int = Engine.get_frames_drawn()
	var top_fps: int = frames - _last_frames
	_last_frames = frames
	var bottom_fps: int = top_fps
	var sent: int = 0
	if display != null:
		var shown: int = display.frames_shown()
		bottom_fps = shown - _last_shown
		_last_shown = shown
		sent = display.frames_sent - _last_sent
		_last_sent = display.frames_sent
	_top_label.text = "TOP %d fps  mode %s" % [top_fps, ScreensService.Mode.keys()[Screens.mode]]
	_bottom_label.text = "BOTTOM %d fps (sent %d)" % [bottom_fps, sent]
	print("BENCH mode=%s transport=%s bottom_redraw=%s top_fps=%d bottom_fps=%d sent=%d" % [
		ScreensService.Mode.keys()[Screens.mode], _transport_name(), Redraw.keys()[bottom_redraw], top_fps, bottom_fps, sent,
	])
	request_redraw(Screen.BOTTOM)


func _on_transport_pressed() -> void:
	var display: AndroidDisplay = Screens.get_node_or_null("AndroidDisplay") as AndroidDisplay
	if display == null:
		return
	var next: AndroidDisplay.Transport = AndroidDisplay.Transport.GL if display.transport == AndroidDisplay.Transport.READBACK \
		else AndroidDisplay.Transport.READBACK
	display.open(next)
	_update_buttons()


func _on_redraw_pressed() -> void:
	set_redraw(Screen.BOTTOM, Redraw.ON_CHANGE if bottom_redraw == Redraw.ALWAYS else Redraw.ALWAYS)
	_update_buttons()


func _on_touch_area_input(event: InputEvent, dot: ColorRect) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		dot.position = (event as InputEventFromWindow).position - dot.size / 2.0


func _update_buttons() -> void:
	_transport_button.text = "T: %s" % _transport_name()
	_redraw_button.text = "R: %s" % Redraw.keys()[bottom_redraw]
	request_redraw(Screen.BOTTOM)


func _transport_name() -> String:
	var display: AndroidDisplay = Screens.get_node_or_null("AndroidDisplay") as AndroidDisplay
	return "-" if display == null else AndroidDisplay.Transport.keys()[display.transport]


func _add_sprite(parent: Node, texture: Texture2D, at: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.position = at
	parent.add_child(sprite)
	return sprite


func _make_texture() -> ImageTexture:
	var image: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color8(255, 180, 84))
	image.fill_rect(Rect2i(2, 2, 4, 4), Color8(32, 24, 64))
	return ImageTexture.create_from_image(image)
