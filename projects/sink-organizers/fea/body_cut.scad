// The soap caddy's body as it stands on the bed when the nozzle is at z = cut:
// everything below the layer being printed, for print_sway.py.
//   openscad -o body.stl -D cut=150 [-D ...] body_cut.scad
cut = 209;
include <../soap-caddy.scad>
part = "none";

intersection() {
    body(fins = true);
    translate([-500, -500, -1]) cube([1000, 1000, cut + 1]);
}
echo("FEA", "HX", hx);
echo("FEA", "IX", ix);
echo("FEA", "UD", ud);
echo("FEA", "BODY_BACK", body_back);
echo("FEA", "OPEN_HW", open_hw);
echo("FEA", "TOP", top);
echo("FEA", "FIN_X1", hx + side_add + fin_gap + fin_w - fin_t / 2);
echo("FEA", "FIN_Y", -(ud - 1 - fin_t / 2));
echo("FEA", "FIN_W", fin_w);
