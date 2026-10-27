// A cutlery drainer bin (or a riser, fea_riser > 0) as it stands on the bed
// when the nozzle is at z = cut, for print_sway.py (PIECE=bin).
//   openscad -o bin.stl -D cut=150 [-D bin_wall=1.68] bin_cut.scad
cut = 200;
fea_riser = 0;       // print a riser this tall instead of the bin
include <../cutlery-drainer.scad>
part = "none";

h = fea_riser > 0 ? fea_riser : bin_h;
intersection() {
    if (fea_riser > 0) riser(fea_riser); else bin();
    translate([-500, -500, -1]) cube([1000, 1000, cut + 1]);
}
echo("FEA", "TOP", h);
