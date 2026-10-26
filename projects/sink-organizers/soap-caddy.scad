// Soap caddy: a wall-mounted holder for an upside-down dish soap bottle and
// the scourer sponge, next to the sink. One of the sink organizers: the wall
// plate, the body on its dovetails, the floor, ledges, tray and style come
// from common.scad.
//
//   - plate: the wall plate, on four suction cups: two side by side low down
//     and two one above the other behind the box (where the earlier caddy had
//     them, so the cups stay put). It takes the turning moment of the bottle
//     and of a hand pressing the sponge: the top cups pull, the bottom ones
//     press.
//   - body: two side walls, deep at the bottom round the tray and as deep as
//     the box above it with a rounded step between them, the floor under the
//     tray, ledges for the tray and the box, and at the front of the box two
//     returns and a bar across the top, which keep the box in and tie the
//     side walls. It slides down onto the plate's dovetails.
//   - tray: a slatted cradle for the sponge over a floor that slopes forward
//     and spills into the sink. Lift its front over the bumps at the ends of
//     the ledges and it slides out.
//   - box: an open-front box that holds the bottle upside down, its cap
//     through a hole in the floor, right over the sponge. It drops in from
//     the top onto its ledges and lifts out; the bottle drops into it from
//     the top, and the open front is where you squeeze it.
//
// Coordinates and print orientation: see common.scad. The box stands on its
// floor.

/* [Part] */
part = "assembly";   // [assembly, plate, body, tray, box, button, test_keyhole, test_buttons, test_dovetail_housing, test_dovetail_tail, test_width, test_sway]
show_items = true;   // draw the bottle, sponge, cups, wall and counter (assembly only)
section = "none";    // [none, upper, lower] cut the assembly through the upper keyholes (x = 0) or a lower one, for the section renders
explode = 0;         // [0:0.1:1] tray slid out, box and bottle lifted (renders)
body_lift = 0;       // [0:1:300] body slid up off the plate (renders)

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
counter_gap = 12;    // counter to the bottom of the body (preview and checks) [3:1:100]
cabinet_h = 460;     // counter to the wall cabinet: the bottle must go in from the top [250:1:900]

/* [Cups] */
cup_pitch = 55;      // vertical distance between the upper two cups [50:1:90]
lower_cup_span = 56; // horizontal distance between the lower two cups [50:1:90]

/* [Body] */
sponge_rim = 12;     // the side walls' deep part rises this much above the slats [0:1:40]
step_r = 10;         // radius of the step between the deep and the shallow part of the side walls [2:1:20]
bar_h = 6;           // bar across the top of the front, over the box [4:1:20]
side_add = 0;        // extra thickness on the side walls' outer faces, in front of the dovetails: the body prints standing, and its thin walls sway under the nozzle higher up [0:0.42:3.36]
side_add_z = 0;      // where the extra thickness starts, 45° below it [0:1:200]
frame_t = 1.68;      // the front returns and the bar across the top (4 lines) [1.26:0.42:4.2]
fin_w = 20;          // fins beside the side walls, printed with the body and lifted off after (0: none): without them its 1.68 mm walls swayed under the nozzle above ~165 mm [0:1:40]
fin_t = 1.26;        // fin thickness (3 lines) [0.84:0.42:2.52]
fin_flange = 0;      // flange across each fin's outer edge, for fins with no tabs [0:1:30]
fin_gap = 0.3;       // gap between the fins and the side walls, bridged by the tabs [0.1:0.05:0.6]
fin_sides = [-1, 1]; // which side walls get fins
tab_w = 0.42;        // tabs tying the fins to the walls: width along the wall (1 line), so they snap off flush [0.42:0.42:1.68]
tab_h = 0.4;         // tab height (2 layers; 0: no tabs, and the walls only rest on the fins: that holds them one way only) [0:0.2:4]
tab_pitch = 20;      // tab spacing, up the fins [4:1:40]
test_sway_h = 120;   // test_sway: height of its two strips: bare, the top bends 17 mm/N at ~78 mm, 24 at ~88 and 33 at ~98 (the body from 150 to 190 mm) and 60 at 120 [40:5:200]
test_sway_len = 40;  // test_sway: their length [20:5:80]
test_sway_fin = 12;  // test_sway: how far its fins stand out [6:1:20]
back_wall = 0;       // a slotted wall across the back, in front of the plate's housings and button heads (0: none); the tray and the box move forward by it [0:0.42:2.52]

