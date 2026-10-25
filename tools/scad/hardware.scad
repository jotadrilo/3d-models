// Bought hardware, as simple stand-ins: for assemblies, demos and clearance
// checks, never printed. Load with
//   use <../../tools/scad/hardware.scad>

// Suction cup with a threaded stud (DIYexpert Ø50, M4 × 10): the cup's rim on
// z = 0 (the wall), the hub face at z = h, the stud on +z.
module suction_cup(d = 50, h = 12, hub_d = 16, stud_d = 4, stud_len = 12) {
    hull() {
        cylinder(d = d, h = 0.8);
        translate([0, 0, h - 0.01]) cylinder(d = hub_d, h = 0.01);
    }
    translate([0, 0, h]) cylinder(d = stud_d, h = stud_len);
}

// Countersunk wood screw (90° head): head top on z = 0, shank down to -len.
module wood_screw(d = 4, head_d = 8, len = 30) {
    translate([0, 0, -(head_d - d) / 2]) cylinder(d1 = d, d2 = head_d, h = (head_d - d) / 2);
    translate([0, 0, -len + d]) cylinder(d = d, h = len - (head_d - d) / 2 - d + 0.01);
    translate([0, 0, -len]) cylinder(d1 = 0.6, d2 = d, h = d);
}

// Plain rod or pin (metal dowel, bolt shank): axis z, from z = 0 to len.
module rod(d = 3, len = 30) cylinder(d = d, h = len);

// Hex bolt (ISO 4017): head on z = 0 down to -k, shank up +z to len.
module hex_bolt(d = 6, len = 40) {
    af = d == 5 ? 8 : d == 6 ? 10 : d == 8 ? 13 : 1.6 * d;
    translate([0, 0, -0.7 * d]) cylinder(d = af / cos(30), h = 0.7 * d, $fn = 6);
    cylinder(d = d, h = len);
}

// Hex nut (ISO 4032) on z = 0 up to its height.
module hex_nut(d = 6) {
    af = d == 5 ? 8 : d == 6 ? 10 : d == 8 ? 13 : 1.6 * d;
    difference() {
        cylinder(d = af / cos(30), h = 0.8 * d, $fn = 6);
        translate([0, 0, -1]) cylinder(d = d, h = d + 2);
    }
}

// Flat washer (DIN 125 by default; large = DIN 9021), on z = 0.
module washer(d = 6, large = false) {
    od = large ? 3 * d : 2 * d;
    difference() { cylinder(d = od, h = d / 4 + 0.1); translate([0, 0, -1]) cylinder(d = d + 0.4, h = d); }
}


// Carriage bolt (DIN 603): domed head on z = 0 down to -0.6 d, square neck
// and shank up +z to len. Its low head sits against a wall where a hex head would not.
module carriage_bolt(d = 6, len = 30) {
    hd = d == 5 ? 13.5 : d == 6 ? 16 : d == 8 ? 20 : 2.6 * d;
    translate([0, 0, -0.6 * d]) scale([1, 1, 0.6 * d / (hd / 2)]) intersection() {
        sphere(d = hd);
        translate([0, 0, hd / 4]) cube(hd / 2 + 0.1, center = true);
    }
    translate([-d / 2, -d / 2, 0]) cube([d, d, 0.7 * d]);
    cylinder(d = d, h = len);
}
