// Soap caddy: a wall-mounted holder for an upside-down dish soap bottle and
// the scourer sponge, next to the sink.
//
// Modular, like the cutlery drainer: one frame stays on the wall, and the
// pieces that get wet come out on their own, to wash or reprint them:
//   - frame: a back plate with four keyholes and two side walls, deep at the
//     bottom round the tray and as deep as the box above it, with a rounded
//     step between them. Ledges inside carry the tray and the box.
//   - tray: a slatted cradle for the sponge over a floor that slopes forward
//     and spills into the sink. It rests on the lower ledges; lift its front
//     over the bumps at their ends and it slides out.
//   - box: an open-front box that holds the bottle upside down, its cap
//     through a hole in the floor, right over the sponge. It drops in from
//     the top onto the upper ledges and lifts out; the bottle drops into it
//     from the top, and the open front is where you squeeze it.
// The frame hangs on four suction cups: two side by side low down and two one
// above the other behind the box (where the earlier two-piece caddy had them,
// so the cups stay put). A single frame on all four takes the turning moment
// of the bottle and of a hand pressing the sponge, with nothing resting on the
// wall. Each cup's M4 stud screws into a printed button (flange, shank, cone
// head); the keyholes drop onto the buttons and the cone heads seat in
// countersinks, pulling the frame against the flanges.
//
// Coordinates: x along the wall, y = 0 on the frame's back face (the face
// that rests on the button flanges) and negative towards the sink, z up with
// z = 0 at the front bottom edge of the tray; the frame reaches ledge_h lower.
//
// Print: the frame and the tray lie on their backs (walls, ledges, slats and
// the sloping floor become upright walls), the box stands on its floor. Every
// wall is a multiple of the 0.42 mm line.

/* [Part] */
part = "assembly";   // [assembly, frame, tray, box, button, test_keyhole, test_width]
show_items = true;   // draw the bottle, sponge, cups, wall and counter (assembly only)
section = "none";    // [none, upper, lower] cut the assembly through the upper keyholes (x = 0) or a lower one, for the section renders
explode = 0;         // [0:0.1:1] tray slid out, box and bottle lifted (renders)

/* [Bottle] */
bottle_w = 90;       // widest part of the bottle, along the wall (its base) [50:0.5:120]
bottle_d = 50;       // bottle depth, front to back [30:0.5:90]
bottle_h = 210;      // total height with the cap: checks it fits under the cabinet [100:1:320]
neck_d = 34;         // widest part that goes through the floor hole (cap, neck ring) [20:0.5:50]
seat_to_tip = 35;    // how far the cap tip hangs below the floor, bottle resting [15:1:70]
bottle_play = 1.5;   // clearance around the bottle, per side, at least [0.5:0.5:5]

/* [Sponge] */
sponge_w = 90;       // sponge length, along the wall [40:1:140]
sponge_d = 65;       // sponge width, front to back [30:1:100]
sponge_h = 45;       // sponge height, with the nail guard [10:1:70]
sponge_play = 2;     // clearance around the sponge, per side [0.5:0.5:6]
tip_gap = 15;        // gap between the closed cap tip and the sponge top [5:1:40]

/* [Kitchen] */
sink_dist = 115;     // wall to the inner edge of the sink bowl [40:1:250]
drip_over = 10;      // how far the tray edge reaches past the sink edge [0:1:40]
counter_gap = 15;    // counter to the tray's front bottom edge (preview and checks) [5:1:100]
cabinet_h = 460;     // counter to the wall cabinet: the bottle must go in from the top [250:1:900]

/* [Suction cups] */
cup_d = 50;          // suction cup diameter [30:1:80]
cup_h = 12;          // wall to the cup's hub face, cup pressed on [5:0.5:30]
cup_pitch = 55;      // vertical distance between the upper two cups [50:1:90]
lower_cup_span = 56; // horizontal distance between the lower two cups [50:1:90]
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
ledge_w = 3.36;      // ledges inside the side walls (8 lines) [2.1:0.42:6]
ledge_h = 4;         // ledge height [2:0.5:10]
ledge_stop = 2;      // bump at the front of the tray ledges: lift the tray this much to slide it out [1:0.5:4]
sponge_rim = 12;     // the side walls' deep part rises this much above the slats [0:1:40]
step_r = 10;         // radius of the step between the deep and the shallow part of the side walls [2:1:20]