/* [Tray] */
slat_pitch = 9;      // slat spacing [5:0.5:15]

/* [Box] */
box_play = 0.25;     // clearance between the box and the side walls, per side (0.4 printed ~0.5) [0.1:0.05:1]
box_h = 90;          // height of the box [60:1:200]
wall_t = 1.68;       // box walls and front returns (4 lines) [1.26:0.42:4.2]
floor_t = 2;         // box floor (10 layers) [1.2:0.2:4]
collar_t = 4;        // round collar round the floor hole (20 layers) [2:0.2:8]
return_w = 10;       // front returns that keep the bottle from tipping forward; they round into the sides [0:1:25]

include <common.scad>
use <../../tools/scad/print_aids.scad>

// The wall plate's slot fields as windows, the upper ones with 20 mm solid
// bands above and below: 7.4 % less plate, 29 % less bending and a third of
// the stress, in daily use and under the bottle alone (fea/README.md).
// After the include, so they win over common.scad's defaults; -D still wins.
plate_window = [0, 1];
plate_window_inset = [0, 20];

// Heights, from the bottom of the body
reach = sink_dist + drip_over - wall_gap;      // tray front edge, from the plate's back face
tray_y1 = -reach;
tray_y0 = -(back_wall > 0 ? body_in + back_wall + 0.5 : back_clear + 0.5);   // tray back, clear of the button heads and housings, or of the back wall
z_fb = tray_top(tray_y0);
z_s = z_fb + slat_clear + slat_h;              // slat tops (the sponge rests here)
z_seat = z_s + sponge_h + tip_gap + seat_to_tip;   // box floor
lower_top = z_s + sponge_rim;                  // top of the side walls' deep part
top = z_seat + box_h;                          // top of the body and the plate

// Cups: as on the earlier caddy
lo_cup_x = lower_cup_span / 2;
lo_cup_z = z_fb + 1 + drop + entry_r;
up_cup_z = [for (i = [0:1]) z_seat + floor_t + drop + entry_r + 4 + i * cup_pitch];
cups = concat([for (s = [-1, 1]) [s * lo_cup_x, lo_cup_z]], [for (z = up_cup_z) [0, z]]);

// Plan: the body is as wide as the wider of the tray (round the sponge) and
// the box (round the bottle)
tray_need = sponge_w + 2 * sponge_play + 2 * tray_wall + 2 * tray_play;
box_need = bottle_w + 2 * bottle_play + 2 * wall_t + 2 * box_play;
ix = max(tray_need, box_need) / 2;             // body inner half width
hx = ix + side_t;
body_w = 2 * hx;
thx = ix - tray_play;                          // tray half width
reach_f = reach + ledge_stop + 1;              // body front at the tray: the ledge bumps sit in front of it
cradle_y = tray_y0 - tray_wall - 2 * sponge_play - sponge_d;   // front of the slats
box_y0 = tray_y0;                              // box back
bw = 2 * (ix - box_play);                      // box width
inner_w = bw - 2 * wall_t;
inner_d = bottle_d + 2 * bottle_play;
box_d = inner_d + 2 * wall_t;
up_d = -box_y0 + box_d;                        // the box's front, from y = 0
ud = up_d + frame_t;                           // body depth at the box: the front stands in front of the box
y_bc = box_y0 - wall_t - inner_d / 2;          // bottle axis
hole_d = neck_d + 1;
collar_d = hole_d + 12;
ret = box_play + wall_t + return_w;            // the body's front returns, in line with the box's
open_hw = ix - ret;                            // half width of the opening between them
chf = open_hw - 5;                             // 45° top corners of the opening: a 10 mm bridge, printed standing

top_above_counter = counter_gap + top;

