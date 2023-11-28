model configuration

global {
	//PARAMETERS
	bool updatePollution <-false parameter: "Pollution:" category: "Simulation";
	bool updateDensity <-false parameter: "Density:" category: "Simulation";
	bool weatherImpact <-true parameter: "Weather impact:" category: "Simulation";
	
	//ADJUSTMENT PARAMETERS
    float price <-0.0 parameter: "Price:" category: "Adjustment" min:-1.0 max:1.0;
	float time_ad <-0.0 parameter: "Time:" category: "Adjustment" min:-1.0 max:1.0;
	float social_pattern <- 0.0 parameter: "Social:" category: "Adjustment" min:-1.0 max:1.0;
	float difficulty <- 0.0 parameter: "Difficulty:" category: "Adjustment" min:-1.0 max:1.0;	
	float proba_car <- 0.0 parameter: "Proba car:" category: "Adjustment" min:0.0 max:1.0;
	float proba_bike <- 0.0 parameter: "Proba bike:" category: "Adjustment" min:0.0 max:1.0;	
	
	//ENVIRONMENT
	float step <- 1 #mn;
	date starting_date <-date([2023,7,11,0,0]);
	string case_study <- "costanera";
	int nb_people <- 1000;
	
    string cityGISFolder <- "./../../includes/city/"+case_study;
	file<geometry> buildings_shapefile <- file<geometry>(cityGISFolder+"/Buildings.shp");
	file<geometry> external_cities_shapefile <- file<geometry>(cityGISFolder+"/Cities.shp");
	
	// Use this roads shp to ease parameter adjustment
	// file<geometry> roads_shapefile <- file<geometry>(cityGISFolder+"/Roads_adjust.shp");
	file<geometry> roads_shapefile <- file<geometry>(cityGISFolder+"/Roads.shp");
	geometry shape <- envelope(buildings_shapefile);
		
	// MOBILITY DATA
	list<string> mobility_list <- ["walking", "bike","car","bus"];
	file activity_file <- file("./../../includes/ActivityPerProfile.csv");
	file criteria_file <- file("./../../includes/CriteriaFile.csv");
	file profile_file <- file("./../../includes/Profiles.csv");
	file mode_file <- file("./../../includes/Modes.csv");
	file weather_coeff <- file("./../../includes/weather_coeff_per_month_south_hemisphere.csv");
	
	map<string,rgb> color_per_category <- [ "Restaurant"::rgb("#2B6A89"), "Night"::rgb("#1B2D36"),"GP"::rgb("#244251"), "Cultural"::rgb("#2A7EA6"), "Shopping"::rgb("#1D223A"), "HS"::rgb("#FFFC2F"), "Uni"::rgb("#807F30"), "O"::rgb("#545425"), "R"::rgb("#222222"), "Park"::rgb("#24461F")];	
	map<string,rgb> color_per_type <- [ "High School Student"::rgb("#FFFFB2"), "College student"::rgb("#FECC5C"),"Young professional"::rgb("#FD8D3C"),  "Mid-career workers"::rgb("#F03B20"), "Executives"::rgb("#BD0026"), "Home maker"::rgb("#0B5038"), "Retirees"::rgb("#8CAB13")];
	
}
