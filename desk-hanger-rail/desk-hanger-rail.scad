// Desk hanger rail: two C brackets that clip onto the front edge of a desk
// and hold a bar underneath it, for coat hangers.
//
// Each bracket wraps the desk edge (top lip, front web, underside arm) and
// carries the bar further in, below the desk. The load of the hangers levers
// the lip tip down onto the desk top and the arm up against the underside, so
// it holds without screws; a nub under the lip tip adds a light press fit.
//
// Print: the brackets lie flat (side profile on the bed), so the bending of
// the C runs along the layers; the bar lies flat on its keel. Both are
// designed to be printed solid (see bambu_project.py), in PETG.

/* [Part] */
part = "assembly"; // [assembly, bracket_left, bracket_right, bar, test_socket, test_bar, test_clip]
show_desk = true;  // draw a slice of the desk in the assembly (preview only)

/* [Desk] */
desk_t = 25;           // desk top thickness [10:0.5:60]
edge_r = 1;            // rounding of the desk edge; inner fillet of the C [0:0.5:3]

/* [Rail] */
width = 200;           // overall width along the desk edge (bar fits the bed up to ~260) [60:5:260]
bar_inset = 50;        // bar axis, measured in from the desk front edge [25:1:120]
hook_clearance = 45;   // gap between the desk underside and the top of the bar [30:1:80]
bar_d = 12;            // diameter of the round top the hangers sit on [8:0.5:20]
bar_h = 18;            // total bar height (round top + keel below it) [12:0.5:30]

/* [Bracket] */
bracket_w = 16;        // bracket thickness along the desk edge [10:0.5:30]
lip_len = 30;          // how far the top lip reaches onto the desk [15:1:60]
lip_t = 4.2;           // top lip thickness at the tip (10 lines) [2.52:0.42:8.4]
lip_root_t = 6.72;     // top lip thickness where it meets the web (16 lines) [2.52:0.42:10.08]
web_t = 6.72;          // front web thickness (16 lines) [3.36:0.42:10.08]
arm_t = 6.72;          // underside arm and truss member width [3.36:0.42:10.08]
socket_wall = 4.2;     // wall around the bar socket [2.52:0.42:8.4]
socket_depth = 10;     // how deep the bar goes into each bracket [5:1:25]
truss_window = true;   // open the triangle under the desk into a truss

/* [Fit] */
grip_play = 0.3;       // clearance between the C and the desk (per side)
grip_squeeze = 0.6;    // how far the lip nub presses into the desk top
bar_play = 0.15;       // clearance of the bar in its socket, per side (0.15-0.20: removable fit)
end_gap = 0.5;         // gap between each bar end and the socket bottom

/* [Fit test] */
test_h = 6;            // height of test_socket and length of test_bar [4:1:20]
test_clip_w = 4;       // thickness of test_clip, a slice of the C without the truss [3:1:16]

/* [Hidden] */
$fa = 1; $fs = $preview ? 0.8 : 0.4;
eps = 0.01;
chamfer = 0.6;         // 45° chamfer on the bed-side edges, 3 layers of 0.2
layer = 0.2;
round_r = 1.5;         // rounding of the outer corners of the profile
nub_r = 2;
window_r = 3;
gap_top = desk_t + grip_play;              // underside of the lip
bar_c = [bar_inset, -hook_clearance - bar_d / 2];  // bar axis in the side profile
boss_half = bar_d / 2 + bar_play + socket_wall;
bar_len = width - 2 * (bracket_w - socket_depth) - 2 * end_gap;

assert(socket_depth <= bracket_w - 3, "socket_depth leaves less than 3 mm behind the socket");
assert(hook_clearance > socket_wall + arm_t, "hook_clearance too small for the bracket arm");

// ---------------------------------------------------------------- 2D profiles

// Bar cross-section, centred on the round top: a circle on a keel with a flat,
// chamfered bottom. The flanks are steeper than 45°, so it prints lying down.
module bar_section(grow = 0) {
    bf = bar_d / 2;                        // width of the flat bottom
    offset(delta = grow) hull() {
        circle(d = bar_d);
        translate([-bf / 2, -(bar_h - bar_d / 2) + chamfer]) square([bf, eps]);
        translate([-bf / 2 + chamfer, -(bar_h - bar_d / 2)]) square([bf - 2 * chamfer, eps]);
    }
}

// Under-desk part of the bracket: arm along the underside, leg down to the
// socket boss, and the diagonal back to the web.
module truss() {
    boss();
    difference() {
        g();
        if (truss_window)
            difference() {
                offset(r = window_r) offset(delta = -(arm_t + window_r)) g();
                offset(r = arm_t) boss();
            }
    }
    module g() hull() {
        translate([-web_t, -arm_t]) square([web_t + bar_inset + boss_half, arm_t]);
        boss();
    }
    module boss() translate(bar_c) bar_section(bar_play + socket_wall);
}