assert(reach_f > ud + step_r, "the tray does not reach past the box: raise sink_dist");
assert(cradle_y > tray_y1 + 5, "the tray does not reach past the sponge: raise sink_dist");
assert(floor_y1() < cradle_y, "the floor under the tray is too short: lower drip_clear");
assert(lower_top + step_r <= z_seat - ledge_h - ledge_w, "no room for the step between the tray and the box");
assert(up_cup_z[1] + pad_hi <= top, "the upper cups do not fit on the plate: raise box_h or lower cup_pitch");
assert(cup_pitch >= cup_d + 2, "cup_pitch is smaller than the cups");
assert(lower_cup_span >= cup_d + 2, "lower_cup_span is smaller than the cups");
assert(lo_cup_x + pad_w / 2 <= hx - side_t / 2 - house_hw, "lower_cup_span is wider than the plate between its housings");
assert(lo_cup_z + pad_hi + 3 * slot_w <= z_seat, "the lower keyholes reach the box");
assert(chf > 0, "no room for the front opening: lower return_w");
assert(counter_gap >= dt_cap, "the plate reaches the counter");

echo(str("body: ", body_w + 2 * side_add, " x ", reach_f, " x ", top, " mm (w x d x h); plate ", 2 * plate_hx(), " x ", top + dt_cap,
         "; tray ", 2 * thx, " x ", tray_y0 - tray_y1, " x ", z_s, "; box ", bw, " x ", box_d, " x ", box_h, " (inside ", inner_w, " x ", inner_d, ")"));
echo(str("cups above the counter: lower pair ", counter_gap + lo_cup_z, " (", lower_cup_span,
         " apart), upper pair ", [for (z = up_cup_z) counter_gap + z], " mm (centred)"));
echo(str("tray edge ", reach + wall_gap, " mm from the wall; button ", button_h, " mm long (flange ", flange_t, ")"));
echo(str("top ", top_above_counter, " mm above the counter; bottle needs ",
         top_above_counter + bottle_h, " of ", cabinet_h, " mm to go in from the top"));
if (top_above_counter + bottle_h > cabinet_h)
    echo("WARNING: the bottle will not drop in from the top under the cabinet");

// ---------------------------------------------------------------- parts

module plate() wall_plate(top, cups, [[lo_cup_z + pad_hi + slot_margin, z_seat - slot_margin], [z_seat + slot_margin, top - slot_margin]]);

// The side walls seen from the side: deep at the bottom round the tray, as
// deep as the box (and its front) above it, a rounded step between them.
module side_profile() {
    translate([-ud, 0]) square([ud - body_back, top]);
    hull() {
        translate([-reach_f, 0]) square([reach_f - body_back, lower_top - step_r]);
        translate([-reach_f + step_r, lower_top - step_r]) circle(r = step_r);
        translate([-ud, lower_top - 1]) square([ud - body_back, 1]);
    }
    translate([-ud - step_r, lower_top - eps]) difference() {   // fillet in the step
        square(step_r + eps);
        translate([0, step_r + eps]) circle(r = step_r);
    }
}

// The body; as printed (fins = true), with its stabilizer fins.
module body(fins = false) {
    body_core();
    if (fins && fin_w > 0) stabilizer_fins();
}

// Printing aids: two fins beside each side wall, standing on the bed in the
// XZ plane: the body has no wall across it, so each side wall bends on its
// own under the nozzle (fea/README.md, "The body while it prints"). Tabs
// one line wide every tab_pitch tie the walls to the fins both ways; a fin
// that only touched its wall would stop it leaning out but not in. The tabs
// sit where the walls are solid: just in front of the plate's housings, and
// in front of the slots by the box's front. Snap the fins off after
// printing.
module stabilizer_fins() for (s = [-1, 1], y = [-(body_in + 0.52), -(ud - 1 - fin_t / 2)])
    if (len([for (f = fin_sides) if (f == s) f]) > 0)
        translate([s * (hx + side_add), y, 0]) mirror([s < 0 ? 1 : 0, 0, 0])
            stabilizer_fin(top, fin_w, fin_t, fin_gap, fin_flange, tab_w, tab_h, tab_pitch);

