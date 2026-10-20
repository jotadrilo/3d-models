// Soap caddy: a wall-mounted holder for an upside-down dish soap bottle and
// the scourer sponge, next to the sink.
//
// Two pieces, each hanging on two suction cups through keyholes, so they lift
// off for cleaning while the cups stay on the wall:
//   - upper: an open-front box that holds the bottle upside down, its cap
//     through a hole in the floor. The bottle drops in from the top; the
//     open front is where you squeeze it.
//   - lower: a slatted cradle for the sponge right under the cap, over a
//     tray that slopes forward and spills into the sink.
// The upper piece's cups sit one above the other, cup_pitch apart, so the
// pair takes the bottle's turning moment. The lower piece's cups sit side by
// side, which keeps the piece short; two pegs at its bottom rest on the wall
// and stop it nodding forward. Each cup's M4 stud screws into a printed
// button (flange, shank, cone head); the keyholes drop onto the buttons and
// the cone heads seat in countersinks, pulling the piece against the flanges.
//
// Coordinates (both pieces): x along the wall, y = 0 on the back face (the
// face that rests on the button flanges) and negative towards the sink,
// z up. The lower piece sits at z = 0 (front bottom edge of the tray); the
// upper piece's floor sits at z = z_seat.
//
// Print: the upper piece stands on its floor; the lower piece lies on its
// back (see bambu_project.py). Every wall is a multiple of the 0.42 mm line.

/* [Part] */
part = "assembly";   // [assembly, upper, lower, button, peg, test_keyhole]
show_items = true;   // draw the bottle, sponge, cups, wall and counter (assembly only)

/* [Bottle] */
bottle_w = 82;       // bottle width, along the wall [50:0.5:120]
bottle_d = 55;       // bottle depth, front to back [30:0.5:90]
bottle_h = 210;      // total height with the cap: checks it fits under the cabinet [100:1:320]
neck_d = 34;         // widest part that goes through the floor hole (cap, neck ring) [20:0.5:50]
seat_to_tip = 35;    // how far the cap tip hangs below the floor, bottle resting [15:1:70]
bottle_play = 1.5;   // clearance around the bottle, per side [0.5:0.5:5]

/* [Sponge] */
sponge_w = 90;       // sponge length, along the wall [40:1:140]
sponge_d = 65;       // sponge width, front to back [30:1:100]
sponge_h = 45;       // sponge height, with the nail guard [10:1:70]
sponge_play = 2;     // clearance around the sponge, per side [0.5:0.5:6]
tip_gap = 15;        // gap between the closed cap tip and the sponge top [5:1:40]

/* [Kitchen] */
sink_dist = 115;     // wall to the inner edge of the sink bowl [40:1:250]
drip_over = 10;      // how far the tray edge reaches past the sink edge [0:1:40]
counter_gap = 15;    // counter to the bottom of the tray (preview and checks) [0:1:100]
cabinet_h = 460;     // counter to the wall cabinet: the bottle must go in from the top [250:1:900]

/* [Suction cups] */
cup_d = 50;          // suction cup diameter [30:1:80]
cup_h = 12;          // wall to the cup's hub face, cup pressed on [5:0.5:30]
cup_pitch = 55;      // vertical distance between the upper piece's two cups [50:1:90]
lower_cup_span = 56; // horizontal distance between the lower piece's two cups [50:1:90]
stud_len = 10;       // length of the cup's threaded stud [5:0.5:20]
stud_hole = 3.4;     // pilot hole for the M4 stud, which taps its own thread [3:0.1:4.2]

/* [Keyhole] */
shank_d = 7;         // button shank diameter [5:0.5:10]
head_d = 12;         // button head diameter [9:0.5:16]
head_cyl = 1.2;      // straight part of the head, proud of the pad [0.6:0.2:3]
flange_d = 16;       // button flange diameter (rests on the cup hub) [10:0.5:24]
keyhole_play = 0.3;  // radial clearance of shank and head in the keyhole [0.1:0.05:0.6]
shank_play = 0.2;    // axial clearance between the pad and the head cone [0:0.05:0.6]
drop = 12;           // how far a piece drops onto its buttons; lift it this much to take it off [8:1:20]
pad_t = 4.2;         // pad thickness around each keyhole (10 lines) [3.36:0.42:6.3]
pad_w = 22;          // pad width [18:1:40]

