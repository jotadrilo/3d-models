// Detergent measuring scoop: a rounded-rectangle cup that holds exactly
// `capacity_ml` up to an engraved fill line, with a flat handle and a
// collar underneath that fits over the bottle cap, so the scoop can be
// stored sitting on top of the bottle.
// The cup height is solved from the capacity, so changing the footprint
// or the capacity keeps the measure exact.
// Print it upside down (rim and handle on the bed): no supports needed.
// All dimensions in mm.

/* [Capacity] */
capacity_ml = 190;     // volume up to the fill line
headroom    = 6;       // wall above the fill line, so it doesn't spill

/* [Cup] */
inner_l       = 75;    // inside length (along the handle)
inner_w       = 55;    // inside width (grown if the collar needs it)
corner_r      = 12;    // inside corner radius, seen from above
bottom_fillet = 6;     // inside radius between floor and walls (<= corner_r)
wall          = 2;
floor_t       = 2;

/* [Fill line] */
fill_mark   = true;    // groove around the inside just above the fill level
mark_h      = 0.8;
mark_depth  = 0.6;

/* [Handle] */
handle_l      = 60;    // from the cup wall to the tip
handle_w      = 22;
handle_t      = 4;
hang_hole_d   = 8;     // 0 = no hole
label         = true;  // engrave the capacity on the handle
label_size    = 7;
label_depth   = 0.6;

/* [Bottle mount] */
mount         = true;  // collar under the floor that fits over the bottle cap
cap_d         = 45;    // measure your bottle cap (widest point)
cap_clearance = 0.4;   // added to the diameter
collar_h      = 12;    // how far the cap goes in
collar_wall   = 2;
grip_ribs     = 6;     // small vertical ribs inside for a snug fit (0 = none)
rib_bump      = 0.5;   // how much each rib sticks in

/* [Render] */
part = "scoop";        // [scoop, cavity]

/* [Hidden] */
$fn = 128;
eps = 0.01;

recess_d  = cap_d + cap_clearance;
collar_od = recess_d + 2 * collar_wall;

L = inner_l;
W = mount ? max(inner_w, collar_od - 2 * wall) : inner_w;
r = corner_r;
f = bottom_fillet;

// Plan area of the rounded rectangle.
area = L * W - (4 - PI) * r * r;

// Volume the bottom fillet takes out of the straight prism (Pappus): the
// fillet's cross-section, swept along the straight walls and around the
// four corners about each corner centre.
fillet_a   = (1 - PI / 4) * f * f;
fillet_c   = (10 - 3 * PI) / (12 - 3 * PI) * f;   // its centroid, from the wall
fillet_vol = fillet_a * (2 * (L - 2 * r) + 2 * (W - 2 * r)
                        + 2 * PI * (r - fillet_c));

fill_h = (capacity_ml * 1000 + fillet_vol) / area;
H      = fill_h + headroom;    // inside depth, floor to rim

assert(f <= r, "bottom_fillet must be <= corner_r");
assert(2 * r <= min(L, W), "corner_r too large for the footprint");
assert(f <= fill_h, "bottom_fillet taller than the fill level");

echo(str("Inside ", L, " x ", W, " mm, fill line at ", fill_h,
         " mm, inside depth ", H, " mm, total height ",
         H + floor_t + (mount ? collar_h : 0), " mm"));

// Quarter of the section of a rounded-bottom corner post, revolved into a
// "puck" of radius rr with a bottom edge radius ff, hh tall.
module puck(rr, ff, hh) {
    rotate_extrude()
        intersection() {
            square([rr, hh]);
            hull() {
                translate([0, ff]) square([rr, hh - ff]);
                square([max(rr - ff, eps), hh]);
                translate([rr - ff, ff]) circle(ff);
            }
        }
}

// Rounded box with filleted bottom edges, bottom face at z = 0.
module rounded_box(l, w, rr, ff, hh) {
    hull()
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (l / 2 - rr), sy * (w / 2 - rr), 0])
                puck(rr, ff, hh);
}

module rounded_rect(l, w, rr) {
    offset(r = rr) square([l - 2 * rr, w - 2 * rr], center = true);
}

module cavity(hh) { rounded_box(L, W, r, f, hh); }

module handle() {
    x0 = L / 2 + wall - eps;
    translate([0, 0, H - handle_t])
        difference() {
            linear_extrude(handle_t)
                hull() {
                    translate([x0, -handle_w / 2]) square([eps, handle_w]);
                    translate([x0 + handle_l - handle_w / 2, 0])
                        circle(d = handle_w);
                }
            if (hang_hole_d > 0)
                translate([x0 + handle_l - handle_w / 2, 0, -eps])
                    cylinder(d = hang_hole_d, h = handle_t + 2 * eps);
            if (label)
                translate([x0 + (handle_l - handle_w / 2 - hang_hole_d / 2) / 2,
                           0, handle_t - label_depth])
                    linear_extrude(label_depth + eps)
                        text(str(capacity_ml, " ml"), size = label_size,
                             halign = "center", valign = "center",
                             font = "Liberation Sans:style=Bold");
        }
    // Gusset under the handle, against the wall.
    gh = min(handle_l / 2, H / 2);
    translate([x0, 0, H - handle_t])
        rotate([90, 0, 0])
            linear_extrude(handle_t, center = true)
                polygon([[0, 0], [gh, 0], [0, -gh]]);
}

module collar() {
    // Starts inside the body; the cavity is subtracted afterwards, so it
    // never eats into the measured volume.
    translate([0, 0, -floor_t - collar_h])
        cylinder(d = collar_od, h = collar_h + floor_t + f);
}

module cap_recess() {
    translate([0, 0, -floor_t - collar_h - eps])
        difference() {
            union() {
                cylinder(d = recess_d, h = collar_h + eps);
                // lead-in chamfer
                cylinder(d1 = recess_d + 2, d2 = recess_d, h = 1);
            }
            for (i = [0 : grip_ribs - 1])
                rotate(i * 360 / max(grip_ribs, 1))
                    translate([recess_d / 2 + 1 - rib_bump, 0, 1.5])
                        cylinder(r = 1, h = collar_h, $fn = 24);
        }
}

module scoop() {
    difference() {
        union() {
            translate([0, 0, -floor_t])
                rounded_box(L + 2 * wall, W + 2 * wall, r + wall, f + wall,
                            H + floor_t);
            handle();
            if (mount) collar();
        }
        translate([0, 0, 0]) cavity(H + eps);
        if (mount) cap_recess();
        if (fill_mark)
            translate([0, 0, fill_h])
                linear_extrude(mark_h)
                    rounded_rect(L + 2 * mark_depth, W + 2 * mark_depth,
                                 r + mark_depth);
    }
}

if (part == "cavity") cavity(fill_h);
else scoop();
