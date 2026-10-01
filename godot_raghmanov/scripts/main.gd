extends Node2D

const BG := Color("#101820")
const PANEL := Color("#1b2933")
const PANEL_2 := Color("#243642")
const GOLD := Color("#e0b45b")
const TEXT := Color("#edf2f4")
const MUTED := Color("#9aabb5")

var treasury := 72
var stability := 61
var support := 54
var military := 48
var turn := 1
var selected_region := 0
var log_lines: Array[String] = ["بدأت المرحلة الانتقالية بعد تفكك الاتحاد.", "الرئاسة الجديدة مطالبة باستعادة الاستقرار."]
var region_names := ["جمهورية رغمنوف", "جمهورية سيفير", "جمهورية أورلين"]
var region_notes := [
	"العاصمة ومركز الإدارة والصناعة. الموارد: صناعة وطاقة.",
	"إقليم شمالي زراعي وذو موانئ. يحتاج إلى استثمارات في البنية التحتية.",
	"إقليم شرقي غني بالمعادن. توجد توترات محلية ويحتاج إلى تسوية سياسية."
]
var map_view: MapView
var region_title: Label
var region_description: Label
var treasury_label: Label
var stability_label: Label
var support_label: Label
var military_label: Label
var turn_label: Label
var event_log: RichTextLabel
var adviser_label: Label

