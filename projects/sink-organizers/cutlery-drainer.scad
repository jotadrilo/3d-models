// Cutlery drainer: a wall-mounted holder for wet cutlery next to the sink,
// with a bar for the dish towel. The soap caddy's design: a straight back on
// the wall, rounded front corners, close rounded slots, hung on suction cups
// through keyholes.
//
// Four pieces, so the ones that stay wet can be washed or reprinted alone:
//   - frame: the back plate with four keyholes and two side walls with
//     sloping ledges inside. Stays on the wall.
//   - tray: a slatted floor over a floor that slopes forward and spills into
//     the sink. It rests on the ledges and slides out to the front.
//   - bins: open boxes with slotted floors, side by side on the tray. They
//     lift out (and get reprinted when the knives have scored them).
//   - handle: a U across the front for the towel. Its arms are sprung apart
//     to snap diamond pins into sockets on both side walls (sprung_handle in
//     tools/scad/joints.scad): it cannot turn, and pulling the towel up or
//     forward cannot unseat it. Fold the towel over the bar.
// Four cups in two rows of two: the rows take the turning moment of the wet
// cutlery and the towel, which hang well in front of the wall.
//
// Coordinates: x along the wall, y = 0 on the frame's back face (the face
// that rests on the button flanges), negative towards the sink, z up with
// z = 0 at the bottom of the frame and of the tray's front edge.
//
// Print: the frame and the tray lie on their backs (walls, ledges, the
// sloping floor and the slats all become upright walls), the bins stand on
// their floors, the bar lies flat (its bending plane in XY). Every wall is a
// multiple of the 0.42 mm line.

use <../../tools/scad/basics.scad>
use <../../tools/scad/style.scad>
use <../../tools/scad/mounts.scad>
use <../../tools/scad/joints.scad>

/* [Part] */
part = "assembly";   // [assembly, frame, tray, bin, handle, button, test_pin]
show_items = true;   // draw the wall, counter, suction cups, cutlery and towel (assembly only)
section = "none";    // [none, keyhole, handle] cut the assembly through a keyhole, or level with the handle's pins, for the section renders

/* [Size] */
frame_w = 210;       // width of the frame, along the wall [120:1:300]
bins = 3;            // number of bins [1:1:5]
bin_d = 90;          // bin depth, front to back [50:1:120]
bin_h = 80;          // bin height: low enough to pick teaspoons out [50:1:140]

/* [Kitchen] */
sink_dist = 115;     // wall to the inner edge of the sink bowl: the tray must reach past it [40:1:250]
counter_gap = 15;    // counter to the bottom of the frame (preview and checks) [0:1:100]

/* [Suction cups] */
cup_d = 50;          // suction cup diameter [30:1:80]
cup_h = 12;          // wall to the cup's hub face, cup pressed on [5:0.5:30]
cup_span = 120;      // horizontal distance between the cups of a row [52:1:250]
cup_pitch = 55;      // vertical distance between the two rows [52:1:90]
stud_len = 12;       // the cup's threaded stud, from the hub face (measure it: the button needs to be longer) [5:0.5:20]
stud_hole = 3.7;     // pilot hole for the M4 stud as modelled (prints ~3.45); the stud taps its own thread [3:0.1:4.2]

/* [Keyhole] */
shank_d = 7;         // button shank diameter [5:0.5:10]
head_d = 12;         // button head diameter [9:0.5:16]
head_cyl = 1.2;      // straight part of the head, proud of the pad [0.6:0.2:3]
flange_d = 16;       // button flange diameter (rests on the cup hub) [10:0.5:24]
keyhole_play = 0.3;  // radial clearance of shank and head in the keyhole [0.1:0.05:0.6]
shank_play = 0.1;    // axial clearance between the pad and the head cone (0.2 left a little play) [0:0.05:0.6]
drop = 12;           // how far the frame drops onto its buttons; lift it this much to take it off [8:1:20]
pad_t = 4.2;         // pad thickness around each keyhole (10 lines) [3.36:0.42:6.3]
pad_w = 22;          // pad width [18:1:40]

