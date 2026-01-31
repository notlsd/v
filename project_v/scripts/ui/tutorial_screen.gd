## TutorialScreen
## 新手教程弹窗 - 使用用户提供的 ASCII Art
extends CanvasLayer

const TUTORIAL_TEXT = """[center][code]
[color=#00ff41]  _____ ______ _       __  [/color] [b][color=#ffffff] [ G.F.W. SIMULATOR ] [/color][/b] [color=#666666]v1.0[/color]
[color=#00ff41] / ____|  ____| |     / /  [/color] [color=#666666]--------------------------[/color]
[color=#00ff41]| |  __| |__  | | /| / /   [/color] [color=#cccccc]INIT_SEQ:[/color] [color=#ffffff]GAME_JAM_48H[/color]
[color=#00ff41]| | |_ |  __| | |/ |/ /    [/color] [color=#cccccc]THEME:[/color]    [color=#00ff41]"MASK"[/color] [color=#666666]>[/color] [color=#00ff41]SUBNET_MASK[/color]
[color=#00ff41]| |__| | |    |   |   |    [/color] [color=#cccccc]CORE:[/color]     [color=#ffffff]PRECISION & SPEED[/color]
[color=#00ff41] \\_____|_|     |__/|__/    [/color] [color=#cccccc]MODE:[/color]     [color=#ffffff]LEFT(KEY) + RIGHT(MOUSE)[/color]

[color=#666666]==============================================================[/color]
    [b]PROTOCOL:[/b] [ [color=#00ffff]TARGET_IP[/color] ] = [ [color=#00ff41]INCOMING[/color] ] & [ [color=#ffff00]MASK[/color] ]
[color=#666666]==============================================================[/color]

      [color=#cccccc][ INCOMING TRAFFIC ][/color]              [color=#cccccc][ SYSTEM IDENTITY ][/color]
             │
             ▼                            [color=#ffffff].|||||||||.[/color]
      [color=#00ff41]192.168.1.45[/color]  ✓ [color=#666666](MATCH)[/color]            [color=#ffffff]|||||||||||||[/color]
      [color=#ff3333]10.0.0.12[/color]     ✗ [color=#666666](DROP)[/color]            [color=#ffffff]/. `|||||||||'[/color]
      [color=#ff0000][ WARNING ][/color]   ☠ [color=#666666](VIRUS)[/color]          [color=#ffffff]o__,_|||||||||[/color]
                                       [color=#ffffff]|  |||||||||||[/color]
      [color=#cccccc]CURRENT TARGET:[/color]                   [color=#ffffff]\\ `||||||||||[/color]
      > [color=#00ffff]192.168.1.0/24[/color]                   [color=#ffffff]`||||||||||'[/color]
                                          [color=#ffffff]`||||||||'[/color]
      [color=#cccccc]YOUR MASK STATUS:[/color]                     [color=#ffffff]`||||'[/color]
      > [color=#ffff00]255.255.255.0[/color]                  [i]"Ideas are bulletproof."[/i]

[color=#666666]==============================================================[/color]
[ [color=#ffffff]CONTROLS[/color] ]  [color=#cccccc]SELECT SUBNET MASK (CIDR)[/color]
[color=#ffff00][Q][/color] /8      [color=#ffff00][W][/color] /16      [color=#ffff00][E][/color] /24 [color=#00ff41](Active)[/color]   [color=#ffff00][R][/color] /32
[color=#888888](255.0.0.0) (255.255.0.0) (255.255.255.0)    (255...255)[/color]
[color=#666666]==============================================================[/color]
             >> PRESS ANY KEY TO INITIALIZE <<
[/code][/center]"""


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()


func _create_ui() -> void:
	# 全屏黑色背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# 居中容器
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)
	
	# ASCII Art 文本
	var text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.custom_minimum_size = Vector2(1200, 800)
	text_label.scroll_active = false
	text_label.add_theme_font_size_override("normal_font_size", 18)
	text_label.add_theme_font_size_override("mono_font_size", 18)
	text_label.text = TUTORIAL_TEXT
	center.add_child(text_label)
	
	# 暂停游戏
	get_tree().paused = true


func _input(event: InputEvent) -> void:
	# 任意键开始
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			get_tree().paused = false
			queue_free()
