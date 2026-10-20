// Samples of every component in the shared library, each with its mate.
//
// part = "<sample>": one printable sample, in print orientation. Every
//   component comes as a pair (socket and key, groove and tongue, pad and
//   button…), so the plate doubles as a fit test.
// demo = "<component>": the component in use, for the renders: the printed
//   piece (grey), its printed mate (orange), the bought hardware it takes
//   (dark grey), the wall it hangs on (white) and red arrows for how it goes
//   together, slightly exploded.

use <basics.scad>
use <style.scad>
use <mounts.scad>
use <joints.scad>
use <hardware.scad>

part = "all";   // [all, keyhole_pad, keyhole_button, standoff_peg, peg_block, screw_plate, holes, diamond_female, diamond_male, tongue_female, tongue_male, lead_in_female, lead_in_male, house_box]
demo = "none";  // [none, keyhole, standoff_peg, screw, holes, diamond, tongue, lead_in, house]

$fa = 1; $fs = 0.4;
eps = 0.01;

// The piece's colour is the project filament (Bambu PLA Basic Grey); the
// others match no filament, so the renders show them as plain context.
PIECE = "#8E9089";   // the printed piece
MATE = "#FF6A13";    // its printed mate
HW = "#545454";      // bought hardware
WALL = "#F4F4F4";    // the wall
ARROW = "#C12E1F";   // how it goes together

// Shared sizes
pad_t = 4.2; pad_w = 22; drop = 12; shank_d = 7; head_d = 12;   // keyhole, as in soap-caddy
cup_h = 12;
flange_t = keyhole_button_flange_t(pad_t, shank_d, head_d);
peg_d = 6; peg_len = pad_t + cup_h + flange_t; boss_t = pad_t;
key_s = 3;   // diamond key side
plug_d = 8;  // lead-in plug

// ---------------------------------------------------------------- printable samples

module keyhole_pad_sample()   // lying on its back, countersink up
    rotate([-90, 0, 0]) difference() {
        keyhole_pad(pad_t, pad_w, drop, shank_d, head_d);
        keyhole_cut(pad_t, drop, shank_d, head_d);
    }
module keyhole_button_sample() keyhole_button(pad_t, shank_d, head_d);
module standoff_peg_sample() standoff_peg(peg_d, peg_len);
module peg_block_sample()     // a slice of the piece the peg presses into
    difference() {
        chamfered_prism(boss_t) square([24, 20], center = true);
        translate([0, 0, boss_t]) standoff_peg_hole(peg_d, boss_t + 1);
    }
module screw_plate_sample()   // a plate screwed to the wall, head up
    difference() {
        chamfered_prism(5) square([30, 30], center = true);
        translate([0, 0, 5]) countersunk_screw(4, 8, 10, extra = 1);
    }
module holes_sample()         // teardrop, flat teardrop, polyhole, countersink
    difference() {
        chamfered_prism(20) square([56, 20], center = true);
        translate([-18, 0, 10]) teardrop(8.4, 22);
        translate([-4, 0, 10]) teardrop(8.4, 22, flat = true);
        translate([8, 0, -1]) polyhole(3, 22);
        translate([19, 0, 20]) countersunk_screw(3.5, 7, 15, extra = 1);
    }
module diamond_female_sample()   // socket on the top face
    difference() {
        chamfered_prism(12) square(16, center = true);
        translate([0, 0, 12]) diamond_socket(key_s, 7);
    }
module diamond_male_sample()     // a bar lying down, the key out of its end, corners up and down
    translate([-15, 0, 0]) {
        chamfered_prism(10) square([30, 12], center = true);
        translate([15 - eps, 0, 5]) rotate([0, 90, 0]) diamond_key(key_s, 0, 6);
    }
module tongue_female_sample()    // groove along the top
    difference() {
        chamfered_prism(10) square([40, 14], center = true);
        translate([-25, 0, 10]) rotate([90, 0, 90]) linear_extrude(50) groove_profile();
    }
module tongue_male_sample()      // tongue along the top
    union() {
        chamfered_prism(6) square([40, 14], center = true);
        translate([-20 + 1, 0, 6 - eps]) rotate([90, 0, 90]) linear_extrude(38) tongue_profile();
    }
