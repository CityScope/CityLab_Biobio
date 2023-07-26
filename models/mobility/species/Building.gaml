model Building


species building {
	string usage;
	string scale;
	string category;
	rgb color <- #grey;
	float height <- 0.0;//50.0 + rnd(50);
	aspect default {
		draw shape color: color ;
	}
	aspect depth {
		draw shape color: color  depth: height;
	}
}
