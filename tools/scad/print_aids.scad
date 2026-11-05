// Printing aids: geometry printed with a part and taken off after.

use <basics.scad>

// A stabilizer fin for a thin wall that prints standing: a plate standing
// on the bed in the XZ plane, out along +x from a wall face at x = 0, `gap`
// clear of it. In its own plane the fin is far stiffer than the wall across
// it, so the wall, pushed by the nozzle towards the fin, rests on it after
// `gap`. Fins on both faces of a part hold it both ways. Mirror it for a
// wall face looking along -x.
// With no tabs (tab_h = 0) the fin never touches the part: it lifts off and
// leaves no mark, but has to stand on its own, so give it a flange (a T in
// plan). Tabs every tab_pitch (the first one tab_pitch up) tie it to the
// wall instead, and leave a nub to cut off.
//   h          fin height (the wall's)
//   w          how far it stands out from the wall
//   t          fin thickness (3 lines)
//   gap        between fin and wall
//   flange     width of the flange across the fin's outer edge (0: none)
//   tab_w      tab width along the wall (1 line: it snaps off flush)
//   tab_h      tab height (0: no tabs)
//   tab_pitch  tab spacing up the fin
//   foot_w     width of a rounded foot under the fin, for its grip on the bed
//              (0: none): the bare fin holds on by about 20 mm²
//   foot_h     foot height (whole layers)
//   foot_in    how far the foot starts from the fin's inner end, clear of the wall and what is beside it
module stabilizer_fin(h, w = 20, t = 1.26, gap = 0.3, flange = 0, tab_w = 0.42, tab_h = 0.4, tab_pitch = 20,
                      foot_w = 0, foot_h = 0.6, foot_in = 1.5) {
    box([gap, -t / 2, 0], [gap + w, t / 2, h]);
    if (foot_w > 0) linear_extrude(foot_h) hull()
        for (x = [gap + foot_in + foot_w / 2, gap + w - foot_w / 2]) translate([x, 0]) circle(d = foot_w);
    if (flange > 0) box([gap + w - t, -flange / 2, 0], [gap + w, flange / 2, h]);
    if (tab_h > 0) for (z = [tab_pitch : tab_pitch : h - tab_h])
        box([-0.01, -tab_w / 2, z], [gap + 0.01, tab_w / 2, z + tab_h]);
}