class MapView extends Control:
	signal region_clicked(index: int)
	var selected := 0
	var hover := -1
	var font := ThemeDB.fallback_font
	var polygons: Array[PackedVector2Array] = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(queue_redraw)

	func _polygons() -> Array[PackedVector2Array]:
		var w := size.x
		var h := size.y
		return [
			PackedVector2Array([Vector2(w*0.37,h*0.08),Vector2(w*0.63,h*0.12),Vector2(w*0.69,h*0.37),Vector2(w*0.57,h*0.52),Vector2(w*0.40,h*0.47),Vector2(w*0.30,h*0.27)]),
			PackedVector2Array([Vector2(w*0.10,h*0.18),Vector2(w*0.30,h*0.12),Vector2(w*0.37,h*0.28),Vector2(w*0.40,h*0.47),Vector2(w*0.30,h*0.64),Vector2(w*0.12,h*0.56),Vector2(w*0.06,h*0.35)]),
			PackedVector2Array([Vector2(w*0.40,h*0.47),Vector2(w*0.57,h*0.52),Vector2(w*0.69,h*0.37),Vector2(w*0.87,h*0.46),Vector2(w*0.91,h*0.70),Vector2(w*0.73,h*0.86),Vector2(w*0.46,h*0.78),Vector2(w*0.30,h*0.64)])
		]

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#13242c"))
		# Subtle map-grid background
		for x in range(20, int(size.x), 40):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.35, 0.48, 0.52, 0.12), 1.0)
		for y in range(20, int(size.y), 40):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.35, 0.48, 0.52, 0.12), 1.0)
		var shapes := _polygons()
		var fills := [Color("#456b70"), Color("#42617d"), Color("#786443")]
		var names := ["رغمنوف", "سيفير", "أورلين"]
		for i in range(shapes.size()):
			var fill := fills[i]
			if i == selected:
				fill = fill.lightened(0.28)
			elif i == hover:
				fill = fill.lightened(0.14)
			draw_colored_polygon(shapes[i], fill)
			draw_polyline(PackedVector2Array(shapes[i] + [shapes[i][0]]), GOLD if i == selected else Color("#a9bdc3"), 3.0 if i == selected else 2.0, true)
			var center := Vector2.ZERO
			for p in shapes[i]:
				center += p
			center /= shapes[i].size()
			draw_string(font, center + Vector2(-38, 5), names[i], HORIZONTAL_ALIGNMENT_CENTER, 100, 17, TEXT)
		draw_string(font, Vector2(16, 25), "خريطة سياسية تخطيطية • اضغط على أي جمهورية", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b7c8ce"))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var old := hover
			hover = _hit_test(event.position)
			if old != hover:
				queue_redraw()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var hit := _hit_test(event.position)
			if hit >= 0:
				selected = hit
				region_clicked.emit(hit)
				queue_redraw()

	func _hit_test(point: Vector2) -> int:
		var shapes := _polygons()
		for i in range(shapes.size()):
			if Geometry2D.is_point_in_polygon(point, shapes[i]):
				return i
		return -1

func _ready() -> void:
	_build_ui()
	_update_ui()

func _build_ui() -> void:
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_top", 14)
	root.add_theme_constant_override("margin_bottom", 14)
	ui.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "اتحاد رغمنوف  |  مكتب الرئاسة"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	turn_label = Label.new()
	turn_label.add_theme_font_size_override("font_size", 18)
	turn_label.add_theme_color_override("font_color", TEXT)
	header.add_child(turn_label)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 12)
	root.add_child(stats)
	treasury_label = _stat_card(stats, "الخزانة")
	stability_label = _stat_card(stats, "الاستقرار")
	support_label = _stat_card(stats, "التأييد")
	military_label = _stat_card(stats, "الجاهزية العسكرية")

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)

	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.custom_minimum_size = Vector2(500, 360)
	_style_panel(map_panel)
	body.add_child(map_panel)
	map_view = MapView.new()
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.custom_minimum_size = Vector2(500, 360)
	map_view.region_clicked.connect(_select_region)
	map_panel.add_child(map_view)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(300, 0)
	side.size_flags_horizontal = Control.SIZE_FILL
	side.add_theme_constant_override("separation", 10)
	body.add_child(side)

	var region_panel := PanelContainer.new()
	_style_panel(region_panel)
	side.add_child(region_panel)
	var region_box := VBoxContainer.new()
	region_box.add_theme_constant_override("separation", 8)
	region_panel.add_child(region_box)
	region_title = Label.new()
	region_title.add_theme_font_size_override("font_size", 20)
	region_title.add_theme_color_override("font_color", GOLD)
	region_box.add_child(region_title)
	region_description = Label.new()
	region_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	region_description.custom_minimum_size = Vector2(270, 90)
	region_description.add_theme_color_override("font_color", TEXT)
	region_box.add_child(region_description)

	var action_title := Label.new()
	action_title.text = "قرارات رئاسية"
	action_title.add_theme_font_size_override("font_size", 18)
	action_title.add_theme_color_override("font_color", GOLD)
	side.add_child(action_title)
	_add_action(side, "تمويل الخدمات  (-12 خزانة، +8 استقرار)", _decision.bind("services"))
	_add_action(side, "دعم المصانع  (-10 خزانة، +7 تأييد)", _decision.bind("industry"))
	_add_action(side, "رفع الجاهزية  (-8 خزانة، +9 جيش)", _decision.bind("army"))
	_add_action(side, "خطاب مصالحة  (+6 استقرار، +5 تأييد)", _decision.bind("unity"))
	_add_action(side, "إنهاء الدور", _next_turn)

	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size = Vector2(0, 140)
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)
	var adviser_panel := PanelContainer.new()
	adviser_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(adviser_panel)
	bottom.add_child(adviser_panel)
	var adviser_box := VBoxContainer.new()
	adviser_panel.add_child(adviser_box)
	var adviser_heading := Label.new()
	adviser_heading.text = "مكتب المستشارين"
	adviser_heading.add_theme_color_override("font_color", GOLD)
	adviser_heading.add_theme_font_size_override("font_size", 18)
	adviser_box.add_child(adviser_heading)
	adviser_label = Label.new()
	adviser_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	adviser_label.text = "الاقتصاد: حافظ على احتياطي نقدي.
الدفاع: ارفع الجاهزية تدريجيًا.
الداخلية: تابع الاستقرار في الأقاليم."
	adviser_label.add_theme_color_override("font_color", TEXT)
	adviser_box.add_child(adviser_label)

	var log_panel := PanelContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(log_panel)
	bottom.add_child(log_panel)
	var log_box := VBoxContainer.new()
	log_panel.add_child(log_box)
	var log_heading := Label.new()
	log_heading.text = "سجل الأحداث"
	log_heading.add_theme_color_override("font_color", GOLD)
	log_heading.add_theme_font_size_override("font_size", 18)
	log_box.add_child(log_heading)
	event_log = RichTextLabel.new()
	event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_log.bbcode_enabled = true
	event_log.scroll_following = true
	event_log.add_theme_color_override("default_color", TEXT)
	log_box.add_child(event_log)

