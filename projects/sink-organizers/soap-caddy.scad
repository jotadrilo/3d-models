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
//     the box above it with a rounded step between them, a slotted back
//     wall, the floor under the tray, ledges for the tray and the box, and a
//     closed front round the box with a window for the thumb. Printed in two
//     parts cut under the box's ledges (lower: the tray's part; upper: a
//     closed tube round the box), joined by a split collar; both slide down
//     onto the plate's dovetails.
//   - tray: a slatted cradle for the sponge over a floor that slopes forward
//     and spills into the sink. Lift its front over the bumps at the ends of
//     the ledges and it slides out.
//   - box: an open-front box that holds the bottle upside down, its cap
//     through a hole in the floor, right over the sponge. It drops in from
//     the top onto its ledges and lifts out; the bottle drops into it from
//     the top, and you squeeze it through the body's thumb window.
//
// Coordinates and print orientation: see common.scad. The box stands on its
// floor.

/* [Part] */
part = "assembly";   // [assembly, plate, body, body_lower, body_upper, tray, box, button, adapter, jig, test_keyhole, test_buttons, test_dovetail_housing, test_dovetail_tail, test_dovetail_tail_play, test_width, test_sway, test_split_lower, test_split_upper]
show_items = true;   // draw the bottle, sponge, cups, wall and counter (assembly only)
section = "none";    // [none, upper, lower] cut the assembly through the upper keyholes (x = 0) or a lower one, for the section renders
explode = 0;         // [0:0.1:1] tray slid out, box and bottle lifted (renders)
body_lift = 0;       // [0:1:300] body slid up off the plate (renders)
upper_lift = 0;      // [0:1:300] the body's upper part lifted off the lower one (renders)

/* [Bottle] */
bottle_w = 85;       // widest part of the bottle, along the wall (its base) [50:0.5:120]
bottle_d = 60;       // bottle depth, front to back [30:0.5:90]
bottle_h = 210;      // total height with the cap: checks it fits under the cabinet [100:1:320]
neck_d = 55;         // widest part that goes through the floor hole (cap, neck ring) [20:0.5:70]
neck_play = 1;       // clearance round the neck in the floor hole, per side: 0.5 jammed the Fairy cap in PETG Matte (the hole prints small) [0.25:0.25:3]
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
side_add = 0;        // extra thickness on the side walls' outer faces, in front of the dovetails: the body prints standing, and its thin walls sway under the nozzle higher up [0:0.42:3.36]
side_add_z = 0;      // where the extra thickness starts, 45° below it [0:1:200]
frame_t = 1.68;      // the closed front above the cut (4 lines) [1.26:0.42:4.2]
fin_w = 0;           // fins beside the side walls, printed with the body and lifted off after (0: none): without them its 1.68 mm walls swayed under the nozzle above ~165 mm [0:1:40] Off since the back wall (back_wall) closes the U: in PETG Matte they tore off the bed
fin_t = 1.26;        // fin thickness (3 lines) [0.84:0.42:2.52]
fin_flange = 0;      // flange across each fin's outer edge, for fins with no tabs [0:1:30]
fin_foot = 10;       // width of the rounded foot under each body fin, 3 layers tall (0: none): bare, the fins' 20 mm² on the bed tore off in PETG Matte [0:1:14]
fin_gap = 0.3;       // gap between the fins and the side walls, bridged by the tabs [0.1:0.05:0.6]
fin_sides = [-1, 1]; // which side walls get fins
tab_w = 0.42;        // tabs tying the fins to the walls: width along the wall (1 line), so they snap off flush [0.42:0.42:1.68]
tab_h = 0.4;         // tab height (2 layers; 0: no tabs, and the walls only rest on the fins: that holds them one way only) [0:0.2:4]
tab_pitch = 20;      // tab spacing, up the fins [4:1:40]
test_sway_h = 120;   // test_sway: height of its two strips: bare, the top bends 17 mm/N at ~78 mm, 24 at ~88 and 33 at ~98 (the body from 150 to 190 mm) and 60 at 120 [40:5:200]
test_sway_len = 40;  // test_sway: their length [20:5:80]
test_sway_fin = 12;  // test_sway: how far its fins stand out [6:1:20]
split_play = 0.1;    // the body is printed in two parts, cut under the box's ledges: play between the lower part's collar and the upper part's walls, per side (test_split) [0:0.025:0.3]
split_collar_h = 4;  // how far the lower part's collar rises into the upper part [2:0.2:8]
split_reveal_c = 0.6; // the V reveal round the outside of the cut, each side [0:0.2:1.2]
thumb_d = 55;        // the window in the closed front where the thumb squeezes the bottle (0: none); its top rises to a 45° point [0:1:80]
thumb_z = 40;        // the window's centre, above the box floor [20:1:80]
back_wall = 1.68;    // a slotted wall across the back, in front of the plate's housings and button heads (0: none): it closes the U into a tube, so the side walls do not sway as it prints (fea/README.md); the tray and the box move forward by it [0:0.42:2.52]

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