/* [Upper piece] */
frame_h = 90;        // height of the bottle box [60:1:200]
wall_t = 1.68;       // side walls and front returns (4 lines) [1.26:0.42:4.2]
back_t = 1.68;       // back plates of both pieces (4 lines) [1.26:0.42:4.2]
floor_t = 2;         // box floor (10 layers) [1.2:0.2:4]
collar_t = 4;        // square collar round the floor hole (20 layers) [2:0.2:8]
return_w = 10;       // front returns that keep the bottle from tipping forward; they round into the sides [0:1:25]

/* [Lower piece] */
tray_slope = 6;      // tray slope towards the sink, degrees [3:0.5:15]
tray_t = 1.26;       // tray floor (3 lines) [0.84:0.42:2.52]
side_t = 1.68;       // tray side walls (4 lines) [1.26:0.42:3.36]
slat_w = 2.1;        // slat thickness (5 lines) [1.26:0.42:4.2]
slat_h = 5;          // slat height [3:0.5:12]
slat_pitch = 9;      // slat spacing [5:0.5:15]
slat_clear = 3;      // gap between the slats and the tray floor, at the back [2:0.5:10]
sponge_rim = 12;     // side walls rise this much above the slats [0:1:40]
peg_d = 6;           // pegs that rest the bottom of the lower piece on the wall [4:0.5:10]
peg_fit = 0.1;       // added to the peg holes, which print ~0.2 small: a press fit [-0.1:0.05:0.4]
peg_inset = 10;      // peg axis, in from each side of the lower piece [6:1:30]

/* [Style] */
corner_r = 14;       // radius of the front corners, in plan (the back stays straight) [0:1:40]
slot_w = 4;          // width of the rounded vertical slots in the walls [2:0.5:12]
slot_rib = 2.6;      // material between slots [2:0.2:12]
slot_margin = 6;     // solid band above and below the slots [3:1:20]

/* [Hidden] */
$fa = 1; $fs = $preview ? 0.8 : 0.4;
eps = 0.01;
chamfer = 0.6;                    // bottom-edge chamfer on the bed
piece_colour = "#1A1A1A";

// Keyhole and button sizes, from tools/scad/mounts.scad
shank_r = keyhole_shank_r(shank_d, keyhole_play);        // keyhole slot radius
entry_r = keyhole_entry_r(head_d, keyhole_play);         // keyhole entry radius
flange_t = keyhole_button_flange_t(pad_t, shank_d, head_d, shank_play, head_cyl, stud_len);
button_h = keyhole_button_h(pad_t, shank_d, head_d, shank_play, head_cyl, stud_len);
pad_hi = keyhole_pad_hi(shank_d, keyhole_play);          // pad above a keyhole's rest point
head_front = pad_t + shank_play + head_cyl;    // how far the heads reach in front of y = 0

wall_gap = cup_h + flange_t;                   // wall to the back face of the pieces
reach = sink_dist + drip_over - wall_gap;      // tray front edge, from the back face
tan_s = tan(tray_slope);
tray_tv = tray_t / cos(tray_slope);            // vertical thickness of the tray floor
function tray_top(y) = tray_tv + (reach + y) * tan_s;   // tray floor top at y (y <= 0)
z_fb = tray_top(0);                            // tray floor top at the back
z_s = z_fb + slat_clear + slat_h;              // slat tops (the sponge rests here)
z_seat = z_s + sponge_h + tip_gap + seat_to_tip;   // upper floor bottom

// Upper box
inner_w = bottle_w + 2 * bottle_play;
up_w = inner_w + 2 * wall_t;
y_in = -(head_front + 0.5);                    // bottle back
inner_d = bottle_d + 2 * bottle_play;
up_d = -y_in + inner_d + wall_t;
y_bc = y_in - inner_d / 2;                     // bottle axis
hole_d = neck_d + 1;
collar_d = hole_d + 12;

