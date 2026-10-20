// Joints between printed parts. Load with
//   use <../tools/scad/joints.scad>
// Clearances are per side; print the project's fit test before trusting them.

use <basics.scad>

// Square key turned 45° (a diamond), side s, from z0 to z1 along z. Printed
// with its axis horizontal the diamond's corners point up and down, so the
// key and its socket print without overhangs past 45°. Socket: the same with
// s + 2 * play (0.15 is a slip fit in PLA).
module diamond_key(s, z0, z1)
    translate([0, 0, z0]) rotate([0, 0, 45]) translate([-s / 2, -s / 2, 0]) cube([s, s, z1 - z0]);

// Tongue profile (2D, in the joint's section plane): t thick, h tall from the
// base line y = 0 upwards, with a lead-in chamfer c on the tongue's tip.
// Groove: the same with play > 0 and c = 0 (0.05 per side is a press fit).
// Extrude it along the joint.
module tongue_profile(t = 2, h = 2.5, play = 0, c = 0.4) {
    x0 = -t / 2 - play;  x1 = t / 2 + play;
    polygon([[x0, -0.01], [x1, -0.01], [x1, h - c], [x1 - c, h], [x0 + c, h], [x0, h - c]]);
}

// Blind socket for a prism of `profile` (2D children), opening at z = 0 and
// going down `depth`, with a 45° chamfered mouth c as a lead-in. Grow the
// profile by the clearance before passing it. Convex profiles only (hull).
// From desk-hanger-rail.
module lead_in_socket(depth, c = 0.6) {
    translate([0, 0, -depth]) hull() {
        linear_extrude(depth + 0.01) children();
        translate([0, 0, depth - c]) linear_extrude(c + 0.01) offset(delta = c) children();
    }
}

// Female side of diamond_key: a socket for a key of side s, `depth` deep from
// z = 0 downwards (plus a hair above so it cuts through the face).
module diamond_socket(s, depth, play = 0.15) diamond_key(s + 2 * play, -depth, 0.01);

// Female side of tongue_profile: the groove, a hair deeper than the tongue.
module groove_profile(t = 2, h = 2.5, play = 0.05) translate([0, -0.01]) tongue_profile(t, h + 0.2, play, 0);

// Male side of lead_in_socket: a prism of `profile` (2D children) h long from
// z = 0 up, its tip chamfered by c so it finds the socket's mouth.
module lead_in_plug(h, c = 0.6) {
    hull() {
        linear_extrude(h - c) children();
        linear_extrude(h) offset(delta = -c) children();
    }
}

// ---------------------------------------------------------------- sprung handle

// A U-shaped handle whose arms are sprung apart by hand so the diamond pins
// at their ends snap into sockets on both sides of a part, like a bucket
// handle that cannot turn. Once seated it needs no preload: the pins only
// come out if the arms are spread again, so a pull up or forward on the bar
// does nothing. In print orientation: the U flat on the bed (the load on the
// bar, perpendicular to it, bends it along XY), the bar along x with its
// front face on y = 0, the arms towards +y, the pins pointing inward at the
// arm ends, their axes at z = s / 2.
//   span     between the arms' inner faces (the part's width + 2 × clearance)
//   reach    from the bar's back face to the pin axes
//   s        bar section, square, edges chamfered by c
//   pin_s    diamond pin: side of the square (corners up and down: no overhang)
//   pin_len  how far the pins reach in from the arms' inner faces
//   r        fillet inside the bar/arm corners: at least s (CLAUDE.md §4.7)
// Make span the part's width plus clearance, so the seated pins carry no
// preload (PETG creeps under a constant load, more so warm).
module sprung_handle(span, reach, s = 10, pin_s = 6, pin_len = 5, r = undef, c = 0.6, lead = 1) {
    r = r == undef ? s : r;
    hw = span / 2 + s;                         // outer half width
    module outline()
        offset(r = -r) offset(delta = r) offset(r = 2) offset(delta = -2) difference() {
            translate([-hw, 0]) square([2 * hw, s + reach + s / 2]);
            translate([-span / 2, s]) square([span, reach + s]);
        }
    chamfered_prism(s, c) outline();
    // the pins, with a lead-in chamfer at the tip
    for (m = [0, 1]) mirror([m, 0, 0]) translate([span / 2 + 0.01, s + reach, s / 2]) rotate([0, -90, 0])
        hull() {
            diamond_key(pin_s, 0, pin_len - lead);
            diamond_key(pin_s - 2 * lead, 0, pin_len);
        }
}

// Socket for a sprung_handle pin, along x into a face on the plane x = 0,
// going towards -x (mirror it for the other side): `depth` deep, with a
// chamfered mouth that guides the pin in.
module sprung_handle_socket(pin_s = 6, depth = 6, play = 0.15, lead = 1) {
    rotate([0, 90, 0]) {                       // local -z -> world -x
        diamond_socket(pin_s, depth, play);
        translate([0, 0, -lead]) hull() {
            diamond_key(pin_s + 2 * play, 0, lead + 0.01);
            diamond_key(pin_s + 2 * play + 2 * lead, lead, lead + 0.01);
        }
    }
}

// Peak strain when each arm end is spread by `spread` to clear the pins:
// equal forces at the arm tips, arms of length a = reach + s / 2 and the bar
// of length L = span + s both bending in the plane of the U, section depth s:
//   eps = 3 s spread / (a (2a + 3L))
// (the cantilever snap-fit formula 1.5 h y / a^2 when L = 0). Keep it under
// 1 % in PETG for a handle taken on and off often, 2 % for a one-off.
function sprung_handle_strain(span, reach, s, spread) =
    let(a = reach + s / 2, L = span + s) 3 * s * spread / (a * (2 * a + 3 * L));