// Adhesive adapters (mount="tape"): a square of tape at the top keyhole, which the bottle and a hand on the sponge pull off the wall; rounds at the others (README, "Adhesive mount").
tape_squares = 1;
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
hole_d = neck_d + 2 * neck_play;
collar_d = hole_d + 12;
ret = box_play + wall_t + return_w;            // the body's front returns, in line with the box's
open_hw = ix - ret;                            // half width of the box's front opening, between the returns

// The cut between the body's two parts: under the box's ledges, so the collar
// clears them, on a layer; the lower side wall slots stop under the collar's corbel
z_ledge = z_seat - ledge_h - ledge_w;          // the box ledges' (and the front's) lowest point
z_cut = floor((z_ledge - split_collar_h - 0.4) / 0.2) * 0.2;
collar_b = side_t;
lower_slot_top = min(z_ledge - slot_margin, z_cut - collar_b - 3);
z_thumb = z_seat + thumb_z;

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
assert(thumb_d == 0 || z_thumb + thumb_d / 2 * sqrt(2) <= top - 4, "the thumb window reaches the top: lower thumb_z or thumb_d");
assert(thumb_d < 2 * ix - 8, "the thumb window is wider than the front");
assert(counter_gap >= dt_cap, "the plate reaches the counter");

echo(str("body: ", body_w + 2 * side_add, " x ", reach_f, " x ", top, " mm (w x d x h); plate ", 2 * plate_hx(), " x ", top + dt_cap,
         "; tray ", 2 * thx, " x ", tray_y0 - tray_y1, " x ", z_s, "; box ", bw, " x ", box_d, " x ", box_h, " (inside ", inner_w, " x ", inner_d, ")"));
echo(str("body cut at ", z_cut, " mm: lower part ", z_cut + split_collar_h, " tall with its collar, upper part ", top - z_cut));
echo(str("cups above the counter: lower pair ", counter_gap + lo_cup_z, " (", lower_cup_span,
         " apart), upper pair ", [for (z = up_cup_z) counter_gap + z], " mm (centred)"));
echo(str("tray edge ", reach + wall_gap, " mm from the wall; button ", button_h, " mm long (flange ", flange_t, ")"));
echo(str("top ", top_above_counter, " mm above the counter; bottle needs ",
         top_above_counter + bottle_h, " of ", cabinet_h, " mm to go in from the top"));
if (top_above_counter + bottle_h > cabinet_h)
    echo("WARNING: the bottle will not drop in from the top under the cabinet");

// ---------------------------------------------------------------- parts

module plate() wall_plate(top, cups, [[lo_cup_z + pad_hi + slot_margin, z_seat - slot_margin], [z_seat + slot_margin, top - slot_margin]]);

// Installation jig: a bar across through the lower cups, one up through the
// upper ones, in a frame round the plate and the body.
module jig() let(w = max(plate_hx(), hx))
    install_jig(cups, [[[-w, lo_cup_z], [w, lo_cup_z]], [[0, lo_cup_z], [0, top]]], w, -dt_cap, top);

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

