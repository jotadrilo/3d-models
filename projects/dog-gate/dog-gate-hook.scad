// Dog gate, hooked version: the same board on two one-sided brackets, for an
// open stair of pressed steel tray treads (a plate with its front and back
// edges folded down, open below, gaps between the steps). Each bracket's heel
// hooks under the back flange of the tread it stands on, so the gate cannot
// tip or slide down the stair: a leaning dog's push goes into the hooks. Two
// vertical battens on the board's downhill face carry that push down to the
// brackets, whose shoes grip board and batten together (fea/board_fea.py: a
// 10 mm board alone bends 20-37 cm as a cantilever).
// Slide it 20 mm down the stair to hook it, 20 mm up to free it, from the top
// edge, from either side.
//
// Display coordinates as dog-gate.scad: x across the stair, y along it
// (+ uphill), z up from the tread's top; the tread runs from its front edge
// at y = -tread/2 to its back edge at y = +tread/2.

use <../../tools/scad/basics.scad>
use <../../tools/scad/boards.scad>
use <../../tools/scad/hardware.scad>

/* [Part] */
part = "assembly"; // [assembly, bracket, hook_test]
show_context = true;   // the treads, in the assembly
show_stringers = true; // and the stair's stringers (off for a side view: they hide the rest)
section = false;       // cut the assembly through a bracket's bolts (look from +x)
section_h = 0;         // and keep only z from -80 to section_h mm (0: all), for a close-up of the shoe and hook

/* [Stair: open, tray treads] */
tread = 300;           // tread depth, front edge to back edge [200:5:350]
rise = 175;            // step height [150:5:200]
overlap = 20;          // how far the next tread's front edge comes over this one's back edge (0: none) [0:1:50]
edge_h = 50;           // depth of the tread's back flange (or the plank's thickness): measure it, print hook_test first [20:1:80]
sheet = 2;             // the tread's steel, for the context only

/* [Board] */
board_w = 780;         // [600:10:1000]
board_h = 1000;        // [700:10:1200]
board_t = 10;          // plywood thickness [6:0.5:18]
board_density = 450;   // kg/m³ (the light end)
bracket_inset = 200;   // bracket (and batten) centre from each edge of the board: 200 halves the board's span between the battens [80:5:300]
batten_w = 45;         // vertical batten on the downhill face, at each bracket: plywood strips cut from the rest of the sheet, grain along them [30:1:70]
batten_t = 30;         // its depth (off the board): three 10 mm strips glued flat [10:10:40]
batten_top = 40;       // stops this far below the board's top [0:5:200]

/* [Bracket] */
slide = 20;            // how far the gate slides to hook and unhook [15:1:40]
slide_clear = 5;       // the board's back to the next tread's front flange, hooked and slid back [2:1:20]
board_play = 0.3;      // per side in the shoe [0:0.05:1]
lip = 12.6;            // the shoe's back lip and floor: the board's foot pushes back on it (fea/bracket_fea.py) [4.2:0.42:16.8]
lean = 5;              // the board leans over the feet (it also stands on a flat floor) [0:0.5:12]
reach = 180;           // foot length in front of the leg: the hook holds it down now, not the reach [120:5:250]
bracket_h = 110;       // leg height up the board [80:5:160]
bracket_w = 55;        // width along the board: covers the batten [40:1:70]
member = 12.6;         // leg, foot and brace, 30 lines: the brace carries ~850 N in compression and the leg bends under the batten (fea/bracket_fea.py) [8.4:0.42:16.8]
heel_h = 25;           // depth of the arm from the shoe to the hook [12:1:35]
hook_t = 12.6;         // the hook's strap and lip [6.3:0.42:16.8]
hook_lip = 15;         // how far the lip reaches under the edge (< slide) [8:1:30]
hook_clear = 1;        // play round the edge [0.5:0.1:3]
fillet = 3;            // rounds the shoe's bottom corners and the hook's corner over the tread's edge (under the edge's own radius) [0:0.5:5]
bolt_d = 6.5;          // M6
bolt_z = [34, 85];     // bolt heights: the lower head clears the heel arm, the upper nut stays reachable through the hollow

/* [Hidden] */
$fa = 1; $fs = 0.4;
shoe = board_t + batten_t + 2 * board_play;   // board and batten
next_y = tread / 2 - overlap;                 // the next tread's front edge
board_back = next_y - slide - slide_clear;    // the board's uphill face, at its foot
leg_y = board_back - shoe + board_play;       // the leg's face on the batten
board_y = board_back - board_t / 2;           // the board's mid-plane
lip_y = leg_y + shoe + lip;
heel = tread / 2 - leg_y;                     // leg face to the tread's back edge
toe_y = leg_y - reach;
stair_w = board_w + 10;                       // the board spans the stair, 5 mm off each stringer
BOLT_LEN = 80;         // M6 × 80: lip, board, batten, leg, washer and nut
PRINT = "#8A8D8F";     // grey ABS
WOOD = "#D8B88A";
STEEL = "#3C4046";
HW = "#545454";

