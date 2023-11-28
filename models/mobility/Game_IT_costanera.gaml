/**
* Name: gamit Costanera
* Author: Arnaud Grignard, Tri Nguyen Huu, Patrick Taillandier, Benoit Gaudou
* Description: Describe here the model and its experiments
* Tags: Mobility, Costanera
*/

model gamit

import "./species/Building.gaml"
import "./species/Bus.gaml"
import "./species/External_City.gaml"
import "./species/People.gaml"
import "./species/Road.gaml"

import "./Actions.gaml"

import "./Configuration.gaml"

global {
	
	map<string,map<string,int>> activity_data;
	map<string, float> proportion_per_type;
	map<string, float> proba_bike_per_type;
	map<string, float> proba_car_per_type;	
	map<string,rgb> color_per_mobility;
	map<string,float> width_per_mobility;
	map<string,float> speed_per_mobility;
	map<string,graph> graph_per_mobility;
	map<string,float> weather_coeff_per_mobility;
	map<string,list<float>> charact_per_mobility;
	map<road,float> congestion_map;  
	map<string,map<string,list<float>>> weights_map <- map([]);
	list<list<float>> weather_of_month;
	
	// INDICATOR
	map<string,int> transport_type_cumulative_usage <- map(mobility_list collect (each::0));
	map<string,int> transport_type_cumulative_usage_high_school <- map(mobility_list collect (each::0));	
	map<string,map<string,int>> transport_type_cumulative_usage_per_profile <- map([]);
	map<string,int> transport_type_cumulative_usage_college <- map(mobility_list collect (each::0));
	map<string,int> transport_type_cumulative_usage_young_prof <- map(mobility_list collect (each::0));
	
	map<string,int> transport_type_usage <- map(mobility_list collect (each::0));
	map<string,float> transport_type_distance <- map(mobility_list collect (each::0.0)) + ["bus_people"::0.0];
	map<string, int> buildings_distribution <- map(color_per_category.keys collect (each::0));
	
	// UTIL
	list<string> cats <- [];
	
	// G.A. parameters:
	// fitness represents the value of the fitness function
	// set adjusting to true if the experiment will adjust parameters 
	float fitness <- 0.0;
	bool adjusting <- false;
	string adjusting_profile <- "Mid-career workers";
	
	// the sum of the objectives must be 1
	float objetive_walking <- 0.109;
	float objective_car <- 0.536;
	float objective_bus <- 0.342;
	float objective_bike <- 0.013;	
	
	float weather_of_day min: 0.0 max: 1.0;	

	image_file costanera <- image_file("../includes/city/costanera/concepcion.jpg");

	float co2_capita <- 0.0;

	init {
		gama.pref_display_flat_charts <- true;
		do import_shapefiles;	
		do profils_data_import;
		do activity_data_import;
		do criteria_file_import;
		do characteristic_file_import;
		do import_weather_data;
		do compute_graph;

		create bus_stop number: 6 {
			location <- one_of(building).location;
		}
		
		create bus {
			stops <- list(bus_stop);
			location <- first(stops).location;
			stop_passengers <- map<bus_stop, list<people>>(stops collect(each::[]));
		}		
		
		create people number: nb_people {
			type <- proportion_per_type.keys[rnd_choice(proportion_per_type.values)];
			has_car <- flip(proba_car_per_type[type]);
			has_bike <- flip(proba_bike_per_type[type]);
			living_place <- one_of(building where (each.usage = "R"));
			current_place <- living_place;
			location <- any_location_in(living_place);
			color <- color_per_type[type];
			closest_bus_stop <- bus_stop with_min_of(each distance_to(self));						
			do create_trip_objectives;
		}	
		save "cycle,walking,walking_acum,bike,bike_acum,car,car_acum,bus,bus_acum,average_speed,walk_distance,bike_distance,car_distance,bus_distance, bus_people_distance,CO2_capita,daylight" to: "../results/mobility.csv";
		save "cycle,walking,bike,car,bus,average_speed,walk_distance,bike_distance,car_distance,bus_distance, bus_people_distance" to: "../results/mobility_aggregated.csv";		

		write costanera.path;
	}
	
}


