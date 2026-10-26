// The cutlery drainer's body as it stands on the bed when the nozzle is at
// z = cut, for print_sway.py (PIECE=drainer).
//   openscad -o body.stl -D cut=80 [-D ...] drainer_body_cut.scad
cut = 114;
include <../cutlery-drainer.scad>
part = "none";

intersection() {
    body();
    translate([-500, -500, -1]) cube([1000, 1000, cut + 1]);
}
echo("FEA", "TOP", top);