// The body, whole (its two parts together); with fins = true, with its
// stabilizer fins.
module body(fins = false) {
    body_lower();
    body_upper();
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
            stabilizer_fin(top, fin_w, fin_t, fin_gap, fin_flange, tab_w, tab_h, tab_pitch, foot_w = fin_foot);

// The body's two parts, printed standing, cut at z_cut (CLAUDE.md §4.7,
// "Split collar"): the lower part carries a collar inside its side and back
// walls that rises into the upper one, and the V reveal turns the cut into a
// shadow line. Both slide into the plate's housings, the lower first; the
// tails and the collar hold the upper part, its weight seats it.
module body_lower(play = split_play) difference() {
    union() {
        intersection() { body_core(); box([-500, -500, -1], [500, 500, z_cut]); }
        // the collar along the walls, stopping behind the upper part's front
        translate([0, 0, z_cut]) intersection() {
            split_collar(collar_b, split_collar_h, play, 0.6) cut_hollow();
            box([-500, -up_d + play, -50], [500, 0, 50]);
        }
    }
    translate([0, 0, z_cut]) split_reveal(split_reveal_c) cut_outline();
}
module body_upper() difference() {
    intersection() { body_core(); box([-500, -500, z_cut], [500, 500, top + 1]); }
    translate([0, 0, z_cut]) split_reveal(split_reveal_c) cut_outline();
}
// At the cut, in plan: the hollow inside the side and back walls (open at
// the front, so it runs on past it) and the body's outline.
module cut_hollow() translate([-ix, -ud - 20]) square([2 * ix, ud + 20 - body_in - back_wall]);
module cut_outline() translate([-hx - side_add, -ud]) square([2 * (hx + side_add), ud]);

module body_core() difference() {
    union() {
        for (s = [-1, 1]) yz_prism(s > 0 ? ix : -hx, s > 0 ? hx : -ix) side_profile();
        body_tails(z_cut);
        translate([0, 0, z_cut]) body_tails(top - z_cut);   // the upper part's tails, a lead-in at their foot
        tray_ledges(-reach_f);
        body_floor();
        // box ledges under its floor, 45° underneath: the body prints standing
        for (s = [-1, 1]) hull() {
            box([s * (ix + eps), -body_in, z_seat - ledge_h], [s * (ix - ledge_w), -up_d, z_seat]);
            box([s * (ix + eps), -body_in, z_seat - ledge_h - ledge_w], [s * (ix - eps), -up_d, z_seat]);
        }
        // the front, closed from the cut up: it starts on the bed with the upper
        // part, and closes the upper part into a tube, so its walls do not sway
        // as it prints. A window for the thumb to squeeze the bottle.
        translate([0, -up_d, 0]) rotate([90, 0, 0]) linear_extrude(frame_t + eps) difference() {
            translate([-ix - eps, z_cut]) square([2 * (ix + eps), top - z_cut]);
            if (thumb_d > 0) translate([0, z_thumb]) hull() {
                circle(d = thumb_d);
                translate([0, thumb_d / 2 * sqrt(2) - 0.01]) square(0.02, center = true);
            }
        }
        if (side_add > 0) for (s = [-1, 1]) side_slab(s);
        if (back_wall > 0) box([-ix - eps, -body_in, 0], [ix + eps, -(body_in + back_wall), top]);
    }
    // side walls: 45° slots along the box, and between the sponge and the box ledges
    for (s = [-1, 1], z = [[z_seat + slot_margin, top - slot_margin], [lower_top, lower_slot_top]])
        slots_tilted(s * (hx - side_t / 2 + side_add / 2), -(up_d - slot_rib - slot_w / 2), -(body_back + slot_rib), z[0], z[1], "x", side_t + side_add);
    // the back wall: the same 45° slots, between the ledges
    if (back_wall > 0) for (z = [[z_seat + slot_margin, top - slot_margin], [lower_top, lower_slot_top]])
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
            intersection() {   // a wide cap's collar runs into the walls
                translate([0, yc, 0]) cylinder(d = collar_d, h = collar_t);
                linear_extrude(collar_t) plan(bw, box_d);
            }
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

// Fit test for the cut: the lower part's top (6 mm of wall and the collar)
// with split_play at 0.05, 0.1 and 0.15, marked by 1 to 3 notches in the right
// side wall's foot, and the upper part's foot, 10 mm, standing as they print.
// The upper ring must drop over each collar with no force and sit flush.
split_test_plays = [0.05, 0.1, 0.15];
test_split_k = 1;    // which of split_test_plays test_split_lower prints [0:1:2]
module test_split_lower(k = 1) translate([0, 0, -(z_cut - 6)]) difference() {
    intersection() { body_lower(split_test_plays[k]); box([-500, -500, z_cut - 6], [500, 500, z_cut + split_collar_h + 1]); }
    for (i = [0 : k]) translate([hx + side_add, -ud + 4 + 3 * i, z_cut - 6]) cube([2, 1.2, 2.4], center = true);
}
module test_split_upper() translate([0, 0, -z_cut]) intersection() { body_upper(); box([-500, -500, z_cut], [500, 500, z_cut + 10]); }

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
    cut() mounts(top, cups, mate_colour);
    // wall and counter, just round the caddy
    color("#EEEEEE") cut() translate([-100, wall_gap, -counter_gap - 20]) cube([200, 10, top + counter_gap + 60]);
    color("#C8B89A") cut() translate([-100, -sink_dist + wall_gap, -counter_gap - 20]) cube([200, sink_dist, 20]);
}

if (part == "plate") plate();
else if (part == "body") body(fins = true);
else if (part == "body_lower") body_lower();
else if (part == "body_upper") body_upper();
else if (part == "test_split_lower") test_split_lower(test_split_k);
else if (part == "test_split_upper") test_split_upper();
else if (part == "tray") soap_tray();
else if (part == "box") bottle_box();
else if (part == "button") button();
else if (part == "jig") jig();
else if (part == "adapter") tape_adapter();
else if (part == "test_keyhole") test_keyhole();
else if (part == "test_buttons") test_buttons();
else if (part == "test_dovetail_housing") test_dovetail_housing();
else if (part == "test_dovetail_tail") test_dovetail_tail(0);   // the housing ladder's mate, as tested
else if (part == "test_dovetail_tail_play") test_dovetail_tail_play();
else if (part == "test_width") test_width();
else if (part == "test_sway") test_sway();
else if (part == "assembly") {
    color(piece_colour) cut() plate();
    color(piece_colour) cut() translate([0, 0, body_lift]) body_lower();
    color(piece_colour) cut() translate([0, 0, body_lift + upper_lift]) body_upper();
    color(piece_colour) cut() translate([0, -pull, body_lift]) soap_tray();
    color(piece_colour) cut() translate([0, 0, z_seat + lift + body_lift]) bottle_box();
    if (show_items) items();
}
