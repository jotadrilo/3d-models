// What the sink organizers share: every piece is a wall plate that hangs on
// suction cups through keyholes, and a body that slides down onto it on two
// sliding dovetails, with a slotted floor, ledges for a drip tray that slopes
// into the sink, and the house style (straight back, rounded front corners,
// close rounded slots, 45° in the side walls).
//
// Included, not used, by soap-caddy.scad and cutlery-drainer.scad after their
// own parameters, so they share these values (override them with -D, as any
// other; the Customizer shows only the piece's own). A change here changes
// both pieces.
//
// Coordinates: x along the wall, y = 0 on the plate's back face (the face
// that rests on the button flanges) and negative towards the sink, z up with
// z = 0 at the bottom of the body. The tray's front bottom edge is ledge_h up.
//
// Print: the plate flat on its back (the keyholes' slots and the housings'
// flanks in XY), the body standing on its floor (the dovetail tails along Z,
// a front wall and the slots print like any wall), the tray on its back.

use <../../tools/scad/basics.scad>
use <../../tools/scad/style.scad>
use <../../tools/scad/mounts.scad>
use <../../tools/scad/joints.scad>

/* [Suction cups] */
cup_d = 50;          // suction cup diameter [30:1:80]
cup_h = 12;          // wall to the cup's hub face, cup pressed on [5:0.5:30]
stud_len = 12;       // the cup's threaded stud, from the hub face (measure it: the button needs to be longer) [5:0.5:20]
stud_hole = 3.7;     // pilot hole for the M4 stud as modelled (prints ~3.45); the stud taps its own thread [3:0.1:4.2]

/* [Keyhole] */
shank_d = 7;         // button shank diameter [5:0.5:10]
head_d = 12;         // button head diameter [9:0.5:16]
head_cyl = 1.2;      // straight part of the head, proud of the pad [0.6:0.2:3]
flange_d = 16;       // button flange diameter (rests on the cup hub) [10:0.5:24]
keyhole_play = 0.3;  // radial clearance of shank and head in the keyhole [0.1:0.05:0.6]
shank_play = 0.1;    // axial clearance between the pad and the head cone (0.2 left a little play) [0:0.05:0.6]
drop = 12;           // how far the plate drops onto its buttons; lift it this much to take it off [8:1:20]
pad_t = 4.2;         // pad thickness around each keyhole (10 lines) [3.36:0.42:6.3]
pad_w = 22;          // pad width [18:1:40]

/* [Plate and body] */
back_t = 1.68;       // wall plate (4 lines) [1.26:0.42:4.2]
side_t = 1.68;       // the body's walls (4 lines): also the dovetails' necks [1.26:0.42:3.36]
tie_t = 1.6;         // the body's floor under the tray, which ties the side walls together (8 layers: it prints on the bed) [1.2:0.2:3.2]
drip_clear = 5;      // the floor stops this far behind the tray's front edge, so the drips fall clear of it [2:1:20]
ledge_w = 3.36;      // ledges inside the side walls that carry the tray (8 lines) [2.1:0.42:6]
ledge_h = 4;         // ledge height, at the front [2:0.5:10]
ledge_stop = 2;      // bump at the front of each ledge: lift the tray this much to slide it out [1:0.5:4]

/* [Dovetail] */
dt_w = 1.68;         // how far the tails widen on each side, at 45° (4 lines: 1.26 printed round, standing) [0.84:0.42:2.52]
dt_d = 4;            // tail depth, from its wide face to the neck [2:0.5:6]
dt_play = 0.1;       // clearance on the flanks, per side (0.25 was loose in PETG: pick it from the fit test) [0:0.05:0.5]
dt_floor = 0.2;      // clearance between the tails and the plate (0.35 let them rock) [0.1:0.05:0.6]
dt_lip = 1.26;       // housing in front of the flanks (3 lines) [0.84:0.42:2.52]
dt_side = 1.68;      // housing beside the tails (4 lines) [1.26:0.42:3.36]
dt_cap = 2;          // the housings' closed bottoms, under the body: it rests on them [1:0.2:4]

