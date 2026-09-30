// Cosmere RPG tracker: Health, Focus and (optionally) Investiture, each
// counted 00-99 on a wheel that reads the same from both sides of the table.
//
// Each wheel is an outer ring (tens) around an inner disc (units), both with
// digits on both faces. The front plate has a window at 9 o'clock and the
// back plate one at 3 o'clock, so both the player and the rest of the table
// read tens on the left and units on the right. The ring is turned by its
// ridged edge sticking out of the top; the disc by the knob on the front.
//
// Digits, labels and window rims are flush inlays meant for a multi-colour
// printer (AMS): export with --enable=lazy-union to 3MF and every colour
// comes out as its own part. Everything prints flat without supports.
// All dimensions in mm.

/* [Stats] */
show_investiture = true;
labels           = ["SALUD", "CONCENTRACIÓN", "INVESTIDURA"];

/* [Colours] */
body_color   = "#1b1b1b";
digit_color  = "#f2f2f2";
label_colors = ["#e0b040", "#e0b040", "#e0b040"];  // one per stat
rim_color    = "#f2f2f2";                          // frame around the windows

/* [Digits] */
digit_h   = 7;      // height of a digit on the wheel
font      = "Liberation Sans:style=Bold";
label_h   = 5.5;  // strokes must stay wider than a first-layer line
ink_depth = 0.6;    // inlay thickness (3 layers at 0.2)
window_rim = 1.2;   // coloured frame around each window (0 = none)

/* [Wheels] */
wheel_t    = 3.2;   // ring and disc thickness
gap_z      = 0.3;   // play between a wheel face and a plate
wheel_gap  = 0.5;   // radial play between disc and ring
hub_r      = 5.5;   // knob on the disc, through the front plate
hub_play   = 0.25;
knob_h     = 4;     // how far the knob sticks out of the front plate
grip       = 5;     // how far the ring sticks out of the top edge
ridges     = 60;
ridge_r    = 0.6;
ring_play  = 0.4;   // radial play between the ring ridges and the housing

/* [Housing] */
plate_t     = 2;
side_wall   = 6;
bottom_wall = 4;
between     = 3;    // narrowest wall between two wheels
corner_r    = 4;
peg_d       = 3;
peg_h       = 1.5;
peg_play    = 0.1;

/* [Stand] */
stand_depth = 40;
stand_h     = 7;
slot_depth  = 5;
slot_play   = 0.3;

/* [Render] */
part    = "assembly";  // [assembly, frame, front, wheels, ring, disc, stand]
explode = 0;           // spread the assembly along Z

/* [Hidden] */
$fn = 96;
eps = 0.01;

n  = show_investiture ? 3 : 2;
dw = digit_h * 0.62;                                       // digit width (radial)
r1 = max(10 * (digit_h + 1.4) / (2 * PI),                  // units track
         hub_r + hub_play + 1.5 + dw / 2);
disc_r   = r1 + dw / 2 + 1.4;
ring_ir  = disc_r + wheel_gap;
r2       = ring_ir + 1.4 + dw / 2;                         // tens track
y_top    = r2 + dw / 2 + 1.2;                              // plates cover the digits
ring_or  = y_top + grip;
cavity_r = ring_or + ridge_r + ring_play;
pitch    = 2 * cavity_r + between;
cav_t    = wheel_t + 2 * gap_z;
T        = 2 * plate_t + cav_t;                            // total thickness
W        = (n - 1) * pitch + 2 * (cavity_r + side_wall);
y_bot    = -(cavity_r + bottom_wall);
H        = y_top - y_bot;

// Window spans both tracks; tall enough for one digit, not its neighbours.
win_x0 = r1 - dw / 2 - 1;
win_x1 = r2 + dw / 2 + 1;
win_h  = digit_h + 1.2;

function wheel_x(i) = (i - (n - 1) / 2) * pitch;

echo(str("Tracker ", W, " x ", H, " x ", T, " mm (+", knob_h, " knob); wheel Ø",
         2 * (ring_or + ridge_r)));

// ---------- 2D ----------

module outline()
    translate([-W / 2, y_bot])
        offset(r = corner_r) offset(delta = -corner_r) square([W, H]);

