model People

import "./Building.gaml"
import "../Game_IT_costanera.gaml"

species people skills: [moving]{
	string type;
	rgb color ;
	float size<-10#m;	
	building living_place;
	list<trip_objective> objectives;
	trip_objective my_current_objective;
	building current_place;
	string mobility_mode;
	list<string> possible_mobility_modes;
	bool has_car ;
	bool has_bike;

	bus_stop closest_bus_stop;	
	int bus_status <- 0;
	
	action create_trip_objectives {
		map<string,int> activities <- activity_data[type];
		//if (activities = nil ) or (empty(activities)) {write "my type: " + type;}
		loop act over: activities.keys {
			if (act != "") {
				list<string> parse_act <- act split_with "|";
				string act_real <- one_of(parse_act);
				list<building> possible_bds;
				list<building> external <- externalCities where true;
				if (length(act_real) = 2) and (first(act_real) = "R") {
					possible_bds <- building where ((each.usage = "R") and (each.scale = last(act_real)));
					if(length(possible_bds) = 0){
						possible_bds <- possible_bds + external;
					}
				} 
				else if (length(act_real) = 2) and (first(act_real) = "O") {
					possible_bds <- building where ((each.usage = "O") and (each.scale = last(act_real)));
					if(length(possible_bds) = 0 or rnd(100)>90){
						possible_bds <- possible_bds + external;
					}
				
				} 
				else {
					possible_bds <- building where (act_real in each.category);
					if(length(possible_bds) = 0 or rnd(100)>90){
						possible_bds <- possible_bds + external;
					}
				}
				
				building act_build <- one_of(possible_bds);
				if (act_build= nil) {write "problem with act_real: " + act_real;}
				do create_activity(act_real,act_build,activities[act]);
			}
		}
	}
	
	action create_activity(string act_name, building act_place, int act_time) {
		create trip_objective {
			name <- act_name;
			place <- act_place;
			starting_hour <- act_time;
			starting_minute <- rnd(60);
			myself.objectives << self;
		}
	} 
	
	action choose_mobility_mode {
		list<list> cands <- mobility_mode_eval();
		map<string,list<float>> crits <-  weights_map[type];
		list<float> vals;
		loop obj over:crits.keys {
			if (obj = my_current_objective.name) or
			 ((my_current_objective.name in ["RS", "RM", "RL"]) and (obj = "R"))or
			 ((my_current_objective.name in ["OS", "OM", "OL"]) and (obj = "O")){
				vals <- crits[obj];
				break;
			} 
		}
		list<map> criteria_WM;
		loop i from: 0 to: length(vals) - 1 {
			criteria_WM << ["name"::"crit"+i, "weight" :: vals[i]];
		}
		int choice <- weighted_means_DM(cands, criteria_WM);
		if (choice >= 0) {
			mobility_mode <- possible_mobility_modes [choice];
		} else {
			mobility_mode <- one_of(possible_mobility_modes);
		}
		transport_type_cumulative_usage[mobility_mode] <- transport_type_cumulative_usage[mobility_mode] + 1;
		
		if (type = 'High School Student') {
			transport_type_cumulative_usage_high_school[mobility_mode] <- transport_type_cumulative_usage_high_school[mobility_mode] + 1;
		}
		
		transport_type_cumulative_usage_per_profile[type][mobility_mode] <- transport_type_cumulative_usage_per_profile[type][mobility_mode] + 1;
		transport_type_usage[mobility_mode] <-transport_type_usage[mobility_mode]+1;
		speed <- speed_per_mobility[mobility_mode];
	}
	
	list<list> mobility_mode_eval {
		list<list> candidates;
		loop mode over: possible_mobility_modes {
			list<float> characteristic <- charact_per_mobility[mode];
			list<float> cand;
			float distance <-  0.0;
			using topology(graph_per_mobility[mode]){
				distance <-  distance_to (location,my_current_objective.place.location);
			}
			cand << characteristic[0] + characteristic[1]*distance;
			cand << characteristic[2] #mn +  distance / speed_per_mobility[mode];
			cand << characteristic[4];
		
			cand << characteristic[5] * (weatherImpact ?(1.0 + weather_of_day * weather_coeff_per_mobility[mode]  ) : 1.0);
			add cand to: candidates;
		}
		
		//normalisation
		list<float> max_values;
		loop i from: 0 to: length(candidates[0]) - 1 {
			max_values << max(candidates collect abs(float(each[i])));
		}
		loop cand over: candidates {
			loop i from: 0 to: length(cand) - 1 {
				if ( max_values[i] != 0.0) {cand[i] <- float(cand[i]) / max_values[i];}
				
			}
		}
		return candidates;
	}
	
	action updatePollutionMap{
		ask gridHeatmaps overlapping(current_path.shape) {
			pollution_level <- pollution_level + 1;
		}
	}	
	
	reflex updateDensityMap when: (every(#hour) and updateDensity=true){
		ask gridHeatmaps{
		  density<-length(people overlapping self);	
		}
	}
	
	
	
	reflex choose_objective when: my_current_objective = nil {
	    //location <- any_location_in(current_place);
		do wander speed:0.01;
		my_current_objective <- objectives first_with ((each.starting_hour = current_date.hour) and (current_date.minute >= each.starting_minute) and (current_place != each.place) );
		if (my_current_objective != nil) {
			current_place <- nil;
			possible_mobility_modes <- ["walking"];
			if (has_car) {possible_mobility_modes << "car";}
			if (has_bike) {possible_mobility_modes << "bike";}
			possible_mobility_modes << "bus";				
			do choose_mobility_mode;
		}
	}
	reflex move when: (my_current_objective != nil) and (mobility_mode != "bus") {
		transport_type_distance[mobility_mode] <- transport_type_distance[mobility_mode] + speed/step;
		if ((current_edge != nil) and (mobility_mode in ["car"])) {road(current_edge).current_concentration <- max([0,road(current_edge).current_concentration - 1]); }
		if (mobility_mode in ["car"]) {
			do goto target: my_current_objective.place.location on: graph_per_mobility[mobility_mode] move_weights: congestion_map ;
		}else {
			do goto target: my_current_objective.place.location on: graph_per_mobility[mobility_mode]  ;
		}
		
		if (location = my_current_objective.place.location) {
			if(mobility_mode = "car" and updatePollution = true) {do updatePollutionMap;}					
			current_place <- my_current_objective.place;
			location <- any_location_in(current_place);
			my_current_objective <- nil;	
			mobility_mode <- nil;
		} else {
			if ((current_edge != nil) and (mobility_mode in ["car"])) {road(current_edge).current_concentration <- road(current_edge).current_concentration + 1; }
		}
	}
	
	reflex move_bus when: (my_current_objective != nil) and (mobility_mode = "bus") {

		if (bus_status = 0){
			do goto target: closest_bus_stop.location on: graph_per_mobility["walking"];
			transport_type_distance["walking"] <- transport_type_distance["walking"] + speed/step;
			
			if(location = closest_bus_stop.location) {
				add self to: closest_bus_stop.waiting_people;
				bus_status <- 1;
			}
		} else if (bus_status = 2){
			do goto target: my_current_objective.place.location on: graph_per_mobility["walking"];		
			transport_type_distance["walking"] <- transport_type_distance["walking"] + speed/step;
			
			if (location = my_current_objective.place.location) {
				current_place <- my_current_objective.place;
				closest_bus_stop <- bus_stop with_min_of(each distance_to(self));						
				location <- any_location_in(current_place);
				my_current_objective <- nil;	
				mobility_mode <- nil;
				bus_status <- 0;
			}
		}
	}	
	
	aspect default {
		if (mobility_mode = nil) {
			draw circle(size) at: location + {0,0,(current_place != nil ?current_place.height : 0.0) + 4}  color: color ;
		} else {
			if (mobility_mode = "walking") {
				draw circle(size) color: color  ;
			}else if (mobility_mode = "bike") {
				draw triangle(size) rotate: heading +90  color: color depth: 8 ;
			} else if (mobility_mode = "car") {
				draw square(size*2)  color: color ;
			}
		}
	}
	
	
	aspect base{
	  draw circle(size) at: location + {0,0,(current_place != nil ?current_place.height : 0.0) + 4}  color: color ;
	}
	aspect layer {
		if(cycle mod 180 = 0){
			draw sphere(size) at: {location.x,location.y,cycle*2} color: color ;
		}
	}
}

species trip_objective{
	building place; 
	int starting_hour;
	int starting_minute;
}

species bus_stop {
	list<people> waiting_people;
	
	aspect c {
		draw circle(30) color: empty(waiting_people)?#black:#blue border: #black depth:1;
	}
}