module lead_in_female_sample()
    difference() {
        chamfered_prism(14) square(18, center = true);
        translate([0, 0, 14]) lead_in_socket(10) circle(d = plug_d + 0.4);
    }
module lead_in_male_sample() {
    chamfered_prism(3) square(18, center = true);
    translate([0, 0, 3 - eps]) lead_in_plug(14) circle(d = plug_d);
}
module house_box_sample() {   // the house style: a small box with a keyhole in its back
    w = 60; d = 45; h = 40; t = 1.68;
    difference() {
        union() {
            hull() {
                linear_extrude(eps) offset(r = -0.6) house_plan(w, d);
                translate([0, 0, 0.6]) linear_extrude(2 - 0.6) house_plan(w, d);
            }
            linear_extrude(h) house_shell(w, d, t);
            translate([0, 0, 24]) keyhole_pad(pad_t, pad_w, drop, shank_d, head_d);
        }
        translate([0, 0, 24]) keyhole_cut(pad_t, drop, shank_d, head_d);
        for (y = slot_positions(t + 2.6, d - 14 - 2.6), s = [-1, 1]) wall_slot(s * w / 2, -y, 8, h - 6, "x");
        for (x = slot_positions(-w / 2 + 2.6, -11 - 2.6)) for (s = [-1, 1]) wall_slot(s * x, 0, 8, h - 6, "y");
    }
}

module sample(p) {
    if (p == "keyhole_pad") keyhole_pad_sample();
    else if (p == "keyhole_button") keyhole_button_sample();
    else if (p == "standoff_peg") standoff_peg_sample();
    else if (p == "peg_block") peg_block_sample();
    else if (p == "screw_plate") screw_plate_sample();
    else if (p == "holes") holes_sample();
    else if (p == "diamond_female") diamond_female_sample();
    else if (p == "diamond_male") diamond_male_sample();
    else if (p == "tongue_female") tongue_female_sample();
    else if (p == "tongue_male") tongue_male_sample();
    else if (p == "lead_in_female") lead_in_female_sample();
    else if (p == "lead_in_male") lead_in_male_sample();
    else if (p == "house_box") house_box_sample();
}

// ---------------------------------------------------------------- demos
// Display coordinates: z up; mounts on a wall in the plane y = 0, with the
// pieces in front of it (towards -y, the viewer).

module arrow(p, q, d = 2) {
    v = q - p; l = norm(v); hl = min(3 * d, l / 2);
    b = p + v * (l - hl) / l;
    hull() { translate(p) sphere(d = d); translate(b) sphere(d = d); }
    translate(b) rotate([0, acos(v[2] / l), atan2(v[1], v[0])]) cylinder(d1 = 2.4 * d, d2 = 0, h = hl);
}

module wall(x0, x1, z0, z1) box([x0, 0, z0], [x1, 3, z1]);

