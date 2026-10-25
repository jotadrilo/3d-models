// Dog gate: a plywood board standing across a stair tread, against the riser
// of the next step, held upright by two brackets ("escuadras") on its
// downhill face, their feet along the whole tread. It leans a few degrees
// over the feet, so its weight sits over them and it also stands on its own
// on a flat floor; on the stair the riser behind it stops it tipping uphill. Nothing is fixed to the stair.
// It keeps a dog that does not push at it from going up or down; it does not
// hold a push (README, "Strength").
//
// Display coordinates: x across the stair (0 at the board's left edge), y
// along it (+ uphill), z up from the tread the board stands on. The tread
// runs from its nosing at y = -tread/2 to the next riser at y = +tread/2.

use <../../tools/scad/basics.scad>
use <../../tools/scad/boards.scad>
use <../../tools/scad/hardware.scad>

/* [Part] */
part = "assembly"; // [assembly, bracket]
show_context = true;   // the stair, in the assembly
section = false;       // cut the assembly through a bracket's bolts (look from +x)
section_h = 0;         // and keep only its lowest section_h mm (0: all), for a close-up of the shoe

/* [Stair] */
tread = 300;           // going: tread depth, nosing to the next riser [200:5:350]
nosing = 0;            // how far the next step's nosing overhangs its riser: the board stands at the nosing [0:1:40]
rise = 175;            // step height, for the context only [150:5:200]

/* [Board] */
board_w = 780;         // [600:10:1000]
board_h = 1000;        // [700:10:1200]
board_t = 10;          // plywood thickness: measure it, it varies by ±0.5 [6:0.5:18]
board_density = 450;   // kg/m³: 450 light poplar/pine plywood (the worst case for tipping), 680 birch
bracket_inset = 100;   // bracket centre from each edge of the board [40:5:200]

/* [Bracket] */
head_gap = 5.2;        // the shoe's back to the next riser (or nosing): room for the bolt heads, M6 4.2 + 1 [4:0.2:20]
board_play = 0.3;      // per side in the shoe: the bolts squeeze the lip and the leg onto the board [0:0.05:1]
lip = 4.2;             // the shoe's back lip and floor, 10 lines [2.52:0.42:6.3]
lean = 5;              // the board leans over the feet: more stands steadier on a flat floor, less tips harder downhill on the stair [0:0.5:12]
clearance = 5;         // toe to the nosing edge [0:1:20]
bracket_h = 80;        // leg height up the board: 80 lets the 280 mm bracket fit the bed, turned 54° [60:5:100]
bracket_w = 30;        // width along the board [20:1:50]
member = 8.4;          // leg, foot and brace, 20 lines of 0.42 [6.3:0.42:12.6]
bolt_d = 6.5;          // M6 bolt hole
bolt_z = [25, 62];     // bolt heights; the upper one stays reachable through the hollow

/* [Hidden] */
$fa = 1; $fs = 0.4;
shoe = board_t + 2 * board_play;                            // the slot the board stands in
lip_y = tread / 2 - nosing - head_gap;                      // the shoe's back face
leg_y = lip_y - lip - shoe;                                 // the leg's face on the board
board_y = leg_y + shoe / 2;                                 // the board's mid-plane, at its foot
reach = leg_y + tread / 2 - clearance;
BOLT_LEN = 35;         // M6 × 35 hex bolt: lip, board, leg, washer and nut
PRINT = "#8A8D8F";     // grey ABS: the printed brackets
WOOD = "#D8B88A";
STONE = "#B9B4AC";
HW = "#545454";

// board_bracket's lean tilts the leg away from the toe; this one leans towards it.
module bracket() board_bracket(reach, bracket_h, bracket_w, member, bolt_d, bolt_z, lean = -lean, shoe = shoe, lip = lip, floor = lip);
module bracket_print() board_bracket_print(reach, bracket_h, bracket_w, member, bolt_d, bolt_z, lean = -lean, shoe = shoe, lip = lip, floor = lip);

// The board and what is bolted to it lean over the feet, about the foot of the leg.
module leaning() translate([0, leg_y, 0]) rotate([lean, 0, 0]) translate([0, -leg_y, 0]) children();

module stair() {
    for (i = [-1 : 1]) translate([-60, -tread / 2 + i * tread, -2 * rise]) cube([board_w + 120, tread, (2 + i) * rise]);
}

module board() translate([0, board_y, lip]) difference() {
    translate([0, -board_t / 2, 0]) cube([board_w, board_t, board_h]);
    for (x = [bracket_inset, board_w - bracket_inset], z = bolt_z)   // Ø7 drilled for the M6 bolts
        translate([x, 0, z - lip]) rotate([90, 0, 0]) cylinder(d = 7, h = board_t + 2, center = true);
}

// Hex bolts from the riser side through the lip, the board and the leg;
// washer and nut inside the bracket's hollow.
module bolts() {
    for (x = [bracket_inset, board_w - bracket_inset], z = bolt_z) translate([x, 0, z]) {
        translate([0, lip_y, 0]) rotate([90, 0, 0]) hex_bolt(6, BOLT_LEN);
        translate([0, leg_y - member, 0]) rotate([90, 0, 0]) washer(6);
        translate([0, leg_y - member - 1.6, 0]) rotate([90, 0, 0]) hex_nut(6);
    }
}

module cut() {
    if (section) intersection() {
        union() children();
        translate([-200, -1000, section_h > 0 ? -10 : -1000]) cube([200 + bracket_inset, 2000, section_h > 0 ? section_h + 10 : 3000]);
    }
    else children();
}

if (part == "bracket") color(PRINT) bracket_print();
else {
    if (show_context) color(STONE) cut() stair();
    color(WOOD) cut() leaning() board();
    color(PRINT) cut() for (x = [bracket_inset, board_w - bracket_inset])
        translate([x, leg_y, 0]) mirror([0, 1, 0]) bracket();
    color(HW) cut() leaning() bolts();
}

// Weight of the board alone (the brackets add their grams, `make report`)
// and the pushes at the top that tip it: forwards over the toes, and
// backwards over the shoe's back edge (on a flat floor; on the stair the
// riser stops that one). stability.py does this with the brackets' mass.
board_kg = board_w * board_h * board_t * 1e-9 * board_density;
lean_off = board_h / 2 * tan(lean);                         // the centre of mass, forward of the leg's foot
echo(str("reach ", reach, " mm; lean ", lean, "°; board ", board_kg, " kg; tipped at the top by ",
         board_bracket_tip_force(board_kg * 9.81, reach + shoe / 2 - lean_off, board_h), " N forwards (over the toes), ",
         board_bracket_tip_force(board_kg * 9.81, lean_off - shoe / 2 + shoe + lip, board_h), " N backwards (flat floor)"));
echo(str("GEOM leg_y=", leg_y, " lip_y=", lip_y, " board_y=", board_y, " shoe=", shoe, " toe_y=", -tread / 2 + clearance));
