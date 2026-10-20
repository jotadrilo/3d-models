// Remote control stand: two-row stepped box with ribbed outer walls.
// Front row is lower, back row is taller and has a raised floor so its
// remotes sit higher than the front ones. Rounded ribs run all the way
// around the body, corners included, and across the step face.
// All dimensions in mm.

/* [Front row (lower)] */
front_count    = 1;
front_remote_w = 120;   // widest remote in this row
front_remote_t = 30;   // thickest remote in this row
front_wall_h   = 55;

/* [Back row (upper)] */
back_count    = 2;
back_remote_w = 60;
back_remote_t = 30;
back_wall_h   = 95;
back_floor_h  = 35;    // raised floor: back remotes sit this much higher

/* [Body] */
clearance = 2;         // added to each slot's width and thickness
wall      = 2.4;       // thinnest wall, measured at the bottom of a valley
divider   = 2.4;
step_gap  = 3;         // flat ledge between the front pockets and the step ribs
floor_t   = 2.4;
corner_r  = 8;         // corner radius of the core, under the ribs
slot_r    = 6;         // pocket corner radius

/* [Ribs] */
rib_r     = 1;         // rib roundness
rib_h     = 1;       // how far each rib stands out from the core
rib_pitch = 3;
valley_r  = -1;        // valley fillet: -1 auto (smooth wave, no flat), 0 sharp, >0 fixed

/* [Details] */
dust_holes  = true;
dust_hole_d = 6;
feet_recess = true;    // pockets for adhesive rubber feet
foot_d      = 10.5;
foot_depth  = 1;

/* [Hidden] */
$fn = 48;
eps = 0.01;

fw = front_remote_w + clearance;
ft = front_remote_t + clearance;
bw = back_remote_w + clearance;
bt = back_remote_t + clearance;

function row_w(n, w) = n * w + (n - 1) * divider;

// Core: the body without ribs, spanning [0, W] x [0, D].
inner_w = max(row_w(front_count, fw), row_w(back_count, bw));
W = inner_w + 2 * wall;
D = wall + ft + step_gap + rib_h + divider + bt + wall;

y_front = wall;
y_div   = y_front + ft;        // back face of the front slots
y_step  = y_div + step_gap + rib_h;   // core face of the step; ribs stop step_gap short of y_div
y_back  = y_step + divider;

// The narrower row spreads its spare width evenly around its slots.
function slot_x(i, n, w) =
    let(g = (inner_w - row_w(n, w)) / (n + 1))
    wall + g + i * (w + divider + g);

module rounded_square(w, d, r) {
    offset(r) offset(-r) square([w, d]);
}

// Point and outward normal at arc length s along the core outline,
// starting at the front-left tangent point and running counterclockwise.
function arc_pt(c, a) = [c + corner_r * [cos(a), sin(a)], [cos(a), sin(a)]];

function outline_pt(s) =
    let(r = corner_r, a = W - 2 * r, b = D - 2 * r, q = PI * r / 2)
    s < a             ? [[r + s, 0], [0, -1]] :
    s < a + q         ? arc_pt([W - r, r], -90 + (s - a) / q * 90) :
    s < a + q + b     ? [[W, r + s - a - q], [1, 0]] :
    s < a + 2*q + b   ? arc_pt([W - r, D - r], (s - a - q - b) / q * 90) :
    s < 2*a + 2*q + b ? [[W - r - (s - a - 2*q - b), D], [0, 1]] :
    s < 2*a + 3*q + b ? arc_pt([r, D - r], 90 + (s - 2*a - 2*q - b) / q * 90) :
    s < 2*a + 3*q + 2*b ? [[0, D - r - (s - 2*a - 3*q - b)], [-1, 0]] :
                        arc_pt([r, r], 180 + (s - 2*a - 3*q - 2*b) / q * 90);

perimeter = 2 * (W - 2 * corner_r) + 2 * (D - 2 * corner_r) + 2 * PI * corner_r;
n_ribs    = round(perimeter / rib_pitch);
rib_step  = perimeter / n_ribs;

// Auto valley radius: the concave arc between two ribs just touches the
// core, so the profile is one continuous wave whatever the rib spacing.
rib_c    = rib_h - rib_r;     // rib centre offset from the core outline
valley_f = valley_r >= 0 ? valley_r
         : max(0, (pow(rib_step / 2, 2) + rib_c * rib_c - rib_r * rib_r) / (2 * (rib_r + rib_c)));

module ribbed_outline() {
    rounded_square(W, D, corner_r);
    for (k = [0 : n_ribs - 1])
        let(p = outline_pt(k * rib_step))
            translate(p[0] + p[1] * (rib_h - rib_r)) circle(r = rib_r);
}

// Ribs on the step face, spread edge to edge so the outermost ones sit on
// the step's side corners, flush with the side ribs.
module step_ribs() {
    x0 = rib_r - rib_h;
    n = max(1, round((W - 2 * x0) / rib_pitch));
    for (k = [0 : n])
        translate([x0 + k * (W - 2 * x0) / n, y_step + rib_r - rib_h]) circle(r = rib_r);
}

// Rounds the concave corners of a 2D shape (morphological closing).
module fillet_valleys() {
    offset(r = -valley_f) offset(r = valley_f) children();
}

module body() {
    linear_extrude(front_wall_h) fillet_valleys() ribbed_outline();
    linear_extrude(back_wall_h) fillet_valleys() {
        intersection() {
            ribbed_outline();
            translate([-rib_h - 1, y_step]) square([W + 2 * rib_h + 2, D]);
        }
        step_ribs();
    }
}

module slots() {
    for (i = [0 : front_count - 1])
        translate([slot_x(i, front_count, fw), y_front, floor_t])
            linear_extrude(front_wall_h) rounded_square(fw, ft, min(slot_r, ft / 2 - eps));
    for (i = [0 : back_count - 1])
        translate([slot_x(i, back_count, bw), y_back, back_floor_h])
            linear_extrude(back_wall_h) rounded_square(bw, bt, min(slot_r, bt / 2 - eps));
}

module holes() {
    for (i = [0 : front_count - 1])
        translate([slot_x(i, front_count, fw) + fw / 2, y_front + ft / 2, -1])
            cylinder(d = dust_hole_d, h = floor_t + 2);
    for (i = [0 : back_count - 1])
        translate([slot_x(i, back_count, bw) + bw / 2, y_back + bt / 2, -1])
            cylinder(d = dust_hole_d, h = back_floor_h + 2);
}

module feet() {
    inset = corner_r + foot_d / 2;
    for (x = [inset, W - inset], y = [inset, D - inset])
        translate([x, y, -eps]) cylinder(d = foot_d, h = foot_depth + eps);
}

difference() {
    body();
    slots();
    if (dust_holes) holes();
    if (feet_recess) feet();
}

echo(str("Footprint: ", W + 2 * rib_h, " x ", D + 2 * rib_h, " mm, height ", back_wall_h, " mm"));
