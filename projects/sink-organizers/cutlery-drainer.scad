// Cutlery drainer: a wall-mounted holder for wet cutlery next to the sink,
// with a bar for the dish towel. One of the sink organizers: the wall plate,
// the body on its dovetails, the floor, ledges, tray and style come from
// common.scad.
//
//   - plate: the wall plate, on four suction cups in two rows of two: the
//     rows take the turning moment of the wet cutlery and the towel, which
//     hang well in front of the wall.
//   - body: two side walls, deep at the bottom round the tray and as deep as
//     the rack above it, the floor under the tray, and ledges for the tray
//     and the rack. It slides down onto the plate's dovetails. There is no
//     front wall: one above the tray would be a 200 mm bridge, printed
//     standing. The floor, the plate and the handle tie the side walls.
//   - tray: a floor that slopes forward and spills into the sink past
//     everything else, with rims. Lift its front over the bumps at the ends
//     of its ledges and it slides out under the rack, the bins left in place.
//   - rack: a slotted shelf on two ledges over the tray, with a fence at its
//     front and back that holds the bins' feet and stiffens it across. A
//     bump on each ledge stops it sliding forward. It lifts out once the
//     bins are out.
//   - bins: open boxes with slotted floors, side by side on the rack with
//     little play. They lift out (and get reprinted when the knives have
//     scored them).
//   - handle: an optional U across the front for the towel. Its arms are
//     sprung apart to snap diamond pins into sockets on both side walls
//     (sprung_handle in tools/scad/joints.scad): it cannot turn, and pulling
//     the towel up or forward cannot unseat it. Fold the towel over the bar.
//
// Coordinates and print orientation: see common.scad. The rack and the bins
// stand on their floors, the handle lies flat (its bending plane in XY).

/* [Part] */
part = "assembly";   // [assembly, plate, body, tray, rack, bin, handle, button, test_pin]
show_items = true;   // draw the wall, counter, suction cups, cutlery and towel (assembly only)
section = "none";    // [none, keyhole, handle] cut the assembly through a keyhole, or level with the handle's pins, for the section renders
with_handle = true;  // the towel handle (assembly only)
explode = 0;         // [0:0.1:1] tray slid out, rack and bins lifted (renders)
body_lift = 0;       // [0:1:200] body slid up off the plate (renders)

/* [Size] */
frame_w = 210;       // width of the body, along the wall [120:1:300]
bins = 3;            // number of bins [1:1:5]
bin_d = 90;          // bin depth, front to back [50:1:120]
bin_h = 80;          // bin height: low enough to pick teaspoons out [50:1:140]

/* [Kitchen] */
counter_gap = 15;    // counter to the bottom of the body (preview and checks) [3:1:100]

/* [Cups] */
cup_span = 120;      // horizontal distance between the cups of a row [52:1:250]
cup_pitch = 55;      // vertical distance between the two rows [52:1:90]

/* [Body] */
towel_gap = 14;      // room for the towel between the front of the body and the handle [8:1:30]
step_r = 6;          // radius of the step between the deep and the shallow part of the side walls [2:1:20]

/* [Tray] */
tray_rim = 5;        // the tray's rims above its floor, at the back [3:1:15]

/* [Rack] */
rack_t = 1.6;        // rack floor (8 layers) [1.2:0.2:3]
fence_t = 1.68;      // fences at the rack's front and back (4 lines) [1.26:0.42:2.52]
fence_h = 15;        // fences above the rack floor: they hold the bins' feet and stiffen the rack across [8:1:30]
rack_stop = 2;       // depth of the bumps in front of the rack, on its ledges [1:0.5:4]

/* [Bins] */
bin_wall = 1.26;     // bin walls (3 lines) [1.26:0.42:2.52]
bin_floor = 1.6;     // bin floor (8 layers) [1.2:0.2:3]
bin_r = 5;           // rounded vertical corners of the bins [1:0.5:12]
bin_play = 0.25;     // clearance round each bin, per side: the soap caddy's box_play [0.1:0.05:1]

