// The cutlery drainer's dimensions the FEA model needs, echoed for
// drainer_model.py, with whatever -D overrides the variant uses, and the
// parts the drainer's .scad exports in print orientation, placed as they
// sit on the wall:
//   openscad -o x.echo [-D ...] drainer_dims.scad
//   openscad -o handle.stl -D 'fea_part="handle"' [-D ...] drainer_dims.scad
fea_part = "none";   // [none, handle]
include <../cutlery-drainer.scad>
part = "none";       // nothing from the drainer's own part selector

if (fea_part == "handle") handle_placed();

echo("FEA", "HX", hx);
echo("FEA", "IX", ix);
echo("FEA", "THX", thx);
echo("FEA", "LEDGE_W", ledge_w);
echo("FEA", "LEDGE_H", ledge_h);
echo("FEA", "BACK_T", back_t);
echo("FEA", "HOUSE_X", hx - side_t / 2);
echo("FEA", "CAV_X1", side_t / 2 + dt_w + dt_play);
echo("FEA", "HOUSE_HW", house_hw);
echo("FEA", "HOUSE_D", house_d);
echo("FEA", "DT_D", dt_floor + dt_d);
echo("FEA", "TRAY_Y0", tray_y0);
echo("FEA", "TRAY_Y1", tray_y1);
echo("FEA", "TRAY_SLOPE", tray_slope);
echo("FEA", "Z_R", z_r);
echo("FEA", "RACK_T", rack_t);
echo("FEA", "RACK_Y1", rack_y1);
echo("FEA", "BIN_XS", bin_xs);
echo("FEA", "BIN_W", bin_w);
echo("FEA", "BIN_Y0", bin_y0);
echo("FEA", "BIN_Y1", bin_y1);
echo("FEA", "CUPS", cups);
echo("FEA", "SHANK_R", keyhole_shank_r(shank_d, keyhole_play));
echo("FEA", "PAD_T", pad_t);
echo("FEA", "CONE", (head_d - shank_d) / 2);
echo("FEA", "FLANGE_R", flange_d / 2);
echo("FEA", "TOP", top);
echo("FEA", "WALL_GAP", wall_gap);
echo("FEA", "BOSS_T", boss_t);
echo("FEA", "BOSS_W", boss_w);
echo("FEA", "PIN_Y", pin_y);
echo("FEA", "ARM_Z", arm_z);
echo("FEA", "PIN_S", pin_s);
echo("FEA", "PIN_LEN", pin_len);
echo("FEA", "SPAN", span);
echo("FEA", "BAR_Y", bar_y);
echo("FEA", "HANDLE_S", handle_s);