/* [Frame] */
back_t = 1.68;       // back plate (4 lines) [1.26:0.42:4.2]
side_t = 1.68;       // side walls (4 lines) [1.26:0.42:3.36]
ledge_w = 3.36;      // ledges inside the side walls that carry the tray (8 lines) [2.1:0.42:6]
ledge_h = 4;         // ledge height [2:0.5:10]
ledge_stop = 2;      // bump at the front of each ledge: lift the tray this much to slide it out [1:0.5:4]
front_lip = 8;       // tray floor in front of the bins, where the water spills [4:1:30]
towel_gap = 14;      // room for the towel between the front of the frame and the handle [8:1:30]

/* [Tray] */
tray_play = 0.25;    // clearance between the tray and the side walls, per side (0.4 printed ~0.5) [0.1:0.05:1]
tray_t = 1.26;       // tray floor (3 lines) [0.84:0.42:2.52]
tray_wall = 1.68;    // tray back and side rims (4 lines) [1.26:0.42:2.52]
tray_slope = 6;      // floor slope towards the sink, degrees [3:0.5:15]
slat_w = 2.1;        // slat thickness (5 lines) [1.26:0.42:4.2]
slat_h = 5;          // slat height [3:0.5:12]
slat_pitch = 18;     // slat spacing: the bins have floors of their own, the slats only lift them off the water [9:1:30]
slat_clear = 3;      // gap between the slats and the floor, at the back [2:0.5:10]
stop_h = 8;          // tie across the front of the bins, above the slats [4:1:20]

/* [Bins] */
bin_wall = 1.26;     // bin walls (3 lines) [1.26:0.42:2.52]
bin_floor = 1.6;     // bin floor (8 layers) [1.2:0.2:3]
bin_r = 5;           // rounded vertical corners of the bins [1:0.5:12]
bin_play = 0.5;      // clearance round each bin [0.2:0.1:1.5]

/* [Towel handle] */
handle_s = 10;       // handle section, square, with chamfered edges [7:0.5:16]
handle_drop = 12;    // pin axes below the top of the frame [8:1:60]
pin_s = 6;           // diamond pins: side of the square [4:0.5:9]
pin_len = 5;         // how far the pins reach into the side walls [3:0.5:8]
pin_play = 0.15;     // clearance of the pins in their sockets, per side [0:0.05:0.4]
boss_t = 4.2;        // bosses on the side walls round the sockets (10 lines) [2.1:0.42:8]
boss_w = 16;         // boss height and length [12:1:30]
handle_play = 0.4;   // clearance between the handle's arms and the bosses, per side [0.2:0.1:1]

/* [Style] */
corner_r = 14;       // radius of the tray's front corners, in plan [0:1:40]
slot_w = 4;          // width of the rounded vertical slots in the walls [2:0.5:12]
slot_rib = 2.6;      // material between slots [2:0.2:12]
slot_margin = 6;     // solid band above and below the slots [3:1:20]
side_slot_tilt = 45; // side wall slots, degrees from vertical: the frame prints on its back, so at 0 each slot roofs over as one long bridge [0:5:60]

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
wall_gap = cup_h + flange_t;                   // wall to the frame's back face

// Plan, back to front: the button heads, the tray and bins, the towel gap, the bar
hx = frame_w / 2;
ix = hx - side_t;                              // inner half width
tray_y0 = -(head_front + bin_play);            // tray and bins' back, clear of the button heads
bin_y1 = tray_y0 - bin_d;                      // bins' front
stop_y = bin_y1 - bin_play;                    // back face of the tray's stop tie
reach = -(stop_y - slat_w - front_lip);        // front of the frame, from the back face
bar_y = -reach - towel_gap - handle_s / 2;     // handle bar axis, in front of the frame
tray_y1 = -reach + ledge_stop + 1;             // tray front, behind the ledge bumps
thx = ix - tray_play;                          // tray half width
tix = thx - tray_wall;                         // tray inner half width
bin_w = (2 * tix - (bins + 1) * bin_play) / bins;
bin_xs = [for (i = [0 : bins - 1]) -tix + bin_play + bin_w / 2 + i * (bin_w + bin_play)];

