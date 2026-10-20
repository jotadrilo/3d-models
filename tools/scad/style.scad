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

// Centres of the slots that fit between lo and hi.
function slot_positions(lo, hi, w = 4, rib = 2.6) = spaced(lo, hi, w, rib);