/* [Towel handle] */
handle_s = 10;       // handle section, square, with chamfered edges [7:0.5:16]
handle_drop = 12;    // pin axes below the top of the body [8:1:60]
pin_s = 6;           // diamond pins: side of the square [4:0.5:9]
pin_len = 5;         // how far the pins reach into the side walls [3:0.5:8]
pin_play = 0.15;     // clearance of the pins in their sockets, per side [0:0.05:0.4]
boss_t = 4.2;        // bosses on the side walls round the sockets (10 lines) [2.1:0.42:8]
boss_w = 16;         // boss height and length [12:1:30]
handle_play = 0.4;   // clearance between the handle's arms and the bosses, per side [0.2:0.1:1]

include <common.scad>

// Plan, back to front: the button heads and housings, the rack's back fence,
// the bins, its front fence, the bumps (the front of the body above the
// tray), the tray's edge and the bumps under it, the towel gap, the bar
hx = frame_w / 2;
ix = hx - side_t;                              // inner half width
reach = sink_dist + drip_over - wall_gap;      // tray front edge, from the plate's back face
tray_y1 = -reach;
tray_y0 = -(back_clear + 0.5);                 // tray and rack back, clear of the button heads and housings
bin_y0 = tray_y0 - fence_t - bin_play;         // bins' back
bin_y1 = bin_y0 - bin_d;                       // bins' front
rack_y1 = bin_y1 - bin_play - fence_t;         // rack front
ud = -rack_y1 + rack_stop;                     // body depth above the tray
reach_f = reach + ledge_stop + 1;              // body front at the tray: the ledge bumps sit in front of it
bar_y = -reach_f - towel_gap - handle_s / 2;   // handle bar axis, in front of the body
thx = ix - tray_play;                          // tray and rack half width
cell = 2 * ix / bins;
bin_w = cell - 2 * bin_play;
bin_xs = [for (i = [0 : bins - 1]) -ix + (i + 0.5) * cell];

// Heights, from the bottom of the body
z_fb = tray_top(tray_y0);                      // tray floor top at the back
z_s = z_fb + tray_rim;                         // tray rim tops
// rack floor's underside: the tray, lifted over its bumps, slides out under
// the rack's ledges, which sit over the tray's side rims
z_r = z_s + ledge_stop + 1 + ledge_h + ledge_w;
z_b = z_r + rack_t;                            // the bins stand here
lower_top = ledge_h + ledge_stop + tray_rim;   // top of the side walls' deep part
lo_z = pad_lo + 2 - dt_cap;                    // lower keyholes' rest point: the pads start 2 mm up the plate
hi_z = lo_z + cup_pitch;
top = max(z_b + bin_h, hi_z + pad_hi);         // top of the body and the plate
pin_y = -ud + boss_w / 2 + 2;                  // pin axes, near the front of the side walls
arm_z = top - handle_drop;                     // pin axes and the handle's mid-plane
span = frame_w + 2 * (boss_t + handle_play);   // between the handle's arms
handle_reach = pin_y - (bar_y + handle_s / 2);
spread = pin_len + 0.5;                        // how far each arm opens to put it on

cups = [for (x = [-cup_span / 2, cup_span / 2], z = [lo_z, hi_z]) [x, z]];

assert(reach_f > ud + step_r, "the tray does not reach past the rack: raise sink_dist or drip_over, or lower bin_d");
assert(cup_span / 2 + pad_w / 2 <= hx - side_t / 2 - house_hw, "cup_span is wider than the plate between its housings");
assert(cup_pitch >= cup_d + 2, "cup_pitch is smaller than the cups");
assert(cup_span >= cup_d + 2, "cup_span is smaller than the cups");
assert(pin_s * sqrt(2) + 4 <= boss_w, "the pins are too big for the bosses");
assert(pin_len <= boss_t + side_t + 1, "the pins are longer than the bosses are deep");
assert(sprung_handle_strain(span, handle_reach, handle_s, spread) <= 0.01, "the handle strains over 1 % to go on: lengthen its arms (towel_gap) or shorten the pins");
assert(hi_z + pad_hi <= top, "the upper keyholes do not fit on the plate");
assert(arm_z - boss_w / 2 - boss_t >= z_r + slot_margin, "the handle's bosses reach the rack: raise bin_h or lower handle_drop");
assert(counter_gap >= dt_cap, "the plate reaches the counter");

