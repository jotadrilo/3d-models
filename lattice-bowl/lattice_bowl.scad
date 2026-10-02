// =====================================================================
//  Decorative lattice bowl — fully parametric
// ---------------------------------------------------------------------
//  - The wall is a solid of revolution defined by a profile r(z).
//  - Openings are diamonds (squares rotated 45°) laid out in the
//    surface's own coordinates: angle around the axis and arc length
//    along the profile. Each opening is a prism that crosses the wall
//    along the local surface normal, so the pattern wraps the curvature
//    instead of being a straight cut.
//  - Printable without supports: the upper edges of every diamond rise
//    diagonally (no horizontal bridges), the base is flat and the wall
//    flare is checked (see the printability checks at the end).
//
//  Units: millimetres.
//  Export:  openscad -o lattice_bowl.stl lattice_bowl.scad
//           (or `make` in this directory)
// =====================================================================

/* [Bowl shape] */

// Approximate outer diameter at the top rim.
top_diameter = 180;
// Approximate outer diameter at the base (footprint on the bed).
base_diameter = 120;
// Total bowl height.
height = 85;
// Wall profile curvature:
//   1.0 -> straight conical wall
//   >1  -> rounded bowl: flares quickly at the bottom, near vertical at the top
//   <1  -> trumpet: flares more towards the rim (watch the overhangs!)
curvature = 2.6;
// Wall thickness (measured perpendicular to the surface).
wall_thickness = 2.4;
// Solid floor thickness.
floor_thickness = 2.0;

/* [Lattice] */

// Width of the lattice rods (measured perpendicular to the rod).
rod_width = 1.0;
// Approximate side of each square opening (rotated 45°), measured at
// mid-height. Also sets the spacing: pitch = opening + rod.
opening_size = 4;
// Vertical stretch of the openings (diamond height / width).
//   1.0 = perfect square at 45°; >1 = taller diamonds with steeper edges,
//   which are easier to print without supports.
opening_stretch = 1.25;
// Subdivisions per diamond side. More = the outline hugs the curvature
// more closely (slower to render).
side_subdivisions = 3;

/* [Solid bands] */

// Height (along the wall) of the solid top rim that adds stiffness.
top_rim_height = 6;
// Height (along the wall) of the solid bottom band joined to the floor.
bottom_band_height = 5;

/* [Quality] */

// Profile segments (vertical resolution of the wall).
profile_steps = 80;
// Segments around the axis.
$fn = 180;

// =====================================================================
//  Derived geometry (no need to edit below this line)
// =====================================================================

r_base = base_diameter / 2 - wall_thickness / 2;    // mid-surface radius
r_top  = top_diameter / 2 - wall_thickness / 2;

// --- Wall mid-surface profile: r(z) and its slope dr/dz ---
function r_at_z(z) =
    let(t = min(max(z / height, 0), 1))
    r_base + (r_top - r_base) * (1 - pow(1 - t, curvature));

function drdz(z) =
    let(t = min(max(z / height, 0), 1 - 1e-6))
    (r_top - r_base) * curvature * pow(1 - t, curvature - 1) / height;

// Wall tilt from vertical (degrees).
function tilt(z) = atan(drdz(z));

// --- Arc length along the profile: table of [s, z] ---
dz_step = height / profile_steps;
function _accumulate(i, s = 0, out = []) =
    i > profile_steps ? out :
    let(z  = i * dz_step,
        ds = i == 0 ? 0 : norm([r_at_z(z) - r_at_z(z - dz_step), dz_step]))
    _accumulate(i + 1, s + ds, concat(out, [[s + ds, z]]));

s_z_table = _accumulate(0);
s_total   = s_z_table[len(s_z_table) - 1][0];
function z_at_s(s) = lookup(s, s_z_table);

// 3D point on the mid-surface offset by `d` along the normal
// (d > 0 = outwards). ang in degrees, s = arc length.
function surface_point(ang, s, d) =
    let(z   = z_at_s(s),
        phi = tilt(z),
        r   = r_at_z(z) + d * cos(phi),
        zz  = z - d * sin(phi))
    [r * cos(ang), r * sin(ang), zz];

// --- Lattice layout ---
s_min = bottom_band_height + floor_thickness;       // start of perforated zone
s_max = s_total - top_rim_height;                   // end of perforated zone
r_ref = r_at_z(z_at_s((s_min + s_max) / 2));        // reference radius

// Diamond grid: diagonal neighbours at (±H, ±V) in (arc, arc length).
// For a 45° square of side L and rods of width w: H = (L + w) / √2.
H_ref   = (opening_size + rod_width) / sqrt(2);
columns = max(3, round(PI * r_ref / H_ref));        // openings per row
V       = opening_stretch * PI * r_ref / columns;   // vertical pitch between rows

// Opening factor: fraction of the half-pitch left open so that the rod
// (perpendicular to the diamond edge) is exactly rod_width wide.
function open_factor(H) = 1 - rod_width * sqrt(1 / (H * H) + 1 / (V * V)) / 2;

