// The soap caddy's dimensions the FEA model needs, echoed for caddy_model.py,
// with whatever -D overrides the variant uses:
//   openscad -o x.echo [-D ...] soap_dims.scad
include <../soap-caddy.scad>

echo("FEA", "IX", ix);
echo("FEA", "LEDGE_W", ledge_w);
echo("FEA", "LEDGE_H", ledge_h);
echo("FEA", "BACK_T", back_t);
echo("FEA", "HOUSE_X", hx - side_t / 2);
echo("FEA", "CAV_X1", side_t / 2 + dt_w + dt_play);
echo("FEA", "HOUSE_HW", house_hw);
echo("FEA", "HOUSE_D", house_d);
echo("FEA", "DT_D", dt_floor + dt_d);
echo("FEA", "Z_SEAT", z_seat);
echo("FEA", "FLOOR_T", floor_t);
echo("FEA", "COLLAR_T", collar_t);
echo("FEA", "WALL_T", wall_t);
echo("FEA", "Z_S", z_s);
echo("FEA", "TRAY_Y0", tray_y0);
echo("FEA", "TRAY_Y1", tray_y1);
echo("FEA", "TRAY_SLOPE", tray_slope);
echo("FEA", "BOX_HW", bw / 2);
echo("FEA", "BOX_FRONT_Y", box_y0 - box_d);
echo("FEA", "Y_BC", y_bc);
echo("FEA", "HOLE_R", hole_d / 2);
echo("FEA", "CUPS", cups);
echo("FEA", "SHANK_R", keyhole_shank_r(shank_d, keyhole_play));
echo("FEA", "PAD_T", pad_t);
echo("FEA", "CONE", (head_d - shank_d) / 2);
echo("FEA", "FLANGE_R", flange_d / 2);
echo("FEA", "TOP", top);