/* [Tray] */
tray_play = 0.25;    // clearance between the tray and the side walls, per side (0.4 printed ~0.5) [0.1:0.05:1]
tray_slope = 6;      // floor slope towards the sink, degrees [3:0.5:15]
tray_t = 1.26;       // tray floor (3 lines) [0.84:0.42:2.52]
tray_wall = 1.68;    // tray back and side rims (4 lines) [1.26:0.42:2.52]
slat_w = 2.1;        // slat thickness (5 lines) [1.26:0.42:4.2]
slat_h = 5;          // slat height [3:0.5:12]
slat_pitch = 9;      // slat spacing [5:0.5:15]
slat_clear = 3;      // gap between the slats and the tray floor, at the back [2:0.5:10]

/* [Box] */
box_play = 0.25;     // clearance between the box and the side walls, per side (0.4 printed ~0.5) [0.1:0.05:1]
box_h = 90;          // height of the box [60:1:200]
wall_t = 1.68;       // box walls and front returns (4 lines) [1.26:0.42:4.2]
floor_t = 2;         // box floor (10 layers) [1.2:0.2:4]
collar_t = 4;        // round collar round the floor hole (20 layers) [2:0.2:8]
return_w = 10;       // front returns that keep the bottle from tipping forward; they round into the sides [0:1:25]

/* [Style] */
corner_r = 14;       // radius of the front corners of the tray and box, in plan (the back stays straight) [0:1:40]
slot_w = 4;          // width of the rounded vertical slots in the walls [2:0.5:12]
slot_rib = 2.6;      // material between slots [2:0.2:12]
slot_margin = 6;     // solid band above and below the slots [3:1:20]
side_slot_tilt = 45; // side wall slots, degrees from vertical: the frame prints on its back, so at 0 each slot roofs over as one long bridge [0:5:60]

/* [Hidden] */
$fa = 1; $fs = $preview ? 0.8 : 0.4;
eps = 0.01;
chamfer = 0.6;                    // bottom-edge chamfer on the bed
piece_colour = "#1A1A1A";

use <../../tools/scad/basics.scad>
use <../../tools/scad/style.scad>
use <../../tools/scad/mounts.scad>

// Keyhole and button sizes, from tools/scad/mounts.scad
entry_r = keyhole_entry_r(head_d, keyhole_play);
flange_t = keyhole_button_flange_t(pad_t, shank_d, head_d, shank_play, head_cyl, stud_len);
button_h = keyhole_button_h(pad_t, shank_d, head_d, shank_play, head_cyl, stud_len);
pad_hi = keyhole_pad_hi(shank_d, keyhole_play);
head_front = pad_t + shank_play + head_cyl;    // how far the button heads reach in front of y = 0
wall_gap = cup_h + flange_t;                   // wall to the frame's back face

// Heights, from the tray's front bottom edge
reach = sink_dist + drip_over - wall_gap;      // tray front edge, from the back face
tan_s = tan(tray_slope);
tray_tv = tray_t / cos(tray_slope);            // vertical thickness of the tray floor
function tray_bottom(y) = (reach + y) * tan_s; // tray underside at y (y <= 0)
function tray_top(y) = tray_bottom(y) + tray_tv;
z_fb = tray_top(0);
z_s = z_fb + slat_clear + slat_h;              // slat tops (the sponge rests here)
z_seat = z_s + sponge_h + tip_gap + seat_to_tip;   // box floor
lower_top = z_s + sponge_rim;                  // top of the side walls' deep part
top = z_seat + box_h;                          // top of the frame
z0 = -ledge_h;                                 // bottom of the frame, under the tray ledges

