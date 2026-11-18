// The soap caddy body's upper part as it stands on the bed (on its cut) when
// the nozzle is at z = cut above the bed, for print_sway.py (PIECE=upper).
//   openscad -o body.stl -D cut=60 [-D ...] upper_cut.scad
cut = 102;
include <../soap-caddy.scad>
part = "none";

intersection() {
    translate([0, 0, -z_cut]) body_upper();
    translate([-500, -500, -1]) cube([1000, 1000, cut + 1]);
}
echo("FEA", "HX", hx);
echo("FEA", "IX", ix);
echo("FEA", "UD", ud);
echo("FEA", "BODY_BACK", body_back);
echo("FEA", "OPEN_HW", open_hw);
echo("FEA", "TOP", top - z_cut);
echo("FEA", "UPPER", 1);
