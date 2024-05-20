extends Node

var start_menu
var options_menu

var saved_window_size
# Bug in Godot 4.3: DisplayServer.window_set_position is not implemented for Wayland!
var saved_window_position

func _ready():
	start_menu = $Start_Menu
	options_menu = $Options_Menu
	
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

# Hint: Button_Start is connected by code in Main node
func _on_button_open_website_pressed() -> void:
	var _err = OS.shell_open(ProjectSettings.get_setting("application/config/webpage"))

func _on_button_options_pressed() -> void:
	options_menu.visible = true
	start_menu.visible = false

func _on_button_quit_pressed() -> void:
	get_tree().quit()

func _on_button_back_pressed() -> void:
	start_menu.visible = true
	options_menu.visible = false

func _on_check_button_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		saved_window_size = DisplayServer.window_get_size()
		saved_window_position = DisplayServer.window_get_position()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if toggled_on == false:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(saved_window_size)
		DisplayServer.window_set_position(saved_window_position)

func _on_check_button_v_sync_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	if toggled_on == false:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_check_button_debug_toggled(toggled_on: bool) -> void:
		get_node("/root/Globals").set_debug_display(toggled_on)

func _on_h_slider_mouse_sensitivity_value_changed(value: float) -> void:
	# Get the globals singleton
	var globals = get_node("/root/Globals")
	# Set the mouse sensitivity
	globals.mouse_sensitivity = value