module digit(k) resize([0, digit_h], auto = true)
    text(str(k), font = font, halign = "center", valign = "center");

// Digit k shows at 9 o'clock on the front face (or 3 o'clock on the back
// face) when the wheel has turned 36*k degrees.
module track(r, back) for (k = [0 : 9])
    rotate(-36 * k) translate([back ? r : -r, 0])
        if (back) mirror([1, 0]) digit(k); else digit(k);

module window(back)
    translate([back ? win_x0 : -win_x1, -win_h / 2])
        offset(r = 1) offset(delta = -1) square([win_x1 - win_x0, win_h]);

module label(i, back)
    translate([0, (y_top + win_h / 2 + hub_r) / 2 + 1])
        mirror([back ? 1 : 0, 0])
            text(labels[i], size = label_h, font = font, halign = "center", valign = "center");

module peg_spots() {
    for (s = [-1, 1], y = [-10, 10]) translate([s * (W / 2 - side_wall / 2), y]) children();
    for (i = [0 : n - 2], y = [-18, 18]) translate([(wheel_x(i) + wheel_x(i + 1)) / 2, y]) children();
}

// ---------- 3D helpers ----------

// Inlay slab on the face at z = z0, going inwards (dir = +1 up, -1 down).
// `grow` pushes it out through the face, so the pocket cut is clean.
module ink_slab(z0, dir, grow = 0)
    translate([0, 0, dir > 0 ? z0 - grow : z0 - ink_depth])
        linear_extrude(ink_depth + grow) children();

// ---------- Parts (assembled position: back face at z = 0) ----------

module frame_solid() difference() {
    union() {
        linear_extrude(plate_t) outline();
        translate([0, 0, plate_t]) linear_extrude(cav_t) difference() {
            outline();
            for (i = [0 : n - 1]) translate([wheel_x(i), 0]) circle(cavity_r);
        }
        translate([0, 0, plate_t + cav_t]) peg_spots() cylinder(d = peg_d, h = peg_h, $fn = 24);
    }
    for (i = [0 : n - 1]) translate([wheel_x(i), 0, -eps])
        linear_extrude(plate_t + 2 * eps) window(true);
}

module frame_ink(i, what, grow = 0) translate([wheel_x(i), 0]) ink_slab(0, 1, grow)
    if (what == "label") label(i, true);
    else if (window_rim > 0) difference() { offset(r = window_rim) window(true); window(true); }

module front_solid() translate([0, 0, plate_t + cav_t]) difference() {
    linear_extrude(plate_t) outline();
    for (i = [0 : n - 1]) translate([wheel_x(i), 0, -eps]) {
        linear_extrude(plate_t + 2 * eps) window(false);
        cylinder(r = hub_r + hub_play, h = plate_t + 2 * eps);
    }
    peg_spots() translate([0, 0, -eps]) cylinder(d = peg_d + peg_play, h = peg_h + 0.2, $fn = 24);
}

module front_ink(i, what, grow = 0) translate([wheel_x(i), 0]) ink_slab(T, -1, grow)
    if (what == "label") label(i, false);
    else if (window_rim > 0) difference() { offset(r = window_rim) window(false); window(false); }

// Wheels in their own frame: back face at z = 0.
module ring_solid() difference() {
    cylinder(r = ring_or, h = wheel_t, $fn = 180);
    translate([0, 0, -eps]) cylinder(r = ring_ir, h = wheel_t + 2 * eps, $fn = 180);
}

module ring_ridges() for (a = [0 : ridges - 1]) rotate(a * 360 / ridges)
    translate([ring_or, 0, 0]) cylinder(r = ridge_r, h = wheel_t, $fn = 12);

module disc_solid() {
    cylinder(r = disc_r, h = wheel_t, $fn = 180);
    // knob: through the front plate, grooved where it sticks out
    top = wheel_t + gap_z + plate_t;
    difference() {
        cylinder(r = hub_r, h = top + knob_h);
        for (a = [0 : 11]) rotate(a * 30) translate([hub_r + 0.3, 0, top + 0.5])
            cylinder(r = 0.9, h = knob_h, $fn = 16);
        translate([0, 0, top + knob_h - 0.8]) difference() {
            cylinder(r = hub_r + 1, h = 1);
            cylinder(r1 = hub_r, r2 = hub_r - 1, h = 1 + eps);
        }
    }
}