// Cups: as on the earlier two-piece caddy
lo_cup_x = lower_cup_span / 2;
lo_cup_z = z_fb + 1 + drop + entry_r;
up_cup_z = [for (i = [0:1]) z_seat + floor_t + drop + entry_r + 4 + i * cup_pitch];
cups = concat([for (s = [-1, 1]) [s * lo_cup_x, lo_cup_z]], [for (z = up_cup_z) [0, z]]);

// Plan: the frame is as wide as the wider of the tray (round the sponge) and
// the box (round the bottle)
tray_need = sponge_w + 2 * sponge_play + 2 * tray_wall + 2 * tray_play;
box_need = bottle_w + 2 * bottle_play + 2 * wall_t + 2 * box_play;
ix = max(tray_need, box_need) / 2;             // frame inner half width
hx = ix + side_t;
frame_w = 2 * hx;
thx = ix - tray_play;                          // tray half width
tix = thx - tray_wall;                         // tray inner half width
reach_f = reach + ledge_stop + 1;              // frame front: the ledge bumps sit in front of the tray
tray_y0 = -(head_front + 0.5);                 // tray back, clear of the button heads
tray_y1 = -reach;                              // tray front
cradle_y = tray_y0 - tray_wall - 2 * sponge_play - sponge_d;   // front of the slats
box_y0 = -(head_front + 0.5);                  // box back, clear of the button heads
bw = 2 * (ix - box_play);                      // box width
inner_w = bw - 2 * wall_t;
inner_d = bottle_d + 2 * bottle_play;
box_d = inner_d + 2 * wall_t;
up_d = -box_y0 + box_d;                        // frame depth at the box
y_bc = box_y0 - wall_t - inner_d / 2;          // bottle axis
hole_d = neck_d + 1;
collar_d = hole_d + 12;

top_above_counter = counter_gap + top;

assert(reach_f > up_d + step_r, "the tray does not reach past the box: raise sink_dist");
assert(cradle_y > tray_y1 + 5, "the tray does not reach past the sponge: raise sink_dist");
assert(lower_top + step_r <= z_seat - ledge_h, "no room for the step between the tray and the box");
assert(up_cup_z[1] + pad_hi <= top, "the upper cups do not fit on the frame: raise box_h or lower cup_pitch");
assert(cup_pitch >= cup_d + 2, "cup_pitch is smaller than the cups");
assert(lower_cup_span >= cup_d + 2, "lower_cup_span is smaller than the cups");
assert(lo_cup_x + pad_w / 2 <= ix, "lower_cup_span is wider than the frame");
assert(lo_cup_z + pad_hi + 3 * slot_w <= z_seat, "the lower keyholes reach the box");
assert(counter_gap >= ledge_h, "the frame reaches the counter");

echo(str("frame: ", frame_w, " x ", reach_f, " x ", top - z0, " mm (w x d x h); tray ", 2 * thx, " x ", tray_y0 - tray_y1,
         " x ", z_s, "; box ", bw, " x ", box_d, " x ", box_h, " (inside ", inner_w, " x ", inner_d, ")"));
echo(str("cups above the counter: lower pair ", counter_gap + lo_cup_z, " (", lower_cup_span,
         " apart), upper pair ", [for (z = up_cup_z) counter_gap + z], " mm (centred)"));
echo(str("tray edge ", reach + wall_gap, " mm from the wall; button ", button_h, " mm long (flange ", flange_t, ")"));
echo(str("top of the frame ", top_above_counter, " mm above the counter; bottle needs ",
         top_above_counter + bottle_h, " of ", cabinet_h, " mm to go in from the top"));
if (top_above_counter + bottle_h > cabinet_h)
    echo("WARNING: the bottle will not drop in from the top under the cabinet");

// ---------------------------------------------------------------- helpers

