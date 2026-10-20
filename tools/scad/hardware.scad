// Bought hardware, as simple stand-ins: for assemblies, demos and clearance
// checks, never printed. Load with
//   use <../../tools/scad/hardware.scad>

// Suction cup with a threaded stud (DIYexpert Ø50, M4 × 10): the cup's rim on
// z = 0 (the wall), the hub face at z = h, the stud on +z.
module suction_cup(d = 50, h = 12, hub_d = 16, stud_d = 4, stud_len = 10) {
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
