// Samples of every component in the shared library, each with its mate.
//
// part = "<sample>": one printable sample, in print orientation. Every
//   component comes as a pair (socket and key, groove and tongue, pad and
//   button…), so the plate doubles as a fit test.
// demo = "<component>": the component in use, for the renders: the printed
//   piece (grey), its printed mate (orange), the bought hardware it takes
//   (dark grey), the wall it hangs on (white) and red arrows for how it goes
//   together, slightly exploded.
// assembled = true: the demo put together, no arrows. With section = true it
//   is cut through the plane that shows the joint (cut_plane), for the
//   section renders: every anchor and insert is shown seated, in section.

use <basics.scad>
use <style.scad>
use <mounts.scad>
use <joints.scad>
use <hardware.scad>
use <boards.scad>
use <print_aids.scad>

part = "all";   // [all, keyhole_pad, keyhole_button, standoff_peg, peg_block, screw_plate, holes, diamond_female, diamond_male, tongue_female, tongue_male, lead_in_female, lead_in_male, handle_block, handle, dovetail_housing, dovetail_tail, house_box, board_bracket, board_bracket_hook, stabilizer]
demo = "none";  // [none, keyhole, standoff_peg, screw, holes, diamond, tongue, lead_in, handle, dovetail, bracket, bracket_hook, stabilizer]
assembled = false;
section = false;

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
peg_d = 6; peg_len = cup_h + flange_t; boss_t = pad_t;
key_s = 3;   // diamond key side
plug_d = 8;  // lead-in plug
hb_w = 30; hb_d = 20; hb_h = 16;   // block between a sprung handle's arms
h_play = 0.4; h_reach = 14;
dt_h = 30; dt_plate = 2.1; dt_wall = 20;   // sliding dovetail: length, the plate under the housing, the wall behind the tail
bb_reach = 60; bb_h = 70; bb_w = 20; bb_m = 6.3; bb_bolts = [18, 40]; bb_t = 10;   // a small board bracket, M6, on a 10 mm board
st_h = 40; st_w = 10; st_len = 30;   // a strip of 1.68 mm wall with a stabilizer fin on each face
bh_heel = 35; bh_edge = 20; bh_sheet = 2; bh_shoe = 10.6; bh_lip = 6.3;              // the same with a shoe and a hook under a 20 mm flange

// ---------------------------------------------------------------- printable samples

module keyhole_pad_sample()   // lying on its back, countersink up
    rotate([-90, 0, 0]) difference() {
        keyhole_pad(pad_t, pad_w, drop, shank_d, head_d);
        keyhole_cut(pad_t, drop, shank_d, head_d);
    }
module keyhole_button_sample() keyhole_button(pad_t, shank_d, head_d);
module standoff_peg_sample() standoff_peg(peg_d + 0.1, boss_t, peg_len);
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
        translate([-25, 0, 10]) rotate([90, 0, 90]) linear_extrude(50) mirror([0, 1]) groove_profile();   // down into the block
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
    translate([0, 0, 3 - eps]) lead_in_plug(9) circle(d = plug_d);
}
module handle_block_sample()    // a block with a socket on each side, on its side as the frame prints
    difference() {
        translate([-hb_w / 2, -hb_d / 2, 0]) cube([hb_w, hb_d, hb_h]);
        for (m = [0, 1]) mirror([m, 0, 0]) translate([hb_w / 2, 0, hb_h / 2]) sprung_handle_socket(6, 7);
    }
module handle_sample() sprung_handle(hb_w + 2 * h_play, h_reach, 8, 6, 5);
module dovetail_housing_sample()   // a strip of wall plate, flat, the housing up
    rotate([-90, 0, 0]) {
        w = dovetail_housing_w() + 8;
        translate([-w / 2, 0, -2]) cube([w, dt_plate, dt_h + 2]);
        dovetail_housing(dt_h);
    }
module dovetail_tail_sample()      // a strip of wall standing on its end, the tail along Z
    translate([0, dt_wall, 0]) {
        dovetail_tail(dt_h);
        translate([-1.68 / 2, -dovetail_housing_d() - dt_wall, 0]) cube([1.68, dt_wall, dt_h]);
    }