// Lower piece
lo_inner = sponge_w + 2 * sponge_play;
lo_w = lo_inner + 2 * side_t;
cradle_end = head_front + sponge_play + sponge_d + sponge_play + slat_w;
lo_cup_x = lower_cup_span / 2;
peg_x = lo_w / 2 - peg_inset;
peg_z = (z_fb - tray_tv) / 2;                  // under the tray floor
peg_len = pad_t + wall_gap;                    // through the boss and back to the wall
peg_collar = peg_d + 4;
peg_collar_t = 1.6;

// Cup heights, lower-piece coordinates. The lower pair's keyhole entries must
// clear the tray floor; the upper pair's lowest keyhole must clear the box floor.
lo_cup_z = z_fb + 1 + drop + entry_r;
up_cup_z = [for (i = [0:1]) z_seat + floor_t + drop + entry_r + 4 + i * cup_pitch];
lower_top = max(lo_cup_z + pad_hi, z_s + sponge_rim);

top_above_counter = counter_gap + z_seat + frame_h;

assert(reach > cradle_end + 5, "the tray does not reach past the sponge: raise sink_dist");
assert(up_cup_z[1] + pad_hi <= z_seat + frame_h, "the upper cups do not fit on the box: raise frame_h or lower cup_pitch");
assert(cup_pitch >= cup_d + 2, "cup_pitch is smaller than the cups");
assert(lower_cup_span >= cup_d + 2, "lower_cup_span is smaller than the cups");
assert(lo_cup_x + pad_w / 2 <= lo_w / 2, "lower_cup_span is wider than the lower piece");
assert(lower_top + drop < z_seat, "the lower piece cannot lift off under the box");
assert(button_h >= stud_len + 0.9, "the button is shorter than the stud");

echo(str("upper piece: ", up_w, " x ", up_d, " x ", frame_h, " mm (w x d x h)"));
echo(str("lower piece: ", lo_w, " x ", reach, " x ", lower_top, " mm (w x d x h)"));
echo(str("cups above the counter: lower pair ", counter_gap + lo_cup_z, " (", lower_cup_span,
         " apart), upper pair ", [for (z = up_cup_z) counter_gap + z], " mm (centred)"));
echo(str("pegs ", peg_len + peg_collar_t, " mm long, reach ", wall_gap, " mm behind the lower piece"));
echo(str("tray edge ", reach + wall_gap, " mm from the wall; button ", button_h, " mm long (flange ", flange_t, ")"));
echo(str("top of the box ", top_above_counter, " mm above the counter; bottle needs ",
         top_above_counter + bottle_h, " of ", cabinet_h, " mm to go in from the top"));
if (top_above_counter + bottle_h > cabinet_h)
    echo("WARNING: the bottle will not drop in from the top under the cabinet");

// ---------------------------------------------------------------- helpers

use <../../tools/scad/basics.scad>
use <../../tools/scad/style.scad>
use <../../tools/scad/mounts.scad>


// The house style (tools/scad/style.scad) with this project's sizes.
module plan(w, d) house_plan(w, d, corner_r);
module shell(w, d, t) house_shell(w, d, t, corner_r);
function slot_xs(lo, hi) = slot_positions(lo, hi, slot_w, slot_rib);
module slot(x, y, z0, z1, axis) wall_slot(x, y, z0, z1, axis, slot_w);

// Slots through a back plate, between z0 and z1, clear of the keyhole pads
// at pad_xs (pad centres).
module back_slots(pad_xs, half_w, z0, z1) {
    xs = slot_xs(-half_w + slot_rib, half_w - slot_rib);
    if (z1 - z0 >= 3 * slot_w)
        for (x = xs)
            if (min([for (p = pad_xs) abs(x - p)]) >= pad_w / 2 + slot_rib + slot_w / 2)
                slot(x, 0, z0, z1, "y");
}

// Slots through both side walls, along the straight part (before the corners round).
module side_slots(hx, d, z0, z1) {
    if (z1 - z0 >= 3 * slot_w)
        for (y = slot_xs(back_t + pad_t + slot_rib, d - corner_r - slot_rib), s = [-1, 1])
            slot(s * hx, -y, z0, z1, "x");
}