// One role of a demo: "piece", "mate", "hw", "wall" or "arrow".
module demo_part(name, role) {
    if (name == "keyhole") {
        // cup on the wall, the button screwed onto its stud; the piece's
        // keyhole goes over the button head (1) and drops (2)
        yb = -cup_h - 14;                      // button flange face, exploded off the hub
        yp = yb - flange_t - 24;               // piece back face, exploded off the flange
        if (role == "wall") wall(-40, 40, -45, 45);
        if (role == "hw") rotate([90, 0, 0]) suction_cup(h = cup_h);
        if (role == "mate") translate([0, yb, 0]) rotate([90, 0, 0]) keyhole_button(pad_t, shank_d, head_d);
        if (role == "piece") translate([0, yp, drop]) difference() {
            keyhole_pad(pad_t, pad_w, drop, shank_d, head_d);
            keyhole_cut(pad_t, drop, shank_d, head_d);
        }
        if (role == "arrow") {
            arrow([0, yp + 4, -12], [0, yb - flange_t - 4, -12]);       // 1: over the head
            arrow([0, yp - pad_t - 4, drop + 10], [0, yp - pad_t - 4, -2]); // 2: drop
            arrow([0, yb - 2, -22], [0, -cup_h - 2, -22]);                // the button screws onto the stud
        }
    }
    else if (name == "standoff_peg") {
        // a piece hanging clear of the wall; the peg presses into it and rests on the wall
        yf = -(cup_h + flange_t);              // piece back face
        if (role == "wall") wall(-30, 30, -25, 25);
        if (role == "piece") translate([0, yf, 0]) rotate([90, 0, 0]) difference() {
            box([-20, -18, 0], [20, 18, boss_t]);
            translate([0, 0, boss_t]) standoff_peg_hole(peg_d, boss_t + 1);
        }
        if (role == "mate") translate([0, yf - boss_t - 18, 0]) rotate([-90, 0, 0]) standoff_peg(peg_d, peg_len);
        if (role == "arrow") arrow([12, yf - boss_t - 18, 0], [12, yf - boss_t - 4, 0]);
    }
    else if (name == "screw") {
        if (role == "wall") wall(-30, 30, -30, 30);
        if (role == "piece") rotate([90, 0, 0]) difference() {
            chamfered_prism(5) square([30, 30], center = true);
            translate([0, 0, 5]) countersunk_screw(4, 8, 10, extra = 1);
        }
        if (role == "hw") translate([0, -5 - 18, 0]) rotate([90, 0, 0]) wood_screw(4, 8, 30);
        if (role == "arrow") arrow([12, -5 - 22, 0], [12, -8, 0]);
    }
    else if (name == "holes") {
        if (role == "piece") holes_sample();
        if (role == "hw") {
            translate([-18, -55, 10]) rotate([-90, 0, 0]) rod(8, 25);   // bolts about to go into the teardrops
            translate([-4, -55, 10]) rotate([-90, 0, 0]) rod(8, 25);
            translate([8, 0, 26]) rod(3, 16);                           // pin above the polyhole
            translate([19, 0, 34]) wood_screw(3.5, 7, 16);              // screw above the countersink
        }
        if (role == "arrow") {
            for (x = [-18, -4]) arrow([x, -26, 18], [x, -12, 18]);
            arrow([13, 0, 44], [13, 0, 28]);
        }
    }
    else if (name == "diamond") {
        if (role == "piece") diamond_female_sample();
        if (role == "mate") translate([0, 0, 12 + 10 + 6]) rotate([0, 90, 0]) diamond_male_sample();
        if (role == "arrow") arrow([12, 0, 30], [12, 0, 16]);
    }
    else if (name == "tongue") {
        if (role == "piece") tongue_female_sample();
        if (role == "mate") translate([0, 0, 10 + 18]) rotate([180, 0, 0]) tongue_male_sample();
        if (role == "arrow") arrow([0, -12, 24], [0, -12, 12]);
    }
    else if (name == "lead_in") {
        if (role == "piece") lead_in_female_sample();
        if (role == "mate") translate([0, 0, 14 + 8 + 17]) rotate([180, 0, 0]) lead_in_male_sample();
        if (role == "arrow") arrow([14, 0, 32], [14, 0, 16]);
    }
    else if (name == "house") {
        // the house-style box hung on its keyhole over a cup's button
        if (role == "wall") wall(-50, 50, -40, 50);
        if (role == "hw") translate([0, 0, 24]) rotate([90, 0, 0]) suction_cup(h = cup_h);
        if (role == "mate") translate([0, -cup_h, 24]) rotate([90, 0, 0]) keyhole_button(pad_t, shank_d, head_d);
        if (role == "piece") translate([0, -cup_h - flange_t, 0]) house_box_sample();
    }
}

names = ["keyhole_pad", "keyhole_button", "standoff_peg", "peg_block", "screw_plate", "holes",
         "diamond_female", "diamond_male", "tongue_female", "tongue_male", "lead_in_female",
         "lead_in_male", "house_box"];

if (demo != "none") {
    color(PIECE) demo_part(demo, "piece");
    color(MATE) demo_part(demo, "mate");
    color(HW) demo_part(demo, "hw");
    color(WALL) demo_part(demo, "wall");
    color(ARROW) demo_part(demo, "arrow");
}
else if (part == "all") color(PIECE) for (i = [0 : len(names) - 1]) translate([(i % 5) * 70, -floor(i / 5) * 60, 0]) sample(names[i]);
else color(PIECE) sample(part);