// Heights. The tray floor slopes down to the front; the ledges follow its underside.
tan_s = tan(tray_slope);
tray_tv = tray_t / cos(tray_slope);
function tray_bottom(y) = ledge_h + (y - tray_y1) * tan_s;   // floor underside at y (y <= 0), z = ledge top
function tray_top(y) = tray_bottom(y) + tray_tv;
z_fb = tray_top(tray_y0);                      // floor top at the back
z_s = z_fb + slat_clear + slat_h;              // slat tops (the bins stand here)
lo_z = pad_lo + 2;                             // lower keyholes' rest point: the pads start 2 mm up
hi_z = lo_z + cup_pitch;
top = max(z_s + bin_h, hi_z + pad_hi);         // top of the frame
pin_y = -reach + boss_w / 2 + 2;               // pin axes, near the front of the side walls
arm_z = top - handle_drop;                     // pin axes and the handle's mid-plane
span = frame_w + 2 * (boss_t + handle_play);   // between the handle's arms
handle_reach = pin_y - (bar_y + handle_s / 2);
spread = pin_len + 0.5;                        // how far each arm opens to put it on

cup_xs = [-cup_span / 2, cup_span / 2];
cup_zs = [lo_z, hi_z];

assert(reach + wall_gap >= sink_dist + 5, "the tray does not reach past the sink edge: raise front_lip or bin_d");
assert(cup_span / 2 + pad_w / 2 <= ix, "cup_span is wider than the frame");
assert(cup_pitch >= cup_d + 2, "cup_pitch is smaller than the cups");
assert(cup_span >= cup_d + 2, "cup_span is smaller than the cups");
assert(pin_s * sqrt(2) + 4 <= boss_w, "the pins are too big for the bosses");
assert(pin_len <= boss_t + side_t + 1, "the pins are longer than the bosses are deep");
assert(sprung_handle_strain(span, handle_reach, handle_s, spread) <= 0.01, "the handle strains over 1 % to go on: lengthen its arms (towel_gap) or shorten the pins");
assert(hi_z + pad_hi <= top, "the upper keyholes do not fit on the back plate");

echo(str("frame: ", frame_w, " x ", reach, " x ", top, " mm (w x d x h); front edge ", reach + wall_gap,
         " mm from the wall, the handle ", -bar_y + handle_s / 2 + wall_gap));
echo(str("tray: ", 2 * thx, " x ", tray_y0 - tray_y1, " x ", z_s + stop_h, " mm; ",
         bins, " bins ", bin_w, " x ", bin_d, " x ", bin_h, " mm (inside ", bin_w - 2 * bin_wall, " x ", bin_d - 2 * bin_wall, ")"));
echo(str("cups above the counter: ", counter_gap + lo_z, " and ", counter_gap + hi_z, " mm, ", cup_span, " mm apart"));
echo(str("handle: ", span + 2 * handle_s, " x ", handle_reach + 1.5 * handle_s, " mm; its arms open ", spread,
         " mm each to go on: ", round(sprung_handle_strain(span, handle_reach, handle_s, spread) * 1000) / 10, " % strain in the bar; button ", button_h, " mm"));

// ---------------------------------------------------------------- helpers

module plan(w, d) house_plan(w, d, corner_r);
function slot_xs(lo, hi) = slot_positions(lo, hi, slot_w, slot_rib);
module slot(x, y, z0, z1, axis) wall_slot(x, y, z0, z1, axis, slot_w);

module pad_at(z, x) translate([x, 0, z]) keyhole_pad(pad_t, pad_w, drop, shank_d, head_d, keyhole_play);
module keyhole_at(z, x) translate([x, 0, z]) keyhole_cut(pad_t, drop, shank_d, head_d, keyhole_play);