echo(str("body: ", frame_w, " x ", reach_f, " x ", top, " mm (w x d x h), ", ud, " deep above the tray; plate ", 2 * plate_hx(), " x ", top + dt_cap,
         "; tray edge ", reach + wall_gap, " mm from the wall, the handle ", -bar_y + handle_s / 2 + wall_gap));
echo(str("tray: ", 2 * thx, " x ", tray_y0 - tray_y1, " x ", z_s, " mm; rack ", 2 * thx, " x ", tray_y0 - rack_y1, " x ", rack_t + fence_h, " mm at ", z_r, "; ",
         bins, " bins ", bin_w, " x ", bin_d, " x ", bin_h, " mm (inside ", bin_w - 2 * bin_wall, " x ", bin_d - 2 * bin_wall, ")"));
echo(str("cups above the counter: ", counter_gap + lo_z, " and ", counter_gap + hi_z, " mm, ", cup_span, " mm apart"));
echo(str("handle: ", span + 2 * handle_s, " x ", handle_reach + 1.5 * handle_s, " mm; its arms open ", spread,
         " mm each to go on: ", round(sprung_handle_strain(span, handle_reach, handle_s, spread) * 1000) / 10, " % strain in the bar; button ", button_h, " mm"));

// ---------------------------------------------------------------- parts

module plate() wall_plate(top, cups, [[slot_margin, top - slot_margin]]);

// The side walls seen from the side: deep at the bottom round the tray, as
// deep as the rack above it, a rounded step between them.
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

// The handle's bosses on the outside of both side walls, tapered at 45°
// underneath: the body prints standing.
module bosses() for (m = [0, 1]) mirror([m, 0, 0]) hull() {
    box([hx - eps, pin_y - boss_w / 2, arm_z - boss_w / 2], [hx + boss_t, pin_y + boss_w / 2, arm_z + boss_w / 2]);
    box([hx - eps, pin_y - boss_w / 2, arm_z - boss_w / 2 - boss_t], [hx, pin_y + boss_w / 2, arm_z + boss_w / 2]);
}

module body() difference() {
    union() {
        for (s = [-1, 1]) yz_prism(s > 0 ? ix : -hx, s > 0 ? hx : -ix) side_profile();
        body_tails(top);
        tray_ledges(-reach_f);
        body_floor();
        // rack ledges under its floor, 45° underneath, and the bumps in
        // front of it
        for (s = [-1, 1]) {
            hull() {
                box([s * (ix + eps), -body_in, z_r - ledge_h], [s * (ix - ledge_w), -ud, z_r]);
                box([s * (ix + eps), -body_in, z_r - ledge_h - ledge_w], [s * (ix - eps), -ud, z_r]);
            }
            box([s * (ix + eps), rack_y1, z_r - eps], [s * (ix - ledge_w), -ud, z_r + ledge_stop]);
        }
        bosses();
    }
    for (m = [0, 1]) mirror([m, 0, 0]) translate([hx + boss_t, pin_y, arm_z]) sprung_handle_socket(pin_s, boss_t + side_t + 1, pin_play);
    // side walls: 45° slots along the bins, clear of the bosses. The union
    // matters: with lazy-union a bare for() here would be split, and the
    // right wall's slots subtracted from the left's.
    difference() {
        union() for (s = [-1, 1])
            slots_tilted(s * (hx - side_t / 2), -ud + slot_margin, -(body_back + slot_rib), z_r + slot_margin, top - slot_margin, "x", side_t);
        for (m = [0, 1]) mirror([m, 0, 0])
            box([ix - 1, pin_y - boss_w / 2 - slot_rib, arm_z - boss_w / 2 - boss_t - slot_rib], [hx + 1, pin_y + boss_w / 2 + slot_rib, arm_z + boss_w / 2 + slot_rib]);
    }
}

// The rims run full height to the front of the rack, then down to the edge.
module drainer_tray() tray(thx, tray_y0, z_s, 0, -ud + slat_w, slats = false);

