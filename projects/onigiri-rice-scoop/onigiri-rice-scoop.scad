// Onigiri rice scoop: a rounded-triangle cup that holds `grams` of raw rice
// levelled off at the rim, with a handle shaped like a little onigiri with
// a face. You hold it by its nori, like a real one.
// The cup depth is solved from the capacity (grams / rice density), so the
// measure stays exact whatever the size or the rice.
// Print it upside down (rim and handle on the bed): no supports, and the
// face, the nori and the cheeks are 0.6 mm inlays in the first three layers.
// All dimensions in mm.

/* [Rice] */
grams            = 100;        // rice the scoop holds, levelled off at the rim
rice             = "basmati";  // [basmati, integral, custom]
basmati_density  = 0.78;       // g/ml, raw white basmati (about 185 g per US cup)
integral_density = 0.85;       // g/ml, raw brown rice (about 200 g per US cup)
custom_density   = 0.80;       // g/ml, used with rice = "custom"
custom_label     = "ARROZ";    // label on the nori with rice = "custom"
show_label       = true;       // rice name in the nori
bottom_text      = true;       // engrave the dose under the cup

/* [Cup] */
cup_core   = 30;     // side of the sharp triangle the cup is rounded from [10:1:60]
cup_r      = 20;     // corner radius at the rim, seen from above [8:1:30]
floor_r    = 2;      // corner radius at the floor; the walls run down to it at 45°
wall       = 1.68;   // 4 lines
floor_t    = 2;      // 10 layers
foot_r     = 4;      // outside radius between the floor and the walls
rim_c      = 0.4;    // chamfer on the rim (on the bed: hides the elephant foot)

/* [Rice grains] */
grains       = true;   // rice grains in relief all over the outside of the cup
grain_size   = [5.2, 2.4];   // length and width
grain_relief = 0.7;    // how far they stand out
grain_step   = [9, 7]; // spacing around the cup and up it
grain_seed   = 7;      // another number shuffles them

/* [Handle] */
pad_core   = 30;     // side of the sharp triangle the onigiri handle is rounded from
pad_r      = 10;     // its corner radius
neck_l     = 12;     // stick from the cup wall to the onigiri's bottom edge
neck_w     = 14;
handle_t   = 5;      // thickness (25 layers)
handle_r   = 1.6;    // rounding of the underside edges
gusset     = 16;     // 45° rib under the neck, against the cup wall: its reach (FEA: fea/README.md)
gusset_w   = 6.72;   // its width (16 lines)

/* [Face] */
inlay_t    = 0.6;    // inlay depth (3 layers)
eye_d      = 4.4;
eye_gap    = 16;     // between eye centres
eye_shine  = 1.4;    // white highlight in each eye (0 = none)
mouth_r    = 2.2;    // smile radius (centre line)
mouth_w    = 0.9;    // smile stroke
cheek_size = [5.2, 3.4];
cheek_gap  = 25;     // between cheek centres
nori_h     = 13;     // nori band, from the onigiri's bottom edge
label_size = 5;

/* [Colours] */
rice_color  = "#FFFFFF";
nori_color  = "#000000";
cheek_color = "#F55A74";

/* [Render] */
part = "scoop";      // [scoop, body, cavity]

/* [Hidden] */
$fa = 1; $fs = 0.4;
eps = 0.01;

density = rice == "basmati" ? basmati_density
        : rice == "integral" ? integral_density : custom_density;
label = rice == "basmati" ? "BASMATI"
      : rice == "integral" ? "INTEGRAL" : custom_label;
capacity_ml = grams / density;

// Vertices of an equilateral triangle of side s around its centroid, tip at -x.
function tri(s) = [for (a = [180, 60, -60]) s / sqrt(3) * [cos(a), sin(a)]];
function inradius(s) = s / (2 * sqrt(3));

// Plan area of the triangle rounded by t (Steiner): core + perimeter·t + πt².
function area(s, t) = sqrt(3) / 4 * s * s + 3 * s * t + PI * t * t;

// The cavity narrows at 45° from cup_r at the wall to floor_r at the floor,
// so upside down its roof is the small triangle left, bridged in one go.
cham_h   = cup_r - floor_r;
cham_vol = sqrt(3) / 4 * cup_core * cup_core * cham_h
         + 3 * cup_core / 2 * (cup_r * cup_r - floor_r * floor_r)
         + PI / 3 * (pow(cup_r, 3) - pow(floor_r, 3));