// The bar's key and its socket are tools/scad/joints.scad's diamond_key and
// diamond_socket: a square turned 45°, its corners along x and y. The frame
// prints on its back and the bar flat, so in both the corners point up and
// down and nothing overhangs past 45°.

// Prism along y from y0 to y1 of a 2D profile in (y, z): for the sloping parts.
module yz_prism(x0, x1) rotate([90, 0, 90]) translate([0, 0, x0]) linear_extrude(x1 - x0) children();

// ---------------------------------------------------------------- frame

module frame() {
    difference() {
        union() {
            // back plate and keyhole pads
            box([-hx, 0, 0], [hx, -back_t, top]);
            for (x = cup_xs, z = cup_zs) pad_at(z, x);
            // side walls, full height out to the front: a plain rectangle from the side,
            // their front edges rounded
            for (s = [-1, 1]) hull() {
                box([s * hx, -back_t + eps, 0], [s * ix, -reach + side_t / 2, top]);
                translate([s * (hx - side_t / 2), -reach + side_t / 2, 0]) cylinder(d = side_t, h = top);
            }
            // ledges under the tray's side rims, with a bump at the front
            for (s = [-1, 1]) yz_prism(s > 0 ? ix - ledge_w : -ix, s > 0 ? ix + eps : -ix + ledge_w)
                polygon([[-back_t, 0], [-back_t, tray_bottom(-back_t)], [tray_y1 - 0.5, tray_bottom(tray_y1 - 0.5)],
                         [tray_y1 - 0.5, tray_bottom(tray_y1) + ledge_stop], [-reach, tray_bottom(tray_y1) + ledge_stop], [-reach, 0]]);
            // bosses for the handle's pins, on the outside of both side walls;
            // tapered at the back, which faces down when the frame prints on its back
            for (m = [0, 1]) mirror([m, 0, 0]) hull() {
                box([hx - eps, pin_y - boss_w / 2, arm_z - boss_w / 2], [hx + boss_t, pin_y + boss_w / 2, arm_z + boss_w / 2]);
                box([hx - eps, pin_y + boss_w / 2, arm_z - boss_w / 2], [hx, pin_y + boss_w / 2 + boss_t, arm_z + boss_w / 2]);
            }
        }
        for (x = cup_xs, z = cup_zs) keyhole_at(z, x);
        for (m = [0, 1]) mirror([m, 0, 0]) translate([hx + boss_t, pin_y, arm_z]) sprung_handle_socket(pin_s, boss_t + side_t + 1, pin_play);
        // slots: the back plate clear of the pads, the side walls along the bins
        for (x = slot_xs(-ix + slot_rib, ix - slot_rib))
            if (min([for (c = cup_xs) abs(x - c)]) >= pad_w / 2 + slot_rib + slot_w / 2)
                slot(x, 0, z_s + slot_margin, top - slot_margin, "y");
        if (side_slot_tilt > 0)
            for (s = [-1, 1])
                wall_slots_tilted(s * hx, bin_y1 + slot_rib, tray_y0 - slot_rib, z_s + slot_margin, top - slot_margin,
                                  "x", side_slot_tilt, slot_w, slot_rib);
        else
            for (s = [-1, 1], y = slot_xs(-tray_y0 + slot_rib, -bin_y1 - slot_rib))
                slot(s * hx, -y, z_s + slot_margin, top - slot_margin, "x");
    }
}

// ---------------------------------------------------------------- tray

