// One sample of every piece in the shared library, in print orientation, to
// check them after a change and to render them (`make render` here).
// part = "all" lays them out in a row.

use <basics.scad>
use <style.scad>
use <mounts.scad>
use <joints.scad>

part = "all";   // [all, keyhole_pad, keyhole_button, standoff_peg, house_box, holes, sockets, keys]
colour = "#8E9089"; // sample colour (Bambu PLA Basic Grey), for the colour export the renders use
cut = false;    // cut away the front-right quarter (x > cut_x(part), y < 0) of the samples that hide their inside, for renders

$fa = 1; $fs = 0.4;
eps = 0.01;

// keyhole_pad + keyhole_cut, lying on the back face: the countersink faces up
// and the slot runs along x (entry at -x)
module s_keyhole_pad()
    rotate([0, 0, -90]) rotate([-90, 0, 0]) difference() {
        keyhole_pad(4.2, 22, 12, 7, 12);
        keyhole_cut(4.2, 12, 7, 12);
    }

module s_keyhole_button() keyhole_button(4.2);
module s_standoff_peg() standoff_peg();

// house_plan / house_shell / wall_slot: a small box in the house style,
// standing on its chamfered floor, with a keyhole in its back
module s_house_box() {
    w = 60; d = 45; h = 40; t = 1.68;
    difference() {
        union() {
            hull() {
                linear_extrude(eps) offset(r = -0.6) house_plan(w, d);
                translate([0, 0, 0.6]) linear_extrude(2 - 0.6) house_plan(w, d);
            }
            linear_extrude(h) house_shell(w, d, t);
            translate([0, 0, 24]) keyhole_pad(4.2, 22, 12, 7, 12);
        }
        translate([0, 0, 24]) keyhole_cut(4.2, 12, 7, 12);
        for (y = slot_positions(t + 2.6, d - 14 - 2.6), s = [-1, 1]) wall_slot(s * w / 2, -y, 8, h - 6, "x");
        for (x = slot_positions(-w / 2 + 2.6, -11 - 2.6)) for (s = [-1, 1]) wall_slot(s * x, 0, 8, h - 6, "y");
    }
}

// teardrop, flat teardrop (front face), polyhole and countersunk screw (top),
// on a chamfered block
module s_holes() {
    difference() {
        chamfered_prism(20) square([56, 20], center = true);
        translate([-18, 0, 10]) teardrop(9, 22);
        translate([-4, 0, 10]) teardrop(9, 22, flat = true);
        translate([8, 0, -1]) polyhole(3, 22);
        translate([19, 0, 20]) countersunk_screw(3.5, 7, 15, extra = 1);
    }
}

// sockets on the top face of a block: diamond socket, tongue groove, lead-in socket
module s_sockets() {
    difference() {
        chamfered_prism(14) square([50, 20], center = true);
        translate([-17, 0, 14 - 6]) diamond_key(3 + 0.3, 0, 7);
        translate([0, 0, 14 + eps]) rotate([90, 0, 0]) mirror([0, 1, 0])
            linear_extrude(16, center = true) tongue_profile(play = 0.05, c = 0);
        translate([16, 0, 14 + eps]) lead_in_socket(8) circle(d = 8.4);
    }
}

// the mating keys on a bar: a diamond key out of its end face, axis level and
// corners up and down (as it prints on a part's side), and a tongue on top
module s_keys() {
    chamfered_prism(8) square([40, 12], center = true);
    translate([20 - eps, 0, 4]) rotate([0, 90, 0]) diamond_key(3, 0, 6);
    translate([0, 0, 8 - eps]) rotate([90, 0, 0]) linear_extrude(12, center = true) tongue_profile();
}

// samples whose inside is the point: a quarter is cut away, so the render
// shows the outline and the section through the axis
sectioned = ["keyhole_pad", "keyhole_button", "holes", "sockets"];
function cut_x(p) = p == "keyhole_pad" ? -6 : p == "keyhole_button" ? 0 : 2;   // through the slot, the axis, between features

module sample(p) {
    if (cut && len([for (n = sectioned) if (n == p) 1]) > 0) difference() {
        sample_whole(p);
        translate([cut_x(p), -500, -500]) cube([500, 500, 1000]);
    }
    else sample_whole(p);
}

module sample_whole(p) {
    if (p == "keyhole_pad") s_keyhole_pad();
    else if (p == "keyhole_button") s_keyhole_button();
    else if (p == "standoff_peg") s_standoff_peg();
    else if (p == "house_box") s_house_box();
    else if (p == "holes") s_holes();
    else if (p == "sockets") s_sockets();
    else if (p == "keys") s_keys();
}

names = ["keyhole_pad", "keyhole_button", "standoff_peg", "house_box", "holes", "sockets", "keys"];
xs = [0, 30, 50, 100, 165, 230, 285];
color(colour)
    if (part == "all") for (i = [0 : len(names) - 1]) translate([xs[i], 0, 0]) sample(names[i]);
    else sample(part);