// Rack, in place: a floor chamfered on the bed, slotted between the ledges,
// and the two fences.
module rack() {
    module outline(o = 0) translate([-thx - o, rack_y1 - o]) square([2 * (thx + o), tray_y0 - rack_y1 + 2 * o]);
    lx = ix - ledge_w - slot_rib;
    translate([0, 0, z_r]) difference() {
        union() {
            hull() {
                linear_extrude(eps) outline(-chamfer);
                translate([0, 0, chamfer]) linear_extrude(rack_t - chamfer) outline();
            }
            for (y = [rack_y1, tray_y0 - fence_t]) box([-thx, y, 0], [thx, y + fence_t, rack_t + fence_h]);
        }
        for (y = slot_xs(bin_y1 + slot_rib, bin_y0 - slot_rib), g = slot_segments(-lx, lx, slot_rib, slot_max_len))
            translate([0, y, -1]) linear_extrude(rack_t + 2)
                hull() for (x = [g[0] + slot_w / 2, g[1] - slot_w / 2]) translate([x, 0]) circle(d = slot_w);
    }
}

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
        // drain slots across the floor, split at slot_max_len like the walls'
        for (y = slot_xs(-d / 2 + bin_wall + 2, d / 2 - bin_wall - 2),
             g = slot_segments(-(w / 2 - bin_wall - 2), w / 2 - bin_wall - 2, slot_rib, slot_max_len))
            translate([0, y, -1]) linear_extrude(bin_floor + 2)
                hull() for (x = [g[0] + slot_w / 2, g[1] - slot_w / 2]) translate([x, 0]) circle(d = slot_w);
        // slots in all four walls, to air the cutlery, in rows no taller than
        // slot_max_len: the bin prints standing, and the ribs between long
        // slots sway under the nozzle (the soap caddy's box came out rough)
        for (s = [-1, 1], x = slot_xs(-w / 2 + r + slot_rib, w / 2 - r - slot_rib))
            slot(x, s * d / 2, bin_floor + slot_margin, bin_h - slot_margin, "y");
        for (s = [-1, 1], y = slot_xs(-d / 2 + r + slot_rib, d / 2 - r - slot_rib))
            slot(s * w / 2, y, bin_floor + slot_margin, bin_h - slot_margin, "x");
    }
}

// The towel handle, in print orientation: the U flat on the bed.
module handle() sprung_handle(span, handle_reach, handle_s, pin_s, pin_len);
module handle_placed() translate([0, bar_y - handle_s / 2, arm_z - handle_s / 2]) handle();

// Fit test: a block with a socket on each side, as wide as two bosses and
// two walls with a gap, and a small handle that snaps onto it. Printed the
// way the real ones print: the block standing (sockets along x), the
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
pull = explode * 80;                           // tray, slid out
lift = explode * 120;                          // rack and bins, lifted
y_bins = (bin_y0 + bin_y1) / 2;

module items() {
    cut() cups_and_buttons(cups, mate_colour);
    // cutlery standing in the bins: a few handles with their heads up
    color("#B8BCC2") cut() for (i = [0 : bins - 1], j = [0 : 2]) {
        l = [150, 210, 130][i % 3];
        translate([bin_xs[i] + (j - 1) * bin_w / 4, y_bins + (j - 1) * 18, z_b + bin_floor + body_lift + lift])
            rotate([(j - 1) * 5, (j - 1) * 6, 0]) {
                translate([-1.5, -5, 0]) cube([3, 10, l - 45]);
                translate([0, 0, l - 25]) scale([0.4, 1.4, 3]) sphere(d = 15);
            }
    }
    // the towel, folded over the bar, hanging both sides (not in the handle's
    // section, where it would hide the pins)
    if (with_handle && section != "handle") color("#5B7FA6") cut() translate([0, 0, body_lift]) {
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

if (part == "plate") plate();
else if (part == "body") body();
else if (part == "tray") drainer_tray();
else if (part == "rack") rack();
else if (part == "bin") bin();
else if (part == "handle") handle();
else if (part == "button") button();
else if (part == "test_pin") test_pin();
else if (part == "assembly") {
    color(piece_colour) cut() plate();
    color(piece_colour) cut() translate([0, 0, body_lift]) {
        body();
        translate([0, -pull, 0]) drainer_tray();
        translate([0, 0, lift]) {
            rack();
            for (x = bin_xs) translate([x, y_bins, z_b + lift / 2]) bin();
        }
    }
    if (with_handle) color(mate_colour) cut() translate([0, 0, body_lift]) handle_placed();
    if (show_items) items();
}