module tray() {
    slat_xs = [for (k = [-30:30]) let(x = k * slat_pitch) if (abs(x) + slat_w / 2 <= tix - 1) x];
    d = tray_y0 - tray_y1;
    rim = z_s;                                 // the back and side rims reach the slat tops
    union() {
        // floor, sloping to the front edge, front corners rounded
        intersection() {
            yz_prism(-thx, thx) polygon([[tray_y0, tray_bottom(tray_y0)], [tray_y0, tray_top(tray_y0)],
                                         [tray_y1, tray_top(tray_y1)], [tray_y1, tray_bottom(tray_y1)]]);
            translate([0, tray_y0, 0]) linear_extrude(rim + 1) plan(2 * thx, d);
        }
        // back rim, and side rims that round into the front corners
        box([-thx, tray_y0, tray_bottom(tray_y0)], [thx, tray_y0 - tray_wall, rim]);
        intersection() {
            translate([0, tray_y0, 0]) linear_extrude(rim) difference() { plan(2 * thx, d); offset(r = -tray_wall) plan(2 * thx, d); }
            yz_prism(-thx - 1, thx + 1) polygon([[tray_y0, tray_bottom(tray_y0)], [tray_y0, rim],
                                                 [stop_y - slat_w, rim], [tray_y1, tray_top(tray_y1) + 3], [tray_y1, tray_bottom(tray_y1)]]);
            box([-thx - 1, tray_y0 + 1, 0], [thx + 1, -reach, rim]);
            union() {                          // side rims only: the front stays open for the water
                box([-thx - 1, tray_y0 + 1, 0], [-tix + corner_r, -reach, rim]);
                box([tix - corner_r, tray_y0 + 1, 0], [thx + 1, -reach, rim]);
            }
        }
        // slats from the back rim to the stop tie, a tie under their middle
        for (x = slat_xs) box([x - slat_w / 2, tray_y0 - tray_wall + eps, z_s - slat_h], [x + slat_w / 2, stop_y, z_s]);
        box([-tix - eps, (tray_y0 + bin_y1) / 2 - slat_w / 2, z_s - slat_h], [tix + eps, (tray_y0 + bin_y1) / 2 + slat_w / 2, z_s - slat_h + 2.5]);
        // the stop tie across the front of the bins, on the slat ends
        box([-tix - eps, stop_y, z_s - slat_h], [tix + eps, stop_y - slat_w, z_s + stop_h]);
    }
}

// ---------------------------------------------------------------- bins

// One bin, in print orientation: floor on the bed, centred on x and y.
module bin() {
    w = bin_w; d = bin_d; r = bin_r;
    module outline(o = 0) offset(r = r + o) offset(delta = -r) square([w, d], center = true);
    difference() {
        union() {
            hull() {
                linear_extrude(eps) offset(delta = -chamfer) outline();
                translate([0, 0, chamfer]) linear_extrude(bin_floor - chamfer) outline();
            }
            linear_extrude(bin_h) difference() { outline(); outline(-bin_wall); }
        }
        // drain slots across the floor
        for (y = slot_xs(-d / 2 + bin_wall + 2, d / 2 - bin_wall - 2))
            translate([0, y, -1]) linear_extrude(bin_floor + 2)
                hull() for (x = [-1, 1]) translate([x * (w / 2 - bin_wall - 2 - slot_w / 2), 0]) circle(d = slot_w);
        // slots in all four walls, to air the cutlery
        for (s = [-1, 1], x = slot_xs(-w / 2 + r + slot_rib, w / 2 - r - slot_rib))
            slot(x, s * d / 2, bin_floor + slot_margin, bin_h - slot_margin, "y");
        for (s = [-1, 1], y = slot_xs(-d / 2 + r + slot_rib, d / 2 - r - slot_rib))
            slot(s * w / 2, y, bin_floor + slot_margin, bin_h - slot_margin, "x");
    }
}

// ---------------------------------------------------------------- handle

// The towel handle, in print orientation: the U flat on the bed.
module handle() sprung_handle(span, handle_reach, handle_s, pin_s, pin_len);

// In assembly coordinates: across the front, its pins in the side walls.
module handle_placed() translate([0, bar_y - handle_s / 2, arm_z - handle_s / 2]) handle();

