// Holding a board (a sheet of plywood, a panel) upright. From dog-gate.
// Load with
//   use <../../tools/scad/boards.scad>
//
// Every module takes its sizes as arguments. Bolts are metric, with nuts and
// washers; horizontal holes are teardrops with their tip towards the print Z.
// Research and rules: CLAUDE.md §4.7 ("Board bracket").

use <basics.scad>

eps = 0.01;

// Horizontal bolt hole along x (tip up), centred on the origin.
module bolt_hole_x(d, h) rotate([0, 0, 90]) teardrop(d, h);

// ---------------------------------------------------------------- bracket

// The bracket's profile in its own plane (u along the floor from the board
// face, v up the board): a braced triangle, every member `m` wide, its
// hollow rounded. The toe ends square at u = reach, the top of the leg
// square at v = h. `lean` tilts the leg away from the toe (the board leans
// back by that angle, onto a wall or a riser behind it; negative leans it
// over the foot). `shoe` > 0 adds a U round the board's foot: a slot `shoe`
// wide behind the leg, a `lip` on the board's other face and a `floor` under
// it, sheared with the leg, with a 45° lead-in at the top of the slot.
// `heel` > 0 adds a hook that anchors the bracket to an open stair tread: an
// arm `heel_h` deep along the floor behind the leg to `heel` (the tread's
// back edge, measured from the leg's face), a strap down behind the tread's
// back edge (or flange) and a lip `hook_lip` long under it, `hook_clear`
// below an edge `edge_h` deep. Sliding the bracket forwards engages it, back
// releases it; it holds the heel down, so the bracket cannot tip forwards.
// `fillet` rounds the slot's bottom corners and the corner the hook wraps
// round the tread's edge (keep it under the edge's own radius).
module board_bracket_profile(reach, h, m, lean = 0, shoe = 0, lip = 4.2, floor = 4.2,
                             heel = 0, heel_h = 20, edge_h = 50, hook_t = 8.4, hook_lip = 15, hook_clear = 1, fillet = 0) {
    k = tan(lean);
    outer = [[0, 0], [reach, 0], [reach, m], [m - h * k, h], [-h * k, h]];
    difference() {
        union() {
            polygon(outer);
            if (heel > 0) {
                back = -heel - hook_clear;                          // the strap's face on the edge
                low = -edge_h - hook_clear;                          // the lip's top
                translate([back - hook_t, 0]) square([hook_t - back + m, heel_h]);   // arm
                translate([back - hook_t, low - hook_t]) square([hook_t, hook_t - low + heel_h]);   // strap
                translate([back - hook_t, low - hook_t]) square([hook_t + hook_clear + hook_lip, hook_t]);   // lip
                if (fillet > 0) translate([back, -fillet]) difference() {     // round the corner over the tread's edge
                    square(fillet);
                    translate([fillet, 0]) circle(r = fillet, $fn = 32);
                }
            }
            if (shoe > 0) multmatrix([[1, -k, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0]]) {
                translate([-shoe - lip, 0]) square([lip, h]);
                translate([-shoe - lip, 0]) square([shoe + lip + m / 2, floor]);
            }
        }
        offset(r = 4) offset(delta = -m - 4) polygon(outer);
        if (shoe > 0) multmatrix([[1, -k, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0]]) union() {
            polygon([[-shoe, floor + fillet], [0, floor + fillet], [0, h - 2], [2, h + 0.01], [-shoe - 2, h + 0.01], [-shoe, h - 2]]);
            translate([-shoe, floor]) offset(r = fillet) offset(delta = -fillet) square([shoe, 3 * fillet + 0.01]);   // rounded bottom
        }
    }
}

// A bracket ("escuadra") that stands a board on a floor or a step: its leg
// bolted to the board's face, its foot on the floor. Used in pairs, one on
// each face, the same bolts through both legs and the board (lean = 0); or
// on one face only: then a shoe (shoe = board thickness + play) holds the
// board's foot on both faces, the bolts squeezing the lip and the leg onto
// it, and `lean` tilts the board, back onto a wall behind it or (negative)
// over the foot, so it also stands on its own on a flat floor.
// Display position: the board's face on y = 0 (the bracket on +y), the
// floor on z = 0, the bracket centred on x = 0, w wide. With a shoe the
// board stands on its floor, `floor` up.
// Print: on its side (`board_bracket_print`), so the leg, the foot and the
// brace bend within the layers.
module board_bracket(reach = 140, h = 160, w = 30, m = 8.4, bolt_d = 6.5, bolts = [30, 100], c = 0.6, lean = 0,
                     shoe = 0, lip = 4.2, floor = 4.2, heel = 0, heel_h = 20, edge_h = 50, hook_t = 8.4, hook_lip = 15, hook_clear = 1, fillet = 0) {
    multmatrix([[0, 0, 1, -w / 2], [1, 0, 0, 0], [0, 1, 0, 0]])
        board_bracket_print(reach, h, w, m, bolt_d, bolts, c, lean, shoe, lip, floor, heel, heel_h, edge_h, hook_t, hook_lip, hook_clear, fillet);
}
module board_bracket_print(reach = 140, h = 160, w = 30, m = 8.4, bolt_d = 6.5, bolts = [30, 100], c = 0.6, lean = 0,
                           shoe = 0, lip = 4.2, floor = 4.2, heel = 0, heel_h = 20, edge_h = 50, hook_t = 8.4, hook_lip = 15, hook_clear = 1, fillet = 0) {
    back = shoe > 0 ? shoe + lip : 0;      // how far the bolts reach behind the leg
    difference() {
        chamfered_prism(w, c) board_bracket_profile(reach, h, m, lean, shoe, lip, floor, heel, heel_h, edge_h, hook_t, hook_lip, hook_clear, fillet);
        for (v = bolts) translate([(m - back) / 2 - v * tan(lean), v, w / 2]) rotate([0, 0, lean]) bolt_hole_x(bolt_d, m + back + 2);
    }
}

// Force at height `at` above the floor that tips a board standing in a pair
// of brackets, from the weight of board + brackets (N) and the arm from the
// toe to their centre of mass (the reach, plus what the board leans back).
function board_bracket_tip_force(weight, reach, at) = weight * reach / at;
