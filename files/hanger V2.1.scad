/*
* @license CC-BY
*
Version 2.1
-------------
Added customizable bar roundness
Made Thingiverse Customizer compatible
Added tolerance parameter for clearances
Made vertical crossbeam in hanger stonger
Added control of number of facets in beam
Added parameter to control hook height

TODO
-----
TEST: Clearance around bottom pin plate

*/
part = "side"; // ["side", "hook", "all"]
// end-to-end length
length = 390; 
// approximate height to top of diagonal, from center of bar to center of bar
height = 110; 
// bar diameter
bar_d = 7;
// corner bend diameter
bend_d = 38;
// space between pins on pin plate
pin_buffer = 5;
// hook centerline diameter. Equals inner diameter plus bar_d
hook_d = 57;
// top of diagonal to top of hook
hook_h = 110;
// roundness. 8 is good for printing with no supports. 12 might work, too.
bar_facets = 8; // [8,12,16,20,24,32,64]
// space between mating parts
tolerance = 0.2; 

/* [Hidden] */
// bar radius
bar_r = bar_d / 2;
// bend radius
bend_r = bend_d / 2;
// compensate for truncation of radius due to low poly count
thickness = bar_d*cos(180/(bar_facets)); 
// pin diameter
pin_d = bar_d;
// left-to-right plate height
plate_h = pin_d * 2 + pin_buffer + 4;
// top to bottom plate width
plate_w = pin_d * 2;
// thickness of bottom plate
plate_t = thickness / 2;
// left-to-right crossbeam height
crossbeam_h = pin_d;
// length of horizontal bar
bottom_l = length /2 - bend_r - plate_h / 2;
// corner angle
//corner_a = atan((height - bend_d)/ bottom_l);
corner_a = atan((height - bend_d)/ bottom_l);
// length of diagonal bar
top_l = sqrt((bottom_l + tan(corner_a)*bend_r) * (bottom_l + tan(corner_a)*bend_r) + (height - bend_d)*(height - bend_d));

bend_a = 180 - corner_a;
// hook radius
hook_r = hook_d / 2;
// distance to move the horizontal bar
bottom_offset = -sin(corner_a)*top_l - bend_d - bar_r;

module ring(outer, inner) {
	rotate_extrude($fn=64) translate([inner, 0, 0]) rotate([0, 0, -22.5]) circle(r = outer, $fn = bar_facets);
}

module partial_ring(outer, inner, deg) {
  compliment = 360 - deg;
	
	difference() {
		ring(outer, inner);

		if (compliment < 90) {
			translate([0, 0, -outer])
				linear_extrude(height = outer * 2)
					polygon(points = [[0,0],
														[-(inner + outer), 0], 
														[-(inner + outer),(inner + outer) * tan(compliment)]]);
		}
		else if (compliment < 180) {
			translate([-(inner + outer), 0, -outer])
				cube(size = [inner + outer, inner + outer, outer*2], center = false);

			translate([0, 0, -outer])
			linear_extrude(height = outer * 2)
				polygon(points = [[0,0],
													[0, (inner + outer)], 
													[(inner + outer) * tan(compliment - 90),
			(inner + outer),]]);
		}
		else if (compliment < 270) {
			translate([-(inner + outer), 0, -outer])
				cube(size = [(inner + outer)*2, inner + outer, outer*2], center = false);

			translate([0, 0, -outer])
			linear_extrude(height = outer * 2)
				polygon(points = [[0,0],
													[(inner + outer), 0], 
													[(inner + outer),
			-(inner + outer) * tan(compliment - 180)]]);

		}
		else {
			translate([-(inner + outer), 0, -outer])
				cube(size = [(inner + outer)*2, inner + outer, outer*2], center = false);

translate([0, -(inner + outer), -outer])
	cube(size = [inner + outer, inner + outer, outer*2], center = false);
	
			translate([0, 0, -outer])
			linear_extrude(height = outer * 2)
				polygon(points = [[0,0],
													[0, -(inner + outer)], 
													[(inner + outer) * tan(90 - (compliment - 180)),
														-(inner + outer)]]);
		}
  }
}

module pin(height, rad) {
	spline_sides = 4;
	module __spline() cylinder(h = height, r = tolerance*2, center = false, $fn = spline_sides);

  union() {
    cylinder(h = height, r = rad, center = false, $fn = 20);
    translate([-rad, 0, 0]) __spline();
    translate([rad, 0, 0]) __spline();
    translate([0, -rad, 0]) __spline();
    translate([0, rad, 0]) __spline();
  }
}

module pinplate(plate_t, num_pins, pin_d, bar=false) {
  plate_w = pin_d * (num_pins * 2);
	pin_r = pin_d / 2;
	
	module __plate(bar) {
		if (bar) {
			intersection() {
				// rounded top of plate
				translate([plate_w - bar_r, 0, plate_t]) rotate([-90, 0, 0]) bar(plate_h);
				cube([plate_w, plate_h, plate_t], center=false);
			}
			// bottom of plate
			cube(size = [plate_w*3/4, plate_h, plate_t], center=false);
		} else {
			// bottom of plate
			cube(size = [plate_w, plate_h, plate_t], center=false);
		}
	}
	