module wheel_ink(r, grow = 0) {
    ink_slab(0, 1, grow) track(r, true);
    ink_slab(wheel_t, -1, grow) track(r, false);
}

// ---------- Body / ink pairs ----------

module frame_body() difference() {
    frame_solid();
    for (i = [0 : n - 1]) { frame_ink(i, "label", eps); frame_ink(i, "rim", eps); }
}
module front_body() difference() {
    front_solid();
    for (i = [0 : n - 1]) { front_ink(i, "label", eps); front_ink(i, "rim", eps); }
}
module ring_body() { difference() { ring_solid(); wheel_ink(r2, eps); } ring_ridges(); }
module disc_body() difference() { disc_solid(); wheel_ink(r1, eps); }

module stand() difference() {
    translate([-(W + 10) / 2, -stand_depth / 2, 0])
        linear_extrude(stand_h) offset(r = 4) offset(delta = -4) square([W + 10, stand_depth]);
    translate([-(W + 2 * slot_play) / 2, -(T + slot_play) / 2, stand_h - slot_depth])
        cube([W + 2 * slot_play, T + slot_play, slot_depth + eps]);
}

// ---------- Print layouts ----------

module front_print() translate([0, 0, T]) rotate([180, 0, 0]) children();

module wheels_layout(which = "all") {
    step = 2 * (ring_or + ridge_r) + 4;
    for (i = [0 : n - 1]) {
        if (which != "disc") translate([(i - (n - 1) / 2) * step, step / 2]) children(0);
        if (which != "ring") translate([(i - (n - 1) / 2) * step, -step / 2]) children(1);
    }
}

module place_wheels(ring_z, disc_z) for (i = [0 : n - 1]) translate([wheel_x(i), 0]) {
    translate([0, 0, ring_z]) rotate(36 * [3, 1, 0][i]) children(0);
    translate([0, 0, disc_z]) rotate(36 * [7, 5, 4][i]) children(1);
}

// ---------- Output (one top-level object per colour with lazy-union) ----------

if (part == "frame") {
    color(body_color) frame_body();
    for (i = [0 : n - 1]) color(label_colors[i]) frame_ink(i, "label");
    if (window_rim > 0) color(rim_color) for (i = [0 : n - 1]) frame_ink(i, "rim");
}
else if (part == "front") {
    color(body_color) front_print() front_body();
    for (i = [0 : n - 1]) color(label_colors[i]) front_print() front_ink(i, "label");
    if (window_rim > 0) color(rim_color) front_print() for (i = [0 : n - 1]) front_ink(i, "rim");
}
else if (part == "wheels") {
    color(body_color) wheels_layout() { ring_body(); disc_body(); }
    color(digit_color) wheels_layout() { wheel_ink(r2); wheel_ink(r1); }
}
else if (part == "ring") {
    color(body_color) ring_body();
    color(digit_color) wheel_ink(r2);
}
else if (part == "disc") {
    color(body_color) disc_body();
    color(digit_color) wheel_ink(r1);
}
else if (part == "stand") {
    color(body_color) stand();
}
else {  // assembly, standing in the stand; shows 37 / 15 / 04
    translate([0, 0, -y_bot + stand_h - slot_depth]) rotate([90, 0, 0]) translate([0, 0, -T / 2]) {
        color(body_color) frame_body();
        for (i = [0 : n - 1]) color(label_colors[i]) frame_ink(i, "label");
        color(rim_color) for (i = [0 : n - 1]) frame_ink(i, "rim");
        place_wheels(plate_t + gap_z + explode, plate_t + gap_z + 2 * explode) {
            union() { color(body_color) ring_body(); color(digit_color) wheel_ink(r2); }
            union() { color(body_color) disc_body(); color(digit_color) wheel_ink(r1); }
        }
        translate([0, 0, 3 * explode]) {
            color(body_color) front_body();
            for (i = [0 : n - 1]) color(label_colors[i]) front_ink(i, "label");
            color(rim_color) for (i = [0 : n - 1]) front_ink(i, "rim");
        }
    }
    color(body_color) translate([0, 0, 0]) stand();
}
