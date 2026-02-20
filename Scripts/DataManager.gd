extends Node

# --- 1. Global / Member Variables (Visible to all functions) ---
@export var ad_rate_per_viewer: float = 500000.0

var all_contracts: Array[Contract] = []
var networks = {} 
var shows = {}    
var people = {}   
var show_types = {} 

# --- 2. Configuration Data ---
var role_weights = {
	"Lead Actor": 1.0,
	"Host": 1.0,
	"Anchor": 1.0,
	"Showrunner": 0.8,
	"Support": 0.5,
	"Reporter": 0.4
}

# --- 3. Built-in Godot Functions ---
func _ready():
	randomize() # Ensures different results each run
	
	# Load all CSV data
	load_networks("res://Data/TV network data - Networks.csv")
	load_shows("res://Data/TV network data - Shows.csv")
	load_people("res://Data/TV network data - People.csv")
	load_contracts("res://Data/TV network data - Contracts.csv")
	
	# Run the Simulation
	simulate_weekly_ratings()
	run_network_summary()

# --- 4. Data Loading Functions ---
func load_networks(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return
	file.get_csv_line() 
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 2: continue
		var net = Network.new()
		net.id = line[0]
		net.name = line[1]
		networks[net.id] = net

func load_shows(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return
	file.get_csv_line()
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 4: continue
		var s = Show.new()
		s.id = line[0]
		s.network_id = line[1]
		s.type_id = line[2]
		s.name = line[3]
		s.duration = int(line[6])
		shows[s.id] = s
		if networks.has(s.network_id):
			networks[s.network_id].shows.append(s)

func load_people(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return
	file.get_csv_line()
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 6: continue
		var p = Person.new()
		p.id = line[0]
		p.name = line[1]
		p.fame = int(line[3])
		p.comedic_timing = int(line[4])
		p.dramatic_gravitas = int(line[5])
		people[p.id] = p

func load_contracts(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return
	file.get_csv_line()
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 8: continue
		var c = Contract.new()
		c.show_id = line[1]
		c.person_id = line[2]
		c.salary = float(line[5])
		c.role = line[7]
		all_contracts.append(c)
		if shows.has(c.show_id):
			shows[c.show_id].weekly_cost += c.salary

# --- 5. Simulation Logic ---
func get_contracts_for_show(target_show_id: String) -> Array[Contract]:
	var found_contracts: Array[Contract] = []
	for c in all_contracts:
		if c.show_id == target_show_id:
			found_contracts.append(c)
	return found_contracts

func calculate_show_quality(show_id: String) -> float:
	var show = shows[show_id]
	var total_weighted_score = 0.0
	var total_weight = 0.0
	
	for contract in get_contracts_for_show(show_id):
		if not people.has(contract.person_id): continue
		var person = people[contract.person_id]
		var weight = role_weights.get(contract.role, 0.3)
		
		# Simplification for prototype: avg of talent stats
		var talent_avg = (person.comedic_timing + person.dramatic_gravitas) / 2.0
		var performance = (person.fame + talent_avg) / 2.0
		
		total_weighted_score += (performance * weight)
		total_weight += weight
		
	return total_weighted_score / total_weight if total_weight > 0 else 0.0

func simulate_weekly_ratings():
	print("\n--- SIMULATING WEEK ---")
	print("Using Ad Rate: ", ad_rate_per_viewer)
	
	for show_id in shows:
		var s = shows[show_id]
		s.quality_score = calculate_show_quality(show_id)
		
		# Convert quality (0-100) to viewers (0-30M)
		var base_viewers = (s.quality_score / 5.0) + randf_range(-1.0, 1.0)
		s.viewers_millions = clamp(base_viewers, 0.1, 30.0)
		
		var blocks = s.duration / 30.0
		var gross_revenue = s.viewers_millions * ad_rate_per_viewer * blocks
		s.weekly_profit = gross_revenue - s.weekly_cost
		
		print("Show: %-20s | Profit: $%10d" % [s.name, s.weekly_profit])

func run_network_summary():
	print("\n--- NETWORK FINANCIAL SUMMARY ---")
	for net_id in networks:
		var net = networks[net_id]
		var total_net_profit = 0.0
		for s in net.shows:
			total_net_profit += s.weekly_profit
		print("Network: %-5s | Total Weekly Profit: $%d" % [net.name, total_net_profit])