grid gridHeatmaps height: 50 width: 50 {
	int pollution_level <- 0 ;
	int density<-0;
	rgb pollution_color <- rgb(255-pollution_level*10,255-pollution_level*10,255-pollution_level*10) update:rgb(255-pollution_level*10,255-pollution_level*10,255-pollution_level*10);
	rgb density_color <- rgb(255-density*50,255-density*50,255-density*50) update:rgb(255-density*50,255-density*50,255-density*50);
	
	aspect density{
		draw shape color:density_color at:{location.x+current_date.hour*world.shape.width,location.y};
	}
	
	aspect pollution{
		draw shape color:pollution_color;
	}
	
	reflex raz when: every(1#hour) {
		pollution_level <- 0;
	}
}


experiment gameit type: gui {
	output {
		display map type: opengl draw_env: false background: #black refresh:every(10#cycle){
			//species gridHeatmaps aspect:pollution;
			//species pie;
			species building aspect:depth refresh: false;
			species road ;		
			species people aspect:base ;
			species externalCities aspect:base;
								
			graphics "time" {
				draw string(current_date.hour) + "h" + string(current_date.minute) +"m" color: # white font: font("Helvetica", 30, #italic) at: {world.shape.width*0.4,-world.shape.height*0.0};
			}
			
			overlay position: { 5, 5 } size: { 240 #px, 680 #px } background: # black transparency: 1.0 border: #black 
            {
            	
                rgb text_color<-#white;
                float y <- 30#px;
  				draw "Building Usage" at: { 40#px, y } color: text_color font: font("Helvetica", 25, #bold) perspective:false;
                y <- y + 30 #px;
                loop type over: color_per_category.keys
                {
                    draw square(20#px) at: { 20#px, y } color: color_per_category[type] border: #white;
                    draw type at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 25, #plain) perspective:false;
                    y <- y + 25#px;
                }
                 y <- y + 30 #px;     
                draw "People Type" at: { 40#px, y } color: text_color font: font("Helvetica", 25, #bold) perspective:false;
                y <- y + 30 #px;
                loop type over: color_per_type.keys
                {
                    draw square(10#px) at: { 20#px, y } color: color_per_type[type] border: #white;
                    draw type at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 25, #plain) perspective:false;
                    y <- y + 25#px;
                }
				y <- y + 30 #px;
                draw "Mobility Mode" at: { 40#px, 600#px } color: text_color font: font("Roboto", 25, #bold) perspective:false;
                map<string,rgb> list_of_existing_mobility <- map<string,rgb>(["Walking"::#green,"Bike"::#yellow,"Car"::#red,"Bus"::#blue]);
                y <- y + 30 #px;
                
                loop i from: 0 to: length(list_of_existing_mobility) -1 {    
                  // draw circle(10#px) at: { 20#px, 600#px + (i+1)*25#px } color: list_of_existing_mobility.values[i]  border: #white;
                   draw list_of_existing_mobility.keys[i] at: { 40#px, 610#px + (i+1)*20#px } color: list_of_existing_mobility.values[i] font: font("Helvetica", 18, #plain) perspective:false; 			
		        }     
            }
            
            chart "Cumulative Trip"background:#black  type: pie size: {0.6,0.6} position: {world.shape.width*1.1,world.shape.height*0 - 300} color: #white axes: #yellow title_font: 'Menlo' title_font_size: 30.0 
			tick_font: 'Menlo' tick_font_size: 20 tick_font_style: 'bold' label_font: 'Menlo' label_font_size: 64 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{
				loop i from: 0 to: length(transport_type_cumulative_usage.keys)-1	{
				  data transport_type_cumulative_usage.keys[i] value: transport_type_cumulative_usage.values[i] color:color_per_mobility[transport_type_cumulative_usage.keys[i]];
				}
			}
			chart "People Distribution" background:#black  type: pie size: {0.6,0.6} position: {world.shape.width*1.1,world.shape.height*0.6} color: #white axes: #yellow title_font: 'Menlo' title_font_size: 30.0 
			tick_font: 'Menlo' tick_font_size: 20 tick_font_style: 'bold' label_font: 'Menlo' label_font_size: 64 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{
				loop i from: 0 to: length(proportion_per_type.keys)-1	{
				  data proportion_per_type.keys[i] value: proportion_per_type.values[i] color:color_per_type[proportion_per_type.keys[i]];
				}
			}
		} 				
	}
}


experiment paramater_adjustment_genetic_algorithm type: batch repeat: 4 until: ( cycle = 4260 ) {
    
   // parameter 'Price:' var: price min: -1.0 max: 0.0 type: float step: 0.01;
   // parameter 'Time:' var: time_ad min: -1.0 max: 0.0 type: float step: 0.01;
   // parameter 'Social:' var: social_pattern min: 0.0 max: 1.0 type: float step: 0.01;
   // parameter 'Difficulty:' var: difficulty min: -1.0 max: 0.0 type: float step: 0.01;
   // parameter 'Proba car:' var: proba_car min: 0.1 max: 0.9 type: float step: 0.02;
   // parameter 'Proba bike:' var: proba_bike min: 0.1 max: 0.5 type: float step: 0.02;
    parameter 'Price:' var: price min: -0.35 max: -0.15 type: float step: 0.01;
    parameter 'Time:' var: time_ad min: -0.66 max: -0.46 type: float step: 0.01;
    parameter 'Social:' var: social_pattern min: 0.01 max: 0.24 type: float step: 0.01;
    parameter 'Difficulty:' var: difficulty min: -0.8 max: -0.6 type: float step: 0.01;
    parameter 'Proba car:' var: proba_car min: 0.04 max: 0.26 type: float step: 0.01;
    parameter 'Proba bike:' var: proba_bike min: 0.0 max: 0.2 type: float step: 0.01;
   
    reflex out{
    	write("fitness: " + fitness);
    	write(weights_map);
    	write(proba_bike_per_type);
    	save [price,time_ad ,social_pattern, difficulty, proba_car, proba_bike, fitness] rewrite:false to: "../results/adjustment.csv" format:"csv";
    	
    }    
    method genetic minimize: fitness 
        pop_dim: 6 crossover_prob: 0.7 mutation_prob: 0.2 
        nb_prelim_gen: 5 max_gen: 10; 
}

experiment parameter_exploration type: batch repeat: 4 until:( cycle = 4260 ) {

	parameter 'Price:' var: price min: -1.0 max: 0.0 type: float step: 0.01;
    parameter 'Time:' var: time_ad min: -1.0 max: 0.0 type: float step: 0.01;
    parameter 'Social:' var: social_pattern min: 0.0 max: 1.0 type: float step: 0.01;
    parameter 'Difficulty:' var: difficulty min: -1.0 max: 0.0 type: float step: 0.01;
    parameter 'Proba car:' var: proba_car min: 0.1 max: 0.9 type: float step: 0.02;
    parameter 'Proba bike:' var: proba_bike min: 0.1 max: 0.5 type: float step: 0.02;
	
	reflex out{
		
		save [price,time_ad ,social_pattern, difficulty, proba_car, proba_bike, fitness] rewrite:false to: "../results/exploration.csv" format:"csv";
		
	}

    method exploration sample:100 sampling: 'uniform';

}


experiment paramater_adjustment_simmulated_anneling type: batch repeat: 2 keep_seed: true until: ( cycle = 1420 ) {
    
    parameter 'Price:' var: price min: -1.0 max: 0.0 type: float step: 0.01;
    parameter 'Time:' var: time_ad min: -1.0 max: 0.0 type: float step: 0.01;
    parameter 'Social:' var: social_pattern min: 0.0 max: 1.0 type: float step: 0.01;
    parameter 'Difficulty:' var: difficulty min: -1.0 max: 0.0 type: float step: 0.01;
    parameter 'Proba car:' var: proba_car min: 0.0 max: 1.0 type: float step: 0.01;
    parameter 'Proba bike:' var: proba_bike min: 0.0 max: 1.0 type: float step: 0.01;
    
    reflex out{
    	write("fitness: " + fitness);
    	write(weights_map);
    }    
    method annealing 
        temp_init: 100  temp_end: 1 
        temp_decrease: 0.5 nb_iter_cst_temp: 5 
        minimize: fitness;
}
