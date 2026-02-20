extends Node

# Place these at the top of DataManager.gd
var all_contracts: Array[Contract] = []

func load_contracts(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Error: Could not open contracts file at ", path)
		return
		
	file.get_csv_line() # Skip header
	
	while !file.eof_reached():
		var line = file.get_csv_line()
		# Your Contracts.csv has 8 columns (0 to 7)
		if line.size() < 8: 
			continue
		
		var c = Contract.new()
		c.show_id = line[1]
		c.person_id = line[2]
		c.salary = float(line[5])
		c.role = line[7]
		
		all_contracts.append(c)
		
		# Link financial data to the show object
		if shows.has(c.show_id):
			shows[c.show_id].weekly_cost += c.salary
# Dictionaries to store data for quick lookup by ID
var networks = {} # Key: Network_ID, Value: Network object
var shows = {}    # Key: Show_ID, Value: Show object
var people = {}   # Key: Person_ID, Value: Person object


func _ready():
	load_networks("res://Data/TV network data - Networks.csv")
	load_shows("res://Data/TV network data - Shows.csv")
	load_people("res://Data/TV network data - People.csv")
	load_contracts("res://Data/TV network data - Contracts.csv")
	
	run_initial_check()

func load_networks(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line() # Skip header
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 2: continue
		
		var net = Network.new()
		net.id = line[0]
		net.name = line[1]
		networks[net.id] = net

func load_shows(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line() # Skip header
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 4: continue
		
		var s = Show.new()
		s.id = line[0]
		s.network_id = line[1]
		s.name = line[3]
		s.duration = int(line[6])
		shows[s.id] = s
		
		# Link show to its network
		if networks.has(s.network_id):
			networks[s.network_id].shows.append(s)

func load_people(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line() # Skip header
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 4: continue
		
		var p = Person.new()
		p.id = line[0]
		p.name = line[1]
		p.fame = int(line[3])
		people[p.id] = p

func load_contracts(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line() # Skip header
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 6: continue
		
		var show_id = line[1]
		var salary = float(line[5])
		
		# Add salary to the show's weekly cost
		if shows.has(show_id):
			shows[show_id].weekly_cost += salary

func run_initial_check():
	print("--- 2008 TV Network Simulation Prototype ---")
	for net_id in networks:
		var net = networks[net_id]
		var total_talent_payroll = 0.0
		for s in net.shows:
			total_talent_payroll += s.weekly_cost
		
		print("Network: %s | Shows: %d | Weekly Talent Spend: $%d" % [
			net.name, 
			net.shows.size(), 
			total_talent_payroll
		])
# Weights: Leads/Hosts have more impact (1.0) than Support (0.5)
var role_weights = {
	"Lead Actor": 1.0,
	"Host": 1.0,
	"Anchor": 1.0,
	"Showrunner": 0.8, # Writers/Producers matter a lot for quality!
	"Support": 0.5,
	"Reporter": 0.4
}
	# We need to find all people linked to this show in our contracts
	# (In a more advanced setup, you'd store a list of People inside the Show object)
for contract in all_contracts_list: 
if contract.show_id == show_id:
			var person = people[contract.person_id]
			var weight = role_weights.get(contract.role, 0.3) # Default 0.3 if role unknown
			
			# Determine which stat to use based on ShowType_ID
			# TYPE_01 = Drama, TYPE_03/04 = Comedy/Late Night
			var talent_stat = 0
		match show.type_id:
				"TYPE_01": talent_stat = person.dramatic_gravitas
				"TYPE_03", "TYPE_04": talent_stat = person.comedic_timing
				_: talent_stat = (person.dramatic_gravitas + person.comedic_timing) / 2
			
			# Quality = (Fame + Talent Stat) / 2
			var person_performance = (person.fame + talent_stat) / 2.0
			
			total_weighted_score += (person_performance * weight)
			total_weight += weight
			
	if total_weight == 0: return 0.0
	return total_weighted_score / total_weight
	
	var show_types = {} # Key: TYPE_01, Value: ShowType object

func load_show_types(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line() # Header
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 2: continue
		
		var st = ShowType.new()
		st.id = line[0]
		st.name = line[1]
		
		# Set which stat matters for this type
		match st.name:
			"Drama": st.primary_stat = "dramatic_gravitas"
			"Comedy", "Late Night": st.primary_stat = "comedic_timing"
			"News": st.primary_stat = "creative_vision"
			"Reality": st.primary_stat = "fame" # In 2008, Reality was all about Fame!
			_: st.primary_stat = "fame"
			
		show_types[st.id] = st

func calculate_show_quality(show_id: String) -> float:
	var show = shows[show_id]
	var type_data = show_types.get(show.type_id)
	
	var total_weighted_score = 0.0
	var total_weight = 0.0
	
	# Loop through contracts (Assuming you have a way to filter contracts by show)
	for contract in get_contracts_for_show(show_id):
		var person = people[contract.person_id]
		var weight = role_weights.get(contract.role, 0.3)
		
		# Dynamically get the stat based on the ShowType's primary_stat
		var talent_stat = person.get(type_data.primary_stat) if type_data else person.fame
		
		# Quality calculation: (Fame + Specific Talent) / 2
		var performance = (person.fame + talent_stat) / 2.0
		total_weighted_score += (performance * weight)
		total_weight += weight
		
	return total_weighted_score / total_weight if total_weight > 0 else 0.0