module stabilizer_wall() {         // a strip of wall standing on a return, along y
    translate([-1.68 / 2, -st_len / 2, 0]) cube([1.68, st_len, st_h]);
    translate([-1.68 / 2, st_len / 2 - 1.68, 0]) cube([12, 1.68, st_h]);
}
module stabilizer_fins() for (s = [0, 1]) mirror([s, 0, 0]) translate([1.68 / 2, -st_len / 4, 0]) stabilizer_fin(st_h, st_w);
module stabilizer_sample() { stabilizer_wall(); stabilizer_fins(); }   // printed as one: cut the fins off
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

module board_bracket_sample() board_bracket_print(bb_reach, bb_h, bb_w, bb_m, 6.5, bb_bolts);
module board_bracket_hook_sample() hooked_bracket(print = true);
module hooked_bracket(print = false) {
    args = [bb_reach, bb_h, bb_w, bb_m, 6.5, [bb_lip_z(), 45], 0.6, 0];
    if (print) board_bracket_print(bb_reach, bb_h, bb_w, bb_m, 6.5, [24, 45], 0.6, 0, bh_shoe, bh_lip, bh_lip,
                                   bh_heel, 12, bh_edge, 6.3, 8, 1, 2);
    else board_bracket(bb_reach, bb_h, bb_w, bb_m, 6.5, [24, 45], 0.6, 0, bh_shoe, bh_lip, bh_lip,
                       bh_heel, 12, bh_edge, 6.3, 8, 1, 2);
}
function bb_lip_z() = 24;

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
    else if (p == "handle_block") handle_block_sample();
    else if (p == "handle") handle_sample();
    else if (p == "dovetail_housing") dovetail_housing_sample();
    else if (p == "dovetail_tail") dovetail_tail_sample();
    else if (p == "stabilizer") stabilizer_sample();
    else if (p == "house_box") house_box_sample();
    else if (p == "board_bracket") board_bracket_sample();
    else if (p == "board_bracket_hook") board_bracket_hook_sample();
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

module wall(x0, x1, z0, z1, t = 3) box([x0, 0, z0], [x1, t, z1]);

X = assembled ? 0 : 1;   // explode factor

// The plane each demo is cut on for its section: "x" keeps x <= 0 (look from
// +x), "y" keeps y >= 0 (look from -y, the front).
function cut_plane(name) = name == "bracket" || name == "bracket_hook" ? "x" : name == "holes" || name == "diamond" || name == "lead_in" ? "y" : name == "handle" || name == "dovetail" || name == "stabilizer" ? "z" : "x";
function cut_z(name) = name == "dovetail" ? dt_h / 2 : name == "stabilizer" ? 20.8 : hb_h / 2;
module cut(name) {
    if (!section) children();
    else intersection() {
        children();
        if (cut_plane(name) == "x") translate([-1000, -1000, -1000]) cube([1000, 2000, 2000]);
        else if (cut_plane(name) == "z") translate([-1000, -1000, cut_z(name) - 2000]) cube([2000, 2000, 2000]);
        else translate([-1000, 0, -1000]) cube([2000, 1000, 2000]);
    }
}

