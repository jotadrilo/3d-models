// The house style for wall-mounted pieces (soap-caddy, and the kitchen pieces
// after it): a straight back against the wall, front corners rounded in plan,
// and walls lightened with close, rounded vertical slots. Load with
//   use <../tools/scad/style.scad>
//
// Plan coordinates: x along the wall, the back edge on y = 0 and the piece
// towards -y. Defaults: corner radius 14, slots 4 wide with 2.6 ribs.

use <basics.scad>

// Footprint w x d, back edge straight on y = 0, front corners rounded by r.
module house_plan(w, d, r = 14) {
    r = min(r, w / 2, d);
    hull() {
        translate([-w / 2, -d + r]) square([w, d - r]);
        for (s = [-1, 1]) translate([s * (w / 2 - r), -d + r]) circle(r = r);
    }
}

// Its wall, t thick: straight back, sides rounding into the front.
module house_shell(w, d, t, r = 14) {
    difference() {
        house_plan(w, d, r);
        offset(r = -t) house_plan(w, d, r);
    }
}

// Rounded vertical slot (stadium) w wide from z0 to z1 at (x, y), through a
// wall whose normal is y (axis = "y") or x (axis = "x"), `depth` deep.
module wall_slot(x, y, z0, z1, axis, w = 4, depth = 20) {
    r = w / 2;
    hull() for (z = [z0 + r, z1 - r])
        translate([x, y, z]) rotate(axis == "y" ? [90, 0, 0] : [0, 90, 0])
            cylinder(r = r, h = depth, center = true);
}

// Slots tilted `tilt` degrees from vertical, filling the rectangle
// [u0, u1] x [z0, z1] of a wall whose normal is x (u = y) or y (u = x),
// centred on the wall at `at` (its x or y). For walls that print standing
// with the slots across Z: a vertical slot turned horizontal on the bed roofs
// over its whole length as one long bridge, a slot at 45 deg steps one layer
// at a time. Each slot keeps its rounded ends inside the rectangle; slots
// shorter than min_len (3 w by default) at the corners are left out.
module wall_slots_tilted(at, u0, u1, z0, z1, axis, tilt = 45, w = 4, rib = 2.6, depth = 20, min_len = undef) {
    assert(tilt > 0 && tilt < 90, "wall_slots_tilted: tilt must be between 0 and 90");
    r = w / 2;
    du = sin(tilt); dz = cos(tilt);            // along a slot
    nu = cos(tilt); nz = -sin(tilt);           // across the slots
    a0 = u0 + r; a1 = u1 - r; b0 = z0 + r; b1 = z1 - r;
    cs = [for (u = [a0, a1], z = [b0, b1]) u * nu + z * nz];
    pitch = w + rib;
    n = floor((max(cs) - min(cs)) / pitch) + 1;
    for (i = [0 : n - 1]) {
        c = (min(cs) + max(cs)) / 2 + (i - (n - 1) / 2) * pitch;
        s0 = max((a0 - c * nu) / du, (b0 - c * nz) / dz);
        s1 = min((a1 - c * nu) / du, (b1 - c * nz) / dz);
        if (s1 - s0 + w >= (is_undef(min_len) ? 3 * w : min_len))
            hull() for (s = [s0, s1])
                let(u = c * nu + s * du, z = c * nz + s * dz)
                    translate(axis == "x" ? [at, u, z] : [u, at, z]) rotate(axis == "y" ? [90, 0, 0] : [0, 90, 0])
                        cylinder(r = r, h = depth, center = true);
    }
}

// Centres of the slots that fit between lo and hi.
function slot_positions(lo, hi, w = 4, rib = 2.6) = spaced(lo, hi, w, rib);