	difference() {
		union() {
			__plate(bar);
			// pins 
			for (i = [0:num_pins - 1]) {
				translate([pin_d + pin_d * i * 2, pin_d + pin_r + pin_buffer + 2, plate_t])
					pin(plate_t, pin_r);
			}
		}    

		// pin holes
		for (i = [0:num_pins - 1]) {
			translate([pin_d + pin_d * i * 2, pin_r + 2, -1])
        cylinder(h = plate_t + 2, r = pin_r + tolerance, center = false, $fn = 20);

/*	rotate(a = [0, 180, 0])
          pinhole(h = plate_t, r = pin_r, lh = plate_t / 3, lt = 1,
	          t = 0.3, tight = true);*/
		}
	}  
}  

module bar(h, flip=false) {
	angle = 180/bar_facets;
	rotation = flip ? angle : -angle;
	rotate([0, 0, rotation]) cylinder(h=h, r = bar_r, $fn = bar_facets);
}

module hangerside() {
	clearance_h = plate_h + tolerance*2;
	
  rotate(a = [270, 0, 0]) {

		difference() {
			union() {
				// horizontal bar
				bar(h=bottom_l);
				// diagonal bar
				translate([bend_r, 0, 0])
					rotate(a = [0, corner_a, 0])
					translate([bend_r, 0, 0])  
						bar(h=top_l + bar_r/2, flip=true);
			}
			
			// trim end of bar
			translate([-height/2, -bar_r, bottom_l - 1 - tolerance])
				cube([height*2, bar_r, clearance_h]);
			translate([height + bar_r, -bar_r, bottom_l - 1 - tolerance])
				cube([plate_w, bar_r, clearance_h]);
		}

		// outside bend
		translate([bend_r, 0, 0])
			rotate([90, 0, 0]) partial_ring(bar_r, bend_r, bend_a);
	}

	// top pin plate
//  translate([height - bar_r * 3, bottom_l - 1, -bar_r + .5])  {
  translate([-bottom_offset - plate_w - bar_r - tolerance, bottom_l - 1, -plate_t])  {
    difference() {
      pinplate(plate_t, 1, pin_d);
			// cut-out for hook "I"
      translate([-1, plate_w/2 + tolerance*2, bar_r / 2 - tolerance])
        cube(size = [plate_w + 2, crossbeam_h + tolerance * 2, bar_d], center=false);
		}
		// gussett next to pin plate
		linear_extrude(height = bar_r)
			 polygon(points = [[0,0], [bar_r * 3, 0], [0, (1/tan(corner_a))* -(bar_r * 3)]]);
  }

  // bottom pin plate
	translate([-plate_w + bar_r, bottom_l-1, -plate_t])
    pinplate(plate_t, 1, pin_d, bar=true);
}

module hangerhook() {
	straight_h = max(hook_h - bar_d - hook_d, 0);
	top_offset = hook_h - hook_r - bar_d;
  rotate(a = [-90, 0, -90]) 
	{
		// build the hook in the z direction
		// top half of hook
		translate([0, 0, top_offset])
      rotate(a = [-90, 0, 0])
      partial_ring(bar_r, hook_r, 180);
		// rounded end of top half
		translate([-hook_r, 0, top_offset]) rotate([0, 0, 180/bar_facets]) sphere(d = bar_d, $fn = bar_facets);
    translate([hook_r, 0, hook_r]) bar(h=straight_h);
    translate([0, 0, hook_r]) rotate(a = [90, 0, 180])
      partial_ring(bar_r, hook_r, 90);
    // smooth entry into the bracket
		translate([0, 0, 0]) scale([3, 1, 1]) rotate([0, 0, 180/bar_facets]) sphere(d = bar_d, $fn = bar_facets);
		translate([0, 0, -bar_r / 2])
			cube(size = [plate_h, thickness, bar_r], center = true);
		// middle of "I"
		translate([0, 0, -plate_w / 2 - tolerance - bar_r])
			cube(size = [crossbeam_h, bar_r, plate_w + tolerance * 2], center = true);
		// bottom of "I"
		translate([0, 0, -(plate_w + bar_r * 3 / 2 + tolerance * 2)])
			cube(size = [plate_h, thickness, bar_r], center = true);
	}
}

/**** Uncomment one of either the hanger side or hook ****/


//Uncomment to render a guide outline for mendel bed
/*difference() {
  cube(size = [200, 200, 1], center=true);
  cube(size = [198, 198, 3], center=true);
}*/

if (part == "hook") {
	hangerhook();
} else if (part == "side") {
	translate([bottom_offset, - bottom_l - (plate_h)/2 + 1, 0])
		hangerside();
} else if (part == "all") {
	%hangerhook();
	translate([-sin(corner_a)*top_l - bend_d - bar_r, - bottom_l - (plate_h)/2 + 1, 0])
		hangerside();
	color("green", 0.2) rotate([180, 0, 0]) translate([-sin(corner_a)*top_l - bend_d - bar_r, - bottom_l - (plate_h)/2 + 1, 0])
		hangerside();
} else {
	echo(str("Warning! Unexpected part \"", part, "\""));
}
