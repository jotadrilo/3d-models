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
//               mouth (3.9 for an M4 stud prints ~3.65 and taps easily by
//               hand; 3.8 holds harder: tested values in tools/README.md, "Tested fits")
function keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play = 0.1) =
    pad_t - (head_d - shank_d) / 2 + axial_play;
function keyhole_button_flange_t(pad_t, shank_d, head_d, axial_play = 0.1, head_cyl = 1, stud_len = 12, min_flange = 3) =
    max(min_flange, stud_len + 1 - (keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play) + (head_d - shank_d) / 2 + head_cyl));
function keyhole_button_h(pad_t, shank_d, head_d, axial_play = 0.1, head_cyl = 1, stud_len = 12, min_flange = 3) =
    keyhole_button_flange_t(pad_t, shank_d, head_d, axial_play, head_cyl, stud_len, min_flange)
    + keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play) + (head_d - shank_d) / 2 + head_cyl;

module keyhole_button(pad_t, shank_d = 7, head_d = 12, flange_d = 16, axial_play = 0.1, head_cyl = 1,
                      stud_len = 12, stud_hole = 3.9, min_flange = 3, chamfer = 0.6) {
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

// ---------------------------------------------------------------- adhesive mount

// Adhesive mount: a light ladder frame stuck to the wall with a few pieces of
// double-sided foam tape, carrying keyhole button heads where suction cups
// would be, so a piece made for keyholes on cups hangs on it unchanged, its
// heads exactly as far apart as the frame holds them (no jig).
// The tape goes where the wall has to hold the piece: a row of n pieces at
// the top takes the pull of the piece's turning moment, and the weight
// (shear) with two feet at the bottom. The bottom only pushes against the
// wall, so the feet carry a piece of tape each (round, foot_d): it bears on
// the wall and shares the weight. Without them the frame would lean the
// tape's thickness into the wall and peel the top row.
// In print orientation: the tape face on the bed (z = 0), the heads up, the
// heads' flange plane (where the piece's back face rests) at z = stand.
//   heads       [[x, y], ...] the head axes in the frame's plane
//   top         y of the frame's top edge; the tape row sits under it
//   bottom      y of the frame's bottom edge; the feet sit over it
//   stand       from the tape face to the piece's back face: the cups' wall
//               gap less what the tape adds (tape_t - seat_depth)
//   n, tape, size, gap   the tape row: n "square" or "round" pieces, side
//               or diameter `size`, `gap` apart, centred on x = 0
//   foot_d      the feet's tape (round, d), under the outermost heads
//               below the tape row (none if every head is in it)
//   seat_depth  shallow seats for the tape and the spacers, to place them
//   frame_d     depth of the bars; base_t the tape bar's back plate;
//               bar_w the bars' width; boss_d the posts that carry the heads
// Head sizes (pad_t, shank_d, head_d, axial_play, head_cyl) as keyhole_button.

// The tape row's pieces: [[x, y], ...], centred on x = 0 at height y.
function tape_row(n, size = 40, gap = 3, y = 0) = [for (i = [0 : n - 1]) [(i - (n - 1) / 2) * (size + gap), y]];
// Tape area of n pieces, cm²
function tape_area(n, tape = "square", size = 40) = n * (tape == "round" ? PI * size * size / 4 : size * size) / 100;
// The feet's x: the outermost heads under the tape row
function tape_feet_x(heads, row_y0) = let(xs = [for (c = heads) if (c[1] < row_y0) c[0]])
    len(xs) == 0 ? [] : min(xs) == max(xs) ? [xs[0]] : [min(xs), max(xs)];

module tape_piece(tape = "square", size = 40) if (tape == "round") circle(d = size); else square(size, center = true);

// The head part of keyhole_button, from its flange plane (z = 0) up.
module keyhole_head(pad_t, shank_d = 7, head_d = 12, axial_play = 0.1, head_cyl = 1) {
    sl = keyhole_button_shank_len(pad_t, shank_d, head_d, axial_play);
    hc = (head_d - shank_d) / 2;
    e = 0.01;
    translate([0, 0, -e]) cylinder(d = shank_d, h = sl + 2 * e);
    translate([0, 0, sl]) cylinder(d1 = shank_d, d2 = head_d, h = hc);
    translate([0, 0, sl + hc - e]) cylinder(d = head_d, h = head_cyl + e);
}

module tape_mount(heads, top, bottom, stand, n = 2, tape = "square", size = 40, gap = 3, foot_d = 30,
                  seat_depth = 0.2, frame_d = 6, base_t = 1.6, bar_w = 6.3, rib_t = 1.26, boss_d = 16,
                  pad_t = 4.2, shank_d = 7, head_d = 12, axial_play = 0.1, head_cyl = 1, chamfer = 0.6) {
    e = 0.01;
    ty = top - 1 - size / 2;                       // the tape row's centre line
    row = tape_row(n, size, gap, ty);
    rw = n * (size + gap) - gap + 2;               // the tape bar
    feet = [for (x = tape_feet_x(heads, ty - size / 2)) [x, bottom + 1 + foot_d / 2]];
    xs = concat([for (c = heads) c[0]], [for (f = feet) f[0]]);
    x0 = min(concat(xs, [-rw / 2 + bar_w / 2])); x1 = max(concat(xs, [rw / 2 - bar_w / 2]));
    yb = len(feet) ? feet[0][1] : min([for (c = heads) c[1]]);
    module bar(a, b) hull() for (p = [a, b]) translate(p) circle(d = bar_w);
    module bar_outline() offset(r = 3) offset(delta = -3) square([rw, size + 2], center = true);
    difference() {
        union() {
            // the tape bar: a back plate with a rim, ribs along the gaps
            translate([0, ty, 0]) {
                chamfered_prism(base_t, chamfer) bar_outline();
                linear_extrude(frame_d) {
                    difference() { bar_outline(); offset(delta = -rib_t) bar_outline(); }
                    for (i = [1 : n - 1]) translate([row[i][0] - (size + gap) / 2 - rib_t / 2, -size / 2 - 1]) square([rib_t, size + 2]);
                }
            }
            // the ladder: a bar across the top, one across the feet, and one
            // up from each head and foot
            chamfered_prism(frame_d, chamfer) {
                bar([x0, ty], [x1, ty]);
                if (len(feet)) bar([x0, yb], [x1, yb]);
                for (x = xs) bar([x, yb], [x, ty]);
            }
            // the feet: a seat for each spacer
            for (f = feet) translate([f[0], f[1], 0]) {
                chamfered_cylinder(foot_d + 2, base_t, chamfer);
                difference() { cylinder(d = foot_d + 2, h = frame_d); translate([0, 0, -e]) cylinder(d = foot_d + 2 - 2 * rib_t, h = frame_d + 2 * e); }
            }
            for (c = heads) translate([c[0], c[1], 0]) {
                chamfered_cylinder(boss_d + 8, frame_d, chamfer);
                translate([0, 0, frame_d - e]) cylinder(d1 = boss_d + 8, d2 = boss_d, h = 4);   // 45° into the post
                cylinder(d = boss_d, h = stand);
                translate([0, 0, stand]) keyhole_head(pad_t, shank_d, head_d, axial_play, head_cyl);
            }
        }
        if (seat_depth > 0) translate([0, 0, -e]) linear_extrude(seat_depth + e) {
            for (p = row) translate(p) tape_piece(tape, size);
            for (f = feet) translate(f) circle(d = foot_d);
        }
    }
}