// The house style (tools/scad/style.scad) with this project's sizes.
module plan(w, d) house_plan(w, d, corner_r);
module shell(w, d, t) house_shell(w, d, t, corner_r);
function slot_xs(lo, hi) = slot_positions(lo, hi, slot_w, slot_rib);
module slot(x, y, za, zb, axis) wall_slot(x, y, za, zb, axis, slot_w);

// Keyholes (tools/scad/mounts.scad), their rest point at (x, 0, z).
module pad_at(z, x) translate([x, 0, z]) keyhole_pad(pad_t, pad_w, drop, shank_d, head_d, keyhole_play);
module keyhole_at(z, x) translate([x, 0, z]) keyhole_cut(pad_t, drop, shank_d, head_d, keyhole_play);

// Prism along x from x0 to x1 of a 2D profile in (y, z).
module yz_prism(x0, x1) rotate([90, 0, 90]) translate([0, 0, x0]) linear_extrude(x1 - x0) children();
// Ledge on the inside of both side walls, profile in (y, z).
module ledges() for (s = [-1, 1]) yz_prism(s > 0 ? ix - ledge_w : -ix - eps, s > 0 ? ix + eps : -ix + ledge_w) children();

// ---------------------------------------------------------------- parts

// Button, in print orientation: flange on the bed, head on top. The cup's
// M4 stud screws into the hole from the flange side.
module button() keyhole_button(pad_t, shank_d, head_d, flange_d, shank_play, head_cyl, stud_len, stud_hole, 3, chamfer);

// The side walls seen from the side: deep at the bottom round the tray, as
// deep as the box above it, a rounded step between them.
module side_profile() {
    translate([-up_d, z0]) square([up_d, top - z0]);
    hull() {
        translate([-reach_f, z0]) square([reach_f, lower_top - step_r - z0]);
        translate([-reach_f + step_r, lower_top - step_r]) circle(r = step_r);
        translate([-up_d, lower_top - 1]) square([up_d, 1]);
    }
    translate([-up_d - step_r, lower_top - eps]) difference() {   // fillet in the step
        square(step_r + eps);
        translate([0, step_r + eps]) circle(r = step_r);
    }
}

module frame() {
    difference() {
        union() {
            box([-hx, 0, z0], [hx, -back_t, top]);
            for (c = cups) pad_at(c[1], c[0]);
            for (s = [-1, 1]) yz_prism(s > 0 ? ix : -hx, s > 0 ? hx : -ix) side_profile();
            // tray ledges, following its underside, with a bump at the front
            ledges() polygon([[-back_t, z0], [-back_t, tray_bottom(-back_t)], [tray_y1 - 0.5, tray_bottom(tray_y1 - 0.5)],
                              [tray_y1 - 0.5, ledge_stop], [-reach_f, ledge_stop], [-reach_f, z0]]);
            // box ledges under its floor
            ledges() polygon([[-back_t, z_seat - ledge_h], [-back_t, z_seat], [-up_d, z_seat], [-up_d, z_seat - ledge_h]]);
        }
        for (c = cups) keyhole_at(c[1], c[0]);
        // back plate: slots between the lower keyholes and the box, and beside the upper keyholes
        for (x = slot_xs(-ix + slot_rib, ix - slot_rib)) {
            slot(x, 0, lo_cup_z + pad_hi + slot_margin, z_seat - slot_margin, "y");
            if (abs(x) >= pad_w / 2 + slot_rib + slot_w / 2) slot(x, 0, z_seat + slot_margin, top - slot_margin, "y");
        }
        // side walls: along the box, and between the sponge and the box ledges
        if (side_slot_tilt > 0)
            for (s = [-1, 1], z = [[z_seat + slot_margin, top - slot_margin], [lower_top, z_seat - ledge_h - slot_margin]])
                wall_slots_tilted(s * (hx - side_t / 2), -(up_d - slot_rib - slot_w / 2), -(back_t + slot_rib), z[0], z[1],
                                  "x", side_slot_tilt, slot_w, slot_rib);
        else
            for (s = [-1, 1], y = slot_xs(back_t + slot_rib, up_d - slot_rib - slot_w / 2)) {
                slot(s * (hx - side_t / 2), -y, z_seat + slot_margin, top - slot_margin, "x");
                slot(s * (hx - side_t / 2), -y, lower_top, z_seat - ledge_h - slot_margin, "x");
            }
    }
}

