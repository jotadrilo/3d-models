// Replacement tilt leg (foot) for the Logitech K120 keyboard.
//
// The leg folds into a recess under the back edge of the keyboard. Two pins
// at the hinge end turn in the recess, and a sprung tongue between two slots
// clicks the leg open or shut with the ridge on its tip.
//
// Dimensions measured from two free community models that are known to fit
// (Printables 697383, public domain, and 548129, CC BY-NC: the same geometry),
// then rebuilt here as a parametric model. Axes: x across the leg (pins along
// x), y along it from the hinge end (y = 0) to the foot end, z up from the
// flat face, which prints on the bed.

/* [Body] */
width       = 15;    // body width, without the pins [12:0.1:18]
length      = 25;    // hinge end to foot end [20:0.5:35]
thick       = 4;     // overall thickness: the side rails [3:0.2:6]
plate_t     = 2;     // thickness of the plate between the rails [1.2:0.2:3]
rail_w      = 2;     // width of each side rail [1.26:0.02:3]
foot_r      = 4;     // radius of the rounded foot end, centred on the bed [2:0.5:6]
bed_chamfer = 0.4;   // 45° chamfer on the bottom edges of the sides and the foot end [0:0.1:0.6]

/* [Hinge pins] */
pin_d    = 2;        // pin diameter [1.6:0.05:2.4]
pin_len  = 2.5;      // how far each pin sticks out of the side [1.5:0.1:3.5]
pin_y    = 1.8;      // pin axis from the hinge end (the hinge end itself is round about y = thick / 2) [1.2:0.1:3]
pin_tip  = 0.3;      // 45° chamfer on the pin tips, a lead-in into the keyboard's sockets [0:0.1:0.6]
pin_flat = 0.2;      // flat cut off the bottom of the pins so they print without support (0 = round) [0:0.05:0.4]

/* [Tongue (snap)] */
slot_w     = 2;      // width of the two slots beside the tongue [1.2:0.1:3]
slot_len   = 9.5;    // slot length from the hinge end [6:0.25:12]
ridge_back = 2;      // the ridge on the tongue's tip ends this far from the hinge end [1:0.1:3]

/* [Stiffening rib] */
rib_y = 20.25;       // rib across the plate, from the hinge end (0 = none) [0:0.5:24]
rib_w = 0.84;        // rib width (2 lines) [0.84:0.42:1.68]
rib_h = 3;           // rib height above the bed [2:0.2:4]

/* [Output] */
part = "leg";        // [leg]
preview_fn = 32;     // facets in preview

/* [Hidden] */
eps = 0.01;
$fa = 1;
$fs = $preview ? 0.4 : 0.15;
hinge_r = thick / 2;               // the hinge end is round about the pin axis
pin_z = thick / 2;
tongue_w = width - 2 * rail_w - 2 * slot_w;

assert(tongue_w >= 3, "the tongue is too narrow: widen the leg or narrow the slots/rails");
assert(pin_y >= pin_d / 2 + 0.4, "the pins need some of the hinge end around them");

echo(str("K120 leg: ", width + 2 * pin_len, " x ", length, " x ", thick,
         " mm over the pins; body ", width, " wide; tongue ", tongue_w, " wide"));

// ------------------------------------------------------------ profiles (y, z)

// Side profile of a rail: round about the pin axis at the hinge end, full
// thickness along the leg, a quarter circle at the foot end.
module rail_profile() {
    intersection() {
        hull() {
            translate([hinge_r, pin_z]) circle(r = hinge_r);
            translate([hinge_r, 0]) square([length - hinge_r, thick]);
        }
        foot_clip();
    }
}

// Side profile of the plate and tongue: plate_t thick, with the tongue's
// ridge (round, full thickness) at the hinge end.
module plate_profile() {
    intersection() {
        union() {
            intersection() {                       // the ridge: the front half of the hinge round
                translate([hinge_r, pin_z]) circle(r = hinge_r);
                square([ridge_back, thick]);
            }
            hull() {
                translate([hinge_r, pin_z]) intersection() {
                    circle(r = hinge_r);
                    translate([-hinge_r, -hinge_r]) square([2 * hinge_r, plate_t]);
                }
                translate([hinge_r, 0]) square([length - hinge_r, plate_t]);
            }
        }
        foot_clip();
    }
}

// The foot end: a circle of foot_r centred on the bed, cut at y = length.
module foot_clip() {
    c = length - foot_r;
    union() {
        translate([-1, -1]) square([c + 1, thick + 2]);
        translate([c, 0]) intersection() {
            circle(r = foot_r);
            square([foot_r, foot_r]);
        }
    }
}

// Extrude a (y, z) profile along x between x0 and x1.
module along_x(x0, x1) {
    translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) children();
}

// ------------------------------------------------------------ the leg

module pin(side) {
    x0 = side * width / 2;
    translate([x0 - (side < 0 ? pin_len : 0) - (side < 0 ? 0 : eps), pin_y, pin_z])
        intersection() {
            rotate([0, 90, 0]) if (side > 0) pin_body(); else translate([0, 0, pin_len + eps]) mirror([0, 0, 1]) pin_body();
            translate([0, -pin_d, pin_flat - pin_d / 2]) cube([pin_len + eps, 2 * pin_d, 2 * pin_d]);
        }
}

// A pin along +z from z = 0 (the side of the leg), its tip chamfered.
module pin_body() {
    cylinder(d = pin_d, h = pin_len + eps - pin_tip);
    translate([0, 0, pin_len + eps - pin_tip - eps]) cylinder(d1 = pin_d, d2 = pin_d - 2 * pin_tip, h = pin_tip + eps);
}

// 45° chamfer under the outer sides and the foot end (hides elephant foot).
module bed_chamfers() {
    c = bed_chamfer;
    if (c > 0) {
        for (s = [-1, 1])
            translate([s * width / 2, hinge_r, 0]) rotate([-90, 0, 0])
                linear_extrude(length) polygon([[-c - eps, eps], [c + eps, eps], [0, -c]] + [[0, 0], [0, 0], [0, 0]]);
        translate([0, length - foot_r, 0]) rotate_extrude($fn = 96)
            translate([foot_r, 0]) polygon([[-c - eps, -eps], [eps, -eps], [eps, c + eps]]);
    }
}

module leg() {
    difference() {
        union() {
            for (s = [-1, 1]) along_x(s < 0 ? -width / 2 : width / 2 - rail_w, s < 0 ? -width / 2 + rail_w : width / 2)
                rail_profile();
            along_x(-width / 2 + rail_w - eps, width / 2 - rail_w + eps) plate_profile();
            if (rib_y > 0)
                translate([-width / 2 + rail_w, rib_y - rib_w / 2, 0]) cube([width - 2 * rail_w, rib_w, rib_h]);
            pin(-1);
            pin(1);
        }
        // the slots that free the tongue, with a round end
        for (s = [-1, 1]) translate([s * (tongue_w + slot_w) / 2, 0, -1]) hull() {
            translate([-slot_w / 2, -1, 0]) cube([slot_w, eps, thick + 2]);
            translate([0, slot_len - slot_w / 2, 0]) cylinder(d = slot_w, h = thick + 2);
        }
        bed_chamfers();
    }
}

if (part == "leg") leg();