H = cham_h + (capacity_ml * 1000 - cham_vol) / area(cup_core, cup_r);   // floor to rim

assert(capacity_ml * 1000 > cham_vol, "cup too wide for the capacity: reduce cup_core or cup_r");
assert(floor_r < cup_r, "floor_r must be smaller than cup_r");

R_out = cup_r + wall;
x_wall = inradius(cup_core) + R_out;                    // the cup's flat back, outside
pad_x  = x_wall + neck_l + inradius(pad_core) + pad_r;  // centroid of the onigiri handle
length = pad_x + pad_core / sqrt(3) + pad_r + cup_core / sqrt(3) + R_out;

echo(str(rice, ": ", grams, " g at ", density, " g/ml = ", capacity_ml, " ml"));
echo(str("Cup ", cup_core + 2 * R_out, " mm wide, inside depth ", H, " mm, total height ",
         H + floor_t, " mm; overall length ", length, " mm"));

// ------------------------------------------------------------ cup

module puck(rr, ff, hh) {   // a cylinder with its bottom edge rounded by ff
    rotate_extrude()
        hull() {
            translate([0, ff]) square([rr, hh - ff]);
            square([max(rr - ff, eps), hh]);
            translate([rr - ff, ff]) circle(ff);
        }
}

module outer_body() {
    hull()
        for (v = tri(cup_core)) translate(v) {
            translate([0, 0, -floor_t]) puck(R_out, foot_r, H + floor_t - rim_c);
            translate([0, 0, H - rim_c]) cylinder(r1 = R_out, r2 = R_out - rim_c, h = rim_c);
        }
}

module cavity(h = H) {
    hull()
        for (v = tri(cup_core)) translate(v) {
            cylinder(r1 = floor_r, r2 = cup_r, h = cham_h);
            translate([0, 0, cham_h]) cylinder(r = cup_r, h = h - cham_h);
        }
}

module rim_flare() {
    hull()
        for (v = tri(cup_core)) translate(v)
            translate([0, 0, H - rim_c])
                cylinder(r1 = cup_r, r2 = cup_r + rim_c + eps, h = rim_c + eps);
}

// A point on the outside of the cup at distance s around it, starting at the
// tip: [x, y, outward normal angle].
seg_l = cup_core + R_out * 2 * PI / 3;
perim = 3 * seg_l;
function around(s0) =
    let(s = (s0 % perim + perim) % perim, i = floor(s / seg_l) % 3, r = s - floor(s / seg_l) * seg_l,
        a = [180, 60, -60][i] - 60, v0 = tri(cup_core)[i], v1 = tri(cup_core)[(i + 1) % 3])
    r < cup_core
        ? concat(v0 + (v1 - v0) * r / cup_core + R_out * [cos(a), sin(a)], a)
        : let(b = a - (r - cup_core) / R_out * 180 / PI) concat(v1 + R_out * [cos(b), sin(b)], b);

module rice_grains() {
    cols = floor(perim / grain_step[0]);
    z0 = -floor_t + foot_r + grain_size[0] / 2;
    z1 = H - rim_c - grain_size[0] / 2 - 1;
    rows = floor((z1 - z0) / grain_step[1]) + 1;
    jit = rands(-0.5, 0.5, 3 * cols * rows, grain_seed);
    s_neck = seg_l + cup_core / 2;   // middle of the back, under the handle
    for (j = [0 : rows - 1], i = [0 : cols - 1]) {
        k = 3 * (j * cols + i);
        s = (i + (j % 2) / 2 + 0.6 * jit[k]) * perim / cols;
        z = min(z1, z0 + j * (z1 - z0) / max(rows - 1, 1) + 0.6 * grain_step[1] * jit[k + 1]);
        p = around(s);
        if (!(abs(s - s_neck) < neck_w / 2 + grain_size[0] && z > H - handle_t - gusset - grain_size[0]))
            translate([p[0], p[1], z]) rotate(p[2])
                translate([grain_relief - grain_size[1] / 2, 0, 0])
                    rotate([90 * jit[k + 2] * 1.6, 0, 0])
                        scale([grain_size[1] / 2, grain_size[1] / 2, grain_size[0] / 2]) sphere(1, $fn = 16);
    }
}