// Fit test: a block with a socket on each side, as wide as two bosses and
// two walls with a gap, and a small handle that snaps onto it. Printed the
// way the real ones print: the block on its side (sockets along x), the
// handle flat.
test_w = 2 * (boss_t + side_t) + 12;
module test_pin() {
    difference() {
        box([-test_w / 2, -boss_w / 2, 0], [test_w / 2, boss_w / 2, boss_w]);
        for (m = [0, 1]) mirror([m, 0, 0]) translate([test_w / 2, 0, boss_w / 2]) sprung_handle_socket(pin_s, boss_t + side_t + 1, pin_play);
    }
    translate([0, boss_w / 2 + 6, 0]) sprung_handle(test_w + 2 * handle_play, 14, handle_s, pin_s, pin_len);
}

// ---------------------------------------------------------------- assembly

// "keyhole" keeps x <= the right column of keyholes (look from +x); "handle"
// keeps z <= the pins' axes (look from the top): the U and its pins in the walls.
module cut() {
    if (section == "none") children();
    else intersection() {
        union() children();
        if (section == "keyhole") translate([cup_span / 2 - 1000, -1000, -1000]) cube([1000, 2000, 2000]);
        else translate([-1000, -1000, arm_z - 2000]) cube([2000, 2000, 2000]);
    }
}
// In a section the mates are orange, to tell them from the pieces that hold them.
mate_colour = section != "none" ? "#FF6A13" : piece_colour;

module items() {
    // cups and buttons
    for (x = cup_xs, z = cup_zs) {
        color("#DDEEFF", 0.45) cut() translate([x, wall_gap, z]) rotate([90, 0, 0]) cylinder(d1 = cup_d, d2 = 14, h = cup_h);
        color(mate_colour) cut() translate([x, flange_t, z]) rotate([90, 0, 0])
            keyhole_button(pad_t, shank_d, head_d, flange_d, shank_play, head_cyl, stud_len, stud_hole, 3, chamfer);
    }
    // cutlery standing in the bins: a few handles with their heads up
    color("#B8BCC2") cut() for (i = [0 : bins - 1], j = [0 : 2]) {
        l = [150, 210, 130][i % 3];
        translate([bin_xs[i] + (j - 1) * bin_w / 4, (tray_y0 + bin_y1) / 2 + (j - 1) * 18, z_s + bin_floor])
            rotate([(j - 1) * 5, (j - 1) * 6, 0]) {
                translate([-1.5, -5, 0]) cube([3, 10, l - 45]);
                translate([0, 0, l - 25]) scale([0.4, 1.4, 3]) sphere(d = 15);
            }
    }
    // the towel, folded over the bar, hanging both sides (not in the handle's
    // section, where it would hide the pins)
    if (section != "handle") color("#5B7FA6") cut() {
        x0 = -85; x1 = 85;
        translate([x0, bar_y, arm_z]) rotate([0, 90, 0]) cylinder(d = handle_s + 5, h = x1 - x0);
        for (s = [-1, 1]) translate([x0, bar_y + s * (handle_s / 2 + 1.5) - 1.25, arm_z - 90]) cube([x1 - x0, 2.5, 90]);
    }
    // wall and counter (just round the drainer in the sections)
    ww = section == "none" ? 2 * frame_w : frame_w + 50;
    wh = section == "none" ? top + counter_gap + 100 : top + counter_gap + 40;
    color("#EEEEEE") cut() translate([-ww / 2, wall_gap, -counter_gap - 20]) cube([ww, 10, wh]);
    color("#C8B89A") cut() translate([-ww / 2, -sink_dist + wall_gap, -counter_gap - 20]) cube([ww, sink_dist, 20]);
}

if (part == "frame") frame();
else if (part == "tray") tray();
else if (part == "bin") bin();
else if (part == "handle") handle();
else if (part == "button") keyhole_button(pad_t, shank_d, head_d, flange_d, shank_play, head_cyl, stud_len, stud_hole, 3, chamfer);
else if (part == "test_pin") test_pin();
else {
    color(piece_colour) cut() frame();
    color(piece_colour) cut() tray();
    color(piece_colour) cut() for (x = bin_xs) translate([x, (tray_y0 + bin_y1) / 2, z_s]) bin();
    color(mate_colour) cut() handle_placed();
    if (show_items) items();
}
