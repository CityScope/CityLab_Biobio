model Bus

import "./People.gaml"

species bus skills: [moving] {
	list<bus_stop> stops; 
	map<bus_stop,list<people>> stop_passengers ;
	bus_stop my_target;
	
	reflex new_target when: my_target = nil{
		bus_stop firstStop <- first(stops);
		remove firstStop from: stops;
		add firstStop to: stops; 
		my_target <- firstStop;
	}
	
	reflex r {
		do goto target: my_target.location on: graph_per_mobility["car"] speed:speed_per_mobility["bus"];
		int nb_passengers <- stop_passengers.values sum_of (length(each));
		if (nb_passengers > 0) {
				transport_type_distance["bus"] <- transport_type_distance["bus"] + speed/step;
				transport_type_distance["bus_people"] <- transport_type_distance["bus_people"] + speed/step * nb_passengers;
		} 
			
		if(location = my_target.location) {
			////////      release some people
			ask stop_passengers[my_target] {
				location <- myself.my_target.location;
				bus_status <- 2;
			}
			stop_passengers[my_target] <- [];
			/////////     get some people
			loop p over: my_target.waiting_people {
				bus_stop b <- bus_stop with_min_of(each distance_to(p.my_current_objective.place.location));
				add p to: stop_passengers[b] ;
			}
			my_target.waiting_people <- [];						
			my_target <- nil;			
		}
	}
	
	aspect bu {
		draw rectangle(40,20) color: empty(stop_passengers.values accumulate(each))?#yellow:#red border: #black;
	}
}