module body_core() difference() {
    union() {
        for (s = [-1, 1]) yz_prism(s > 0 ? ix : -hx, s > 0 ? hx : -ix) side_profile();
        body_tails(top);
        tray_ledges(-reach_f);
        body_floor();
        // box ledges under its floor, 45° underneath: the body prints standing
        for (s = [-1, 1]) hull() {
            box([s * (ix + eps), -body_in, z_seat - ledge_h], [s * (ix - ledge_w), -up_d, z_seat]);
            box([s * (ix + eps), -body_in, z_seat - ledge_h - ledge_w], [s * (ix - eps), -up_d, z_seat]);
        }
        // in front of the box: the returns and the bar across the top, the
        // opening's top corners at 45°
        translate([0, -up_d, 0]) rotate([90, 0, 0]) linear_extrude(frame_t + eps) difference() {
            translate([-ix - eps, z_seat - ledge_h - ledge_w]) square([2 * (ix + eps), top - z_seat + ledge_h + ledge_w]);
            polygon([[-open_hw, z_seat - ledge_h - ledge_w - 1], [open_hw, z_seat - ledge_h - ledge_w - 1], [open_hw, top - bar_h - chf],
                     [open_hw - chf, top - bar_h], [-open_hw + chf, top - bar_h], [-open_hw, top - bar_h - chf]]);
            // the returns' bottom edges rise at 45° from the side walls: level,
            // they would stick out of the walls with nothing under them
            for (s = [-1, 1]) let(zb = z_seat - ledge_h - ledge_w)
                polygon([[s * ix, zb - 1], [s * ix, zb], [s * open_hw, zb + ix - open_hw], [s * open_hw, zb - 1]]);
        }
        if (side_add > 0) for (s = [-1, 1]) side_slab(s);
        if (back_wall > 0) box([-ix - eps, -body_in, 0], [ix + eps, -(body_in + back_wall), top]);
    }
    // side walls: 45° slots along the box, and between the sponge and the box ledges
    for (s = [-1, 1], z = [[z_seat + slot_margin, top - slot_margin], [lower_top, z_seat - ledge_h - ledge_w - slot_margin]])
        slots_tilted(s * (hx - side_t / 2 + side_add / 2), -(up_d - slot_rib - slot_w / 2), -(body_back + slot_rib), z[0], z[1], "x", side_t + side_add);
    // the back wall: the same 45° slots, between the ledges
    if (back_wall > 0) for (z = [[z_seat + slot_margin, top - slot_margin], [lower_top, z_seat - ledge_h - ledge_w - slot_margin]])
        wall_slots_tilted(-(body_in + back_wall / 2), -ix + ledge_w + slot_rib, ix - ledge_w - slot_rib, z[0], z[1], "y",
                          side_slot_tilt, slot_w, slot_rib, back_wall + 2, max_len = slot_max_len);
}

// The extra thickness on a side wall's outer face (s = -1 left, 1 right),
// from side_add_z up and clear of the plate's housings, its bottom edge at
// 45° so it prints standing.
module side_slab(s) intersection() {
    yz_prism(s > 0 ? hx - eps : -hx - side_add, s > 0 ? hx + side_add : -hx + eps) intersection() {
        side_profile();
        translate([-1000, side_add_z]) square([1000 - body_in, 1000]);
    }
    rotate([90, 0, 0]) translate([0, 0, -1000]) linear_extrude(2000)
        polygon([[s * (hx - eps), side_add_z], [s * (hx + side_add), side_add_z + side_add], [s * (hx + side_add), 1000], [s * (hx - eps), 1000]]);
}

module soap_tray() tray(thx, tray_y0, z_s, slat_pitch, cradle_y + slat_w);

// Box: its floor at z = 0, back at y = box_y0. Its side walls stand inside
// the body's, so only the back is slotted, in rows no taller than
// slot_max_len: it prints standing, and the ribs between 76 mm slots swayed
// under the nozzle and came out rough above ~35 mm.
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

// Fit test: the top 12 mm of the body (its side walls and the bar across
// the front), standing as the body prints, and the bottom 12 mm of the box,
// standing as the box prints. The box must drop through the slice with a
// little play, and its front must stop against the returns. The slice keeps
// the body's fins and one row of their tabs.
module test_width() {
    translate([0, 0, -(top - 12)]) intersection() { body(fins = true); translate([-500, -ud - 1, top - 12]) cube([1000, ud - body_back + 1, 13]); }
    translate([0, -ud - 15, 0]) intersection() { bottle_box(); translate([-500, -500, 0]) cube([1000, 1000, 12]); }
}