module bottom_engraving() {
    // Read from below: mirrored in y.
    translate([-inradius(cup_core) / 2, 0, -floor_t - eps])
        linear_extrude(inlay_t + eps)
            mirror([0, 1, 0]) rotate(90)
                text(str(grams, " g"), size = 9, halign = "center", valign = "center",
                     font = "Liberation Sans:style=Bold");
}

// ------------------------------------------------------------ handle

// The onigiri, tip away from the cup, around its centroid.
module pad_2d() { rotate(180) offset(r = pad_r) polygon(tri(pad_core)); }

module neck_2d() { translate([x_wall - 2, -neck_w / 2]) square([pad_x - x_wall + 2, neck_w]); }

// A convex 2D shape as a slab with its top (the rim side, on the bed)
// chamfered by rim_c and its underside edges rounded by handle_r.
module soft_slab(t) {
    n = 6;
    hull() {
        for (i = [0 : n]) {
            z = handle_r * (1 - cos(90 * i / n));
            translate([0, 0, z])
                linear_extrude(eps) offset(delta = -handle_r * (1 - sin(90 * i / n))) children();
        }
        translate([0, 0, handle_r]) linear_extrude(t - handle_r - rim_c) children();
        translate([0, 0, t - eps]) linear_extrude(eps) offset(delta = -rim_c) children();
    }
}

module handle() {
    translate([0, 0, H - handle_t]) {
        translate([pad_x, 0, 0]) soft_slab(handle_t) pad_2d();
        soft_slab(handle_t) neck_2d();
    }
    // 45° rib under the neck, against the wall.
    translate([0, 0, H - handle_t])
        rotate([90, 0, 0])
            linear_extrude(gusset_w, center = true)
                polygon([[x_wall - 2, 0], [x_wall + gusset, 0], [x_wall - 2, -gusset - 2]]);
}

// ------------------------------------------------------------ face
// Drawn in the onigiri's own frame: u to the right, v up (away from the
// cup), origin at its centroid.

v_tip  = pad_core / sqrt(3) + pad_r;       // top corner
v_base = -(inradius(pad_core) + pad_r);    // bottom edge
v_nori = v_base + nori_h;

module face_frame() translate([pad_x, 0]) rotate(-90) children();

module eyes_2d() {
    for (s = [-1, 1])
        translate([s * eye_gap / 2, 6])
            difference() {
                scale([1, 1.15]) circle(d = eye_d);
                if (eye_shine > 0)
                    translate([0.25 * eye_d - 0.3, 0.3 * eye_d]) circle(d = eye_shine);
            }
}

module mouth_2d() {
    translate([0, 2.2]) {
        intersection() {
            difference() {
                circle(mouth_r + mouth_w / 2);
                circle(mouth_r - mouth_w / 2);
            }
            translate([-10, -10]) square([20, 10]);
        }
        for (s = [-1, 1]) translate([s * mouth_r, 0]) circle(d = mouth_w);
    }
}

module cheeks_2d() {
    for (s = [-1, 1]) translate([s * cheek_gap / 2, 2.2]) resize(cheek_size) circle(d = 10);
}

module nori_2d() {
    difference() {
        intersection() {
            rotate(90) pad_2d();
            translate([-50, v_base - 1]) square([100, v_nori - v_base + 1]);
        }
        if (show_label)
            translate([0, (v_base + v_nori) / 2 + 0.3])
                offset(0.1)
                    text(label, size = label_size, halign = "center", valign = "center",
                         font = "Liberation Sans:style=Bold");
    }
}

module inlay(top = H) {
    intersection() {
        translate([0, 0, top - inlay_t]) linear_extrude(inlay_t + eps) face_frame() children();
        handle();
    }
}

module black_2d() { eyes_2d(); mouth_2d(); nori_2d(); }

// ------------------------------------------------------------ parts

module body() {
    difference() {
        union() { outer_body(); handle(); if (grains) rice_grains(); }
        translate([0, 0, -eps]) cavity(H + 2 * eps);
        rim_flare();
        if (bottom_text) bottom_engraving();
        translate([0, 0, H - inlay_t]) linear_extrude(1) face_frame() { black_2d(); cheeks_2d(); }
    }
}

if (part == "cavity") {
    cavity(H);
    rim_flare();
}
else if (part == "body") body();
else {
    color(rice_color) body();
    color(nori_color) inlay() black_2d();
    color(cheek_color) inlay() cheeks_2d();
}