// Keyholes (tools/scad/mounts.scad), their rest point at (x, 0, z).
module pad_at(z, x = 0) translate([x, 0, z]) keyhole_pad(pad_t, pad_w, drop, shank_d, head_d, keyhole_play);
module keyhole_at(z, x = 0) translate([x, 0, z]) keyhole_cut(pad_t, drop, shank_d, head_d, keyhole_play);

// ---------------------------------------------------------------- parts

// Button, in print orientation: flange on the bed, head on top. The cup's
// M4 stud screws into the blind hole from the flange side.
module button() keyhole_button(pad_t, shank_d, head_d, flange_d, shank_play, head_cyl, stud_len, stud_hole, 3, chamfer);

// Upper piece: open-front box, its floor at z = 0.
module upper() {
    ks = [for (z = up_cup_z) z - z_seat];
    hx = up_w / 2;
    difference() {
        union() {
            // floor, chamfered on the bed
            hull() {
                linear_extrude(eps) offset(r = -chamfer) plan(up_w, up_d);
                translate([0, 0, chamfer]) linear_extrude(floor_t - chamfer) plan(up_w, up_d);
            }
            // round collar round the hole
            translate([0, y_bc, 0]) cylinder(d = collar_d, h = collar_t);
            // walls: straight back, sides that round into the front returns
            linear_extrude(frame_h) shell(up_w, up_d, wall_t);
            for (k = ks) pad_at(k);
        }
        // open front between the returns, rounded at the top corners of the opening
        translate([0, -up_d - 1, 0]) rotate([-90, 0, 0])
            linear_extrude(wall_t + 2) offset(r = slot_w) offset(delta = -slot_w)
                translate([-(inner_w / 2 - return_w), -frame_h - slot_w]) square([inner_w - 2 * return_w, frame_h + slot_w - floor_t]);
        // hole for the neck, with a 45° seat for the shoulder
        translate([0, y_bc, -eps]) {
            cylinder(d = hole_d, h = collar_t + 2 * eps);
            translate([0, 0, collar_t - 2.5 + eps]) cylinder(d1 = hole_d, d2 = hole_d + 5 + 2 * eps, h = 2.5 + eps);
        }
        // floor windows round the collar: drips fall through, less plastic
        translate([0, 0, -1]) linear_extrude(floor_t + 2) offset(r = 3) offset(delta = -3) difference() {
            offset(r = -(wall_t + 4)) plan(up_w, up_d);
            translate([-4, -up_d]) square([8, up_d]);
            translate([-up_w / 2, y_bc - 4]) square([up_w, 8]);
            translate([0, y_bc]) circle(d = collar_d + 8);
            translate([-up_w / 2, -back_t - 4]) square([up_w, back_t + 4]);
        }
        for (k = ks) keyhole_at(k);
        back_slots([0], inner_w / 2, floor_t + slot_margin, frame_h - slot_margin);
        side_slots(hx, up_d, floor_t + slot_margin, frame_h - slot_margin);
    }
}