/* [Tray] */
tray_play = 0.25;    // clearance between the tray and the side walls, per side (0.4 printed ~0.5) [0.1:0.05:1]
tray_t = 1.26;       // tray floor (3 lines) [0.84:0.42:2.52]
tray_wall = 1.68;    // tray back and side rims (4 lines) [1.26:0.42:2.52]
tray_slope = 6;      // floor slope towards the sink, degrees [3:0.5:15]
slat_w = 2.1;        // slat thickness (5 lines) [1.26:0.42:4.2]
slat_h = 5;          // slat height [3:0.5:12]
slat_clear = 3;      // gap between the slats and the tray floor, at the back [2:0.5:10]

/* [Style] */
corner_r = 14;       // radius of the front corners in plan (the back stays straight) [0:1:40]
slot_w = 4;          // width of the rounded slots in the walls [2:0.5:12]
slot_rib = 2.6;      // material between slots [2:0.2:12]
slot_margin = 6;     // solid band round the slots [3:1:20]
side_slot_tilt = 45; // side wall and floor slots, degrees from vertical (the house style) [5:5:60]
slot_max_len = 30;   // longest slot; longer ones are split. In a wall that prints standing the thin ribs between long slots sway under the nozzle [15:1:80]

/* [Hidden] */
$fa = 1; $fs = $preview ? 0.8 : 0.4;
eps = 0.01;
chamfer = 0.6;                    // bottom-edge chamfer on the bed
piece_colour = "#1A1A1A";

// Keyhole and button sizes, from tools/scad/mounts.scad
entry_r = keyhole_entry_r(head_d, keyhole_play);
flange_t = keyhole_button_flange_t(pad_t, shank_d, head_d, shank_play, head_cyl, stud_len);
button_h = keyhole_button_h(pad_t, shank_d, head_d, shank_play, head_cyl, stud_len);
pad_lo = keyhole_pad_lo(drop, head_d, keyhole_play);
pad_hi = keyhole_pad_hi(shank_d, keyhole_play);
head_front = pad_t + shank_play + head_cyl;    // how far the button heads reach in front of y = 0
wall_gap = cup_h + flange_t;                   // wall to the plate's back face

// Dovetails (tools/scad/joints.scad), on the side walls' centre lines
house_hw = dovetail_housing_w(side_t, dt_w, dt_play, dt_side) / 2;
house_d = dovetail_housing_d(dt_d, dt_floor, dt_lip);
body_back = back_t + dt_floor + dt_d;          // the side walls' back edges (the tails' necks), from y = 0
body_in = back_t + house_d + 0.3;              // what the body has inside its walls starts here, clear of the housings
back_clear = max(head_front, back_t + house_d);   // what stands in front of the plate: button heads, housings

tan_s = tan(tray_slope);
tray_tv = tray_t / cos(tray_slope);            // vertical thickness of the tray floor

// ---------------------------------------------------------------- helpers
// The piece defines: hx (body half width), ix = hx - side_t, tray_y1 (the
// tray's front edge) and the parts. Functions read them when called.

function plate_hx() = hx - side_t / 2 + house_hw;   // the plate's half width: out to the housings
function tray_bottom(y) = ledge_h + (y - tray_y1) * tan_s;   // tray underside at y
function tray_top(y) = tray_bottom(y) + tray_tv;
function floor_y1() = tray_y1 + drip_clear;   // front of the body's floor

module plan(w, d) house_plan(w, d, corner_r);
module shell(w, d, t) house_shell(w, d, t, corner_r);
function slot_xs(lo, hi) = slot_positions(lo, hi, slot_w, slot_rib);
module slot(x, y, za, zb, axis, max_len = slot_max_len) wall_slot(x, y, za, zb, axis, slot_w, 20, slot_rib, max_len);
// 45° slots, split at slot_max_len, in the rectangle [u0, u1] x [v0, v1] of a
// wall t thick whose normal is x (u = y, v = z) or z (u = x, v = -y).
module slots_tilted(at, u0, u1, v0, v1, axis, t)
    if (axis == "z") rotate([90, 0, 0])
        wall_slots_tilted(at, u0, u1, v0, v1, "y", side_slot_tilt, slot_w, slot_rib, t + 2, max_len = slot_max_len);
    else wall_slots_tilted(at, u0, u1, v0, v1, axis, side_slot_tilt, slot_w, slot_rib, t + 2, max_len = slot_max_len);