module bracket() board_bracket(reach, bracket_h, bracket_w, member, bolt_d, bolt_z, lean = -lean, shoe = shoe, lip = lip, floor = lip,
                               heel = heel, heel_h = heel_h, edge_h = edge_h, hook_t = hook_t, hook_lip = hook_lip, hook_clear = hook_clear, fillet = fillet);
module bracket_print() board_bracket_print(reach, bracket_h, bracket_w, member, bolt_d, bolt_z, lean = -lean, shoe = shoe, lip = lip, floor = lip,
                               heel = heel, heel_h = heel_h, edge_h = edge_h, hook_t = hook_t, hook_lip = hook_lip, hook_clear = hook_clear, fillet = fillet);

// A 10 mm slice of the hook and 40 mm of the arm, to try on the real tread
// before printing the brackets: it must slide on over the back flange and sit
// flat. The Bambu project prints it for several flange depths (edge_h).
module hook_test() {
    back = -heel - hook_clear;
    low = -edge_h - hook_clear;
    intersection() {
        bracket_print();
        translate([back - hook_t - 1, low - hook_t - 1, 0]) cube([hook_t + 1 + 40, hook_t + 1 - low + heel_h + 1, 10]);
    }
}

module tray(y0, z0) {   // a pressed steel tread: plate and front and back flanges, open below
    translate([-5, y0, z0 - sheet]) cube([stair_w, tread, sheet]);
    for (y = [y0, y0 + tread - sheet]) translate([-5, y, z0 - edge_h]) cube([stair_w, sheet, edge_h]);
}
module stair() {
    tray(-tread / 2, 0);
    if (!section) {   // a section shows the tread the gate stands on, not slices of the others
        tray(next_y, rise);
        tray(next_y + tread - overlap, 2 * rise);
        tray(-tread / 2 - tread + overlap, -rise);
        if (show_stringers) for (x = [-15, stair_w - 5]) translate([x, -tread * 1.6, -2 * rise]) rotate([atan(rise / (tread - overlap)), 0, 0]) cube([10, 1200, 200]);   // stringers
    }
}

module board() translate([0, board_y, lip]) difference() {
    union() {
        translate([0, -board_t / 2, 0]) cube([board_w, board_t, board_h]);
        for (x = [bracket_inset, board_w - bracket_inset])
            translate([x - batten_w / 2, -board_t / 2 - batten_t, 0]) cube([batten_w, batten_t, board_h - batten_top]);
    }
    for (x = [bracket_inset, board_w - bracket_inset], z = bolt_z)
        translate([x, -batten_t / 2, z - lip]) rotate([90, 0, 0]) cylinder(d = 7, h = board_t + batten_t + 2, center = true);
}

module bolts() {
    for (x = [bracket_inset, board_w - bracket_inset], z = bolt_z) translate([x, 0, z]) {
        translate([0, lip_y, 0]) rotate([90, 0, 0]) hex_bolt(6, BOLT_LEN);
        translate([0, leg_y - member, 0]) rotate([90, 0, 0]) washer(6);
        translate([0, leg_y - member - 1.6, 0]) rotate([90, 0, 0]) hex_nut(6);
    }
}

module leaning() translate([0, leg_y, 0]) rotate([lean, 0, 0]) translate([0, -leg_y, 0]) children();

module cut() {
    if (section) intersection() {
        union() children();
        translate([0, -1000, section_h > 0 ? -80 : -1000]) cube([bracket_inset, 2000, section_h > 0 ? section_h + 80 : 3000]);
    }
    else children();
}

if (part == "bracket") color(PRINT) bracket_print();
else if (part == "hook_test") color(PRINT) hook_test();
else {
    if (show_context) color(STEEL) cut() stair();
    color(WOOD) cut() leaning() board();
    color(PRINT) cut() for (x = [bracket_inset, board_w - bracket_inset])
        translate([x, leg_y, 0]) mirror([0, 1, 0]) bracket();
    color(HW) cut() leaning() bolts();
}

board_kg = board_w * board_h * board_t * 1e-9 * board_density;
echo(str("heel ", heel, " mm behind the leg; reach ", reach, "; board ", board_kg, " kg"));
echo(str("GEOM leg_y=", leg_y, " lip_y=", lip_y, " board_y=", board_y, " shoe=", shoe, " toe_y=", toe_y,
         " hook_y=", tread / 2, " hook_z=", -edge_h - hook_clear, " next_y=", next_y));
