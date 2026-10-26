// The soap caddy's sway test strips (test_sway) cut at z = cut, for
// print_sway.py (PIECE=strip): the bare strip and the one with fins.
cut = 120;
include <../soap-caddy.scad>
part = "none";

intersection() {
    test_sway();
    translate([-500, -500, -1]) cube([1000, 1000, cut + 1]);
}
echo("FEA", "TOP", test_sway_h);
echo("FEA", "STRIP_DX", 2 * (fin_gap + test_sway_fin) + 12);
echo("FEA", "STRIP_L", test_sway_len);
