// Remote control stand v2: same two-row stepped box as v1, finished with
// straight channels cut into the walls instead of raised ribs.
// The outer surface stays flush: a smooth band runs along each top edge,
// with a rounded outer edge, and below it narrow flat-bottomed channels
// run down to the base, all the way around the body (radial at the
// rounded corners) and across the step face.
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
wall      = 3.2;       // outer wall, channels included
divider   = 3.2;       // wall between rows, channelled on the step face
step_gap  = 3;         // flat ledge between the front pockets and the step face
floor_t   = 2.4;
corner_r  = 8;
slot_r    = 6;         // pocket corner radius

/* [Channels] */
groove_w     = 1.5;    // channel width
groove_depth = 1.2;    // how deep each channel cuts into the wall
groove_pitch = 3;

/* [Rim] */
rim_h     = 5;         // smooth band along the top edges, above the channels
rim_round = 1.5;       // radius of its rounded outer edge
rim_steps = 8;

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

inner_w = max(row_w(front_count, fw), row_w(back_count, bw));
W = inner_w + 2 * wall;
D = wall + ft + step_gap + divider + bt + wall;

y_front = wall;
y_div   = y_front + ft;        // back face of the front slots
y_step  = y_div + step_gap;    // step face
y_back  = y_step + divider;

// The narrower row spreads its spare width evenly around its slots.
function slot_x(i, n, w) =
    let(g = (inner_w - row_w(n, w)) / (n + 1))
    wall + g + i * (w + divider + g);

module rounded_square(w, d, r) {
    offset(r) offset(-r) square([w, d]);
}

// Point and outward normal at arc length s along the outline, starting
// at the front-left tangent point and running counterclockwise.
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
n_grooves = round(perimeter / groove_pitch);
g_step    = perimeter / n_grooves;

// ---------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------

module back_part() {
    intersection() {
        children();
        translate([-1, y_step]) square([W + 2, D]);
    }
}

// Extrude a plan shape up to `top`, rounding its outer top edge with
// stacked slices inset along a quarter circle.
module rounded_top(top) {
    linear_extrude(top - rim_round) children();
    for (i = [0 : rim_steps - 1])
        let(a0 = 90 * i / rim_steps, a1 = 90 * (i + 1) / rim_steps,
            z0 = top - rim_round + rim_round * sin(a0),
            z1 = top - rim_round + rim_round * sin(a1))
            translate([0, 0, z0]) linear_extrude(z1 - z0)
                offset(delta = -rim_round * (1 - cos(a1))) children();
}

module body() {
    rounded_top(front_wall_h) rounded_square(W, D, corner_r);
    rounded_top(back_wall_h) back_part() rounded_square(W, D, corner_r);
}

// ---------------------------------------------------------------------
// Channels
// ---------------------------------------------------------------------

// One channel, cut inwards from the surface at the origin (normal +x).
module groove(z0, z1) {
    translate([-groove_depth, -groove_w / 2, z0]) cube([groove_depth + 1, groove_w, z1 - z0]);
}

// Height a channel may reach at plan depth y. Channels near the step's
// side edge stop at the front row so they don't leave a sliver there.
function groove_top(y) =
    y + groove_w / 2 + 1 < y_step ? front_wall_h - rim_h :
    y - groove_w / 2 - 1 > y_step ? back_wall_h - rim_h :
                                    front_wall_h - rim_h;

module outline_grooves() {
    for (k = [0 : n_grooves - 1])
        let(p = outline_pt(k * g_step))
            translate(p[0]) rotate(atan2(p[1][1], p[1][0])) groove(-1, groove_top(p[0][1]));
}

// Channels on the step face, lined up with the ones on the front face.
module step_grooves() {
    margin = groove_w / 2 + 1.5;
    k0 = ceil((margin - corner_r) / g_step);
    for (x = [corner_r + k0 * g_step : g_step : W - margin])
        translate([x, y_step, 0]) rotate(-90) groove(front_wall_h - eps, back_wall_h - rim_h);
}

// ---------------------------------------------------------------------
// Pockets and details
// ---------------------------------------------------------------------

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
    outline_grooves();
    step_grooves();
    if (dust_holes) holes();
    if (feet_recess) feet();
}

echo(str("Footprint: ", W, " x ", D, " mm, height ", back_wall_h, " mm"));
echo(str("Channels: ", n_grooves, " around, pitch ", g_step, " mm; wall behind them ",
         wall - groove_depth, " mm"));
assert(groove_depth < wall - 0.8 && groove_depth < divider - 0.8, "groove_depth leaves too thin a wall");