// Lower piece: back plate, slatted sponge cradle and the sloping tray.
module lower() {
    hx = lo_w / 2;
    ix = lo_inner / 2;
    // slats every slat_pitch from the centre, none in front of a keyhole entry
    slat_xs = [for (k = [-20:20]) let(x = k * slat_pitch)
               if (abs(x) + slat_w / 2 <= ix - 1 && abs(abs(x) - lo_cup_x) > entry_r + slat_w / 2 + 0.5) x];
    difference() {
        union() {
            // back plate and keyhole pads
            box([-hx, 0, 0], [hx, -back_t, lower_top]);
            for (s = [-1, 1]) pad_at(lo_cup_z, s * lo_cup_x);
            // bosses for the pegs, under the tray floor
            for (s = [-1, 1]) box([s * peg_x - peg_collar / 2 - 1, 0, 0], [s * peg_x + peg_collar / 2 + 1, -pad_t, z_fb - tray_tv + eps]);
            // tray floor, sloping down to the front edge, with rounded front corners
            intersection() {
                rotate([90, 0, 90]) translate([0, 0, -hx]) linear_extrude(lo_w)
                    polygon([[0, z_fb], [-reach, tray_tv], [-reach, 0], [0, z_fb - tray_tv]]);
                translate([0, 0, -1]) linear_extrude(z_fb + 2) plan(lo_w, reach);
            }
            // side walls: a plain rectangle seen from the side, full height out
            // to the front edge, rounding into the front corners; the front stays open
            difference() {
                linear_extrude(lower_top) shell(lo_w, reach, side_t);
                box([-(hx - corner_r), -reach - 1, -1], [hx - corner_r, -reach + side_t + 1, lower_top + 1]);
            }
            // slats, flush at the front so the sponge slides in and out freely
            for (x = slat_xs)
                box([x - slat_w / 2, -back_t + eps, z_s - slat_h], [x + slat_w / 2, -cradle_end, z_s]);
            // ties across the slats: one at the front, one in the middle, under the sponge
            box([-ix - eps, -cradle_end, z_s - slat_h], [ix + eps, -cradle_end + slat_w, z_s]);
            box([-ix - eps, -cradle_end / 2 - slat_w / 2, z_s - slat_h], [ix + eps, -cradle_end / 2 + slat_w / 2, z_s - slat_h + 2.5]);
        }
        for (s = [-1, 1]) keyhole_at(lo_cup_z, s * lo_cup_x);
        for (s = [-1, 1]) translate([s * peg_x, eps, peg_z]) rotate([90, 0, 0])
            cylinder(d = peg_d + peg_fit, h = pad_t + 2 * eps, $fn = 32);
    }
}

// Peg, in print orientation: collar on the bed. It presses into its boss from
// the front of the lower piece, and its rounded tip rests on the wall.
module peg() standoff_peg(peg_d, peg_len, peg_collar, peg_collar_t, chamfer);

// Fit test: a flat pad with one keyhole, for a button.
module test_keyhole() {
    difference() {
        translate([0, pad_t, 0]) pad_at(0);
        translate([0, pad_t, 0]) keyhole_at(0);
    }
}

// ---------------------------------------------------------------- items (preview)

module items() {
    // bottle, upside down
    color("#3C9A3C", 0.55) translate([0, y_bc, z_seat]) {
        translate([0, 0, -seat_to_tip]) cylinder(d = neck_d - 6, h = seat_to_tip + 3);
        translate([0, 0, collar_t])
            linear_extrude(bottle_h - seat_to_tip - collar_t)
                offset(r = 10) square([bottle_w - 20, bottle_d - 20], center = true);
    }
    // sponge: yellow foam on a green scourer
    translate([0, y_in - sponge_play - sponge_d / 2 - 0.5, z_s]) {
        color("#2E6B30") translate([-sponge_w / 2, -sponge_d / 2, 0]) cube([sponge_w, sponge_d, 8]);
        color("#F2D43A") translate([-sponge_w / 2, -sponge_d / 2, 8]) cube([sponge_w, sponge_d, sponge_h - 8]);
    }
    // cups and buttons
    for (c = concat([for (s = [-1, 1]) [s * lo_cup_x, lo_cup_z]], [for (z = up_cup_z) [0, z]])) {
        color("#DDEEFF", 0.45) translate([c[0], wall_gap, c[1]]) rotate([90, 0, 0])
            cylinder(d1 = cup_d, d2 = 14, h = cup_h);
        color("#555555") translate([c[0], flange_t, c[1]]) rotate([90, 0, 0]) button();
    }
    // pegs, pressed in from the front
    for (s = [-1, 1]) color("#555555") translate([s * peg_x, -pad_t - peg_collar_t, peg_z]) rotate([-90, 0, 0]) peg();
    // wall and counter
    color("#EEEEEE") translate([-160, wall_gap, -counter_gap - 20]) cube([320, 10, cabinet_h + 20]);
    color("#C8B89A") translate([-160, -sink_dist + wall_gap, -counter_gap - 20]) cube([320, sink_dist, 20]);
}

// ---------------------------------------------------------------- selection

if (part == "upper") upper();
else if (part == "lower") lower();
else if (part == "button") button();
else if (part == "peg") peg();
else if (part == "test_keyhole") test_keyhole();
else {
    color(piece_colour) lower();
    color(piece_colour) translate([0, 0, z_seat]) upper();
    if (show_items) items();
}