// Side profile of a bracket: u (x) runs from the desk front edge into the
// desk, v (y) is up from the desk underside.
module profile() {
    nub_u = lip_len - lip_t - nub_r;
    // close the inner corners (desk edge fillet), round the outer ones
    offset(r = -edge_r) offset(delta = edge_r)
    offset(r = round_r) offset(delta = -round_r) union() {
        translate([-web_t, -arm_t]) square([web_t, arm_t + gap_top + lip_root_t]); // web
        hull() {                                                                  // lip, tapered to a round tip
            translate([-web_t, gap_top]) square([web_t, lip_root_t]);
            translate([lip_len - lip_t / 2, gap_top + lip_t / 2]) circle(d = lip_t);
        }
        translate([nub_u, desk_t - grip_squeeze + nub_r]) circle(r = nub_r);  // press-fit nub
        truss();
    }
}

// ---------------------------------------------------------------- parts (print orientation)

// Prism of `profile` with 45° chamfers made of layer-high steps at both faces.
module chamfered_prism(h) {
    steps = round(chamfer / layer);
    for (i = [0 : steps - 1]) {
        inset = chamfer - i * layer;
        translate([0, 0, i * layer]) linear_extrude(layer + eps) offset(delta = -inset) children();
        translate([0, 0, h - (i + 1) * layer - eps]) linear_extrude(layer + eps) offset(delta = -inset) children();
    }
    translate([0, 0, chamfer]) linear_extrude(h - 2 * chamfer) children();
}

// Blind socket for the bar, opening at z = 0 and going down, with a chamfered mouth.
module socket(play) {
    translate([0, 0, -socket_depth]) hull() {
        linear_extrude(socket_depth + eps) bar_section(play);
        translate([0, 0, socket_depth - chamfer]) linear_extrude(chamfer + eps) bar_section(play + chamfer);
    }
}

// Left bracket, lying on its outer face; the socket opens upwards.
module bracket_left() {
    difference() {
        chamfered_prism(bracket_w) profile();
        translate([bar_c.x, bar_c.y, bracket_w]) socket(bar_play);
    }
}

module bracket_right() mirror([1, 0, 0]) bracket_left();

// Bar lying along x on its flat keel, ends chamfered for an easy start.
module bar(len = bar_len) {
    rotate([90, 0, 90]) translate([0, bar_h - bar_d / 2]) hull() {
        translate([0, 0, chamfer]) linear_extrude(len - 2 * chamfer) bar_section();
        linear_extrude(len) bar_section(-chamfer);
    }
}

// ---------------------------------------------------------------- fit test

// A ring with the socket profile at bar_play, open at both ends (its end
// chamfers act as lead-ins), to try the bar in it.
module test_socket()
    chamfered_prism(test_h) difference() {
        bar_section(bar_play + socket_wall);
        bar_section(bar_play);
    }

// A short bar for test_socket, a bit longer than the ring.
module test_bar() bar(test_h * 2);

// A slice of the C (lip, web and the start of the arm) to try the grip on the desk.
module test_clip() {
    chamfered_prism(test_clip_w) intersection() {
        profile();
        translate([-web_t - 1, -arm_t - 1]) square([web_t + lip_len + 2, arm_t + gap_top + lip_root_t + 2]);
    }
}

// ---------------------------------------------------------------- assembly

// x along the desk edge, y into the desk (front edge at y = 0), z = 0 at the
// desk underside.
// Print orientation -> assembly: (x, y, z) -> (z + p, x, y).
module place(p) multmatrix([[0, 0, 1, p], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) children();

if (part == "bracket_left") bracket_left();
else if (part == "bracket_right") bracket_right();
else if (part == "bar") bar();
else if (part == "test_socket") test_socket();
else if (part == "test_bar") test_bar();
else if (part == "test_clip") test_clip();
else {
    place(0) bracket_left();
    place(width) mirror([0, 0, 1]) bracket_left();
    translate([bracket_w - socket_depth + end_gap, bar_inset, -hook_clearance - bar_h]) bar();
    if (show_desk)
        color("BurlyWood", 0.5) translate([-40, 0, 0]) cube([width + 80, 120, desk_t]);
}

echo(str("Bracket: ", web_t + bar_inset + boss_half, " x ", gap_top + max(lip_t, lip_root_t) + hook_clearance + bar_h + socket_wall,
         " x ", bracket_w, " mm (depth x height x width)"));
echo(str("Bar: ", bar_len, " mm long, ", bar_d, " mm round top, ", bar_h, " mm tall"));
echo(str("Rail: ", width, " mm wide; bar top ", hook_clearance, " mm below the desk, ", bar_inset,
         " mm in from the edge"));
if (bar_len > 250) echo("WARNING: the bar is longer than the P1S bed allows (~250 mm)");
