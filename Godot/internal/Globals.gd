extends Node

# This script is global. It autoloads and we can access it from other scripts.

# A Variable to distinguish between server and client
var is_server = false

# Player ID to distinguish between active player and others (puppets)
var my_id = ""

func _ready():
	# Is this the server?
	var args = Array(OS.get_cmdline_args())
	if args.has("--server"):
		is_server = true
