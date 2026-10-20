// Joints between printed parts. Load with
//   use <../tools/scad/joints.scad>
// Clearances are per side; print the project's fit test before trusting them.

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
