// Dog gate on a stair: CONCEPT model, to compare the support schemes in
// context before any part is designed for print. The printed parts here are
// placeholders with the right size and position; the chosen ones get designed
// as library components in tools/scad (CLAUDE.md §4.6).
//
// x across the stair (0 at the board's wall edge), y along it (+ uphill),
// z up (0 on the tread the board stands on). The board stands across the
// middle of that tread.

/* [Scene] */
scene = "B"; // [A: brackets only, B: railing clamps + wall channels + brackets + top batten]
show_context = true;
clip_box = [];      // [[x, y, z], [dx, dy, dz]]: show only this box (close-ups)

/* [Stair] */
going = 300;        // tread depth
rise = 175;         // step height
steps_below = 1;
steps_above = 1;
wall_gap = 8;       // wall face to the board's edge

/* [Railing] */
rail_x = 40;        // bar axis beyond the board's railing edge
rail_top_h = 900;   // handrail axis above the nosing line
rail_mid_h = 450;
rail_top_d = 40;
rail_mid_d = 25;

/* [Board] */
board_w = 780;
board_h = 1000;
board_t = 10;
batten_h = 60;
batten_t = 20;

/* [Parts] */
foot_x = [100, 680];    // bracket centres
foot_w = 40;
foot_h = 200;
leg_t = 8;
ch_len = 200;           // wall channel length
ch_lip = 25;            // how far the channel's lips cover the board
clamp_len = 100;        // railing clamp channel length (z)

/* [Hidden] */
$fa = 4; $fs = 2;
eps = 0.01;
slope = atan(rise / going);
PRINT = "#FFFFFF";      // ABS White: the printed parts
WOOD = "#D8B88A";
BATTEN = "#C49A63";
STONE = "#B9B4AC";
WALL = "#EAE6DF";
STEEL = "#4A4D52";

function nosing_z(y) = (y + going / 2) * tan(slope);

module stair() {
    for (i = [-steps_below : steps_above]) {
        y0 = -going / 2 + i * going;
        translate([-wall_gap, y0, -(steps_below + 1) * rise]) cube([board_w + wall_gap + 60, going, (steps_below + 1 + i) * rise]);
    }
}

module wall() {
    translate([-wall_gap - 100, -going / 2 - steps_below * going, -(steps_below + 1) * rise])
        cube([100, (steps_below + steps_above + 1) * going, 1500]);
}

module bar(h, d) {
    y0 = -going / 2 - steps_below * going + 60;
    y1 = going / 2 + steps_above * going - 60;
    hull() for (y = [y0, y1]) translate([board_w + rail_x, y, nosing_z(y) + h]) sphere(d = d, $fn = 24);
}

module railing() {
    bar(rail_top_h, rail_top_d);
    bar(rail_mid_h, rail_mid_d);
    for (y = [-going / 2 - steps_below * going + 60, going / 2 + steps_above * going - 60])
        translate([board_w + rail_x, y, floor((y + going / 2) / going) * rise - 1])
            cylinder(d = rail_top_d, h = nosing_z(y) + rail_top_h - floor((y + going / 2) / going) * rise);
}

module board() {
    translate([0, -board_t / 2, 0]) cube([board_w, board_t, board_h]);
}

module batten() {
    translate([20, board_t / 2, board_h - batten_h]) cube([board_w - 20, batten_t, batten_h]);
}

// The user's bracket ("escuadra"): bolted to the board, its foot on the tread.
// side = +1 uphill (toe against the next riser), -1 downhill.
module bracket(side) {
    reach = going / 2 - board_t / 2 - 5;
    mirror([0, side > 0 ? 0 : 1, 0]) translate([-foot_w / 2, board_t / 2, 0]) {
        cube([foot_w, leg_t, foot_h]);                               // leg on the board
        cube([foot_w, reach, leg_t]);                                // foot on the tread
        hull() {                                                     // gusset
            translate([foot_w / 2 - 3, 0, 0]) cube([6, eps, foot_h * 0.8]);
            translate([foot_w / 2 - 3, 0, 0]) cube([6, reach * 0.8, eps]);
        }
    }
}

// Wall channel: a U screwed to the wall, the board slides down into it.
module wall_channel(z0) {
    gap = board_t + 1;
    translate([-wall_gap, -gap / 2 - 6, z0]) difference() {
        cube([wall_gap + ch_lip, gap + 12, ch_len]);
        translate([wall_gap - eps, 6, -eps]) cube([ch_lip + 1, gap, ch_len + 1]);
    }
}

// Railing clamp: a saddle on the bar and a channel on the board's edge, joined
// by a pin through the board (slotted in x).
module clipped() {
    if (len(clip_box)) intersection() { children(); translate(clip_box[0]) cube(clip_box[1]); }
    else children();
}

module rail_clamp(h, d, t_extra = 0) {
    zb = nosing_z(0) + h;
    gap = board_t + 1 + t_extra;
    z0 = min(zb - clamp_len / 2, board_h - clamp_len);
    color(PRINT) clipped() {
        // channel on the board's edge
        translate([board_w - 30, -board_t / 2 - 0.5 - 6, z0]) difference() {
            cube([30 + rail_x - d / 2, gap + 12, clamp_len]);
            translate([-eps, 6, -eps]) cube([30, gap, clamp_len + 1]);
        }
        // saddle round the bar, along it
        translate([board_w + rail_x, 0, zb]) rotate([-90 + slope, 0, 0]) difference() {
            hull() {
                cylinder(d = d + 16, h = 70, center = true);
                translate([-(rail_x - d / 2) / 2 - d / 4, 0, 0]) cube([eps, d + 16, 70], center = true);
            }
            cylinder(d = d + 0.6, h = 72, center = true);
        }
        // arm from the channel to the saddle
        hull() {
            translate([board_w, -10, z0 + clamp_len / 2 - 10]) cube([1, 20, 20]);
            translate([board_w + rail_x - d / 2 - 4, -10, zb - 10]) cube([1, 20, 20]);
        }
    }
}

if (show_context) {
    color(STONE) clipped() stair();
    color(WALL, 0.3) clipped() wall();
    color(STEEL) clipped() railing();
}
color(WOOD) clipped() board();

if (scene == "A") {
    for (x = foot_x, s = [1, -1]) color(PRINT) clipped() translate([x, 0, 0]) bracket(s);
}
if (scene == "B") {
    color(BATTEN) clipped() batten();
    for (x = foot_x) color(PRINT) clipped() translate([x, 0, 0]) bracket(1);
    for (z = [50, board_h - ch_len]) color(PRINT) clipped() wall_channel(z);
    rail_clamp(rail_mid_h, rail_mid_d);
    rail_clamp(rail_top_h, rail_top_d, batten_t);
}

echo(str("slope ", slope, " deg; handrail at the board ", nosing_z(0) + rail_top_h, " mm, mid bar ", nosing_z(0) + rail_mid_h, " mm"));