// One role of a demo: "piece", "mate", "hw", "wall" or "arrow".
module demo_part(name, role) {
    if (name == "keyhole") {
        // cup on the wall, the button screwed onto its stud; the piece's
        // keyhole goes over the button head (1) and drops (2)
        yb = -cup_h - 14 * X;                  // button flange face, exploded off the hub
        yp = yb - flange_t - 24 * X;           // piece back face, exploded off the flange
        if (role == "wall") if (assembled) wall(-30, 30, -30, 30); else wall(-40, 40, -45, 45);
        if (role == "hw") rotate([90, 0, 0]) suction_cup(h = cup_h);
        if (role == "mate") translate([0, yb, 0]) rotate([90, 0, 0]) keyhole_button(pad_t, shank_d, head_d);
        if (role == "piece") translate([0, yp, drop * X]) difference() {
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
        // a piece hanging clear of the wall; the peg goes into it from behind,
        // its shoulder on the back face, and rests on the wall
        yf = -peg_len - 16 * X;                // piece back face, exploded off the peg
        if (role == "wall") wall(-30, 30, -25, 25);
        if (role == "piece") translate([0, yf, 0]) rotate([90, 0, 0]) difference() {
            box([-20, -18, 0], [20, 18, boss_t]);
            translate([0, 0, boss_t]) standoff_peg_hole(peg_d, boss_t + 1);
        }
        if (role == "mate") rotate([90, 0, 0]) standoff_peg(peg_d + 0.1, boss_t, peg_len);
        if (role == "arrow") arrow([12, yf - boss_t - 14, 0], [12, -peg_len - 2, 0]);
    }
    else if (name == "screw") {
        // the screw bites into a thick wall (a plug, or timber), through its pilot hole
        if (role == "wall") difference() {
            wall(-30, 30, -30, 30, 32);
            translate([0, -1, 0]) rotate([-90, 0, 0]) cylinder(d = 3, h = 27);
        }
        if (role == "piece") rotate([90, 0, 0]) difference() {
            chamfered_prism(5) square([30, 30], center = true);
            translate([0, 0, 5]) countersunk_screw(4, 8, 10, extra = 1);
        }
        if (role == "hw") translate([0, -5 - 18 * X, 0]) rotate([90, 0, 0]) wood_screw(4, 8, 30);
        if (role == "arrow") arrow([12, -5 - 22, 0], [12, -8, 0]);
    }
    else if (name == "holes") {
        if (role == "piece") holes_sample();
        if (role == "hw") {
            translate([-18, -12 - 43 * X, 10]) rotate([-90, 0, 0]) rod(8, 25);   // bolts into the teardrops
            translate([-4, -12 - 43 * X, 10]) rotate([-90, 0, 0]) rod(8, 25);
            translate([8, 0, 8 + 18 * X]) rod(3, 16);                  // pin into the polyhole
            translate([19, 0, 20 + 14 * X]) wood_screw(3.5, 7, 16);     // screw into the countersink
        }
        if (role == "arrow") {
            for (x = [-18, -4]) arrow([x, -26, 18], [x, -12, 18]);
            arrow([13, 0, 44], [13, 0, 28]);
        }
    }
    else if (name == "diamond") {
        if (role == "piece") diamond_female_sample();
        if (role == "mate") translate([-5, 0, 12 + 16 * X]) rotate([0, 90, 0]) diamond_male_sample();
        if (role == "arrow") arrow([12, 0, 30], [12, 0, 16]);
    }
    else if (name == "tongue") {
        if (role == "piece") tongue_female_sample();
        if (role == "mate") translate([0, 0, 16 + 12 * X]) rotate([180, 0, 0]) tongue_male_sample();
        if (role == "arrow") arrow([0, -12, 24], [0, -12, 12]);
    }
    else if (name == "lead_in") {
        if (role == "piece") lead_in_female_sample();
        if (role == "mate") translate([0, 0, 17 + 22 * X]) rotate([180, 0, 0]) lead_in_male_sample();
        if (role == "arrow") arrow([14, 0, 32], [14, 0, 16]);
    }
    else if (name == "dovetail") {
        // a wall plate (on the wall) with the housing; the body's side wall
        // slides down into it, its tail resting on the closed bottom
        if (role == "wall") wall(-20, 20, -5, dt_h + 5);
        if (role == "piece") translate([0, -dt_plate, 0]) {
            translate([-12, 0, -2]) cube([24, dt_plate, dt_h + 2]);
            dovetail_housing(dt_h);
        }
        if (role == "mate") translate([0, -dt_plate, 30 * X]) {
            dovetail_tail(dt_h);
            translate([-1.68 / 2, -dovetail_housing_d() - dt_wall, 0]) cube([1.68, dt_wall, dt_h]);
        }
        if (role == "arrow") arrow([8, -dt_plate - 10, dt_h + 40], [8, -dt_plate - 10, dt_h + 6]);
    }
    else if (name == "bracket") {
        // a board standing on the floor, a bracket on each face, the same two
        // bolts through both legs and the board (cut through the bolts)
        if (role == "wall") box([-30, -60, -3], [30, 60, 0]);                      // the floor
        if (role == "mate") difference() {                                       // the board
            box([-30, -bb_t / 2, 0], [30, bb_t / 2, bb_h + 30]);
            for (z = bb_bolts) translate([0, 0, z]) rotate([90, 0, 0]) cylinder(d = 7, h = bb_t + 2, center = true);
        }
        if (role == "piece") for (s = [0, 1]) mirror([0, s, 0]) translate([0, bb_t / 2 + 12 * X, 0])
            board_bracket(bb_reach, bb_h, bb_w, bb_m, 6.5, bb_bolts);
        if (role == "hw") for (z = bb_bolts) {
            y0 = bb_t / 2 + bb_m + 12 * X;
            translate([0, -y0 - 1.6 - 16 * X, z]) rotate([-90, 0, 0]) hex_bolt(6, 30);
            translate([0, -y0, z]) rotate([90, 0, 0]) washer(6);
            translate([0, y0, z]) rotate([-90, 0, 0]) washer(6);
            translate([0, y0 + 1.6, z]) rotate([-90, 0, 0]) hex_nut(6);
        }
        if (role == "arrow") for (s = [-1, 1]) arrow([0, s * (bb_t / 2 + 40), bb_h + 10], [0, s * (bb_t / 2 + 16), bb_h + 10]);
    }
    else if (name == "bracket_hook") {
        // a bracket hooked under the back flange of a pressed steel tread, the board in its shoe
        // (the tread's back edge at y = bh_heel from the leg's face; cut through the middle)
        if (role == "wall") {   // the tread: plate and back flange, open below
            box([-30, -bb_reach - 20, -bh_sheet], [30, bh_heel, 0]);
            box([-30, bh_heel - bh_sheet, -bh_edge], [30, bh_heel, 0]);
        }
        if (role == "mate") box([-30, 0.3, bh_lip], [30, 10.3, bb_h + 30]);   // the board in the shoe
        if (role == "piece") translate([0, -16 * X, 0]) mirror([0, 1, 0]) hooked_bracket();
        if (role == "arrow") arrow([0, -bb_reach, 30], [0, -bb_reach + 14, 30]);   // slides up the tread to hook on
    }
    else if (name == "stabilizer") {
        // a thin wall printing standing, a fin on each face tied to it by
        // tabs (cut through a tab, from above): the fins in orange
        if (role == "piece") stabilizer_wall();
        if (role == "mate") stabilizer_fins();
    }
    else if (name == "handle") {
        // the handle's arms sprung over the block, its pins seated in the sockets
        if (role == "piece") handle_block_sample();
        if (role == "mate") translate([0, -(8 + h_reach + hb_d / 2), hb_h / 2 - 4]) sprung_handle(hb_w + 2 * h_play, h_reach + hb_d / 2, 8, 6, 5);
    }
}

names = ["keyhole_pad", "keyhole_button", "standoff_peg", "peg_block", "screw_plate", "holes",
         "diamond_female", "diamond_male", "tongue_female", "tongue_male", "lead_in_female",
         "lead_in_male", "dovetail_housing", "dovetail_tail", "house_box"];

if (demo != "none") {
    color(PIECE) cut(demo) demo_part(demo, "piece");
    color(MATE) cut(demo) demo_part(demo, "mate");
    color(HW) cut(demo) demo_part(demo, "hw");
    color(WALL) cut(demo) demo_part(demo, "wall");
    if (!assembled) color(ARROW) demo_part(demo, "arrow");
}
else if (part == "all") color(PIECE) for (i = [0 : len(names) - 1]) translate([(i % 5) * 70, -floor(i / 5) * 60, 0]) sample(names[i]);
else color(PIECE) sample(part);