module pad_at(z, x) translate([x, 0, z]) keyhole_pad(pad_t, pad_w, drop, shank_d, head_d, keyhole_play);
module keyhole_at(z, x) translate([x, 0, z]) keyhole_cut(pad_t, drop, shank_d, head_d, keyhole_play);

// Prism along x from x0 to x1 of a 2D profile in (y, z).
module yz_prism(x0, x1) rotate([90, 0, 90]) translate([0, 0, x0]) linear_extrude(x1 - x0) children();
// On the inside of both side walls, ledge_w wide, profile in (y, z).
module ledges() for (s = [-1, 1]) yz_prism(s > 0 ? ix - ledge_w : -ix - eps, s > 0 ? ix + eps : -ix + ledge_w) children();

// Button, in print orientation: flange on the bed, head on top. The cup's
// M4 stud screws into the hole from the flange side.
module button() keyhole_button(pad_t, shank_d, head_d, flange_d, shank_play, head_cyl, stud_len, stud_hole, 3, chamfer);

// ---------------------------------------------------------------- wall plate

// The plate from z = -dt_cap to h: keyholes at cups ([x, z] each), the two
// housings, and slots in each [z0, z1] of zones, clear of the pads.
module wall_plate(h, cups, zones) {
    sx = hx - side_t / 2 - house_hw - slot_rib;   // the slots stay inside the housings
    difference() {
        union() {
            box([-plate_hx(), 0, -dt_cap], [plate_hx(), -back_t, h]);
            for (c = cups) pad_at(c[1], c[0]);
            for (s = [-1, 1]) translate([s * (hx - side_t / 2), -back_t, 0])
                dovetail_housing(h, side_t, dt_w, dt_d, dt_play, dt_floor, dt_lip, dt_side, dt_cap);
        }
        for (c = cups) keyhole_at(c[1], c[0]);
        for (zn = zones, x = slot_xs(-sx, sx))
            if (min([for (c = cups) zn[0] < c[1] + pad_hi + slot_margin && zn[1] > c[1] - pad_lo - slot_margin
                     ? abs(x - c[0]) : 1e9]) >= pad_w / 2 + slot_rib + slot_w / 2)
                slot(x, 0, zn[0], zn[1], "y");
    }
}

// ---------------------------------------------------------------- body

// The tails on the side walls' back edges, from z = 0 to h.
module body_tails(h) for (s = [-1, 1]) translate([s * (hx - side_t / 2), -back_t, 0])
    dovetail_tail(h, side_t, dt_w, dt_d, dt_floor, dt_lip);

// The tray's ledges, following its underside, with a bump at the front, out
// to y_front; and the floor under the tray, slotted between the ledges.
module tray_ledges(y_front)
    ledges() polygon([[-body_in, 0], [-body_in, tray_bottom(-body_in)], [tray_y1 - 0.5, tray_bottom(tray_y1 - 0.5)],
                      [tray_y1 - 0.5, ledge_h + ledge_stop], [y_front, ledge_h + ledge_stop], [y_front, 0]]);
module body_floor() difference() {
    box([-ix - eps, -body_in, 0], [ix + eps, floor_y1(), tie_t]);
    slots_tilted(tie_t / 2, -ix + ledge_w + slot_rib, ix - ledge_w - slot_rib, body_in + slot_rib, -floor_y1() - slot_rib, "z", tie_t);
}

// ---------------------------------------------------------------- tray

