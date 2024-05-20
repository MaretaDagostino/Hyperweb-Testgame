extends Node

var start_menu
var options_menu

func _ready():
	start_menu = $Start_Menu
	options_menu = $Options_Menu
	
	# Connect all of the start menu buttons
	var _err = $Start_Menu/Button_Open_Godot.connect("pressed",
				Callable(self, "start_menu_button_pressed")) ###FIXME###, ["open_website"]))
	_err = $Start_Menu/Button_Options.connect("pressed",
				Callable(self, "start_menu_button_pressed")) ###FIXME###, ["options"]))
	_err = $Start_Menu/Button_Quit.connect("pressed",
				Callable(self, "start_menu_button_pressed")) ###FIXME###, ["quit"]))
	
	# Connect all of the options menu buttons
	_err = $Options_Menu/Button_Back.connect("pressed",
				Callable(self, "options_menu_button_pressed")) ###FIXME###, ["back"]))
	_err = $Options_Menu/Button_Fullscreen.connect("pressed",
				Callable(self, "options_menu_button_pressed")) ###FIXME###, ["fullscreen"]))
	_err = $Options_Menu/Check_Button_VSync.connect("pressed",
				Callable(self, "options_menu_button_pressed")) ###FIXME###, ["vsync"]))
	_err = $Options_Menu/Check_Button_Debug.connect("pressed",
				Callable(self, "options_menu_button_pressed")) ###FIXME###, ["debug"]))
	_err = $Options_Menu/HSlider_Mouse_Sensitivity.connect("value_changed",
				Callable(self, "set_mouse_sensitivity"))
	
	# Set "Game infos" button to inactive as website is empty
	if !(ProjectSettings.get_setting("application/config/webpage")):
		ProjectSettings.set("application/config/webpage", "")
		ProjectSettings.save()
	if ProjectSettings.get_setting("application/config/webpage") == "":
		$Start_Menu/Button_Open_Godot.disabled = true
	
	# Extract title from project name by adding line breaks
	var temp1 = ProjectSettings.get_setting("application/config/name")
	var temp2 = temp1.replace("-", "\n")
	var temp3 = temp2.replace("_","\n")
	var game_title = temp3.replace(" ","\n")
	$Start_Menu/Title_Label.text = game_title
	
	# Some times when returning to the title screen the mouse is still captured
	# even though it shouldn't be. To prevent this from breaking the game,
	# we just set it here too
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Get the globals singleton
	var globals = get_node("/root/Globals")
	# Get the mouse sensitivity
	$Options_Menu/HSlider_Mouse_Sensitivity.value = globals.mouse_sensitivity

func start_menu_button_pressed(button_name):
	# button_name == "start" triggers server connection in Main.gd, not here
	if button_name == "open_website":
		var _err = OS.shell_open(ProjectSettings.get_setting("application/config/webpage"))
	elif button_name == "options":
		options_menu.visible = true
		start_menu.visible = false
	elif button_name == "quit":
		get_tree().quit()

func options_menu_button_pressed(button_name):
	if button_name == "back":
		start_menu.visible = true
		options_menu.visible = false
	elif button_name == "fullscreen":
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (!((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
	elif button_name == "vsync":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if ($Options_Menu/Check_Button_VSync.pressed) else DisplayServer.VSYNC_DISABLED)
	elif button_name == "debug":
		get_node("/root/Globals").set_debug_display($Options_Menu/Check_Button_Debug.pressed)

func set_mouse_sensitivity(value):
	# Get the globals singleton
	var globals = get_node("/root/Globals")
	# Set the mouse sensitivity
	globals.mouse_sensitivity = value
