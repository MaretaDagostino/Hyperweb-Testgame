extends Node

# This script is global. It autoloads and we can access it from other scripts.

# A Variable to distinguish between server and client
var is_server = false

# Player ID to distinguish between active player and others (puppets)
var my_id = ""

# Inworld reference environment for skyboxes and alike
remotesync var environment = {
	time_of_day = 14.0,     # 0 to <24
	clouds_coverage = 0.5,  # 0 to 1
	fog = 0.2,              # 0 to 1, density
	wind_strength = 4.0,    # 0 to 10
	wind_dir = 130.0,       # 0 to <360 clockwise, 0 is wind from north
	moon_phase = -1.0,      # -1 to 1, new moon is 0
	thunder = false,        # set this to true only, will be reset automatically
}

func _ready():
	# Is this the server?
	var args = Array(OS.get_cmdline_args())
	if args.has("--server"):
		is_server = true

# Server: Distribute environment for skyboxes and alike
func sync_environment():
	rset("environment", Globals.environment)

# Clients: Ask server to modify environment features
func send_time_of_day(value):
	rpc("receive_time_of_day", value)

func send_clouds_coverage(value):
	rpc("receive_clouds_coverage", value)

func send_fog(value):
	rpc("receive_fog", value)

func send_wind_strength(value):
	rpc("receive_wind_strength", value)

func send_wind_dir(value):
	rpc("receive_wind_dir", value)

func send_moon_phase(value):
	rpc("receive_moon_phase", value)

func send_thunder(value):
	rpc("receive_thunder", value)

# Server: Receive request to modify environment features
master func receive_time_of_day(value):
	environment.time_of_day = value

master func receive_clouds_coverage(value):
	environment.clouds_coverage = value

master func receive_fog(value):
	environment.fog = value

master func receive_wind_strength(value):
	environment.wind_strength = value

master func receive_wind_dir(value):
	environment.wind_dir = value

master func receive_moon_phase(value):
	environment.moon_phase = value

master func receive_thunder(value):
	environment.thunder = value