// Tray hw wide each side of x = 0 from y0 (back) to tray_y1 (front): a floor
// sloping to the front edge, back and side rims (the side rims round into
// the front corners, the front stays open for the water), slats at
// slat_pitch from the back rim to a tie across their front ends at tie_y,
// which stands tie_up above the slats, and a tie under their middle.
module tray(hw, y0, z_s, slat_pitch, tie_y, tie_up = 0) {
    iw = hw - tray_wall;
    d = y0 - tray_y1;
    slat_xs = [for (k = [-30:30]) let(x = k * slat_pitch) if (abs(x) + slat_w / 2 <= iw - 1) x];
    union() {
        intersection() {
            yz_prism(-hw, hw) polygon([[y0, tray_bottom(y0)], [y0, tray_top(y0)], [tray_y1, tray_top(tray_y1)], [tray_y1, tray_bottom(tray_y1)]]);
            translate([0, y0, 0]) linear_extrude(z_s + tie_up + 1) plan(2 * hw, d);
        }
        box([-hw, y0, tray_bottom(y0)], [hw, y0 - tray_wall, z_s]);
        intersection() {
            translate([0, y0, 0]) linear_extrude(z_s) difference() { plan(2 * hw, d); offset(r = -tray_wall) plan(2 * hw, d); }
            yz_prism(-hw - 1, hw + 1) polygon([[y0, tray_bottom(y0)], [y0, z_s], [tie_y - slat_w, z_s],
                                               [tray_y1, tray_top(tray_y1) + 3], [tray_y1, tray_bottom(tray_y1)]]);
            union() {
                box([-hw - 1, y0 + 1, 0], [-iw + corner_r, tray_y1 - 1, z_s]);
                box([iw - corner_r, y0 + 1, 0], [hw + 1, tray_y1 - 1, z_s]);
            }
        }
        for (x = slat_xs) box([x - slat_w / 2, y0 - tray_wall + eps, z_s - slat_h], [x + slat_w / 2, tie_y, z_s]);
        box([-iw - eps, tie_y, z_s - slat_h], [iw + eps, tie_y - slat_w, z_s + tie_up]);
        box([-iw - eps, (y0 + tie_y) / 2 - slat_w / 2, z_s - slat_h], [iw + eps, (y0 + tie_y) / 2 + slat_w / 2, z_s - slat_h + 2.5]);
    }
}

// ---------------------------------------------------------------- fit tests

// A keyhole pad, printed flat, for a button.
module test_keyhole() difference() {
    translate([0, pad_t, 0]) pad_at(0, 0);
    translate([0, pad_t, 0]) keyhole_at(0, 0);
}
// A strip of plate with a housing for each play in test_dt_plays, printed
// flat like the plate (k notches in its edge past the mouths mark the k-th), and a strip of
// side wall with its tail, printed standing like the body: the play to use is
// the tightest housing the tail slides all the way down with no rocking.
// 20 mm long: every layer of the standing strip is tiny and waits out the
// filament's minimum layer time (12 s in PETG), so length is print time. The
// strip ends in a return, so it stands without a brim.
test_dt_h = 20;
test_dt_plays = [0.05, 0.1, 0.15, 0.2];
module test_dovetail_housing() {
    n = len(test_dt_plays);
    hw = dovetail_housing_w(side_t, dt_w, max(test_dt_plays), dt_side) / 2;
    pitch = 2 * hw + 3;
    rotate([-90, 0, 0]) difference() {
        union() {
            translate([-n * pitch / 2, 0, -dt_cap]) cube([n * pitch, back_t, test_dt_h + dt_cap + 4]);
            for (i = [0 : n - 1]) translate([(i - (n - 1) / 2) * pitch, 0, 0])
                dovetail_housing(test_dt_h, side_t, dt_w, dt_d, test_dt_plays[i], dt_floor, dt_lip, dt_side, dt_cap);
        }
        for (i = [0 : n - 1], k = [0 : i]) translate([(i - (n - 1) / 2) * pitch + (k - i / 2) * 2 - 0.5, -1, test_dt_h + 2])
            cube([1, back_t + 2, 3]);
    }
}
module test_dovetail_tail() {
    dovetail_tail(test_dt_h, side_t, dt_w, dt_d, dt_floor, dt_lip);
    translate([-side_t / 2, -dt_floor - dt_d - 20, 0]) cube([side_t, 20, test_dt_h]);
    translate([-side_t / 2, -dt_floor - dt_d - 20, 0]) cube([10, side_t, test_dt_h]);
}

// ---------------------------------------------------------------- assembly helpers

// The suction cups and buttons at cups ([x, z] each), in colour c for the buttons.
module cups_and_buttons(cups, c) for (p = cups) {
    color("#DDEEFF", 0.45) translate([p[0], wall_gap, p[1]]) rotate([90, 0, 0]) cylinder(d1 = cup_d, d2 = 14, h = cup_h);
    color(c) translate([p[0], flange_t, p[1]]) rotate([90, 0, 0]) button();
}
