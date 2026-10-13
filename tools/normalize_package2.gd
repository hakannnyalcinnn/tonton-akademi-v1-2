extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Match=preload("res://scripts/core/match_detector.gd")
func _initialize() -> void:
	var content=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels-31-50.json"))
	for definition in content.levels:
		var b=Board.new(definition)
		definition.layout=[];definition.mechanics=[]
		for i in 72:
			definition.layout.append(int(b.cells[i].c))
			for layer in ["trait","armor","obstacle"]:
				if not b.cells[i].has(layer):continue
				var m: Dictionary=b.cells[i][layer]
				var spec: Dictionary={"kind":m.kind,"index":i}
				for key in ["colors","sequence","period","phase","color","required"]:
					if m.has(key):spec[key]=m[key]
				definition.mechanics.append(spec)
		var options:=Match.legal_swaps(b.cells,8,9)
		var chosen: Array=options[0]
		for pair in options:
			var first=b.cells[pair[0]]
			b.cells[pair[0]]=b.cells[pair[1]];b.cells[pair[1]]=first
			var contains_dual:=false
			for index in Match.indices(Match.find(b.cells,8,9,pair)):
				if b.cells[index].get("trait",{}).get("kind","")=="dual":contains_dual=true
			b.cells[pair[1]]=b.cells[pair[0]];b.cells[pair[0]]=first
			if contains_dual and (b.cells[pair[0]].get("trait",{}).get("kind","")=="dual" or b.cells[pair[1]].get("trait",{}).get("kind","")=="dual"):chosen=pair;break
		definition.tutorial_swap=chosen
		assert(b.find_matches().is_empty())
	var output:=FileAccess.open("res://data/levels-31-50.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(content,"  "));output.close()
	print("Normalized 20 explicit trait-safe layouts and legal tutorial gestures")
	quit()