func _stat_card(parent: HBoxContainer, name: String) -> Label:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(panel)
	parent.add_child(panel)
	var label := Label.new()
	label.text = name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", TEXT)
	panel.add_child(label)
	return label

func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color("#344955")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

func _add_action(parent: VBoxContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 36)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", TEXT)
	var normal := StyleBoxFlat.new()
	normal.bg_color = PANEL_2
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(6)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("#354d5a")
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(callback)
	parent.add_child(button)

func _select_region(index: int) -> void:
	selected_region = index
	_update_ui()

func _decision(kind: String) -> void:
	match kind:
		"services":
			if treasury < 12:
				_add_log("رفضت الخزانة تمويل الخدمات لعدم كفاية الأموال.")
			else:
				treasury -= 12
				stability = mini(100, stability + 8)
				_add_log("أُطلقت حزمة خدمات عامة في " + region_names[selected_region] + ".")
		"industry":
			if treasury < 10:
				_add_log("لا توجد أموال كافية لدعم المصانع.")
			else:
				treasury -= 10
				support = mini(100, support + 7)
				_add_log("أُقرّ دعم صناعي جديد.")
		"army":
			if treasury < 8:
				_add_log("لا توجد أموال كافية لرفع الجاهزية.")
			else:
				treasury -= 8
				military = mini(100, military + 9)
				_add_log("بدأت خطة رفع الجاهزية العسكرية.")
		"unity":
			stability = mini(100, stability + 6)
			support = mini(100, support + 5)
			_add_log("ألقى الرئيس خطاب مصالحة وطنية.")
	_update_ui()

func _next_turn() -> void:
	turn += 1
	treasury += 8
	if stability < 35:
		support = maxi(0, support - 3)
		_add_log("تحذير: تراجع الاستقرار يضغط على التأييد الشعبي.")
	else:
		stability = mini(100, stability + 1)
	_add_log("بدأ الدور " + str(turn) + ". دخلت إيرادات دورية إلى الخزانة.")
	_update_ui()

func _add_log(message: String) -> void:
	log_lines.append("الدور %d: %s" % [turn, message])
	if log_lines.size() > 30:
		log_lines.pop_front()
	if is_instance_valid(event_log):
		event_log.clear()
		for line in log_lines:
			event_log.append_text("• " + line + "\n")

func _update_ui() -> void:
	if not is_instance_valid(treasury_label):
		return
	treasury_label.text = "الخزانة\n%d مليار" % treasury
	stability_label.text = "الاستقرار\n%d / 100" % stability
	support_label.text = "التأييد\n%d / 100" % support
	military_label.text = "الجاهزية العسكرية\n%d / 100" % military
	turn_label.text = "الدور %d" % turn
	region_title.text = region_names[selected_region]
	region_description.text = region_notes[selected_region]
	if is_instance_valid(map_view):
		map_view.selected = selected_region
		map_view.queue_redraw()
	if is_instance_valid(event_log):
		event_log.clear()
		for line in log_lines:
			event_log.append_text("• " + line + "\n")
	if stability < 40:
		adviser_label.text = "الاقتصاد: احتفظ بسيولة للطوارئ.\nالداخلية: الاستقرار منخفض؛ أعطِ الأولوية للمصالحة.\nالدفاع: تجنب التوسع في الإنفاق قبل ضبط الميزانية."
	elif treasury < 25:
		adviser_label.text = "الاقتصاد: الخزانة تقترب من مستوى حرج.\nالدفاع: ركّز على الصيانة بدل التوسع.\nالداخلية: الخدمات الأساسية قد تساعد في دعم الاستقرار."
	else:
		adviser_label.text = "الاقتصاد: الوضع يسمح باستثمار محدود مع الاحتفاظ باحتياطي.\nالدفاع: ارفع الجاهزية تدريجيًا حسب الميزانية.\nالداخلية: تابع احتياجات " + region_names[selected_region] + "."
