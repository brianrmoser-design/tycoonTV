extends Resource
class_name Show

var id: String
var name: String
var network_id: String
var type_id: String  # Important: This links to "TYPE_01", "TYPE_03", etc.
var duration: int

# Simulation Results
var quality_score: float = 0.0
var weekly_cost: float = 0.0
