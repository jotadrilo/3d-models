// Basic FDM shapes shared by the projects. Load with
//   use <../tools/scad/basics.scad>
// Every module takes its sizes as arguments: `use` does not see the caller's
// variables (only $fa, $fs and $fn pass through).

// Box from corner a to corner b (any order).
module box(a, b) {
    translate([min(a[0], b[0]), min(a[1], b[1]), min(a[2], b[2])])
        cube([abs(b[0] - a[0]), abs(b[1] - a[1]), abs(b[2] - a[2])]);
}

// Vertical hole that prints true to size: a polyhole (Nophead), whose flats
// touch the nominal circle. Use it as a cutter: h tall from z = 0.
module polyhole(d, h) {
    n = max(round(2 * d), 3);
    cylinder(r = d / 2 / cos(180 / n), h = h, $fn = n);
}

// Horizontal hole along y, centred on the origin: a circle with a 45° tip on
// top, so its roof prints without support. flat = true cuts the tip off level
// with the circle's top (a one-layer bridge instead of a point).
module teardrop(d, h, flat = false) {
    r = d / 2;
    rotate([90, 0, 0]) linear_extrude(h, center = true) intersection() {
        hull() { circle(r = r); rotate(45) square(r); }   // tip at (0, r * sqrt(2))
        translate([-r, -r]) square([2 * r, flat ? 2 * r : 3 * r]);
    }
}

// Cylinder standing on the bed with a 45° chamfer c at its bottom edge
// (hides elephant foot; a fillet there would be an overhang).
module chamfered_cylinder(d, h, c = 0.6) {
    hull() {
        translate([0, 0, c]) cylinder(d = d, h = h - c);
        cylinder(d = d - 2 * c, h = 0.01);
    }
}

// Extrude a 2D profile h tall with 45° chamfers of size c at both faces,
// built from layer-high steps (so the slicer sees clean layers).
module chamfered_prism(h, c = 0.6, layer = 0.2) {
    steps = max(round(c / layer), 1);
    for (i = [0 : steps - 1]) {
        inset = c - i * layer;
        translate([0, 0, i * layer]) linear_extrude(layer + 0.01) offset(delta = -inset) children();
        translate([0, 0, h - (i + 1) * layer - 0.01]) linear_extrude(layer + 0.01) offset(delta = -inset) children();
    }
    translate([0, 0, c]) linear_extrude(h - 2 * c) children();
}

// Centres of features w wide with `gap` between them, as many as fit between
// lo and hi, the group centred in that span (1D).
function spaced(lo, hi, w, gap) =
    let(n = floor((hi - lo + gap) / (w + gap)),
        used = n * w + (n - 1) * gap,
        start = lo + (hi - lo - used) / 2 + w / 2)
    n < 1 ? [] : [for (i = [0 : n - 1]) start + i * (w + gap)];
