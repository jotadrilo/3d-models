// Every piece of the shared library side by side, to check them after a change:
//   openscad --render -o catalog.png --imgsize=1800,700 --autocenter --viewall --camera=0,0,0,55,0,20,0 catalog.scad
use <basics.scad>
use <style.scad>
use <mounts.scad>
use <joints.scad>

$fa = 1; $fs = 0.4;

// keyhole pad (piece lying on its back) with its button
translate([0, 0, 0]) rotate([-90, 0, 0]) difference() {
    keyhole_pad(4.2, 22, 12, 7, 12);
    keyhole_cut(4.2, 12, 7, 12);
}
translate([25, 0, 0]) keyhole_button(4.2);
translate([45, 0, 0]) standoff_peg();
// house shell with slots
translate([90, 10, 0]) difference() {
    linear_extrude(30) house_shell(50, 40, 1.68);
    for (y = slot_positions(4, 22)) for (s = [-1, 1]) wall_slot(s * 25, -y, 6, 24, "x");
}
// a block with a teardrop, a flat teardrop, a polyhole and a countersunk screw
translate([130, 0, 0]) difference() {
    box([0, -10, 0], [40, 10, 20]);
    translate([10, 0, 10]) teardrop(8, 22);
    translate([25, 0, 10]) teardrop(8, 22, flat = true);
    translate([35, 0, -1]) polyhole(3, 22);
    translate([35, -5, 20]) countersunk_screw(3, 6, 15);
}
// joints: diamond key, tongue and a lead-in socket
translate([180, 0, 0]) {
    rotate([0, 90, 0]) diamond_key(3, 0, 12);
    translate([10, 0, 0]) rotate([90, 0, 0]) linear_extrude(12, center = true) tongue_profile();
    translate([25, 0, 10]) difference() {
        chamfered_prism(10) square(14, center = true);
        translate([0, 0, 10.01]) lead_in_socket(6) circle(d = 8.4);
    }
}
