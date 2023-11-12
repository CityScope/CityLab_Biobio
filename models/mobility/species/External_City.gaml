model ExternalCity

import "./Building.gaml"

species externalCities parent:building{
	string id;
	point real_location;
	point entry_location;
	list<float> people_distribution;
	list<float> building_distribution;
	list<building> external_buildings;
	
	aspect base{
		draw circle(0) color:rgb(95,190,190) at:entry_location;
	}
}