// Tray: floor sloping to the front edge, side rims rounding into the front
// corners (the front stays open for the water and the sponge), slats.
module tray() {
    d = tray_y0 - tray_y1;
    slat_xs = [for (k = [-20:20]) let(x = k * slat_pitch) if (abs(x) + slat_w / 2 <= tix - 1) x];
    union() {
        intersection() {
            yz_prism(-thx, thx) polygon([[tray_y0, tray_bottom(tray_y0)], [tray_y0, tray_top(tray_y0)],
                                         [tray_y1, tray_top(tray_y1)], [tray_y1, tray_bottom(tray_y1)]]);
            translate([0, tray_y0, 0]) linear_extrude(z_s + 1) plan(2 * thx, d);
        }
        box([-thx, tray_y0, tray_bottom(tray_y0)], [thx, tray_y0 - tray_wall, z_s]);
        intersection() {
            translate([0, tray_y0, 0]) linear_extrude(z_s) difference() { plan(2 * thx, d); offset(r = -tray_wall) plan(2 * thx, d); }
            yz_prism(-thx - 1, thx + 1) polygon([[tray_y0, tray_bottom(tray_y0)], [tray_y0, z_s], [cradle_y, z_s],
                                                 [tray_y1, tray_top(tray_y1) + 3], [tray_y1, tray_bottom(tray_y1)]]);
            union() {
                box([-thx - 1, tray_y0 + 1, 0], [-tix + corner_r, tray_y1 - 1, z_s]);
                box([tix - corner_r, tray_y0 + 1, 0], [thx + 1, tray_y1 - 1, z_s]);
            }
        }
        // slats from the back rim to a tie at the front of the sponge, a tie under their middle
        for (x = slat_xs) box([x - slat_w / 2, tray_y0 - tray_wall + eps, z_s - slat_h], [x + slat_w / 2, cradle_y, z_s]);
        box([-tix - eps, cradle_y, z_s - slat_h], [tix + eps, cradle_y + slat_w, z_s]);
        box([-tix - eps, (tray_y0 + cradle_y) / 2 - slat_w / 2, z_s - slat_h], [tix + eps, (tray_y0 + cradle_y) / 2 + slat_w / 2, z_s - slat_h + 2.5]);
    }
}

// Box: its floor at z = 0, back at y = box_y0. Its side walls stand inside
// the frame's, so only the back is slotted.
module bottle_box() {
    yc = y_bc - box_y0;
    translate([0, box_y0, 0]) difference() {
        union() {
            hull() {
                linear_extrude(eps) offset(r = -chamfer) plan(bw, box_d);
                translate([0, 0, chamfer]) linear_extrude(floor_t - chamfer) plan(bw, box_d);
            }
            translate([0, yc, 0]) cylinder(d = collar_d, h = collar_t);
            linear_extrude(box_h) shell(bw, box_d, wall_t);
        }
        // open front between the returns, rounded at the top corners of the opening
        translate([0, -box_d - 1, 0]) rotate([-90, 0, 0])
            linear_extrude(wall_t + 2) offset(r = slot_w) offset(delta = -slot_w)
                translate([-(inner_w / 2 - return_w), -box_h - slot_w]) square([inner_w - 2 * return_w, box_h + slot_w - floor_t]);
        // hole for the neck, with a 45° seat for the shoulder
        translate([0, yc, -eps]) {
            cylinder(d = hole_d, h = collar_t + 2 * eps);
            translate([0, 0, collar_t - 2.5 + eps]) cylinder(d1 = hole_d, d2 = hole_d + 5 + 2 * eps, h = 2.5 + eps);
        }
        // floor windows round the collar: drips fall through, less plastic
        translate([0, 0, -1]) linear_extrude(floor_t + 2) offset(r = 3) offset(delta = -3) difference() {
            offset(r = -(wall_t + 4)) plan(bw, box_d);
            translate([-4, -box_d]) square([8, box_d]);
            translate([-bw / 2, yc - 4]) square([bw, 8]);
            translate([0, yc]) circle(d = collar_d + 8);
        }
        for (x = slot_xs(-inner_w / 2 + slot_rib, inner_w / 2 - slot_rib)) slot(x, 0, floor_t + slot_margin, box_h - slot_margin, "y");
    }
}