b_ref  = V * open_factor(PI * r_ref / columns);     // diamond half-height
zone   = s_max - s_min;
rows   = max(0, floor((zone - 2 * b_ref) / V) + 1);
slack  = zone - ((rows - 1) * V + 2 * b_ref);
s_row0 = s_min + b_ref + slack / 2;

// --- One opening: diamond-outlined prism that follows the surface ---
module opening(ang_c, s_c) {
    r_c   = r_at_z(z_at_s(s_c));
    f     = open_factor(PI * r_c / columns);
    a_ang = (180 / columns) * f;          // angular half-width (degrees)
    b_s   = V * f;                        // half-height in arc length
    m     = side_subdivisions;
    // Unit diamond, counter-clockwise as seen from outside the bowl.
    corners = [[1, 0], [0, 1], [-1, 0], [0, -1]];
    outline = [for (k = [0:3], j = [0:m - 1])
                   let(p = corners[k], q = corners[(k + 1) % 4], t = j / m)
                   p + (q - p) * t];
    n  = len(outline);
    d  = wall_thickness / 2 + 0.5;        // cut through the wall with margin
    uv = [for (p = outline) [ang_c + p[0] * a_ang, s_c + p[1] * b_s]];
    pts = concat(
        [for (p = uv) surface_point(p[0], p[1], -d)],   // inner ring
        [for (p = uv) surface_point(p[0], p[1],  d)],   // outer ring
        [surface_point(ang_c, s_c, -d),                 // inner centre
         surface_point(ang_c, s_c,  d)]);               // outer centre
    ci = 2 * n; co = 2 * n + 1;
    faces = concat(
        [for (k = [0:n - 1]) let(k1 = (k + 1) % n) [ci, k, k1]],
        [for (k = [0:n - 1]) let(k1 = (k + 1) % n) [co, n + k1, n + k]],
        [for (k = [0:n - 1]) let(k1 = (k + 1) % n) [k, n + k, n + k1]],
        [for (k = [0:n - 1]) let(k1 = (k + 1) % n) [k, n + k1, k1]]);
    polyhedron(points = pts, faces = faces, convexity = 4);
}

module openings() {
    for (i = [0:rows - 1], j = [0:columns - 1])
        opening((j + (i % 2) / 2) * 360 / columns, s_row0 + i * V);
}

// --- Solid wall between heights z0..z1 (constant normal thickness) ---
module wall(z0, z1) {
    n  = max(2, ceil((z1 - z0) / dz_step));
    zs = [for (i = [0:n]) z0 + (z1 - z0) * i / n];
    outer = [for (z = zs) [r_at_z(z) + wall_thickness / 2 / cos(tilt(z)), z]];
    inner = [for (i = [n:-1:0]) let(z = zs[i])
                [r_at_z(z) - wall_thickness / 2 / cos(tilt(z)), z]];
    rotate_extrude(convexity = 6) polygon(concat(outer, inner));
}

module bowl() {
    z_band = z_at_s(s_min);
    z_rim  = z_at_s(s_max);
    union() {
        difference() {
            wall(0, height);
            if (rows > 0) openings();
        }
        // Solid bands are added afterwards so their height is exact.
        wall(0, z_band);
        wall(z_rim, height);
        // Floor.
        cylinder(r = r_base + wall_thickness / 2 / cos(tilt(0)),
                 h = floor_thickness);
    }
}

bowl();

// =====================================================================
//  Printability checks (see console output)
// =====================================================================
max_tilt = max([for (i = [0:profile_steps]) tilt(i * dz_step)]);

// Angle from horizontal of the faces under the rods (the upper edges of
// each diamond). This is what the slicer sees as overhang: the face holds
// the edge (angle β within the wall plane) and the wall normal (tilted φ),
// so its normal has n_z = cos β · cos φ.
function face_angle(i) =
    let(s    = s_row0 + i * V,
        z    = z_at_s(s),
        H    = PI * r_at_z(z) / columns,
        beta = atan(V / H))
    acos(cos(beta) * cos(tilt(z)));
min_face = rows < 1 ? 90 : min([for (i = [0:rows - 1]) face_angle(i)]);

echo(str("Openings: ", rows, " rows x ", columns, " columns"));
echo(str("Max wall tilt: ", max_tilt, " deg from vertical"));
echo(str("Min overhang face angle: ", min_face, " deg above horizontal"));
if (max_tilt > 50)
    echo("WARNING: wall flares too much (>50 deg). Lower 'curvature' or the diameter difference.");
if (min_face < 45)
    echo("WARNING: faces above the openings are too flat (<45 deg). Raise 'opening_stretch'.");
assert(rows >= 1, "No row of openings fits: reduce the solid bands or opening_size");
assert(rod_width < H_ref, "rod_width too large for opening_size");
