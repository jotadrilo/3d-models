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
// the pilot hole from the flange side. The hole goes right through, so a stud
// longer than expected never bottoms out before the flange reaches the cup.
//   pad_t       thickness of the pad it hangs through
//   axial_play  clearance between pad and head, front to back
//   head_cyl    straight band on top of the cone
//   stud_len    stud length, from the hub face; the flange grows so the button
//               is at least 1 mm longer, and the stud stays inside the head
//   stud_hole   pilot hole as modelled, a polyhole with a lead-in at its
//               mouth (3.7 for an M4 stud prints ~3.45 and taps, but is hard
//               to turn by hand: tested values in tools/README.md, "Tested fits")
function keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play = 0.1) =
    pad_t - (head_d - shank_d) / 2 + axial_play;
function keyhole_button_flange_t(pad_t, shank_d, head_d, axial_play = 0.1, head_cyl = 1, stud_len = 12, min_flange = 3) =
    max(min_flange, stud_len + 1 - (keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play) + (head_d - shank_d) / 2 + head_cyl));
function keyhole_button_h(pad_t, shank_d, head_d, axial_play = 0.1, head_cyl = 1, stud_len = 12, min_flange = 3) =
    keyhole_button_flange_t(pad_t, shank_d, head_d, axial_play, head_cyl, stud_len, min_flange)
    + keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play) + (head_d - shank_d) / 2 + head_cyl;

module keyhole_button(pad_t, shank_d = 7, head_d = 12, flange_d = 16, axial_play = 0.1, head_cyl = 1,
                      stud_len = 12, stud_hole = 3.7, min_flange = 3, chamfer = 0.6) {
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
        translate([0, 0, -e]) polyhole(stud_hole, ft + sl + hc + head_cyl + 2 * e);
        translate([0, 0, -e]) cylinder(d1 = stud_hole + 1, d2 = stud_hole, h = 0.5 + e);
    }
}

// ---------------------------------------------------------------- stand-off peg

// Stand-off peg: a short post that rests on the wall, so a piece hanging on
// two side-by-side mounts cannot nod forward. It goes into a through hole in
// the piece from behind (the wall side), where there is always room: its
// shoulder bears on the piece's back face, so the wall only ever pushes it
// further in, and crush ribs on the spigot hold it in the hole when the piece
// is off the wall. In print orientation: the wall end on the bed.
//   d       nominal hole (standoff_peg_hole); the spigot core is d - 2 * play
//   wall_t  thickness of the wall the hole goes through; the spigot stops 0.4 short
//   len     from the wall to the piece's back face (the shoulder)
//   rib_d   diameter over the ribs: the interference they crush into the hole (d + 0.8)
module standoff_peg(d = 6, wall_t = 4.2, len = 16, body_d = 10, ribs = 4, rib_d = undef, rib_w = 0.8,
                    play = 0.15, chamfer = 0.6) {
    rib_d = rib_d == undef ? d + 0.8 : rib_d;   // 0.4 over the hole fell out in PETG
    sl = wall_t - 0.4;
    core = d - 2 * play;
    chamfered_cylinder(body_d, len, chamfer);
    translate([0, 0, len - 0.01]) {
        cylinder(d = core, h = sl - 0.6);
        translate([0, 0, sl - 0.6 - 0.01]) cylinder(d1 = core, d2 = core - 1.2, h = 0.6);   // lead-in
        intersection() {   // ribs: full height over most of the spigot, tapering at its tip
            for (a = [0:360 / ribs:359]) rotate(a) translate([0, -rib_w / 2, 0]) cube([rib_d / 2, rib_w, sl]);
            union() {
                cylinder(d = rib_d, h = sl - 1.2);
                translate([0, 0, sl - 1.2 - 0.01]) cylinder(d1 = rib_d, d2 = core - 0.6, h = 1.2);
            }
        }
    }
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

// Female side of standoff_peg: its hole, `depth` deep from z = 0 down, right
// through the piece's back wall. The peg's crush ribs make the fit, so the
// hole only needs to be round: fit ~0.1 over d (vertical holes print small).
module standoff_peg_hole(d = 6, depth = 5, fit = 0.1) translate([0, 0, -depth]) polyhole(d + fit, depth + 0.01);
