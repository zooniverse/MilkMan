Milkman::Application.config.project = {
	"name" => "Particle Milkman",
	"project" => "Higgs Hunters",
	"url" => "huggshunters.org",
	"slug" => "higgs_hunter",
	"image" => { "width"=>1024.0, "height"=>1023.0 },
	"object_types" => [ "vertex", "weird" ],
	"hex" => { "vertex"=>"#82DEFF", "weird"=>"#FF8F61" },
	"types" => { "Vertex"=>"vertex", "Weird"=>"weird" },
	"dbscan" => { "eps" => 20, "min" => 2 },
	"styles" => { "action" => "#88cb84", "action_hover" => "#B7E7BA", "accent" => "#c75a5e" },
	"min_random" => 3,
	"example_zoo_id" => "AHH0000055"
}

# Milkman::Application.config.project = {
# 	"name" => "Iced Milkman",
# 	"project" => "Penguin Watch",
# 	"url" => "penguinwatch.org",
# 	"slug" => "penguin",
# 	"image" => { "width"=>1000.0, "height"=>563.0 },
# 	"object_types" => [ "adult", "chick", "egg"],
# 	"hex" => { "adult"=>"#ff9900", "chick"=>"#99ff00", "egg"=>"#ffff00" },
# 	"types" => { "Adult"=>"adult", "Chick"=>"chick", "Egg"=>"egg" },
# 	"dbscan" => { "eps" => 20, "min" => 2 },
# 	"styles" => { "action" => "#30C4FF", "action_hover" => "#8AD7FF", "accent" => "#A6D3FF" },
# 	"min_random" => 2,
# 	"example_zoo_id" => "APZ00003h1"
# }