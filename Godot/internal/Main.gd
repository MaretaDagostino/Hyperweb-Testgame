extends Node

# Here we can specify the public IP address for playing through the internet.
export var IP_ADDR = "localhost"
# Port can be changed, but mus be the same as the server's.
# Make sure your ISP doesn't block it. Also open it in the router settings.
export var PORT = 7936

const MAX_PLAYERS = 15
var spawn_point = null

var enet : NetworkedMultiplayerENet

onready var player_tscn = preload("res://internal/player/Player.tscn")

func _ready():
	# Creating a new network instance
	enet = NetworkedMultiplayerENet.new()
	if Globals.is_server == true:
		var _network = enet.create_server(PORT, MAX_PLAYERS)
		get_tree().set_network_peer(enet)
		# Connecting network events
		var _err_connected = get_tree().connect("network_peer_connected",
			self, "_on_client_connected")
		var _err_disconnected = get_tree().connect("network_peer_disconnected",
			self, "_on_client_disconnected")
		# Set spawn point for players
		# TODO: Fallback if somebody's Level.tscn has no spawn point
		spawn_point = $Level/Spawn_Point
		# We show a small window without start button in server mode
		$Menu/Button.hide()
		OS.set_window_size(Vector2(400, 1))
	else:
		# Connecting network and button events
		var _err_connected = get_tree().connect("network_peer_connected",
			self, "_on_player_connected")
		var _err_disconnected = get_tree().connect("network_peer_disconnected",
			self, "_on_player_disconnected")
		var _err_conn_to_server = get_tree().connect("connected_to_server",
			self, "_on_connected_to_server")
		var _err_conn_failed = get_tree().connect("connection_failed",
			self, "_on_connection_failed")
		var _err_server_disconn = get_tree().connect("server_disconnected",
			self, "_on_server_disconnected")
		var _err_button_pressed = $Menu/Button.connect("pressed",
			self, "_on_connect_pressed")

# Server: Create a player and set its name to the ID given by the network API
func _on_client_connected(id):
	var player = player_tscn.instance()
	player.set_name(str(id))
	$Players.add_child(player)
	player.global_transform.origin = spawn_point.global_transform.origin
	print("Client " + str(id) + " connected.")

# Server: Remove the player resource based on a disconnected ID
func _on_client_disconnected(id):
	for p in $Players.get_children():
		if int(p.name) == id:
			$Players.remove_child(p)
			p.queue_free()
	print("Client " + str(id) + " disconnected.")

# Client: Other player enters the game
func _on_player_connected(id):
	var player = player_tscn.instance()
	player.set_name(str(id))
	# Replace camera with dummy, otherwise it steals focus from active player
	var dummy = Spatial.new()
	dummy.name = "Camera"
	player.get_node("Head/Camera").replace_by(dummy)
	# Add puppet, this is a player without camera
	$Players.add_child(player)

# Client: Other player leaves the game
func _on_player_disconnected(id):
	# Wait a little time for execution of pending RPC communication
	yield(get_tree().create_timer(0.5),"timeout")
	# Remove puppet from scene
	for p in $Players.get_children():
		if int(p.name) == id:
			$Players.remove_child(p)
			p.queue_free()

# Client: After successful connection create a player instance and activate camera
func _on_connected_to_server():
	Globals.my_id = str(get_tree().get_network_unique_id())
	var player = player_tscn.instance()
	player.set_name(Globals.my_id)
	$Players.add_child(player)

# Client: Called after some time without successful connection
func _on_connection_failed():
	# TODO: Better reaction and information to user, endless grey screen here
	get_tree().set_network_peer(null)

# Client: Quit if network breaks
func _on_server_disconnected():
	# TODO: Send information to user instead of silent crash 
	get_tree().quit()

# Client: Start the game
func _on_connect_pressed():
	$Menu/Button.visible = false
	$Menu/Background.visible = false
	# TODO: send information to user that the game is waiting for
	#       server connection instead of showing simply a grey screen
	var _err_client = enet.create_client(IP_ADDR, PORT)
	get_tree().set_network_peer(enet)
