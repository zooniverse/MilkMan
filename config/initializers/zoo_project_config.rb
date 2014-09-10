# Milkman::Application.config.project = {
# 	"name" => "Particle Milkman",
# 	"project" => "Higgs Hunters",
# 	"url" => "huggshunters.org",
# 	"slug" => "higgs_hunter",
# 	"image" => { "width"=>1024.0, "height"=>1023.0 },
# 	"object_types" => {
# 		"vertex" => {
# 			"hex" => "#82DEFF",
# 			"label" => "Vertex"
# 		},
# 		"weird" => {
# 			"hex" => "#FF8F61",
# 			"label" => "Weird"
# 		}
# 	},
# 	"dbscan" => {
# 		"eps" => 20,
# 		"min" => 2,
# 		"params" => {
# 			"x" => 1,
# 			"y" => 1,
# 			"frame" => 1000
# 		},
# 		"param_labels" => {
# 			"x" => "X (px)",
# 			"y" => "Y (px)"
# 		}
# 	},
# 	"styles" => { "action" => "#88cb84", "action_hover" => "#B7E7BA", "accent" => "#c75a5e" },
# 	"min_random" => 5,
# 	"example_zoo_id" => "AHH0000055"
# }

Milkman::Application.config.project = {
	"name" => "Iced Milkman",
	"project" => "Penguin Watch",
	"url" => "penguinwatch.org",
	"slug" => "penguin",
	"image" => { "width"=>1000.0, "height"=>563.0 },
	"object_types" => {
		"adult" => {
			"hex" => "#ff9900",
			"label" => "Adult"
		},
		"chick" => {
			"hex" => "#99ff00",
			"label" => "Chick"
		},
		"egg" => {
			"hex" => "#ffff00",
			"label" => "Egg"
		}
	},
	"dbscan" => {
		"eps" => 20,
		"min" => 3,
		"params" => {
			"x" => 1,
			"y" => 1,
			"frame" => 0
		},
		"param_labels" => {
			"x" => "X (px)",
			"y" => "Y (px)"
		}
	},
	"styles" => { "action" => "#30C4FF", "action_hover" => "#8AD7FF", "accent" => "#A6D3FF" },
	"min_random" => 2,
	"example_zoo_id" => "APZ00003h1"
}

# Milkman::Application.config.project = {
# 	"name" => "Martian Milkman",
# 	"project" => "Planet Four",
# 	"url" => "planetfour.org",
# 	"slug" => "planet_four",
# 	"image" => { "width"=>840.0, "height"=>648.0 },
# 	"object_types" => [ "blotch", "fan"],
# 	"hex" => { "blotch"=>"#57D6E4", "fan"=>"#D1C056" },
# 	"types" => { "Blotch"=>"blotch", "Fan"=>"fan" },
# 	"dbscan" => { "eps" => 20, "min" => 5, "params" => {"x", "y", "rx", "ry"}, "factors" => {} },
# 	"styles" => { "action" => "#E6241C", "action_hover" => "#FD8272", "accent" => "#C27A13" },
# 	"min_random" => 50,
# 	"example_zoo_id" => "APF0000s37"
# }