// Sway test: two strips of the body's side wall, slotted the same way, on a
// thin foot. Bare, a strip bends on its own at the top about as much as the
// body did where it printed rough (fea/README.md, "The body while it
// prints"), so the first should come out rough in its upper part. The
// second has a fin on each face at its free end, tied by the body's tabs: it
// should print clean, and the fins should snap off flush.
module test_sway() for (k = [0 : 1]) translate([k * (2 * (fin_gap + test_sway_fin) + 12), 0, 0]) {
    l = test_sway_len; h = test_sway_h;
    difference() {
        box([-side_t / 2, 0, 0], [side_t / 2, l, h]);
        slots_tilted(0, slot_rib, l - slot_rib, slot_margin, h - slot_margin, "x", side_t);
    }
    box([-6, 6, 0], [6, l, 0.6]);                                   // the foot: 3 layers, clear of the fins
    if (k > 0) for (s = [-1, 1]) translate([s * side_t / 2, 2, 0]) mirror([s < 0 ? 1 : 0, 0, 0])
        stabilizer_fin(h, test_sway_fin, fin_t, fin_gap, fin_flange, tab_w, tab_h, tab_pitch);
}

// ---------------------------------------------------------------- assembly

// Keep x <= the section plane of the children when a section is on.
section_x = section == "lower" ? -lo_cup_x : 0;
module cut() {
    if (section != "none") intersection() { union() children(); translate([section_x - 1000, -1000, -1000]) cube([1000, 2000, 2000]); }
    else children();
}
// In a section the buttons are orange, to tell them from the pieces.
mate_colour = section != "none" ? "#FF6A13" : piece_colour;
lift = explode * (box_h + 20);                 // box and bottle, lifted
pull = explode * 70;                           // tray and sponge, slid out

module items() {
    // bottle, upside down
    color("#3C9A3C", 0.55) cut() translate([0, y_bc, z_seat + lift + body_lift]) {
        translate([0, 0, -seat_to_tip]) cylinder(d = neck_d - 6, h = seat_to_tip + 3);
        translate([0, 0, collar_t]) linear_extrude(bottle_h - seat_to_tip - collar_t)
            offset(r = 10) square([bottle_w - 20, bottle_d - 20], center = true);
    }
    // sponge: yellow foam on a green scourer
    translate([0, tray_y0 - tray_wall - sponge_play - sponge_d / 2 - pull, z_s + body_lift]) {
        color("#2E6B30") cut() translate([-sponge_w / 2, -sponge_d / 2, 0]) cube([sponge_w, sponge_d, 8]);
        color("#F2D43A") cut() translate([-sponge_w / 2, -sponge_d / 2, 8]) cube([sponge_w, sponge_d, sponge_h - 8]);
    }
    cut() cups_and_buttons(cups, mate_colour);
    // wall and counter, just round the caddy
    color("#EEEEEE") cut() translate([-100, wall_gap, -counter_gap - 20]) cube([200, 10, top + counter_gap + 60]);
    color("#C8B89A") cut() translate([-100, -sink_dist + wall_gap, -counter_gap - 20]) cube([200, sink_dist, 20]);
}

if (part == "plate") plate();
else if (part == "body") body(fins = true);
else if (part == "tray") soap_tray();
else if (part == "box") bottle_box();
else if (part == "button") button();
else if (part == "test_keyhole") test_keyhole();
else if (part == "test_buttons") test_buttons();
else if (part == "test_dovetail_housing") test_dovetail_housing();
else if (part == "test_dovetail_tail") test_dovetail_tail();
else if (part == "test_width") test_width();
else if (part == "test_sway") test_sway();
else if (part == "assembly") {
    color(piece_colour) cut() plate();
    color(piece_colour) cut() translate([0, 0, body_lift]) body();
    color(piece_colour) cut() translate([0, -pull, body_lift]) soap_tray();
    color(piece_colour) cut() translate([0, 0, z_seat + lift + body_lift]) bottle_box();
    if (show_items) items();
}
