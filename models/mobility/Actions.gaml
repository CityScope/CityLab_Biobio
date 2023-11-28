
model Actions

import "./Game_IT_costanera.gaml"

  	global{
  		
	
	    reflex save_simu_attribute when: (cycle mod 60 = 0){
			float car_co2 <- 0.26; // kg/km (Car: 24,20 MPG = 9,72 L/100km = 26,05 kg/100km)
			float bus_co2 <- 1.92; // kg/km (Transit bus: 3,26 MPG = 72,152 L/100km = 192,37 kg/100km)
			co2_capita <- co2_capita + (transport_type_usage.values[2]*transport_type_distance.values[2]*car_co2 + transport_type_usage.values[3]*transport_type_distance.values[3]*bus_co2)/nb_people;
			// float daylight_function <- sin((#pi/12) * (cycle) - 2.1*60) + 0.6;
			save [cycle,transport_type_usage.values[0] ,transport_type_cumulative_usage.values[0],transport_type_usage.values[1],transport_type_cumulative_usage.values[1],transport_type_usage.values[2],transport_type_cumulative_usage.values[2],transport_type_usage.values[3],transport_type_cumulative_usage.values[3], mean (people collect (each.speed)), transport_type_distance.values[0],transport_type_distance.values[1],transport_type_distance.values[2],transport_type_distance.values[3],transport_type_distance.values[4],co2_capita] rewrite:false to: "../results/mobility.csv" format:"csv";
			save [cycle,transport_type_cumulative_usage_high_school.values[0] ,transport_type_cumulative_usage_high_school.values[1], transport_type_cumulative_usage_high_school.values[2], transport_type_cumulative_usage_high_school.values[3], mean (people collect (each.speed)), transport_type_distance.values[0],transport_type_distance.values[1],transport_type_distance.values[2],transport_type_distance.values[3],transport_type_distance.values[4]] rewrite:false to: "../results/mobility_aggregated.csv" format:"csv";
			
			// Reset value
			transport_type_usage <- map(mobility_list collect (each::0));
			transport_type_distance <- map(mobility_list collect (each::0.0)) + ["bus_people"::0.0];
			if (cycle mod (60*24) = 0) {
				co2_capita <- 0.0;
			}
			
			if(cycle = 60*24*7){ // show a full week
				do pause;
			}
		}
		
		// This reflex updates the weights when adjusting parameters
	    reflex update_weights when: (cycle = 0){
	
	    	if(adjusting){
	
				map<string, list<float>> m_temp <- map([]);
				loop cat over: cats {
					add [price, time_ad, social_pattern, difficulty] at: cat to: m_temp;
				}
				add m_temp at: adjusting_profile to: weights_map;
				
				proba_car_per_type[adjusting_profile] <- proba_car;
				proba_bike_per_type[adjusting_profile] <- proba_bike;
			}
	    }
	
		// This reflex updates the fitness when adjusting parameters
	    reflex update_fitness when: (cycle mod 1419 = 0){
	    	
	    	if(adjusting and cycle != 0){
		    	write(transport_type_cumulative_usage_per_profile);
		    	int current_walking <- transport_type_cumulative_usage_per_profile[adjusting_profile]["walking"];
		    	int current_bike <- transport_type_cumulative_usage_per_profile[adjusting_profile]["bike"];
		    	int current_car <- transport_type_cumulative_usage_per_profile[adjusting_profile]["car"];
		    	int current_bus <- transport_type_cumulative_usage_per_profile[adjusting_profile]["bus"];
		    	
		    	int sum <- current_walking + current_bike + current_car + current_bus;
		    	float total_difference <- 99999999.0;
		    	if(sum != 0){
		    			float walking_difference <-  (100*objetive_walking) ^ 2;
		    			if(current_walking != 0){
		    				walking_difference <-  (100*objetive_walking - 100*(current_walking / sum)) ^ 2;
		    			} 
		    			
			    		float bike_difference <-  (100*objective_bike) ^ 2;
		    			if(current_bike != 0){
			    			bike_difference <-  (100*objective_bike - 100*(current_bike / sum)) ^ 2;
		    			} 
			    		float car_difference <-  (100*objective_car)^2;
		    			if(current_car != 0){
			    			car_difference <-  (100*objective_car - 100*(current_car / sum))^2;
		    			} 
			    		float bus_difference <-  (100*objective_bus)^2;
		    			if(current_bus != 0){
			    			bus_difference <-  (100*objective_bus - 100*(current_bus / sum))^2;
		    			} 
		    		
		    		// Debug outputs			    	
			    	//write("objetive walking: " + objetive_walking);
			    	//write("current_walking: " + current_walking / sum);
			    	//write("objective_bike: " + objective_bike);
			    	//write("current_bike: " + current_bike / sum);
			    	//write("objective_bus: " + objective_bus);
			    	//write("current_bus: " + current_bus / sum);
			    	//write("objective_car: " + objective_car);
			    	//write("current_car: " + current_car / sum);
			    	
			    	total_difference <- sqrt(walking_difference + bike_difference + car_difference + bus_difference);
		    	}
		    	fitness <- 5*(total_difference);
		    	write("fitness: " + fitness);
	    	}
	    	
	    }
		
		action import_weather_data {
			matrix weather_matrix <- matrix(weather_coeff);
			loop i from: 0 to:  weather_matrix.rows - 1 {
				weather_of_month << [float(weather_matrix[1,i]), float(weather_matrix[2,i])];
			}
		}
		
		action profils_data_import {
			matrix profile_matrix <- matrix(profile_file);
			loop i from: 0 to:  profile_matrix.rows - 1 {
				string profil_type <- profile_matrix[0,i];
				if(profil_type != "") {
					proba_car_per_type[profil_type] <- float(profile_matrix[2,i]);
					proba_bike_per_type[profil_type] <- float(profile_matrix[3,i]);
					proportion_per_type[profil_type] <- float(profile_matrix[4,i]);
					
					// Init map
					transport_type_cumulative_usage_per_profile[profil_type] <- map(mobility_list collect (each::0));	
				}
			}
		}
		
		action activity_data_import {
			matrix activity_matrix <- matrix (activity_file);
			loop i from: 1 to:  activity_matrix.rows - 1 {
				string people_type <- activity_matrix[0,i];
				map<string, int> activities;
				string current_activity <- "";
				loop j from: 1 to:  activity_matrix.columns - 1 {
					string act <- activity_matrix[j,i];
					if (act != current_activity) {
						activities[act] <-j;
						 current_activity <- act;
					}
				}
				activity_data[people_type] <- activities;
			}
		}
		
		action criteria_file_import {
			matrix criteria_matrix <- matrix (criteria_file);
			int nbCriteria <- criteria_matrix[1,0] as int;
			int nbTO <- criteria_matrix[1,1] as int ;
			int lignCategory <- 2;
			int lignCriteria <- 3;
			
			loop i from: 5 to:  criteria_matrix.rows - 1 {
				string people_type <- criteria_matrix[0,i];
				int index <- 1;
				map<string, list<float>> m_temp <- map([]);
				if(people_type != "") {
					list<float> l <- [];
					loop times: nbTO {
						list<float> l2 <- [];
						loop times: nbCriteria {
							add float(criteria_matrix[index,i]) to: l2;
							index <- index + 1;
						}
						string cat_name <-  criteria_matrix[index-nbTO,lignCategory];
						loop cat over: cat_name split_with "|" {
							add l2 at: cat to: m_temp;
							if(not (cats contains cat)) {
								add cat to: cats;
							}
						}
					}
					add m_temp at: people_type to: weights_map;
				}
			}
			
		}
		
		action characteristic_file_import {
			matrix mode_matrix <- matrix (mode_file);
			loop i from: 0 to:  mode_matrix.rows - 1 {
				string mobility_type <- mode_matrix[0,i];
				if(mobility_type != "") {
					list<float> vals <- [];
					loop j from: 1 to:  mode_matrix.columns - 2 {
						vals << float(mode_matrix[j,i]);	
					}
					charact_per_mobility[mobility_type] <- vals;
					color_per_mobility[mobility_type] <- rgb(mode_matrix[7,i]);
					width_per_mobility[mobility_type] <- float(mode_matrix[8,i]);
					speed_per_mobility[mobility_type] <- float(mode_matrix[9,i]);
					weather_coeff_per_mobility[mobility_type] <- float(mode_matrix[10,i]);
				}
			}
		}
			
		action import_shapefiles {
			create road from: roads_shapefile {
				mobility_allowed <-["walking","bike","car","bus"];
				capacity <- shape.perimeter / 10.0;
				congestion_map [self] <- shape.perimeter;
			}
			create building from: buildings_shapefile with: [usage::string(read ("Usage")),scale::string(read ("Scale")),category::string(read ("Category"))]{
				color <- color_per_category[category];
			}
			create externalCities from: external_cities_shapefile with: [];		
		}
			
		
		action compute_graph {
			loop mobility_mode over: color_per_mobility.keys {
				graph_per_mobility[mobility_mode] <- as_edge_graph(road where (mobility_mode in each.mobility_allowed)) use_cache false;	
			}
		}
			
		reflex update_road_weights {
			ask road {
				do update_speed_coeff;	
				congestion_map [self] <- speed_coeff;
			}
		}
		
		reflex update_buildings_distribution{
			buildings_distribution <- map(color_per_category.keys collect (each::0));
			ask building{
				buildings_distribution[usage] <- buildings_distribution[usage]+1;
			}
		}
		
		reflex update_weather when: weatherImpact and every(#day){
			list<float> weather_m <- weather_of_month[current_date.month - 1];
			weather_of_day <- gauss(weather_m[0], weather_m[1]);
		}		

  	
  	}