// Fit test: a keyhole pad, printed flat, for a button.
module test_keyhole() difference() {
    translate([0, pad_t, 0]) pad_at(0, 0);
    translate([0, pad_t, 0]) keyhole_at(0, 0);
}

// Fit test: a strip of the frame (back and side walls, 20 mm of them) and a
// bar as wide as the tray and the box, both printed flat, the way the frame,
// the tray and the box print their widths. The bar must slide between the
// side walls with a little play.
module test_width() {
    linear_extrude(4) difference() {
        translate([-hx, -20]) square([frame_w, 20 + back_t]);
        translate([-ix, -20 - 1]) square([2 * ix, 21]);
    }
    translate([0, -32, 0]) chamfered_prism(4) square([bw, 8], center = true);
}

// ---------------------------------------------------------------- assembly

// Keep x <= the section plane of the children when a section is on.
section_x = section == "lower" ? -lo_cup_x : 0;
module cut() {
    if (section != "none") intersection() { union() children(); translate([section_x - 1000, -1000, -1000]) cube([1000, 2000, 2000]); }
    else children();
}
// In a section the buttons are orange, to tell them from the frame.
mate_colour = section != "none" ? "#FF6A13" : piece_colour;
lift = explode * (box_h + 20);                 // box and bottle, lifted
pull = explode * 70;                           // tray and sponge, slid out

module items() {
    // bottle, upside down
    color("#3C9A3C", 0.55) cut() translate([0, y_bc, z_seat + lift]) {
        translate([0, 0, -seat_to_tip]) cylinder(d = neck_d - 6, h = seat_to_tip + 3);
        translate([0, 0, collar_t]) linear_extrude(bottle_h - seat_to_tip - collar_t)
            offset(r = 10) square([bottle_w - 20, bottle_d - 20], center = true);
    }
    // sponge: yellow foam on a green scourer
    translate([0, tray_y0 - tray_wall - sponge_play - sponge_d / 2 - pull, z_s]) {
        color("#2E6B30") cut() translate([-sponge_w / 2, -sponge_d / 2, 0]) cube([sponge_w, sponge_d, 8]);
        color("#F2D43A") cut() translate([-sponge_w / 2, -sponge_d / 2, 8]) cube([sponge_w, sponge_d, sponge_h - 8]);
    }
    // cups and buttons
    for (c = cups) {
        color("#DDEEFF", 0.45) cut() translate([c[0], wall_gap, c[1]]) rotate([90, 0, 0]) cylinder(d1 = cup_d, d2 = 14, h = cup_h);
        color(mate_colour) cut() translate([c[0], flange_t, c[1]]) rotate([90, 0, 0]) button();
    }
    // wall and counter, just round the caddy
    color("#EEEEEE") cut() translate([-100, wall_gap, -counter_gap - 20]) cube([200, 10, top + counter_gap + 60]);
    color("#C8B89A") cut() translate([-100, -sink_dist + wall_gap, -counter_gap - 20]) cube([200, sink_dist, 20]);
}

if (part == "frame") frame();
else if (part == "tray") tray();
else if (part == "box") bottle_box();
else if (part == "button") button();
else if (part == "test_keyhole") test_keyhole();
else if (part == "test_width") test_width();
else {
    color(piece_colour) cut() frame();
    color(piece_colour) cut() translate([0, -pull, 0]) tray();
    color(piece_colour) cut() translate([0, 0, z_seat + lift]) bottle_box();
    if (show_items) items();
}
