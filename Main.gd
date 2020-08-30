extends Spatial

const DEFAULT_PORT = 3000
const MAX_PEERS = 10
var players = {}
var player_name = "Server"

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	start_server()

func start_server():
	print("Hosting server")
	var host = NetworkedMultiplayerENet.new()
	var err = host.create_server(DEFAULT_PORT, MAX_PEERS)
	
	# will throw an error if address is already in use
#	if (err != OK):
#		return
	
	# we set the network here, creating a peer on the multiplayer network here
	get_tree().set_network_peer(host)
	
	# assigns server as network player ID 1
	# delayed call so it can finish setup before calling "add_child" in func
	call_deferred("spawn_player", 1) 
	print("Server running")

func _player_connected(id):
	print("Player connected to server ID# ", id)
	
func _player_disconnected(id):
	unregister_player(id)
	
remote func register_player_server(id, name):
	print("Sending Register Player call to Clients")
	players[id] = {}
	players[id]["name"] = name
	players[id]["pos"] = Vector3(3, 1, 3)
	spawn_player(id)
	
	rpc("register_player_client", id, "Client")
	
	for pid in players:
		if pid != id:
			rpc_id(id, "register_player_client", pid, "Other Player")

func unregister_player(id):
	print("Unregistering Player")
	players.erase(id)

func spawn_player(id):
	print ("Spawning Server, ID# ", id)
	var player = load("res://Player.tscn").instance()
	player.set_translation(Vector3(3, 1, 3))
	player.set_network_master(id)
	player.set_name(str(id))
	add_child(player)

remote func update_pos_server(movement, player_id):
	var player = get_node(str(player_id))
	player.translate(movement)
	
	rpc_unreliable("update_pos_client", player.get_translation(), player_id)

remote func print_something():
	print("SERVER PRINTING SOMETHING, MEANS PACKET RECEIVED")
