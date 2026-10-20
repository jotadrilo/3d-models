// Mounts: how a piece hangs on the world. Load with
//   use <../tools/scad/mounts.scad>
//
// Keyhole frame: the piece's back face is the plane y = 0 and the piece is on
// the -y side, z up. A keyhole's rest point (the button or screw axis, piece
// hanging) is at the origin; its entry is `drop` below it.

use <basics.scad>

// ---------------------------------------------------------------- keyhole

// Derived sizes, for asserts, echoes and laying pads out.
function keyhole_shank_r(shank_d, play = 0.3) = shank_d / 2 + play;
function keyhole_entry_r(head_d, play = 0.3) = head_d / 2 + play;
// Pad extent below and above the rest point, keeping `margin` round the cut.
function keyhole_pad_lo(drop, head_d, play = 0.3, margin = 4) = drop + keyhole_entry_r(head_d, play) + margin;
function keyhole_pad_hi(shank_d, play = 0.3, margin = 4) = keyhole_shank_r(shank_d, play) + margin;

// Rectangular pad round one keyhole: w wide, t thick (from y = 0 to -t).
module keyhole_pad(t, w, drop, shank_d, head_d, play = 0.3, margin = 4) {
    box([-w / 2, 0, -keyhole_pad_lo(drop, head_d, play, margin)],
        [w / 2, -t, keyhole_pad_hi(shank_d, play, margin)]);
}

// Keyhole through a t thick pad: the entry lets the head through, the slot
// above it takes the shank. cone = true adds a 45° countersink at the front
// for a cone-headed button (keyhole_button), which pulls the piece tight
// against the button's flange; cone = false suits a flat screw head.
// Print with the pad standing (slot vertical) or lying on its back.
module keyhole_cut(t, drop, shank_d, head_d, play = 0.3, cone = true) {
    sr = keyhole_shank_r(shank_d, play);
    er = keyhole_entry_r(head_d, play);
    hc = (head_d - shank_d) / 2;
    e = 0.01;
    rotate([90, 0, 0]) translate([0, 0, -e]) {
        translate([0, -drop, 0]) cylinder(r = er, h = t + 2 * e);
        hull() for (z = [-drop, 0]) translate([0, z, 0]) cylinder(r = sr, h = t + 2 * e);
        if (cone) hull() for (z = [-drop, 0])
            translate([0, z, t - hc + e]) cylinder(r1 = sr, r2 = sr + hc + e, h = hc + e);
    }
}

// Button for a keyhole_cut(cone = true), in print orientation: flange on the
// bed, head on top. A threaded stud (a suction cup's M4, a screw) taps into
// the blind pilot hole from the flange side.
//   pad_t       thickness of the pad it hangs through
//   axial_play  clearance between pad and head, front to back
//   head_cyl    straight band on top of the cone
//   stud_len    stud length; the flange grows so the hole fits it
//   stud_hole   pilot hole (3.4 for M4 tapping into PETG/PLA)
function keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play = 0.2) =
    pad_t - (head_d - shank_d) / 2 + axial_play;
function keyhole_button_flange_t(pad_t, shank_d, head_d, axial_play = 0.2, head_cyl = 1, stud_len = 10, min_flange = 3) =
    max(min_flange, stud_len + 1 - (keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play) + (head_d - shank_d) / 2 + head_cyl));
function keyhole_button_h(pad_t, shank_d, head_d, axial_play = 0.2, head_cyl = 1, stud_len = 10, min_flange = 3) =
    keyhole_button_flange_t(pad_t, shank_d, head_d, axial_play, head_cyl, stud_len, min_flange)
    + keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play) + (head_d - shank_d) / 2 + head_cyl;

module keyhole_button(pad_t, shank_d = 7, head_d = 12, flange_d = 16, axial_play = 0.2, head_cyl = 1,
                      stud_len = 10, stud_hole = 3.4, min_flange = 3, chamfer = 0.6) {
    sl = keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play);
    ft = keyhole_button_flange_t(pad_t, shank_d, head_d, axial_play, head_cyl, stud_len, min_flange);
    hc = (head_d - shank_d) / 2;
    e = 0.01;
    difference() {
        union() {
            chamfered_cylinder(flange_d, ft, chamfer);
            cylinder(d = shank_d, h = ft + sl + e);
            translate([0, 0, ft + sl]) cylinder(d1 = shank_d, d2 = head_d, h = hc);
            translate([0, 0, ft + sl + hc - e]) cylinder(d = head_d, h = head_cyl + e);
        }
        translate([0, 0, -e]) cylinder(d = stud_hole, h = stud_len + 0.3 + e, $fn = 24);
    }
}

// ---------------------------------------------------------------- stand-off peg

// Peg that presses into a hole in the piece and rests its rounded tip on the
// wall, so a piece hanging on two side-by-side mounts cannot nod forward. In
// print orientation: collar on the bed. len = from the collar to the tip.
// Its hole: polyhole(d + fit, depth); fit ~0.1 is a press fit in PETG.
module standoff_peg(d = 6, len = 20, collar_d = 10, collar_t = 1.6, chamfer = 0.6) {
    chamfered_cylinder(collar_d, collar_t, chamfer);
    cylinder(d = d, h = collar_t + len - d / 4);
    translate([0, 0, collar_t + len - d / 4]) cylinder(d1 = d, d2 = d / 2, h = d / 4);
}

// ---------------------------------------------------------------- screws

// Cutter for a countersunk wood screw (90° head, DIN 7997): axis along z,
// head flush with the surface at z = 0, shank going down to -len, and a
// clear bore `extra` above for the screwdriver. Rotate it onto the face.
module countersunk_screw(d = 4, head_d = 8, len = 20, head_play = 0.2, extra = 5) {
    hd = head_d + 2 * head_play;
    translate([0, 0, -len]) polyhole(d + 0.4, len + 0.01);
    translate([0, 0, -(hd - d) / 2]) cylinder(d1 = d, d2 = hd, h = (hd - d) / 2 + 0.01);
    cylinder(d = hd, h = extra);
}

// Female side of standoff_peg: its press-fit hole, `depth` deep from z = 0
// down. fit ~0.1 over d is a press fit in PETG (vertical holes print small).
module standoff_peg_hole(d = 6, depth = 5, fit = 0.1) translate([0, 0, -depth]) polyhole(d + fit, depth + 0.01);
