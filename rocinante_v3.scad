// MCRN Corvette-class "Tachi" (Rocinante) - v3, high detail
//
// Hand-built from primitives, with positions and sizes measured on the orthographic views
// in views/. The orange livery, white markings and yellow lights are traced from the
// views' pixels and projected onto the hull: the views are orthographic, so every traced
// shape lands where it was drawn. All dimensions are source-drawing pixels (632 px = 46 m,
// engine bell to antenna tip); the model is scaled to ship_length at the end.
//
// Axes: Z = ship axis, engine bell at z = 0, nose up.
//       +Y = side shown in the "front" view (MCRN logo, upper airlock, torpedo tube 1)
//       -Y = "back" view side (landing thrusters, torpedo tube 2)
//       -X = "left" view side (lower airlock), +X = "right" view side (mirror of the left)

ship_length = 150;      // mm, engine bell to antenna tip
min_rod = 0.6;          // mm, thinnest rod/barrel diameter (keeps antennas printable)
use_colors = true;      // colors show in preview, render and 3MF export
livery = true;          // traced orange livery, white markings and yellow lights
decal_height = 1.0;     // px the livery stands proud of the hull

/* [Hidden] */
SRC = 632;              // source length, px
K = ship_length / SRC;  // mm per px
$fn = 32;

HULL_DARK = "#3b3e43";
ORANGE    = "#c5562b";
STEEL     = "#9ea2a7";
BLACK     = "#202225";
YELLOW    = "#e8c22a";
WHITE     = "#e4e4e4";

// --------------------------------------------------------------------------------------
// Hull stations: [z, xa, ylo, yhi, k]
//   xa      half height in X (keel flats sit at X = +-xa)
//   ylo/yhi Y extent (side flats sit at Y = ylo / yhi)
//   k       octagon shape: |X|/xa + |Y-yc|/bh <= k; 1.41 = regular octagon, 1.24 =
//           the truncated rhombus seen in the nose-on view
// --------------------------------------------------------------------------------------
HULL = [
    // aft section (behind the drum)
    [141, 59, -62, 62, 1.41],
    [250, 61, -60, 60, 1.41],
    // shoulders up to the main hull
    [256, 64, -60, 60, 1.30],
    [265, 72, -65, 65, 1.26],
    [274, 76, -71, 71, 1.24],
    [296, 78, -73, 73, 1.24],
    [304, 88, -73, 73, 1.24],
    // main hull (PDC section)
    [364, 88, -72, 72, 1.24],
    [372, 81, -66, 66, 1.24],
    [377, 79, -60, 60, 1.24],
    [382, 68, -55, 54, 1.24],
    // forward hull
    [386, 62, -51, 51, 1.24],
    [392, 62, -47, 45, 1.24],
    [396, 62, -47, 42, 1.24],
    [424, 62, -47, 42, 1.24],
    [434, 62, -47, 47, 1.24],
    [456, 57, -42, 48, 1.24],
    // nose
    [470, 54, -38, 44, 1.24],
    [480, 50, -33, 42, 1.24],
    [495, 44, -28, 34, 1.24],
    [510, 38, -24, 27, 1.24],
    [525, 34, -20, 23, 1.24],
    [540, 27, -17, 16, 1.24],
    [550, 20, -15,  9, 1.24],
    [556, 14, -12,  5, 1.24],
    [561,  5,  -9, -2, 1.24],
];

DRUM_AFT = [83, 61, -61, 61, 1.414];
DRUM_FWD = [91, 66, -66, 66, 1.414];

function oct_pts(s) =
    let (xa = s[1], ylo = s[2], yhi = s[3], k = s[4],
         bh = (yhi - ylo) / 2, yc = (yhi + ylo) / 2, kw = (k - 1) * bh, sw = (k - 1) * xa)
    [[xa, yc + kw], [sw, yhi], [-sw, yhi], [-xa, yc + kw],
     [-xa, yc - kw], [-sw, ylo], [sw, ylo], [xa, yc - kw]];

function _seg(S, z, i = 0) = (i >= len(S) - 2 || S[i + 1][0] > z) ? i : _seg(S, z, i + 1);
function sec_at(S, z) =
    let (i = _seg(S, z), a = S[i], b = S[i + 1],
         t = min(1, max(0, (z - a[0]) / (b[0] - a[0]))))
    [z, for (j = [1:4]) a[j] + (b[j] - a[j]) * t];

// Y of the upper / lower hull surface at a given X
function y_top(s, x) =
    let (xa = s[1], ylo = s[2], yhi = s[3], k = s[4], bh = (yhi - ylo) / 2,
         yc = (yhi + ylo) / 2, kw = (k - 1) * bh, sw = (k - 1) * xa, ax = abs(x))
    ax <= sw ? yhi : yhi - (ax - sw) * (yhi - (yc + kw)) / (xa - sw);
function y_bot(s, x) =
    let (xa = s[1], ylo = s[2], yhi = s[3], k = s[4], bh = (yhi - ylo) / 2,
         yc = (yhi + ylo) / 2, kw = (k - 1) * bh, sw = (k - 1) * xa, ax = abs(x))
    ax <= sw ? ylo : ylo + (ax - sw) * ((yc - kw) - ylo) / (xa - sw);

// mid point and outward normal of the +X/+Y corner face of a section
function corner_face(s) =
    let (xa = s[1], ylo = s[2], yhi = s[3], k = s[4], bh = (yhi - ylo) / 2,
         yc = (yhi + ylo) / 2, kw = (k - 1) * bh, sw = (k - 1) * xa,
         p1 = [xa, yc + kw], p2 = [sw, yhi])
    [[(p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2], [p2[1] - p1[1], p1[0] - p2[0]]];

module slab(s, d = 0)
    translate([0, 0, s[0]]) linear_extrude(0.01) offset(delta = d) polygon(oct_pts(s));

// Hull lofted between stations, optionally only over [z0, z1] and grown by d
module loft(S, z0 = -1e9, z1 = 1e9, d = 0) {
    a = max(z0, S[0][0]);
    b = min(z1, S[len(S) - 1][0]);
    st = concat([sec_at(S, a)], [for (s = S) if (s[0] > a && s[0] < b) s], [sec_at(S, b)]);
    for (i = [0:len(st) - 2])
        hull() { slab(st[i], d); slab(st[i + 1], d); }
}

module drum_body(d = 0) {
    hull() { slab(DRUM_AFT, d); slab(DRUM_FWD, d); }
    translate([0, 0, 91]) linear_extrude(38) offset(delta = d) polygon(oct_pts(DRUM_FWD));
}

// Outer skin of drum and hull, grown by h (surface for projected panels and livery)
module skin(h) { loft(HULL, d = h); drum_body(h); }

// Raised panel: the hull skin grown by h, kept only inside an axis-aligned box
module plate(z0, z1, x0, x1, y0, y1, h = 1.2)
    intersection() {
        loft(HULL, z0, z1, h);
        translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]);
    }

// Recessed band (for subtracting): depth d into the hull inside a box (d < 0 trims raised plates)
module recess(z0, z1, x0, x1, y0, y1, d = 1)
    intersection() {
        difference() { loft(HULL, z0, z1, 6); loft(HULL, z0 - 1, z1 + 1, -d); }
        translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]);
    }

// Panel line all the way around the hull
module ring_groove(z, w = 1.4, d = 1) recess(z, z + w, -200, 200, -200, 200, d);

// Which view owns which faces: the keel flats belong to the side views, everything else
// (side flats and corner faces, which face Y more than X) to the front and back views.
// Drawings disagree at grazing angles, so each face takes its livery from one view only.
ZONE = concat([DRUM_AFT, DRUM_FWD, [140.9, 66, -66, 66, 1.414]], HULL);

function zone_pts(s, axis, side) =
    let (xa = s[1], ylo = s[2], yhi = s[3], k = s[4], bh = (yhi - ylo) / 2,
         yc = (yhi + ylo) / 2, kw = (k - 1) * bh)
    axis == "x"
        ? [[side * (xa - 4), yc - kw - 0.5], [side * (xa + 40), yc - kw - 0.5],
           [side * (xa + 40), yc + kw + 0.5], [side * (xa - 4), yc + kw + 0.5]]
        : [[-300, yc + side * (kw - 0.5)], [300, yc + side * (kw - 0.5)], [300, side * 300], [-300, side * 300]];

module zone(axis, side)
    for (i = [0:len(ZONE) - 2]) hull()
        for (s = [ZONE[i], ZONE[i + 1]]) translate([0, 0, s[0]]) linear_extrude(0.01) polygon(zone_pts(s, axis, side));

// 2D shapes drawn in a view, projected onto the skin grown by h.
// on_y: children in (X, Z), side +1 = +Y (front view), -1 = -Y (back view)
// on_x: children in (Y, Z), side -1 = -X (left view), +1 = +X (right view)
// zoned: keep only the faces this view owns (see ZONE)
module on_y(side, h, zoned = false)
    intersection() {
        skin(h);
        rotate([90, 0, 0]) linear_extrude(height = 400, center = true) children();
        translate([-300, side > 0 ? 0 : -300, -20]) cube([600, 300, 700]);
        if (zoned) zone("y", side);
    }
module on_x(side, h, zoned = false)
    intersection() {
        skin(h);
        rotate([90, 0, 90]) linear_extrude(height = 400, center = true) children();
        translate([side > 0 ? 0 : -300, -300, -20]) cube([300, 600, 700]);
        if (zoned) zone("x", side);
    }

// --------------------------------------------------------------------------------------
// Small helpers
// --------------------------------------------------------------------------------------
function rr(r) = max(r, min_rod / 2 / K);   // rod radius, never thinner than min_rod

module rod(p1, p2, r) hull() { translate(p1) sphere(rr(r), $fn = 12); translate(p2) sphere(rr(r), $fn = 12); }
module seg2d(p1, p2, w) hull() { translate(p1) circle(d = w, $fn = 12); translate(p2) circle(d = w, $fn = 12); }

module paint(c) if (use_colors) color(c) children(); else children();

// Local frame: origin o, local +X along x, local +Z along z
module frame(o, x, z) {
    y = cross(z, x);
    multmatrix([[x[0], y[0], z[0], o[0]], [x[1], y[1], z[1], o[1]], [x[2], y[2], z[2], o[2]], [0, 0, 0, 1]])
        children();
}

// Orient children so local +Z points along the outward normal n (in the XY plane);
// local +X then points aft (-Z)
module on_face(p, n) translate(p) rotate([0, 0, atan2(n[1], n[0])]) rotate([0, 90, 0]) children();

// Octagonal hatch frame, local +Z outward
module hatch_frame(r_out, r_in, h = 1.5)
    rotate([0, 0, 22.5]) difference() {
        cylinder(r = r_out / cos(22.5), h = h, $fn = 8);
        translate([0, 0, -1]) cylinder(r = r_in / cos(22.5), h = h + 2, $fn = 8);
    }

// Hatch door detail on a recessed door face, local +Z outward: hub and n spokes
module door_spokes(r, n)
    paint(STEEL) {
        cylinder(r = r * 0.25, h = 1.2, $fn = 16);
        for (a = [0:360 / n:359]) rotate(a + 360 / n / 2) translate([r * 0.2, -0.75, 0]) cube([r * 0.75, 1.5, 1]);
    }

// --------------------------------------------------------------------------------------
// Engine
// --------------------------------------------------------------------------------------
BELL_OUT = [[46.5, 57], [46.5, 45], [49, 40], [51.5, 32], [53, 24], [54, 14], [55, 12], [55, 8], [54.5, 1]];

module engine_bell() {
    paint(STEEL) rotate_extrude($fn = 96) polygon(concat(BELL_OUT, [
        [51, 1],                                            // rim
        [44, 8], [36, 17], [28, 26], [20, 35], [12, 43], [6, 47], [0, 48], [0, 57]]));
    paint(STEEL) {
        // stiffening bands on the outside of the bell
        for (z = [17, 29]) translate([0, 0, z])
            rotate_extrude($fn = 96) translate([54 - (z - 14) * 0.17, 0]) square([1.2, 2]);
        // concentric cooling rings inside the nozzle (seen from below), central plug
        for (r = [36, 30, 18]) rotate_extrude($fn = 96) translate([r - 1, 25 - (r - 30) * 0.9 - 2]) square([2, 3]);
        translate([0, 0, 41]) cylinder(h = 7, r1 = 1, r2 = 5);
        // rim bolts
        for (a = [5:10:355]) rotate(a) translate([54.6, 0, 10]) rotate([0, 90, 0]) cylinder(r = 0.7, h = 1, $fn = 8);
    }
    // panel ribs along the outside of the bell
    paint(STEEL) for (a = [0:15:345]) rotate(a)
        for (i = [1:4]) hull() for (q = [BELL_OUT[i], BELL_OUT[i + 1]]) translate([q[0] - 0.3, -0.6, q[1]]) cube([1.1, 1.2, 0.5]);
    // gimbal pads around the rim, 60 degrees apart, with their actuators
    paint(BLACK) for (a = [0:60:300]) rotate(a) {
        hull() for (y = [-5, 5]) translate([50.5, y, 0]) cylinder(r = 3, h = 9);
        rod([53.5, 0, 6], [54.5, 0, 20], 1.2);
        translate([52, -2, 9]) cube([4, 4, 3]);
    }
}

module thrust_structure() {
    paint(HULL_DARK) translate([0, 0, 45]) cylinder(h = 40, r1 = 44, r2 = 58, $fn = 64);
    paint(STEEL) translate([0, 0, 47]) rotate_extrude($fn = 64) translate([45, 0]) square([2.5, 5]);   // gimbal ring
    // struts from the bell neck to the drum
    paint(BLACK) for (a = [0:30:330]) {
        rod([46 * cos(a + 12), 46 * sin(a + 12), 52], [60 * cos(a), 60 * sin(a), 84], 1.3);
        rod([46 * cos(a - 12), 46 * sin(a - 12), 52], [60 * cos(a), 60 * sin(a), 84], 1.3);
    }
    // gimbal actuators: cylinder body plus piston rod
    for (a = [45:90:315]) {
        p1 = [50.5 * cos(a), 50.5 * sin(a), 30];
        p2 = [57 * cos(a), 57 * sin(a), 84];
        paint(BLACK) rod(p1, p1 + (p2 - p1) * 0.55, 2.3);
        paint(STEEL) rod(p1, p2, 1.2);
    }
}

module drum() {
    paint(HULL_DARK) drum_body();
    // forward flange with a bolt row on every face
    paint(STEEL) {
        translate([0, 0, 128]) linear_extrude(13) polygon(oct_pts([0, 68.5, -68.5, 68.5, 1.414]));
        for (a = [0:45:315], o = [-21, -7, 7, 21]) rotate(a) translate([68.4, o, 134.5]) rotate([0, 90, 0]) cylinder(r = 0.9, h = 1, $fn = 8);
    }
    // corner ribs, aft-face brackets
    paint(BLACK) for (a = [45:90:315]) rotate(a) translate([64.5, -2, 86]) cube([3, 4, 42]);
    paint(STEEL) for (a = [45:90:315]) rotate(a) translate([48, -5, 77]) cube([12, 10, 8]);
    // panel seams on the drum faces
    paint(BLACK) for (a = [0:45:315]) rotate(a) translate([65.3, -0.5, 92]) cube([1.2, 1, 36]);
}

// --------------------------------------------------------------------------------------
// Point defence cannons (6): two on the main hull keels, two aft, two at the nose
// --------------------------------------------------------------------------------------

// Six-barrel gun along local +X, from its mantlet at the origin
module gatling(gl) {
    paint(BLACK) { sphere(r = 3.4, $fn = 20); rotate([0, 90, 0]) cylinder(r = 2.8, h = gl * 0.35); }
    paint(STEEL) rotate([0, 90, 0]) {
        cylinder(r = 1.2, h = gl);
        for (a = [0:60:300]) rotate(a) translate([1.7, 0, gl * 0.3]) cylinder(r = 0.7, h = gl * 0.7, $fn = 8);
        translate([0, 0, gl * 0.62]) cylinder(r = 2.5, h = 1, $fn = 16);
        translate([0, 0, gl - 1.4]) cylinder(r = 2.6, h = 1.4, $fn = 16);
    }
}

// Turret in a local frame: z = up off the hull, x = gun azimuth. len/wid/ht: housing size,
// (px, pz): gun pivot, elev: gun elevation, gl: gun length from the pivot
module pdc_turret(len, wid, ht, px, pz, elev, gl) {
    ring_r = wid * 0.58;
    paint(STEEL) {
        cylinder(r = ring_r, h = 2, $fn = 48);
        for (a = [0:30:330]) rotate(a) translate([ring_r - 1.3, 0, 2]) cylinder(r = 0.8, h = 0.8, $fn = 8);
    }
    paint(BLACK) hull() {
        translate([-len / 2, -wid / 2, 1.5]) cube([len, wid, ht * 0.45]);
        translate([-len / 2 + 1, -wid / 2 + 1.5, 1.5]) cube([len * 0.5, wid - 3, ht - 1.5]);
        translate([len / 2 - wid * 0.32, 0, ht * 0.5]) rotate([90, 0, 0]) cylinder(r = wid * 0.32, h = wid - 2, center = true);
    }
    // side armour plates, sensor head, ammunition feed chute
    paint(HULL_DARK) for (s = [-1, 1])
        translate([-len * 0.35, s * (wid / 2 + 0.4) - 0.6, ht * 0.12]) cube([len * 0.6, 1.2, ht * 0.32]);
    paint(STEEL) translate([-len / 2 + 3, -wid * 0.25, ht - 0.5]) {
        cube([len * 0.22, wid * 0.5, 2.5]);
        translate([len * 0.11, wid * 0.25, 2.5]) sphere(r = wid * 0.14, $fn = 16);
    }
    paint(BLACK) translate([-len * 0.3, -wid / 2 - 2, ht * 0.25]) rotate([0, 90, 0]) cylinder(r = 2.4, h = len * 0.45);
    translate([px, 0, pz]) rotate([0, -elev, 0]) gatling(gl);
}

module pdc_pedestal_main()      // on the +X keel, with pylons fore and aft of the turret
    paint(BLACK) {
        hull() { translate([86, -14, 312]) cube([10, 28, 48]); translate([86, -10, 305]) cube([3, 20, 62]); }
        for (z = [305, 357]) translate([86, -10, z]) cube([11, 20, 9]);
    }
module pdc_pedestal_aft()       // on the +Y face of the aft section
    paint(BLACK) hull() { translate([-14, 58, 156]) cube([28, 11, 44]); translate([-10, 58, 150]) cube([20, 4, 56]); }
module pdc_pedestal_nose()      // on the +X side of the nose
    paint(BLACK) hull() { translate([40, -6, 481]) cube([18, 12, 17]); translate([40, -4, 477]) cube([4, 8, 24]); }

module pdcs() {
    for (m = [0, 1]) mirror([m, 0, 0]) {
        pdc_pedestal_main();
        frame([95.5, 0, 340], [0, 0, 1], [1, 0, 0]) pdc_turret(36, 24, 28.5, 7, 17.5, 90, 28);
        pdc_pedestal_nose();
        frame([57.5, 0, 487], [0, 0, 1], [1, 0, 0]) pdc_turret(23, 16, 17.5, 4, 6.5, 0, 27);
    }
    for (m = [0, 1]) mirror([0, m, 0]) {
        pdc_pedestal_aft();
        frame([0, 68.5, 184], [0, 0, -1], [0, 1, 0]) pdc_turret(28, 22, 27.5, 6, 15.5, 0, 25);
    }
}

// --------------------------------------------------------------------------------------
// Torpedo tubes, airlocks, thrusters
// --------------------------------------------------------------------------------------
module torpedo_tube_housing()          // +Y shoulder, muzzle facing forward
    paint(BLACK) translate([3, 61, 336]) rotate(30) cylinder(r = 10, h = 46, $fn = 6);
module torpedo_tube_muzzle()           // hex muzzle ring proud of the housing face
    paint(STEEL) translate([3, 61, 381]) rotate(30) difference() {
        cylinder(r = 10.8, h = 2, $fn = 6);
        translate([0, 0, -1]) cylinder(r = 7.5, h = 4, $fn = 6);
    }
module torpedo_tube_bore()
    translate([3, 61, 368]) cylinder(r = 5.5, h = 20, $fn = 24);

module lower_airlock_frames()          // on both X faces of the aft section
    paint(ORANGE) for (m = [0, 1]) mirror([m, 0, 0])
        translate([59, 0, 180]) rotate([0, 90, 0]) hatch_frame(21, 16, 3);
module lower_airlock_doors()
    for (m = [0, 1]) mirror([m, 0, 0])
        translate([58.8, 0, 180]) rotate([0, 90, 0]) rotate(22.5) cylinder(r = 16 / cos(22.5), h = 4, $fn = 8);

module upper_airlock_frame()           // +Y flat of the forward hull
    paint(STEEL) translate([0, 41, 408]) rotate([-90, 0, 0]) hatch_frame(12.5, 9, 2.8);
module upper_airlock_door()
    translate([0, 40.8, 408]) rotate([-90, 0, 0]) rotate(22.5) cylinder(r = 9 / cos(22.5), h = 4, $fn = 8);

module airlock_details() {
    for (m = [0, 1]) mirror([m, 0, 0]) {
        translate([58.8, 0, 180]) rotate([0, 90, 0]) door_spokes(16, 6);
        // handrails either side of the hatch
        paint(STEEL) for (y = [-24, 24]) {
            rod([61.4, y, 166], [61.4, y, 194], 0.7);
            for (z = [166, 194]) rod([59.2, y, z], [61.4, y, z], 0.7);
        }
    }
    translate([0, 40.8, 408]) rotate([-90, 0, 0]) door_spokes(9, 4);
    paint(STEEL) for (x = [-13.5, 13.5]) {
        rod([x, 43.6, 396], [x, 43.6, 420], 0.7);
        for (z = [396, 420]) rod([x, 41.5, z], [x, 43.6, z], 0.7);
    }
}

// Horizontal landing thrusters: 8 nozzles on the -Y side, pointing -Y
module landing_thruster(x, z, sunk = 0) {
    y = y_bot(sec_at(HULL, z), x) + sunk;
    translate([x, y, z]) rotate([90, 0, 0]) {
        paint(BLACK) translate([-5, -5, -6]) cube([10, 10, 8]);
        paint(STEEL) difference() {
            translate([0, 0, 2]) cylinder(h = 4, r1 = 2.5, r2 = 3.8);
            translate([0, 0, 3]) cylinder(h = 4, r1 = 1.5, r2 = 3);
        }
    }
}
module landing_thrusters() {
    for (x = [-41, 41], z = [159, 424]) landing_thruster(x, z);
    for (x = [-60, 60], z = [271, 291]) landing_thruster(x, z, 3);   // in the shoulder bays
}

// Control (RCS) thruster quad: local +Z outward, nozzles fore, aft and to both sides
module rcs_quad() {
    paint(BLACK) translate([-4, -4, -3]) cube([8, 8, 6]);
    paint(STEEL) for (r = [[0, 90, 0], [0, -90, 0], [90, 0, 0], [-90, 0, 0]])
        rotate(r) translate([0, 0, 4]) cylinder(h = 2.5, r1 = 1, r2 = 1.8, $fn = 12);
}

module control_thrusters() {
    // 4 around the aft section, 4 at the main hull shoulders, 3 at the nose = 11
    for (z = [222, 368]) {
        f = corner_face(sec_at(HULL, z));
        for (mx = [0, 1], my = [0, 1]) mirror([mx, 0, 0]) mirror([0, my, 0])
            on_face([f[0][0], f[0][1], z], f[1]) rcs_quad();
    }
    for (m = [0, 1]) mirror([m, 0, 0]) translate([sec_at(HULL, 540)[1], 0, 540]) rotate([0, 90, 0]) rcs_quad();
    translate([0, y_bot(sec_at(HULL, 552), 0), 552]) rotate([90, 0, 0]) rcs_quad();
}

// --------------------------------------------------------------------------------------
// Nose: comm array boom and antennas
// --------------------------------------------------------------------------------------
module comm_array() {
    paint(HULL_DARK) difference() {
        hull() {
            translate([12, -34, 478]) cube([22, 8, 1]);
            translate([12, -36, 498]) cube([25, 12, 62]);
            translate([24, -35, 591]) cube([12, 10, 1]);
        }
        for (z = [522, 546, 570]) difference() {                                 // segment joints
            translate([0, -50, z]) cube([60, 40, 1.2]);
            translate([13.2, -34.8, z - 1]) cube([22.6, 9.6, 3.2]);
        }
    }
    paint(STEEL) {
        translate([30, -30, 586]) sphere(r = 4.5, $fn = 20);                  // sensor pod
        rod([30, -30, 590], [30, -30, 631], 1.4);
        rod([30, -30, 600], [30, -30, 621], 2.4);
        for (z = [604, 614]) translate([30, -30, z]) cylinder(r = rr(3.2), h = 1.2, $fn = 16);
        translate([30, -30, 626]) cylinder(h = 3, r1 = rr(3.5), r2 = rr(1.2));
        for (a = [0, 90]) translate([30, -30, 624]) rotate(a) cube([7, 1.2, 2], center = true);
        // short rods under the nose
        rod([-14, -30, 549], [-14, -30, 606], 1.3);
        rod([-22, -30, 549], [-22, -30, 596], 1.3);
        rod([-14, -30, 590], [-14, -30, 600], 2.2);
        rod([-22, -30, 584], [-22, -30, 591], 2.0);
    }
    paint(HULL_DARK) translate([-26, -34, 545]) cube([40, 7, 9]);
}

// --------------------------------------------------------------------------------------
// Hull: raised panels, greebles traced from the views, cut details
// --------------------------------------------------------------------------------------
// Raised blocks drawn in a view: [z0, z1, u0, u1, height, colour]
// (u = X for the +-Y views, u = Y for the left view, which is mirrored onto +X)
BLOCKS_FRONT = [                      // +Y
    [203, 218,  22,  40, 2.5, STEEL], [203, 218, -40, -22, 2.5, STEEL],   // aft equipment boxes
    [226, 236,  22,  31, 2.0, BLACK], [226, 236, -31, -22, 2.0, BLACK],   // RCS housings
    [258, 286,  44,  64, 1.5, BLACK], [258, 286, -64, -44, 1.5, BLACK],   // shoulder plates
    [286, 346, -19,  19, 0.8, BLACK],                                     // centre plate (MCRN)
    [440, 452,  -6,   6, 1.6, STEEL],                                     // box in the forward recess
];
BLOCKS_BACK = [                       // -Y
    [256, 300,  45,  49, 1.5, STEEL], [256, 300, -49, -45, 1.5, STEEL],   // louvres over the bays
    [226, 236,  22,  31, 2.0, BLACK], [226, 236, -31, -22, 2.0, BLACK],
    [286, 346, -19,  19, 0.8, BLACK],                                     // centre plate (NAVY)
];
BLOCKS_LEFT = [                       // -X and +X
    [210, 236,  22,  36, 2.5, STEEL], [210, 236, -36, -22, 2.5, STEEL],   // aft equipment boxes
];

module blocks() {
    for (b = BLOCKS_FRONT) paint(b[5]) on_y(1, b[4]) translate([b[2], b[0]]) square([b[3] - b[2], b[1] - b[0]]);
    for (b = BLOCKS_BACK) paint(b[5]) on_y(-1, b[4]) translate([b[2], b[0]]) square([b[3] - b[2], b[1] - b[0]]);
    for (s = [-1, 1], b = BLOCKS_LEFT) paint(b[5]) on_x(s, b[4]) translate([b[2], b[0]]) square([b[3] - b[2], b[1] - b[0]]);
}

// Armour chevrons ahead of the main hull keels (front and back views)
module chevrons() paint(STEEL) {
    on_y(1, 1.3) for (s = [-1, 1]) seg2d([s * 72, 338], [s * 24, 376], 5);
    on_y(-1, 1.6) {
        for (s = [-1, 1]) seg2d([s * 32, 366], [s * 14, 353], 4);
        seg2d([-14, 353], [14, 353], 4);
    }
}

module hull_body() paint(HULL_DARK) loft(HULL);

module hull_plates() {
    // collar where the aft section leaves the drum
    paint(STEEL) plate(141, 149, -200, 200, -200, 200, 1.5);
    // aft corner strips
    paint(BLACK) for (x = [-46, 38]) plate(150, 248, x, x + 8, -200, 200, 1.2);
    // connector blocks between aft section and main hull (+-Y)
    paint(ORANGE) for (m = [0, 1]) mirror([0, m, 0])
        hull() { translate([-12, 55, 240]) cube([24, 12, 20]); translate([-10, 55, 238]) cube([20, 10, 47]); }
    // grilles on the four corner faces of the main hull
    paint(STEEL) for (mx = [0, 1], my = [0, 1]) mirror([mx, 0, 0]) mirror([0, my, 0])
        plate(306, 346, 26, 62, 0, 200, 1.0);
    // nose deck plate and the plate under the X truss
    paint(STEEL) plate(462, 508, -15, 15, 0, 200, 1.6);
    paint(STEEL) plate(512, 537, -11, 11, 0, 200, 1.0);
}

module hull_cuts() {
    for (z = [147, 232, 301, 334, 389, 446, 500, 528]) ring_groove(z);
    // grille slots
    for (mx = [0, 1], my = [0, 1]) mirror([mx, 0, 0]) mirror([0, my, 0])
        for (z = [309:6:340]) recess(z, z + 1.6, 29, 59, 0, 200, 1.4);
    // seams along the forward hull corner faces
    for (mx = [0, 1], my = [0, 1]) mirror([mx, 0, 0]) mirror([0, my, 0]) recess(392, 456, 34, 35.2, 0, 200, 0.8);
    // aft U-frame recess, forward recess (+Y), hatch recesses (-Y), shoulder thruster bays (-Y)
    for (m = [0, 1]) mirror([0, m, 0]) recess(151, 210, -15, 15, 0, 200, 1.2);
    recess(430, 462, -13, 13, 0, 200, 1.5);
    recess(395, 418, -10, 10, -200, 0, 1.2);
    recess(439, 474, -7, 7, -200, 0, 1.2);
    for (m = [0, 1]) mirror([m, 0, 0]) recess(262, 300, 52, 66, -200, 0, 3);
    // grid on the nose deck plate
    for (x = [-5, 5]) recess(464, 506, x - 0.5, x + 0.5, 0, 200, -0.6);
    for (z = [474, 486, 498]) recess(z, z + 1, -14, 14, 0, 200, -0.6);
    lower_airlock_doors();
    upper_airlock_door();
    for (m = [0, 1]) mirror([0, m, 0]) torpedo_tube_bore();
}

// Smaller fittings: X truss on the nose deck, sensor domes
module fittings() {
    s1 = sec_at(HULL, 513);
    s2 = sec_at(HULL, 535);
    paint(STEEL) for (m = [0, 1]) mirror([m, 0, 0])
        rod([-8, y_top(s1, 8) + 1.6, 513], [8, y_top(s2, 8) + 1.6, 535], 1.0);
    paint(BLACK) {
        for (x = [-9, 9]) translate([x, y_top(sec_at(HULL, 470), x) + 1.4, 470]) sphere(2.6, $fn = 16);
        for (m = [0, 1]) mirror([m, 0, 0]) translate([30, y_top(sec_at(HULL, 300), 30) + 0.8, 300]) sphere(2.4, $fn = 16);
    }
}

// --------------------------------------------------------------------------------------
// Livery traced from the views
// --------------------------------------------------------------------------------------
// The right view is a mirror of the left one, so the +X side reuses the left tracing;
// its TACHI lettering is cut in again so that it reads correctly on that side
module right_side_name()
    rotate([90, 0, 90]) linear_extrude(height = 400, center = true)
        translate([-1.5, 421]) rotate(90) text("TACHI", size = 7.5, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
module livery_decals() {
    paint(ORANGE) {
        on_y(1, decal_height, true) decal_front_orange();
        on_y(-1, decal_height, true) decal_back_orange();
        on_x(-1, decal_height, true) decal_left_orange();
        difference() { on_x(1, decal_height, true) decal_left_orange_unlettered(); right_side_name(); }
    }
    paint(WHITE) {
        on_y(1, decal_height + 0.5, true) decal_front_white();
        on_y(-1, decal_height + 0.5, true) decal_back_white();
        on_x(-1, decal_height + 0.5, true) decal_left_white();
    }
    paint(YELLOW) {
        on_y(1, decal_height + 0.6, true) decal_front_yellow();
        on_y(-1, decal_height + 0.6, true) decal_back_yellow();
        for (s = [-1, 1]) on_x(s, decal_height + 0.6, true) decal_left_yellow();
    }
}

module tachi() {
    difference() {
        union() {
            engine_bell();
            thrust_structure();
            drum();
            hull_body();
            hull_plates();
            blocks();
            chevrons();
            if (livery) livery_decals();
            for (m = [0, 1]) mirror([0, m, 0]) { torpedo_tube_housing(); torpedo_tube_muzzle(); }
            lower_airlock_frames();
            upper_airlock_frame();
        }
        paint(HULL_DARK) hull_cuts();
    }
    airlock_details();
    fittings();
    pdcs();
    landing_thrusters();
    control_thrusters();
    comm_array();
}

scale(K) tachi();

// --------------------------------------------------------------------------------------
// Traced decal shapes (generated from the view images): (X, Z) for front/back, (Y, Z) for left
// --------------------------------------------------------------------------------------
module decal_front_orange() {
    polygon([[-67.88,376.38],[-67.12,375.62],[-68.12,372.62],[-67.12,364.38],[-68.38,363.88],[-69.88,365.62],[-73.12,365.62],[-77.12,362.62],[-77.12,361.38],[-73.12,358.38],[-69.62,359.12],[-68.12,358.62],[-67.38,356.12],[-68.12,351.38],[-70.12,349.62],[-71.38,346.88],[-79.38,342.88],[-80.88,347.38],[-80.88,362.62],[-79.88,364.38],[-79.88,367.62],[-77.88,370.38],[-77.12,373.38],[-73.62,374.12],[-71.62,372.62],[-71.62,375.88]]);
    polygon([[-63.62,283.88],[-66.62,284.88],[-77.62,293.88],[-77.88,297.62],[-79.88,300.38],[-79.88,334.62],[-64.62,342.12],[-63.12,341.62],[-63.12,302.38],[-65.12,299.62],[-65.12,290.38],[-63.12,288.62],[-74.12,323.12],[-74.88,324.62],[-77.88,323.88],[-77.12,322.38],[-74.62,301.62],[-73.88,302.38],[-73.88,306.62],[-75.38,307.38],[-76.12,306.62],[-76.12,302.38],[-69.88,310.38],[-69.88,312.62],[-70.88,313.62],[-75.12,312.62],[-76.12,311.62],[-75.12,309.38],[-70.88,309.38],[-67.12,323.12],[-67.88,324.62],[-71.12,324.62],[-71.88,323.88],[-71.12,322.38],[-67.88,322.38],[-66.12,328.88],[-66.88,330.62],[-69.12,329.62],[-68.38,327.62]], [[0,1,2,3,4,5,6,7,8,9,10,11],[12,13,14,15],[16,17,18,19,20,21],[22,23,24,25,26,27,28],[29,30,31,32,33,34],[35,36,37,38]]);
    polygon([[-57.62,143.88],[-58.88,144.38],[-58.38,150.12],[-57.12,149.62]]);
    polygon([[-57.38,427.88],[-58.62,427.88],[-60.62,430.88],[-59.88,435.62],[-58.38,438.12],[-57.12,437.62],[-57.12,435.38],[-55.12,432.62],[-55.12,430.38]]);
    polygon([[-51.62,459.12],[-51.12,457.38],[-55.12,446.62],[-55.12,444.38],[-56.12,441.38],[-57.38,440.88],[-57.88,442.62],[-56.88,446.62],[-53.88,453.12],[-53.88,457.62],[-52.62,459.12]]);
    polygon([[-47.62,379.88],[-48.88,380.38],[-48.88,391.62],[-50.38,393.38],[-52.12,392.62],[-51.12,389.62],[-51.12,381.38],[-54.12,380.62],[-56.88,382.38],[-56.88,394.62],[-55.12,396.12],[-55.12,397.12],[-57.38,399.38],[-59.88,400.38],[-59.88,420.62],[-55.12,425.38],[-50.88,424.38],[-50.38,422.88],[-57.12,415.62],[-57.12,403.38],[-47.12,393.62]]);
    polygon([[-43.38,83.12],[-50.12,82.62],[-50.62,83.88],[-43.88,84.38]]);
    polygon([[-20.62,348.88],[-21.62,348.88],[-26.62,353.62],[-28.88,358.62],[-35.12,358.62],[-35.88,359.38],[-35.38,369.12],[-34.12,368.62],[-34.12,362.38],[-32.62,361.62],[-31.88,364.62],[-30.62,365.12],[-30.12,362.38],[-26.12,360.12],[-21.38,355.12],[-20.12,352.62]]);
    polygon([[-21.62,167.88],[-22.88,168.38],[-22.38,188.12],[-21.12,187.62],[-21.12,178.38],[-20.12,176.62]]);
    polygon([[-19.88,538.38],[-19.12,536.38],[-20.38,533.88],[-26.88,527.38],[-32.38,518.88],[-34.38,517.88],[-34.62,519.12],[-32.88,521.38],[-32.88,523.62],[-31.12,525.88],[-29.88,529.62],[-26.88,531.38],[-26.62,533.12],[-22.88,537.12]]);
    polygon([[-19.62,205.12],[-19.12,201.38],[-21.12,197.62],[-21.12,191.38],[-22.38,190.88],[-22.88,201.62],[-20.88,204.62]]);
    polygon([[-16.62,143.88],[-18.88,145.62],[-22.12,145.62],[-22.88,146.38],[-22.88,155.62],[-22.12,156.38],[-20.38,155.88],[-21.12,148.38],[-20.38,147.62],[-17.62,148.12],[-16.12,145.62]]);
    polygon([[-13.12,346.38],[-17.12,344.62],[-17.88,345.38],[-17.88,348.62],[-17.12,349.38],[-13.88,349.38]]);
    polygon([[-6.38,79.12],[-12.12,78.62],[-12.62,79.88],[-6.88,80.38]]);
    polygon([[-5.38,83.12],[-9.12,82.62],[-9.62,83.88],[-5.88,84.38]]);
    polygon([[-3.88,123.62],[-17.12,123.62],[-17.88,124.38],[-17.88,139.62],[-17.12,140.38],[-12.88,140.38],[-12.12,139.62],[-12.12,126.38],[-11.12,125.38],[-3.88,125.38]]);
    polygon([[5.88,329.62],[5.12,327.62],[-0.12,327.62],[-0.88,326.88],[-0.12,325.38],[4.62,324.88],[4.12,323.62],[2.12,322.62],[-3.12,322.62],[-3.88,325.62],[-5.88,327.38],[-5.38,329.12],[-2.62,328.62],[-1.88,329.38],[-1.88,332.62],[0.38,334.12],[4.12,332.38]]);
    polygon([[7.88,244.38],[7.12,243.62],[-4.12,243.62],[-4.88,245.62],[-4.12,246.38],[7.12,246.38]]);
    polygon([[10.62,79.12],[9.62,78.88],[8.88,81.12],[7.62,81.38],[6.88,79.38],[5.62,78.88],[5.12,80.62],[3.12,82.38],[3.12,83.62],[3.88,84.38],[10.12,84.38],[10.62,82.88],[9.88,81.12]]);
    polygon([[12.38,243.88],[11.12,244.38],[9.12,248.62],[3.12,249.62],[-1.38,248.88],[-10.12,249.62],[-11.12,248.62],[-10.12,244.38],[-10.88,243.62],[-12.88,244.38],[-12.88,251.62],[-11.88,253.38],[-12.88,257.38],[-11.88,261.38],[-11.88,267.62],[-12.88,270.62],[-11.88,272.38],[-11.88,276.62],[-10.62,278.12],[9.12,278.38],[11.88,276.62],[11.88,272.38],[11.12,271.62],[7.88,271.62],[6.12,273.62],[2.12,274.62],[-0.88,273.62],[-5.12,274.62],[-9.12,272.62],[-9.88,271.12],[-7.12,269.38],[0.12,269.38],[1.88,268.38],[7.12,269.38],[8.62,267.62],[10.62,269.12],[11.88,268.62]]);
    polygon([[12.12,121.38],[12.62,119.88],[11.12,118.12],[11.62,114.88],[10.88,113.62],[10.88,88.38],[10.12,87.62],[5.88,87.62],[4.12,88.62],[1.12,87.62],[-13.12,87.62],[-13.62,89.12],[-11.88,91.38],[-11.88,113.62],[-12.88,115.62],[-15.62,117.88],[-15.62,120.12],[-14.12,121.38],[-7.62,105.62],[-6.88,106.38],[-6.88,116.62],[-8.38,117.38],[-9.12,116.62],[-9.12,106.38],[1.88,101.88],[1.12,103.62],[-1.12,102.62],[-0.38,100.62],[8.38,104.62],[8.88,105.88],[7.62,106.38],[7.12,105.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17],[18,19,20,21,22,23],[24,25,26,27],[28,29,30,31]]);
    polygon([[17.88,139.62],[17.88,124.38],[17.12,123.62],[0.38,124.12],[0.88,125.38],[11.12,125.38],[12.12,126.38],[12.12,132.62],[12.88,133.88],[12.12,138.62],[15.88,140.38]]);
    polygon([[22.12,144.62],[18.88,144.62],[17.12,143.62],[14.38,144.12],[18.12,152.38],[18.12,163.62],[18.88,164.88],[18.12,167.38],[18.12,208.62],[15.88,213.12],[12.12,216.62],[-13.12,216.62],[-17.12,211.38],[-18.38,210.88],[-18.88,212.62],[-17.88,214.38],[-17.88,218.62],[-19.88,222.38],[-19.88,227.62],[-19.12,228.38],[-16.12,227.38],[-11.88,227.38],[-8.12,223.38],[-2.88,223.38],[-1.12,224.38],[2.88,223.38],[9.12,224.38],[12.12,223.38],[13.12,225.62],[10.38,227.12],[10.88,228.38],[18.12,228.38],[19.88,226.62],[19.88,203.38],[22.88,200.62],[22.88,145.38]]);
    polygon([[34.88,519.38],[34.12,518.62],[32.12,519.38],[19.62,538.38],[17.88,538.62],[14.62,535.88],[13.12,536.38],[13.12,545.62],[12.12,546.62],[4.88,545.62],[3.12,549.62],[-4.12,549.62],[-4.88,548.88],[-4.12,547.38],[1.12,547.38],[1.62,546.12],[-7.12,545.62],[-10.88,543.38],[-15.38,538.88],[-16.38,538.88],[-18.62,541.88],[-18.88,543.62],[-17.88,547.62],[-14.62,553.12],[-10.62,557.12],[-8.88,557.38],[-7.88,553.88],[-5.12,551.38],[-1.88,551.38],[-0.12,552.38],[2.88,551.38],[10.12,551.38],[11.12,552.38],[10.38,557.88],[12.62,558.12],[14.62,556.12],[19.12,545.88],[32.62,526.12],[34.88,521.62]]);
    polygon([[35.38,370.12],[35.88,359.38],[35.12,358.62],[30.38,358.38],[21.62,348.88],[18.88,347.62],[17.62,344.88],[15.88,344.62],[13.88,345.62],[13.12,348.62],[19.12,351.38],[25.38,360.38],[30.12,364.38],[31.38,367.12],[33.12,367.38],[34.12,369.62]]);
    polygon([[39.88,165.38],[39.12,164.62],[35.88,164.62],[35.12,165.38],[35.12,168.62],[35.88,169.38],[39.12,169.38],[39.88,168.62]]);
    polygon([[51.62,83.12],[41.88,82.62],[41.38,83.88],[51.12,84.38]]);
    polygon([[58.12,144.62],[55.88,144.62],[54.12,148.38],[54.12,168.62],[55.12,170.38],[55.12,195.62],[55.88,196.38],[57.88,195.62],[57.88,181.38],[57.12,180.12],[57.88,177.62],[57.88,167.38],[56.88,165.62],[56.88,158.38],[55.88,155.38],[58.88,149.62],[58.88,145.38]]);
    polygon([[55.62,408.12],[59.88,403.62],[59.88,399.38],[56.12,397.12],[56.88,394.62],[56.88,382.38],[55.12,380.62],[51.88,380.62],[51.12,381.38],[51.12,391.62],[49.62,392.38],[48.88,391.62],[48.88,379.38],[47.62,378.88],[47.12,389.62],[42.38,394.88],[42.12,396.62],[46.12,401.12],[54.62,408.12]]);
    polygon([[59.12,413.62],[57.38,413.88],[56.12,415.38],[56.12,418.62],[57.12,420.38],[57.12,439.62],[51.12,457.38],[51.62,459.12],[52.62,459.12],[53.88,457.62],[53.88,454.38],[58.88,441.62],[60.62,433.12],[59.88,430.62],[59.88,419.38],[60.88,415.38]]);
    polygon([[79.38,342.88],[72.88,344.62],[70.12,346.38],[70.62,376.12],[72.88,374.38],[76.62,373.12],[79.88,367.62]]);
    polygon([[63.62,282.88],[62.12,283.38],[62.12,286.62],[65.12,289.38],[65.12,300.62],[62.12,302.38],[62.12,341.62],[62.88,342.38],[71.12,339.38],[79.88,334.62],[79.88,300.38],[77.88,296.62],[77.88,294.38],[75.88,293.62],[74.12,290.62],[65.38,326.62],[66.12,328.62],[64.62,329.38],[63.88,327.38],[70.88,305.12],[70.12,306.62],[68.12,305.88],[68.88,304.38],[75.38,306.62],[76.12,309.62],[74.62,310.38],[73.88,307.38],[75.38,297.62],[76.12,298.38],[76.12,302.62],[74.38,303.38],[73.12,302.12],[73.88,298.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14],[15,16,17,18],[19,20,21,22],[23,24,25,26],[27,28,29,30,31,32]]);
}

module decal_front_white() {
    polygon([[-111.12,339.88],[-113.62,339.38],[-114.38,338.62],[-117.62,338.62],[-117.88,343.12],[-113.38,343.38],[-111.12,341.12]]);
    polygon([[-103.38,334.62],[-103.88,334.88],[-103.62,337.38],[-103.12,337.12]]);
    polygon([[-101.12,348.88],[-104.62,348.62],[-104.88,350.12],[-101.38,350.38]]);
    polygon([[-101.12,333.12],[-101.38,331.62],[-103.88,331.88],[-101.62,333.38]]);
    polygon([[-56.38,494.38],[-56.12,492.88],[-57.12,491.38],[-57.12,487.88],[-59.62,487.62],[-60.88,488.88],[-60.88,493.12],[-58.62,494.38]]);
    polygon([[-53.38,491.62],[-53.88,491.88],[-53.88,494.12],[-52.38,494.38],[-52.12,492.88]]);
    polygon([[-42.38,54.62],[-43.88,55.88],[-44.12,58.12],[-46.88,62.88],[-47.12,65.12],[-50.88,71.88],[-51.12,74.12],[-52.88,76.88],[-52.62,78.38],[-51.12,77.12],[-50.88,75.88],[-47.12,71.12],[-46.88,67.88],[-44.38,67.38],[-43.12,66.12],[-42.88,64.88],[-40.12,62.12],[-40.12,58.88],[-40.62,58.38],[-40.12,55.88]]);
    polygon([[-39.12,515.12],[-40.38,513.62],[-41.62,513.38],[-42.38,512.62],[-42.88,512.88],[-42.88,514.12],[-41.62,515.38]]);
    polygon([[-36.12,66.88],[-37.38,64.62],[-38.62,64.62],[-39.88,67.12],[-36.38,67.38]]);
    polygon([[-29.12,7.88],[-36.62,7.62],[-36.88,8.12],[-29.38,8.38]]);
    polygon([[-26.38,515.62],[-26.88,515.88],[-26.62,519.38],[-26.12,519.12]]);
    polygon([[-19.12,281.88],[-23.62,281.62],[-23.88,282.12],[-19.38,282.38]]);
    polygon([[-15.12,7.88],[-24.62,7.62],[-24.88,8.12],[-15.38,8.38]]);
    polygon([[-5.38,347.62],[-6.88,347.88],[-6.62,354.38],[-5.12,354.12],[-5.12,350.88],[-5.62,350.38],[-5.12,349.12]]);
    polygon([[-6.38,341.62],[-6.88,341.88],[-6.62,345.38],[-5.12,344.12],[-5.12,342.88]]);
    polygon([[-5.38,282.62],[-6.88,282.88],[-6.62,295.38],[-5.12,295.12]]);
    polygon([[-4.12,303.12],[-4.38,301.62],[-6.88,301.88],[-5.62,303.38]]);
    polygon([[-1.38,346.62],[-2.88,347.88],[-2.62,351.38],[-2.12,351.12],[-1.88,348.88],[-1.12,348.12]]);
    polygon([[1.88,344.88],[0.62,342.62],[-0.62,342.62],[-1.88,345.12],[-0.88,345.62],[0.88,345.62]]);
    polygon([[1.38,346.62],[1.12,348.12],[2.62,350.38],[2.88,347.88]]);
    polygon([[2.88,305.88],[0.12,305.62],[-1.38,304.62],[-2.62,304.62],[-2.88,305.12],[-2.12,305.88],[-2.12,307.12],[-3.12,307.62],[-5.62,307.62],[-6.88,308.88],[-6.88,312.12],[-5.62,313.38],[2.62,313.38],[2.62,312.62],[-3.88,312.62],[-5.62,311.38],[-5.62,310.62],[-4.88,308.88],[-3.88,308.38],[2.62,308.38]]);
    polygon([[2.62,293.38],[2.88,290.88],[1.12,289.12],[0.88,287.88],[-1.88,285.12],[-2.12,283.88],[-2.62,283.62],[-2.88,287.12],[0.88,290.88],[1.12,292.12]]);
    polygon([[3.88,204.88],[0.38,204.62],[0.12,205.12],[3.62,205.38]]);
    polygon([[5.88,41.88],[5.38,41.62],[4.12,43.12],[5.62,43.38]]);
    polygon([[6.62,347.62],[5.12,347.88],[5.88,348.88],[5.88,350.12],[5.12,350.88],[5.62,351.62],[5.12,352.88],[5.38,354.38],[6.88,354.12]]);
    polygon([[7.88,342.88],[6.38,341.62],[5.12,342.88],[5.12,344.12],[6.62,345.38]]);
    polygon([[7.62,301.62],[5.12,301.88],[5.12,305.12],[5.62,305.62],[5.12,307.12],[6.12,308.62],[6.12,311.38],[5.12,312.88],[5.38,313.38],[7.88,313.12],[7.88,311.88],[6.88,310.38],[7.12,308.88],[7.88,308.12],[7.12,307.12],[7.12,305.88],[7.88,305.12],[7.38,304.38],[7.88,303.12]]);
    polygon([[6.62,295.38],[7.12,292.88],[7.88,291.88],[6.88,290.38],[6.88,282.88],[5.38,282.62],[5.12,287.12],[6.12,288.62],[6.12,292.38],[5.12,294.12]]);
    polygon([[8.88,330.88],[8.12,330.88],[6.62,334.38],[5.38,334.62],[2.88,336.62],[-1.88,336.62],[-4.62,335.38],[-6.38,333.62],[-7.62,333.62],[-7.88,334.12],[-5.62,336.38],[-4.38,336.62],[-3.62,337.38],[4.62,337.38],[8.88,333.12]]);
    polygon([[9.88,326.12],[9.88,324.88],[9.12,324.12],[8.88,322.88],[5.62,319.62],[4.38,319.38],[3.62,318.62],[-3.62,318.62],[-4.88,319.88],[-4.62,320.38],[-3.38,320.38],[-1.88,319.38],[2.62,319.62],[3.38,320.38],[4.62,320.62],[7.88,323.88],[8.12,325.12],[9.38,326.38]]);
    polygon([[9.88,26.88],[8.38,26.62],[8.12,27.12],[8.62,28.12],[7.38,28.62],[2.38,28.62],[2.12,30.12],[9.62,30.38]]);
    polygon([[10.88,34.88],[1.38,34.62],[1.12,35.12],[10.62,35.38]]);
    polygon([[10.88,22.88],[1.38,22.62],[1.12,23.12],[5.88,23.38],[7.38,24.38],[9.62,24.38]]);
    polygon([[20.88,281.88],[19.38,281.62],[19.12,283.12],[19.62,283.38]]);
    polygon([[23.88,299.88],[19.38,299.62],[19.12,301.12],[19.62,301.38],[21.12,300.38],[23.62,300.38]]);
    polygon([[23.88,290.88],[21.38,290.62],[21.12,292.12],[21.62,292.38],[22.88,291.88],[23.62,292.38]]);
    polygon([[23.88,287.12],[23.62,285.62],[22.38,286.38],[21.62,285.62],[19.12,285.88],[19.38,286.38],[21.12,286.38],[22.38,287.38]]);
    polygon([[23.88,283.12],[23.62,281.62],[22.12,281.88],[23.38,283.38]]);
    polygon([[28.62,512.62],[28.12,512.88],[28.38,515.38],[28.88,515.12]]);
    polygon([[29.62,597.62],[29.12,597.88],[29.38,602.38],[29.88,602.12]]);
    polygon([[39.88,66.88],[38.62,64.62],[37.38,64.62],[36.12,67.12],[39.62,67.38]]);
    polygon([[52.62,78.38],[52.88,75.88],[52.12,75.12],[51.88,73.88],[51.12,73.12],[50.88,71.88],[47.12,65.12],[46.88,62.88],[45.12,60.12],[44.88,57.88],[43.88,56.38],[43.88,54.88],[42.38,54.62],[40.12,55.88],[40.12,57.12],[40.88,57.88],[40.88,59.12],[40.12,59.88],[40.12,62.12],[42.88,64.88],[43.12,66.12],[44.38,67.38],[46.88,67.88],[47.12,71.12],[48.88,72.88],[49.12,74.12],[51.88,76.88],[52.12,78.12]]);
    polygon([[58.62,486.62],[57.12,487.88],[57.12,491.38],[56.12,492.88],[56.38,494.38],[57.62,494.38],[58.38,493.62],[59.62,493.38],[60.88,492.12],[60.88,488.88]]);
    polygon([[103.88,348.88],[101.38,348.62],[101.12,350.12],[103.62,350.38]]);
    polygon([[103.62,331.62],[103.12,331.88],[103.38,334.38],[103.88,334.12]]);
    polygon([[117.88,343.12],[117.88,339.88],[115.62,338.62],[114.38,338.62],[112.88,339.62],[110.12,339.88],[113.38,343.38]]);
}

module decal_front_yellow() {
    polygon([[-42.38,467.38],[-42.38,465.62],[-43.62,464.62],[-45.62,464.62],[-45.88,463.88],[-45.38,462.88],[-46.62,461.88],[-47.62,463.12],[-45.88,464.62],[-46.62,465.88],[-45.88,467.12],[-43.62,468.12]]);
    polygon([[-40.38,473.88],[-41.62,472.88],[-42.62,474.12],[-41.38,475.12]]);
    polygon([[-32.38,284.88],[-33.62,285.88],[-33.12,286.88],[-33.62,288.12],[-32.62,289.12],[-31.38,288.12],[-31.88,287.12],[-31.38,285.88]]);
    polygon([[-27.38,229.88],[-28.62,230.62],[-29.62,232.88],[-28.38,234.38],[-27.12,234.12],[-26.12,232.88],[-26.12,231.12]]);
    polygon([[-22.12,230.12],[-23.62,228.88],[-24.62,229.62],[-24.88,230.88],[-23.38,232.12],[-22.38,231.38]]);
    polygon([[-2.38,204.62],[-3.62,203.88],[-5.62,205.62],[-5.88,206.88],[-4.88,208.12],[-3.62,208.38],[-2.38,207.38]]);
    polygon([[2.62,133.38],[2.88,132.12],[2.12,131.38],[1.62,129.62],[-0.62,127.88],[-1.62,129.12],[0.12,131.12],[0.38,133.38],[1.38,134.12]]);
    polygon([[3.62,441.88],[2.12,443.12],[2.12,444.88],[3.38,446.12],[4.88,444.88],[4.88,443.12]]);
    polygon([[5.88,206.12],[4.88,204.88],[3.62,204.62],[2.38,205.62],[2.12,206.88],[3.12,208.12],[4.38,208.38],[5.62,207.38]]);
    polygon([[7.62,375.12],[6.88,373.88],[3.38,370.62],[1.62,370.62],[0.38,371.88],[1.12,373.12],[0.38,375.12],[1.38,376.12],[2.62,375.12],[2.12,374.12],[2.62,373.38],[3.38,373.38],[6.38,376.12]]);
    polygon([[18.62,139.88],[17.38,138.88],[16.38,140.12],[17.62,141.12]]);
    polygon([[20.62,578.88],[19.88,577.88],[18.62,577.62],[16.88,579.62],[15.38,578.88],[14.38,580.12],[15.62,581.12],[17.12,579.38],[18.62,580.38],[19.38,580.38]]);
    polygon([[29.62,229.88],[28.62,228.88],[26.88,230.62],[25.38,229.88],[24.38,230.62],[24.12,231.88],[25.62,233.12],[26.62,232.38],[27.12,230.62],[28.62,231.12]]);
    polygon([[31.38,284.62],[30.12,284.88],[29.38,285.88],[30.12,287.12],[29.38,288.88],[29.88,289.88],[29.38,291.12],[30.38,292.12],[31.62,291.38],[31.88,290.12],[32.88,288.88],[32.12,287.12],[32.62,285.88]]);
    polygon([[43.62,475.12],[41.62,472.88],[40.38,473.88],[42.38,476.12]]);
    polygon([[46.62,461.88],[45.38,462.88],[45.88,463.88],[45.38,464.62],[43.62,464.62],[42.12,466.12],[42.12,467.88],[43.38,469.12],[45.38,467.62],[46.62,468.12],[47.88,466.88],[47.88,466.12],[46.88,464.88],[47.62,462.88]]);
    polygon([[58.62,130.88],[57.38,129.88],[56.38,131.12],[57.62,132.12]]);
}

module decal_back_orange() {
    polygon([[79.38,342.88],[80.88,345.38],[80.88,364.62],[77.88,370.38],[77.88,372.62],[74.62,375.12],[69.38,377.12],[68.12,375.62],[68.12,352.38],[71.38,346.88],[71.62,371.62],[70.88,373.62],[72.12,374.62],[73.12,372.38]], [[0,1,2,3,4,5,6,7,8,9],[10,11,12,13]]);
    polygon([[75.12,296.62],[78.62,298.88],[81.88,303.38],[79.88,311.38],[79.88,321.62],[75.12,323.12],[75.88,324.62],[79.12,324.62],[79.88,325.38],[79.88,334.62],[76.12,337.38],[66.88,340.38],[65.12,342.38],[63.88,342.38],[63.12,341.62],[63.12,310.38],[70.88,308.12],[71.12,303.38],[70.12,300.38],[73.38,296.88],[74.62,307.38],[76.88,305.12],[76.38,303.62],[74.12,305.88],[69.88,313.62],[71.62,314.38],[75.88,310.12],[75.12,309.38],[70.62,309.38],[69.88,310.38],[67.12,323.12],[67.88,324.62],[71.12,324.62],[71.88,323.88],[71.12,322.38],[67.88,322.38],[66.88,328.38],[67.62,330.38],[69.88,329.12],[69.12,327.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19],[20,21,22,23],[24,25,26,27,28,29],[30,31,32,33,34,35],[36,37,38,39]]);
    polygon([[60.62,162.88],[61.88,164.38],[61.88,166.62],[60.88,168.38],[60.88,174.62],[57.88,179.38],[57.88,196.62],[56.38,197.12],[55.12,195.62],[55.12,165.38]]);
    polygon([[55.88,144.62],[58.88,145.38],[58.88,149.62],[57.62,151.12],[56.12,150.62],[55.12,146.62]]);
    polygon([[54.62,427.88],[55.62,427.88],[57.62,429.88],[58.88,432.38],[58.88,438.62],[57.38,443.12],[56.12,442.62],[56.12,434.38],[54.12,431.62]]);
    polygon([[44.88,378.62],[47.12,378.62],[48.62,379.88],[49.88,383.38],[49.12,385.88],[49.62,387.38],[51.12,386.62],[52.62,382.88],[53.88,383.38],[53.88,386.62],[56.62,388.88],[57.88,393.38],[57.88,396.62],[58.88,398.38],[58.88,401.62],[57.88,403.38],[58.88,406.38],[58.88,412.62],[56.62,416.38],[54.12,418.38],[52.88,418.38],[52.38,416.88],[53.38,412.88],[56.12,409.62],[56.12,407.38],[55.12,404.38],[44.12,393.62],[44.12,379.38],[54.12,400.12],[54.88,401.62],[56.88,400.88],[56.12,399.38],[50.12,396.12],[50.88,397.62],[53.88,396.88],[53.12,395.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27],[28,29,30,31],[32,33,34,35]]);
    polygon([[40.62,152.88],[41.88,153.62],[42.38,157.12],[41.12,156.38]]);
    polygon([[21.62,167.88],[22.88,168.38],[22.38,180.12],[21.12,179.62]]);
    polygon([[21.62,154.88],[22.62,154.88],[23.88,156.38],[23.38,163.12],[22.12,162.62],[22.12,158.38],[21.12,156.62]]);
    polygon([[21.62,145.88],[22.88,146.38],[22.38,150.12],[21.12,149.62]]);
    polygon([[20.62,347.88],[21.88,348.38],[30.88,358.62],[32.88,359.38],[32.88,363.62],[32.12,364.38],[29.12,363.12],[21.38,355.12],[20.12,352.62]]);
    polygon([[19.62,208.12],[19.12,202.38],[21.12,197.62],[20.12,191.38],[22.12,190.62],[22.88,191.38],[22.88,201.62],[20.88,205.38],[20.88,207.62]]);
    polygon([[16.62,143.88],[17.88,144.38],[18.88,146.38],[18.38,148.12],[17.12,147.62],[16.12,145.62]]);
    polygon([[12.12,136.38],[12.88,135.62],[17.12,135.62],[17.88,136.38],[17.88,139.62],[14.88,140.38],[12.88,139.38]]);
    polygon([[12.12,128.38],[12.88,127.62],[17.12,127.62],[17.88,128.38],[17.88,131.62],[15.12,133.38],[12.88,133.38],[12.12,132.62]]);
    polygon([[10.12,244.38],[12.12,243.62],[12.88,245.62],[10.88,246.38]]);
    polygon([[6.38,124.12],[17.12,123.62],[17.62,124.88],[6.88,125.38]]);
    polygon([[6.38,79.12],[12.12,78.62],[12.62,79.88],[6.88,80.38]]);
    polygon([[5.38,83.12],[10.12,82.62],[10.62,83.88],[5.88,84.38]]);
    polygon([[-3.88,557.62],[-3.12,554.62],[3.12,554.62],[6.12,553.62],[12.38,548.88],[18.62,550.12],[17.62,552.38],[11.12,558.38],[-3.12,558.38]]);
    polygon([[-7.88,244.38],[-7.12,243.62],[5.12,243.62],[5.88,245.62],[5.12,246.38],[-7.12,246.38]]);
    polygon([[-10.62,82.88],[-7.88,81.62],[-6.12,78.62],[-4.88,78.62],[-3.12,83.62],[-3.88,84.38],[-10.12,84.38]]);
    polygon([[-8.12,435.62],[6.12,435.62],[9.62,436.88],[10.88,438.38],[10.88,441.62],[7.12,442.12],[8.88,444.38],[8.88,450.62],[7.88,452.62],[3.88,456.38],[3.88,459.62],[4.88,460.62],[7.12,459.62],[7.12,456.38],[8.88,456.38],[8.88,460.62],[7.12,463.88],[10.88,464.38],[10.88,475.62],[10.12,476.38],[-10.12,476.38],[-10.88,475.62],[-10.88,443.38],[-11.62,440.88],[-10.12,439.12],[-9.62,436.88],[-2.88,442.12],[-2.88,443.12],[-1.12,444.62],[2.12,444.62],[3.88,443.12],[3.12,441.38],[-2.12,441.38],[-4.88,473.12],[-4.12,474.62],[2.12,474.62],[2.88,473.88],[2.12,472.38],[-4.12,472.38],[-5.38,457.62],[-6.12,460.62],[-4.62,461.38],[-3.88,458.38],[-8.38,446.62],[-8.88,447.88],[-7.62,448.38],[-7.12,447.12],[-8.38,460.62],[-9.12,462.62],[-7.62,463.38],[-6.88,461.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25],[26,27,28,29,30,31,32],[33,34,35,36,37,38],[39,40,41,42],[43,44,45,46],[47,48,49,50]]);
    polygon([[-11.38,243.88],[-10.12,244.38],[-10.12,247.62],[-8.12,249.62],[12.12,249.62],[12.88,250.38],[12.88,270.62],[11.88,272.38],[11.88,276.62],[10.62,278.12],[-9.12,278.38],[-11.62,276.12],[-11.88,272.38],[-11.12,271.62],[-7.88,271.62],[-6.12,273.62],[-1.62,274.38],[0.88,273.62],[6.62,274.38],[10.12,272.62],[9.88,270.88],[8.12,269.38],[0.88,269.38],[-0.88,267.38],[-4.12,267.38],[-5.88,269.38],[-11.12,269.38],[-11.88,268.62]]);
    polygon([[-12.62,421.12],[8.12,420.62],[8.62,421.88],[-12.12,422.38]]);
    polygon([[-12.12,121.38],[-12.62,120.12],[-10.88,118.62],[-10.88,87.38],[13.12,87.62],[13.62,89.12],[11.88,91.38],[11.88,104.62],[12.62,105.88],[11.88,113.62],[13.62,115.88],[13.88,117.62],[16.12,118.62],[16.62,120.12],[15.12,121.38],[8.62,104.62],[8.12,105.88],[9.38,106.38],[9.88,105.12],[-2.88,102.12],[-2.12,103.62],[4.12,103.62],[4.88,102.88],[4.12,101.38],[2.12,100.38],[-0.12,100.38],[-8.88,104.88],[-8.12,106.62],[-5.88,105.62],[-6.62,103.62]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14],[15,16,17,18],[19,20,21,22,23,24,25],[26,27,28,29]]);
    polygon([[-15.38,394.88],[-14.12,395.38],[-14.62,419.12],[-15.88,418.62]]);
    polygon([[-14.38,384.88],[-8.12,388.62],[13.12,388.62],[13.88,390.38],[15.88,391.38],[15.38,420.12],[14.12,419.62],[14.12,390.62],[-16.38,390.12],[-16.62,388.88]]);
    polygon([[-17.88,345.38],[-17.12,344.62],[-14.62,345.38],[-10.88,344.62],[-9.12,346.62],[-6.88,346.62],[-5.12,344.62],[-0.88,344.62],[1.88,347.62],[4.88,346.62],[10.12,347.62],[11.88,344.62],[17.12,344.62],[17.88,345.38],[17.88,349.62],[14.88,350.38],[13.12,349.38],[-12.12,349.38],[-13.88,350.38],[-17.12,350.38],[-17.88,349.62]]);
    polygon([[-3.88,123.62],[-3.88,125.38],[-11.12,125.38],[-11.88,126.12],[-11.12,132.62],[-12.88,134.88],[-11.12,136.38],[-11.12,138.62],[-14.88,140.38],[-17.12,140.38],[-17.88,139.62],[-17.88,124.38],[-17.12,123.62]]);
    polygon([[-21.62,144.88],[-20.12,145.38],[-20.12,148.62],[-18.62,149.38],[-17.88,148.62],[-17.88,144.38],[-17.12,143.62],[-14.38,144.12],[-18.12,152.38],[-17.38,157.12],[-18.88,164.88],[-18.12,167.38],[-18.12,175.62],[-17.38,176.88],[-18.12,179.38],[-18.12,207.62],[-14.88,214.12],[-12.12,216.62],[13.12,216.62],[15.88,214.12],[17.12,211.38],[18.38,210.88],[18.88,220.62],[20.88,224.38],[20.88,226.62],[19.62,228.12],[11.88,227.38],[9.12,223.38],[-12.62,223.62],[-13.88,225.88],[-13.12,226.62],[-9.88,226.62],[-9.88,228.38],[-18.12,228.38],[-19.88,226.62],[-19.88,203.38],[-22.88,199.62],[-22.88,146.38]]);
    polygon([[-35.38,369.12],[-35.88,359.38],[-35.12,358.62],[-30.38,358.38],[-21.62,348.88],[-20.62,348.88],[-20.38,354.12],[-31.38,367.12],[-33.12,367.38],[-33.38,360.62],[-33.88,361.88],[-32.62,362.38],[-32.12,361.12]], [[0,1,2,3,4,5,6,7,8],[9,10,11,12]]);
    polygon([[-48.38,296.88],[-47.12,297.38],[-47.62,300.12],[-48.88,299.62]]);
    polygon([[-51.62,83.12],[-41.88,82.62],[-41.38,83.88],[-51.12,84.38]]);
    polygon([[-41.88,382.62],[-40.38,386.12],[-43.38,393.12],[-53.38,404.12],[-56.88,404.12],[-55.38,406.12],[-56.12,408.38],[-56.12,443.62],[-54.38,448.88],[-55.38,449.12],[-58.88,440.62],[-58.88,397.38],[-57.88,395.62],[-57.88,392.38],[-55.12,385.62],[-46.12,382.62]]);
    polygon([[-58.38,145.88],[-57.12,146.38],[-57.62,151.12],[-58.88,150.62]]);
    polygon([[-79.38,342.88],[-72.88,344.62],[-70.12,346.38],[-70.12,375.62],[-70.88,376.38],[-72.62,376.12],[-74.88,373.38],[-76.62,373.12],[-79.88,367.62]]);
    polygon([[-70.62,287.88],[-69.12,288.38],[-69.12,295.62],[-70.12,297.38],[-70.88,306.12],[-69.12,310.38],[-69.12,322.62],[-68.38,323.38],[-66.88,322.62],[-66.88,309.38],[-65.38,308.88],[-62.12,311.38],[-62.12,341.62],[-62.88,342.38],[-77.62,336.12],[-78.88,334.62],[-78.88,330.38],[-79.88,328.62],[-79.12,324.12],[-79.62,320.88],[-78.88,319.62],[-79.88,300.38],[-77.88,296.62],[-77.62,293.88],[-65.38,326.62],[-66.12,328.62],[-64.62,329.38],[-63.88,327.38],[-75.38,306.62],[-76.12,309.62],[-74.62,310.38],[-73.88,307.38],[-75.12,297.38],[-76.12,298.38],[-76.12,302.62],[-74.38,303.38],[-72.88,301.62],[-72.88,298.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],[24,25,26,27],[28,29,30,31],[32,33,34,35,36,37]]);
}

module decal_back_white() {
    polygon([[111.12,339.88],[113.62,339.38],[114.38,338.62],[116.62,338.62],[117.88,339.88],[117.88,343.12],[113.38,343.38],[112.88,341.88]]);
    polygon([[101.12,347.12],[101.38,346.62],[102.88,346.62],[104.38,345.62],[104.88,345.88],[104.62,347.38]]);
    polygon([[56.38,494.38],[56.12,492.88],[57.12,491.38],[57.12,488.88],[58.62,486.62],[60.88,488.88],[60.88,492.12],[59.62,493.38],[58.38,493.62],[57.62,494.38]]);
    polygon([[42.38,54.62],[43.88,54.88],[43.88,56.38],[45.88,59.88],[46.12,62.12],[49.88,68.88],[50.12,71.12],[52.88,75.88],[52.62,77.38],[50.12,75.12],[49.88,73.88],[47.12,71.12],[46.88,67.88],[44.38,67.38],[43.88,65.88],[41.12,63.12],[40.88,61.88],[40.12,61.12],[40.12,59.88],[40.88,59.12],[40.88,57.88],[40.12,56.88]]);
    polygon([[36.12,66.88],[37.38,64.62],[38.62,64.62],[40.88,67.12],[36.38,67.38]]);
    polygon([[29.38,597.62],[29.88,597.88],[29.62,602.38],[29.12,602.12]]);
    polygon([[24.12,233.88],[28.62,233.62],[28.88,234.12],[24.38,234.38]]);
    polygon([[23.12,300.12],[24.38,297.62],[25.88,298.88],[24.62,300.38]]);
    polygon([[21.12,310.12],[21.38,309.62],[23.62,309.38],[24.38,308.62],[25.88,308.88],[25.62,310.38]]);
    polygon([[-3.88,204.88],[0.62,204.62],[0.88,205.12],[-3.62,205.38]]);
    polygon([[-9.88,34.88],[-1.38,34.62],[-1.12,35.12],[-9.62,35.38]]);
    polygon([[-9.88,22.88],[-1.38,22.62],[-1.38,23.38],[-7.62,23.62],[-9.12,25.62],[-9.12,27.38],[-8.62,28.38],[-2.38,28.62],[-2.12,30.12],[-9.62,30.38]]);
    polygon([[-12.62,27.62],[-12.12,27.88],[-12.38,30.38],[-12.88,30.12]]);
    polygon([[-24.88,297.88],[-23.38,297.62],[-22.62,298.38],[-21.38,298.62],[-20.12,300.12],[-21.38,301.38],[-22.62,301.38],[-22.88,300.88],[-22.38,299.88],[-23.62,299.38]]);
    polygon([[-24.88,291.88],[-24.38,291.62],[-23.88,293.12],[-22.38,293.62],[-21.12,295.12],[-22.62,295.38],[-23.38,294.62],[-24.62,294.38]]);
    polygon([[-24.88,287.12],[-24.62,286.62],[-22.38,286.38],[-21.62,285.62],[-20.12,285.88],[-20.38,287.38]]);
    polygon([[-25.88,305.88],[-24.38,305.62],[-22.62,307.38],[-20.38,307.62],[-20.12,308.12],[-22.62,308.62],[-24.38,310.38],[-25.62,310.38],[-25.88,309.88],[-24.38,308.38],[-24.38,307.62]]);
    polygon([[-25.88,281.88],[-20.38,281.62],[-20.12,282.12],[-22.88,282.38],[-24.62,283.38]]);
    polygon([[-29.88,235.12],[-29.62,233.62],[-23.12,233.88],[-23.38,234.38],[-27.88,234.38],[-29.38,235.38]]);
    polygon([[-37.62,148.62],[-37.12,148.88],[-37.38,151.38],[-37.88,151.12]]);
    polygon([[-38.88,324.88],[-37.38,324.62],[-37.12,326.12],[-37.62,326.38]]);
    polygon([[-39.88,67.12],[-38.62,64.62],[-37.38,64.62],[-36.12,65.88],[-36.38,67.38]]);
    polygon([[-41.62,166.38],[-41.88,163.88],[-40.88,162.62],[-40.88,159.88],[-40.38,159.62],[-40.12,163.12],[-41.12,164.38],[-41.12,166.12]]);
    polygon([[-41.62,151.38],[-41.88,149.88],[-41.12,149.12],[-40.88,147.88],[-39.38,146.62],[-38.88,148.62],[-39.88,149.88],[-40.12,151.12]]);
    polygon([[-45.62,166.38],[-45.88,165.88],[-45.12,165.12],[-44.88,162.88],[-43.88,161.38],[-43.88,158.88],[-43.12,158.12],[-42.88,156.88],[-41.38,155.62],[-41.12,157.12],[-42.88,158.88],[-42.12,159.88],[-43.12,161.62],[-42.88,163.62],[-43.88,164.88],[-44.12,166.12]]);
    polygon([[-52.62,78.38],[-52.88,76.88],[-50.12,72.12],[-49.88,69.88],[-46.12,63.12],[-45.88,60.88],[-45.12,60.12],[-42.88,54.88],[-42.38,54.62],[-40.12,55.88],[-40.62,58.38],[-39.12,61.12],[-41.88,63.88],[-42.12,65.12],[-44.38,67.38],[-45.88,67.88],[-46.12,70.12],[-47.88,71.88],[-48.12,73.12],[-50.88,75.88],[-51.12,77.12]]);
    polygon([[-54.62,486.62],[-53.12,486.88],[-53.38,489.38],[-54.88,487.12]]);
    polygon([[-59.62,480.62],[-58.12,481.88],[-58.38,484.38],[-59.88,483.12]]);
    polygon([[-59.62,487.62],[-57.12,487.88],[-57.12,490.38],[-56.12,491.88],[-56.38,494.38],[-58.62,494.38],[-60.88,493.12],[-60.88,488.88]]);
    polygon([[-117.88,343.12],[-117.88,340.88],[-115.62,338.62],[-114.38,338.62],[-112.88,339.62],[-110.12,339.88],[-113.38,343.38]]);
    polygon([[-122.88,326.12],[-122.62,324.62],[-121.12,324.88],[-122.38,326.38]]);
}

module decal_back_yellow() {
    polygon([[47.12,474.12],[46.38,473.12],[46.88,471.88],[46.12,470.12],[48.38,467.62],[49.62,466.88],[51.62,469.12],[49.88,472.12],[49.62,473.38],[48.38,474.38]]);
    polygon([[41.38,349.88],[42.62,348.88],[43.62,350.12],[42.38,351.12]]);
    polygon([[31.62,284.62],[32.88,284.88],[33.62,285.88],[33.12,286.88],[33.62,288.12],[32.38,289.38],[31.12,289.12],[30.38,288.12],[30.88,287.12],[30.38,285.88]]);
    polygon([[24.38,390.88],[25.88,392.12],[25.88,393.88],[24.62,395.12],[23.12,393.88],[23.12,392.12]]);
    polygon([[23.38,229.62],[24.38,228.88],[25.62,229.62],[27.62,228.88],[28.88,230.12],[28.88,231.88],[29.62,233.12],[28.38,234.38],[27.12,234.12],[26.38,233.12],[26.88,231.88],[25.62,231.38],[24.38,232.12],[23.12,230.88]]);
    polygon([[18.38,577.88],[20.62,579.88],[20.12,581.12],[20.88,582.12],[20.88,583.88],[19.62,585.12],[18.12,583.88],[18.12,582.12],[18.88,580.88],[17.38,578.88]]);
    polygon([[11.38,417.88],[12.62,416.88],[13.62,418.12],[12.38,419.12]]);
    polygon([[8.38,391.88],[9.62,390.88],[10.62,392.12],[9.38,393.12]]);
    polygon([[8.38,130.88],[9.62,129.88],[10.62,131.12],[9.38,132.12]]);
    polygon([[2.38,204.88],[3.38,203.88],[5.88,204.88],[6.88,206.12],[6.62,207.38],[5.38,208.38],[3.12,208.12],[2.38,207.12],[2.88,206.12]]);
    polygon([[-0.62,128.88],[0.62,127.88],[1.62,129.12],[0.38,130.12]]);
    polygon([[-2.88,132.12],[-1.38,130.88],[-0.38,131.62],[-0.12,132.88],[-1.62,134.12],[-2.62,133.38]]);
    polygon([[-4.88,206.12],[-3.88,204.88],[-2.62,204.62],[-1.38,205.62],[-1.12,206.88],[-2.12,208.12],[-3.38,208.38],[-4.62,207.38]]);
    polygon([[-8.62,130.88],[-7.38,129.88],[-6.38,131.12],[-7.62,132.12]]);
    polygon([[-24.88,392.12],[-23.38,390.88],[-22.38,391.62],[-22.12,392.88],[-23.62,394.12],[-24.62,393.38]]);
    polygon([[-24.62,229.88],[-23.12,231.12],[-23.12,232.88],[-24.38,234.12],[-25.88,232.88],[-25.88,231.12]]);
    polygon([[-29.88,230.12],[-28.38,228.88],[-27.38,229.62],[-27.12,230.88],[-28.62,232.12],[-29.62,231.38]]);
    polygon([[-31.38,284.62],[-29.62,284.62],[-28.38,285.88],[-29.88,287.88],[-28.38,290.88],[-29.62,292.38],[-31.38,292.38],[-32.62,291.12],[-32.12,290.12],[-32.62,288.88],[-31.88,287.88],[-32.62,285.88]]);
    polygon([[-48.62,464.88],[-47.38,465.62],[-47.12,466.88],[-45.12,470.12],[-45.38,471.38],[-46.62,472.38],[-48.38,472.38],[-49.88,470.88],[-49.88,468.12],[-50.62,466.88]]);
    polygon([[-58.62,130.88],[-57.38,129.88],[-56.38,131.12],[-57.62,132.12]]);
}

module decal_left_orange() {
    polygon([[-36.12,378.62],[-36.12,372.38],[-43.12,366.62],[-43.12,358.38],[-43.88,357.62],[-55.12,357.62],[-65.38,349.88],[-67.12,349.62],[-68.62,347.88],[-69.88,348.38],[-69.88,352.62],[-67.88,353.38],[-66.12,356.38],[-55.62,365.12],[-52.12,367.38],[-50.62,367.38],[-46.88,372.12],[-39.62,378.12],[-37.62,379.12],[-48.88,360.38],[-48.12,362.12],[-48.88,365.62],[-50.12,366.62],[-51.12,365.62],[-51.12,361.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18],[19,20,21,22,23,24]]);
    polygon([[-26.62,280.88],[-27.62,280.88],[-28.88,282.38],[-28.38,285.12],[-27.12,284.62]]);
    polygon([[-20.38,287.12],[-22.12,286.62],[-22.88,288.62],[-21.38,289.12]]);
    polygon([[-15.38,158.12],[-18.12,157.62],[-19.12,161.12],[-21.38,161.88],[-21.62,162.88],[-17.88,162.38]]);
    polygon([[-15.62,374.12],[-15.12,370.38],[-18.12,364.88],[-18.12,362.38],[-19.38,361.88],[-19.88,363.62],[-18.88,365.12],[-18.88,372.62]]);
    polygon([[-14.88,293.62],[-19.88,295.38],[-19.38,302.12],[-18.12,301.62],[-17.88,299.88],[-14.38,295.12]]);
    polygon([[-12.12,136.38],[-12.88,135.62],[-17.12,135.62],[-17.88,138.62],[-17.12,139.38],[-12.88,139.38]]);
    polygon([[-6.38,124.12],[-17.12,123.62],[-17.88,124.38],[-17.88,132.62],[-17.12,133.38],[-12.88,133.38],[-12.12,132.62],[-12.88,126.12],[-12.12,125.38],[-6.88,125.38]]);
    polygon([[-6.38,79.12],[-12.12,78.62],[-12.62,79.88],[-6.88,80.38]]);
    polygon([[-5.38,83.12],[-10.12,82.62],[-10.62,83.88],[-5.88,84.38]]);
    polygon([[-2.12,144.38],[-4.12,143.62],[-5.88,145.62],[-11.12,146.62],[-12.88,145.62],[-16.12,145.62],[-18.38,143.88],[-18.88,148.62],[-17.88,150.38],[-17.88,154.62],[-12.38,156.62],[-11.12,158.38],[-3.88,158.38],[-3.38,156.88],[-5.12,147.38],[-2.88,146.38],[-9.12,149.12],[-9.88,150.62],[-11.88,149.88],[-11.12,148.38],[-8.12,155.12],[-8.88,156.62],[-10.88,155.88],[-10.12,154.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],[16,17,18,19],[20,21,22,23]]);
    polygon([[-5.88,557.38],[2.12,554.38],[4.62,549.12],[3.38,548.88],[-2.88,552.62],[-5.12,552.62],[-6.12,551.62],[-6.12,534.38],[-3.12,532.62],[-3.12,520.38],[-3.88,519.62],[-9.12,519.62],[-9.88,520.38],[-9.88,531.62],[-8.88,533.38],[-8.88,556.62]]);
    polygon([[6.88,214.62],[6.88,213.38],[4.88,211.62],[3.62,208.88],[2.62,208.88],[1.12,210.62],[-1.12,210.62],[-4.88,208.62],[-5.88,204.62],[-8.12,204.62],[-9.88,202.62],[-12.12,202.62],[-16.38,195.62],[-19.38,192.88],[-20.88,193.38],[-20.88,196.62],[-17.88,200.38],[-18.88,203.38],[-18.12,207.88],[-18.88,213.62],[-18.12,214.38],[-12.88,214.38],[-10.12,212.38],[-9.62,213.88],[-7.62,215.12],[1.12,214.38],[2.88,215.38],[6.12,215.38],[-4.88,208.62],[-4.88,210.62],[-6.38,212.38],[-10.12,212.38],[-8.62,209.62],[-6.12,208.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27],[28,29,30,31,32,33]]);
    polygon([[10.62,83.12],[7.88,81.62],[6.88,79.38],[5.62,78.88],[2.38,83.88],[10.12,84.38]]);
    polygon([[11.12,121.38],[11.62,119.88],[10.12,118.12],[10.88,115.62],[10.88,105.38],[9.88,103.88],[10.88,101.62],[10.88,87.38],[-13.12,87.62],[-13.62,89.12],[-12.12,91.88],[-12.88,94.38],[-12.88,101.62],[-11.88,104.62],[-12.88,107.62],[-11.88,109.38],[-11.88,113.62],[-13.62,115.88],[-13.12,118.88],[-16.38,118.88],[-16.62,120.12],[-15.12,121.38],[3.12,102.62],[2.12,103.62],[-3.12,103.62],[-7.12,104.62],[-8.62,106.38],[-10.12,105.62],[-10.12,103.38],[-9.12,102.38],[-5.88,102.38],[-2.12,100.38],[0.12,100.38],[9.12,105.62],[6.88,106.62],[3.88,103.38],[4.88,102.38],[7.12,102.38],[9.12,104.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21],[22,23,24,25,26,27,28,29,30,31,32],[33,34,35,36,37,38]]);
    polygon([[10.12,546.38],[14.62,540.12],[14.62,538.88],[11.88,535.62],[11.38,517.88],[9.12,519.62],[1.88,519.62],[1.12,520.38],[1.12,529.62],[2.62,530.12],[5.12,529.38],[6.12,530.38],[6.12,538.62],[4.12,541.38],[4.12,543.62],[6.88,546.38]]);
    polygon([[3.88,123.62],[3.88,125.38],[11.12,125.38],[11.88,126.12],[11.12,132.62],[12.88,134.88],[11.12,136.38],[11.12,138.62],[17.12,140.38],[17.88,139.62],[17.88,124.38],[17.12,123.62]]);
    polygon([[19.88,220.38],[18.12,216.62],[13.88,216.62],[12.12,220.62],[-11.12,220.62],[-13.38,221.38],[-14.12,220.62],[-14.12,217.38],[-14.88,216.62],[-18.12,216.62],[-18.88,217.38],[-18.88,220.62],[-20.88,222.38],[-20.88,227.62],[-18.88,228.38],[-14.88,227.38],[-14.88,224.12],[-14.12,223.38],[-7.88,223.38],[-6.62,222.62],[2.12,223.38],[6.12,222.38],[7.88,223.38],[12.38,222.62],[13.12,223.38],[13.12,226.62],[18.12,228.38],[19.88,225.62],[17.38,220.62],[17.88,221.88],[16.62,222.38],[16.12,221.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27],[28,29,30,31]]);
    polygon([[20.38,184.88],[18.38,185.88],[19.12,191.62],[17.88,195.12],[12.38,200.12],[13.88,202.88],[13.12,203.62],[8.88,203.62],[3.38,205.12],[3.88,206.38],[6.12,207.38],[6.38,209.12],[9.88,212.88],[9.12,215.38],[9.62,217.12],[10.88,216.62],[11.88,214.38],[18.12,214.38],[18.88,213.62],[18.88,204.38],[16.88,203.62],[16.12,202.12],[16.88,201.38],[19.38,202.12],[20.88,201.62]]);
    polygon([[6.38,144.88],[5.12,146.38],[5.12,149.62],[4.12,151.38],[4.38,156.12],[5.38,157.12],[6.38,157.12],[7.88,155.38],[11.12,155.38],[13.12,156.38],[14.38,159.12],[18.12,163.38],[18.12,167.62],[19.12,170.62],[20.38,171.12],[20.88,145.38],[17.62,143.88],[18.12,148.62],[16.62,149.38],[15.62,145.88],[14.12,144.62],[11.12,145.62]]);
    polygon([[19.38,379.88],[14.12,382.38],[14.12,394.62],[14.88,395.88],[14.12,397.62],[11.88,396.62],[11.88,383.38],[9.88,382.62],[8.12,383.62],[1.88,383.62],[1.12,384.38],[1.88,389.12],[1.12,390.38],[1.12,400.62],[0.12,401.62],[-2.12,401.62],[-3.12,400.62],[-3.12,384.38],[-3.88,383.62],[-11.12,383.62],[-19.88,379.62],[-24.12,379.62],[-24.88,380.38],[-24.88,389.62],[-23.12,391.12],[-24.62,394.12],[-15.88,404.38],[-15.88,405.62],[-13.88,408.38],[-13.88,443.62],[-9.88,445.38],[-9.38,455.12],[-3.88,454.38],[-3.12,453.62],[-3.12,438.38],[-2.12,437.38],[0.12,437.38],[1.12,438.38],[1.12,454.62],[4.12,455.38],[6.38,453.62],[7.88,455.38],[11.38,457.12],[12.88,456.62],[12.88,404.38],[21.88,393.62],[21.88,392.38],[19.88,390.62],[-6.62,409.62],[-5.88,411.62],[-7.38,412.38],[-8.12,410.38],[-3.12,419.38],[-2.88,421.62],[-4.38,422.38],[-5.12,420.38],[2.12,434.62],[-3.12,434.62],[-4.12,433.62],[-4.12,430.38],[-2.12,428.62],[-2.12,427.38],[-3.88,425.88],[-3.12,424.38],[1.12,424.38],[1.88,425.12],[0.12,427.38],[0.12,428.62],[3.12,430.38],[3.12,433.62],[3.12,421.62],[1.62,422.38],[0.12,419.62],[-2.88,419.62],[-2.88,417.88],[1.12,417.38],[2.38,404.62],[3.12,405.38],[3.12,408.62],[2.38,409.38],[0.12,408.62],[-1.62,409.12],[-1.12,410.38],[2.12,412.38],[2.12,413.62],[-3.12,416.62],[-3.88,415.88],[-3.12,412.38],[-4.12,410.62],[-4.12,407.38],[-2.12,405.38],[6.38,387.62],[6.88,388.88],[5.62,389.38],[5.12,388.12],[6.38,426.62],[7.12,429.62],[5.62,430.38],[4.88,427.38],[6.38,408.62],[7.12,410.62],[5.62,411.38],[4.88,409.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47],[48,49,50,51],[52,53,54,55],[56,57,58,59,60,61,62,63,64,65,66,67,68,69],[70,71,72,73,74,75],[76,77,78,79,80,81,82,83,84,85,86,87,88,89,90],[91,92,93,94],[95,96,97,98],[99,100,101,102]]);
    polygon([[14.62,377.12],[17.62,376.12],[19.62,372.62],[24.12,373.38],[25.62,371.12],[24.88,366.38],[22.12,364.12],[20.88,360.62],[21.88,357.38],[24.88,355.62],[24.88,346.38],[20.12,342.62],[18.12,343.38],[18.12,350.62],[19.12,353.62],[18.12,355.38],[18.12,362.62],[14.12,369.38],[17.38,370.62],[17.88,371.88],[16.62,372.38],[16.12,371.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17],[18,19,20,21]]);
    polygon([[25.38,431.88],[24.12,432.38],[24.62,442.12],[25.88,441.62]]);
    polygon([[30.62,445.88],[30.12,444.62],[27.38,444.12],[27.88,445.38]]);
    polygon([[19.88,324.62],[19.12,325.38],[19.38,336.12],[30.38,342.12],[30.88,325.38],[30.12,324.62],[23.38,328.62],[23.88,329.88],[22.62,330.38],[22.12,329.12]], [[0,1,2,3,4,5],[6,7,8,9]]);
    polygon([[15.62,275.88],[15.12,284.62],[16.88,286.88],[14.12,289.38],[14.12,298.62],[19.12,308.38],[19.12,321.62],[19.88,322.38],[21.88,321.62],[21.88,304.38],[19.88,302.62],[19.88,298.38],[21.88,296.62],[21.88,292.38],[20.12,290.12],[20.12,288.88],[21.88,287.38],[24.12,287.38],[24.88,288.12],[23.38,290.12],[24.12,296.62],[26.12,298.38],[26.12,300.62],[24.12,302.38],[24.12,321.62],[24.88,322.38],[30.12,322.38],[30.88,321.62],[30.88,283.38],[24.12,278.62],[18.12,292.38],[16.62,292.38],[16.12,291.12],[17.38,290.62],[18.12,292.38],[20.12,293.38],[19.38,295.38],[17.88,294.62],[27.38,283.62],[27.88,284.88],[26.62,285.38],[26.12,284.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29],[30,31,32,33],[34,35,36,37],[38,39,40,41]]);
    polygon([[50.62,83.12],[41.88,82.62],[41.38,83.88],[50.12,84.38]]);
    polygon([[59.12,144.62],[54.88,144.62],[54.12,145.38],[54.12,195.62],[54.88,196.38],[56.88,195.62],[56.88,167.38],[56.12,166.12],[56.88,161.38],[55.88,158.38],[57.88,152.38],[59.88,150.62],[59.88,145.38]]);
    polygon([[69.88,347.38],[68.38,346.88],[54.12,357.62],[44.88,357.62],[43.12,358.62],[35.88,357.62],[35.12,358.38],[35.12,378.62],[37.12,379.38],[39.62,377.12],[38.88,371.38],[39.88,370.38],[43.12,370.38],[44.62,372.12],[45.62,372.12],[49.62,369.12],[50.88,366.38],[54.62,365.12],[64.88,357.12],[67.88,353.38],[69.12,353.38],[69.88,352.62],[43.12,360.38],[44.12,361.38],[44.12,364.62],[43.12,365.62],[40.88,365.62],[39.88,364.62],[39.88,361.38],[40.88,360.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21],[22,23,24,25,26,27,28,29]]);
}

module decal_left_white() {
    polygon([[-77.12,176.88],[-78.38,175.62],[-81.62,175.62],[-81.88,180.12],[-80.38,180.62],[-78.62,182.38],[-77.38,182.38]]);
    polygon([[-63.12,307.88],[-66.62,307.62],[-66.88,308.12],[-63.38,308.38]]);
    polygon([[-60.12,297.88],[-62.62,297.62],[-62.88,298.12],[-60.38,298.38]]);
    polygon([[-60.12,292.88],[-61.38,291.62],[-62.62,291.62],[-62.88,292.12],[-62.12,293.12],[-64.62,293.62],[-64.88,295.12],[-64.38,295.38],[-63.62,294.62],[-60.38,293.38]]);
    polygon([[-60.12,286.88],[-64.62,286.62],[-64.88,287.12],[-60.38,287.38]]);
    polygon([[-60.12,281.88],[-66.62,281.62],[-66.88,282.12],[-63.12,282.38],[-61.38,283.38]]);
    polygon([[-49.12,7.88],[-52.62,7.62],[-52.88,8.12],[-49.38,8.38]]);
    polygon([[-42.38,54.62],[-43.88,54.88],[-44.12,57.12],[-46.88,61.88],[-47.12,64.12],[-49.88,68.88],[-50.12,71.12],[-53.88,77.88],[-53.62,78.38],[-52.12,78.12],[-51.88,76.88],[-50.12,75.12],[-49.88,73.88],[-47.12,71.12],[-46.88,67.88],[-44.38,67.38],[-43.88,65.88],[-41.12,63.12],[-40.88,61.88],[-40.12,61.12],[-40.12,59.88],[-41.12,58.38],[-41.12,55.88]]);
    polygon([[-36.12,66.88],[-37.38,64.62],[-38.62,64.62],[-40.88,67.12],[-36.38,67.38]]);
    polygon([[-32.38,607.62],[-32.88,607.88],[-33.12,611.12],[-33.88,611.88],[-33.88,615.12],[-32.62,616.38],[-32.12,616.12]]);
    polygon([[-24.12,233.88],[-28.62,233.62],[-28.88,234.12],[-24.38,234.38]]);
    polygon([[-23.38,499.62],[-23.88,499.88],[-23.62,506.38],[-23.12,506.12]]);
    polygon([[3.62,13.62],[3.12,13.88],[3.38,16.38],[3.88,16.12]]);
    polygon([[9.62,30.38],[10.12,29.62],[9.88,22.88],[4.38,22.62],[4.12,24.12],[5.88,25.88],[5.88,27.12],[4.12,27.88],[3.12,30.12]]);
    polygon([[15.62,22.62],[12.12,22.88],[12.62,24.38],[12.12,24.88],[12.12,28.38],[11.12,29.88],[11.38,30.38],[15.88,30.12],[14.38,28.38],[14.88,26.88],[14.12,26.12],[14.12,24.88],[15.88,23.12]]);
    polygon([[15.88,17.88],[14.38,17.38],[13.12,16.12],[12.88,14.62],[13.88,12.88],[12.38,12.12],[12.88,10.88],[11.62,9.62],[8.38,9.62],[7.12,10.88],[7.62,12.12],[5.12,12.88],[5.38,13.38],[6.88,13.88],[6.88,15.12],[5.12,15.88],[5.62,17.12],[4.62,17.62],[1.38,17.62],[1.12,18.12],[4.88,18.38],[6.38,19.38],[12.62,19.38],[13.38,18.62],[15.62,18.38]]);
    polygon([[17.88,515.88],[16.38,515.62],[16.12,517.12],[16.62,517.38]]);
    polygon([[29.88,235.12],[29.62,233.62],[23.12,233.88],[23.38,234.38],[27.88,234.38],[29.38,235.38]]);
    polygon([[39.62,67.38],[39.88,66.88],[39.12,66.12],[38.88,64.88],[37.38,63.62],[36.12,65.88],[36.12,67.12]]);
    polygon([[46.62,12.62],[46.12,12.88],[46.38,15.38],[46.88,15.12]]);
    polygon([[46.62,7.62],[46.12,7.88],[46.38,11.38],[46.88,11.12]]);
    polygon([[52.62,78.38],[52.88,76.88],[50.12,72.12],[49.88,69.88],[46.12,63.12],[45.88,60.88],[45.12,60.12],[42.88,54.88],[42.38,54.62],[41.62,55.38],[40.38,55.62],[39.12,56.88],[39.88,57.88],[39.12,61.12],[42.88,64.88],[43.12,66.12],[44.38,67.38],[45.88,67.88],[46.12,70.12],[47.88,71.88],[48.12,73.12],[50.88,75.88],[51.12,77.12]]);
    polygon([[56.88,220.88],[56.38,220.62],[55.12,222.12],[56.62,222.38]]);
    polygon([[62.88,301.12],[61.62,299.62],[61.12,299.88],[61.38,301.38]]);
    polygon([[64.62,287.62],[64.12,287.88],[64.12,290.62],[63.12,291.62],[61.12,290.12],[60.88,287.88],[60.12,287.88],[60.12,290.12],[61.38,292.38],[63.62,292.38],[64.88,291.12]]);
    polygon([[66.88,281.88],[65.38,281.62],[64.12,282.12],[63.38,281.62],[62.12,282.12],[61.38,281.62],[61.12,283.12],[66.62,283.38]]);
    polygon([[72.62,337.62],[72.12,337.88],[72.38,345.38],[72.88,345.12]]);
    polygon([[72.62,311.62],[72.12,311.88],[72.38,323.38],[72.88,323.12]]);
    polygon([[72.62,289.62],[72.12,289.88],[72.38,297.38],[72.88,297.12]]);
    polygon([[80.62,175.62],[78.38,175.62],[76.12,177.88],[76.12,179.12],[76.88,179.88],[77.38,182.38],[78.62,182.38],[80.88,180.12]]);
}

module decal_left_yellow() {
    polygon([[-50.38,288.88],[-51.62,287.88],[-52.62,289.12],[-51.38,290.12]]);
    polygon([[-50.38,283.88],[-51.62,282.88],[-52.62,284.12],[-51.38,285.12]]);
    polygon([[-41.38,392.88],[-42.88,394.12],[-42.12,395.88],[-42.88,397.88],[-41.62,399.12],[-40.12,397.88],[-40.88,396.12],[-40.12,394.12]]);
    polygon([[-27.38,228.88],[-29.62,230.88],[-29.12,231.88],[-29.62,233.12],[-28.38,234.38],[-27.12,234.12],[-26.12,232.88],[-26.12,230.12]]);
    polygon([[-5.12,464.12],[-6.12,462.88],[-7.38,462.62],[-8.62,463.62],[-8.88,464.88],[-7.88,466.12],[-6.62,466.38],[-5.38,465.38]]);
    polygon([[-1.38,306.88],[-3.62,304.88],[-4.88,306.12],[-4.88,307.88],[-3.38,309.12]]);
    polygon([[-1.38,461.88],[-2.88,463.12],[-2.88,464.88],[-1.62,466.12],[-0.12,464.88],[-0.12,463.12]]);
    polygon([[1.62,304.88],[0.12,306.12],[0.12,307.88],[1.38,309.12],[2.88,307.88],[2.88,306.12]]);
    polygon([[2.88,132.12],[1.38,130.88],[0.38,131.62],[0.12,132.88],[1.62,134.12],[2.62,133.38]]);
    polygon([[8.62,130.88],[7.38,129.88],[6.38,131.12],[7.62,132.12]]);
    polygon([[17.38,459.62],[16.12,459.88],[15.38,460.88],[15.88,462.12],[15.12,463.12],[15.12,468.88],[15.88,469.88],[15.12,471.88],[16.62,473.38],[17.88,473.12],[19.62,471.12],[19.12,470.12],[19.62,468.88],[18.88,467.88],[18.88,467.12],[19.88,465.88],[19.12,464.12],[19.62,462.88],[18.62,460.62]]);
    polygon([[25.88,232.12],[24.38,230.88],[23.38,231.62],[23.12,232.88],[24.62,234.12],[25.62,233.38]]);
    polygon([[51.38,282.62],[49.62,282.62],[48.38,283.88],[49.12,285.12],[48.38,286.88],[48.88,287.88],[48.38,289.12],[49.62,290.38],[51.38,290.38],[52.62,289.12],[50.12,286.12],[50.62,285.38],[51.88,285.12],[52.62,284.12]]);
}

module decal_left_orange_unlettered() {
    polygon([[-36.12,378.62],[-36.12,372.38],[-43.12,366.62],[-43.12,358.38],[-43.88,357.62],[-55.12,357.62],[-65.38,349.88],[-67.12,349.62],[-68.62,347.88],[-69.88,348.38],[-69.88,352.62],[-67.88,353.38],[-66.12,356.38],[-55.62,365.12],[-52.12,367.38],[-50.62,367.38],[-46.88,372.12],[-39.62,378.12],[-37.62,379.12],[-48.88,360.38],[-48.12,362.12],[-48.88,365.62],[-50.12,366.62],[-51.12,365.62],[-51.12,361.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18],[19,20,21,22,23,24]]);
    polygon([[-26.62,280.88],[-27.62,280.88],[-28.88,282.38],[-28.38,285.12],[-27.12,284.62]]);
    polygon([[-20.38,287.12],[-22.12,286.62],[-22.88,288.62],[-21.38,289.12]]);
    polygon([[-15.38,158.12],[-18.12,157.62],[-19.12,161.12],[-21.38,161.88],[-21.62,162.88],[-17.88,162.38]]);
    polygon([[-15.62,374.12],[-15.12,370.38],[-18.12,364.88],[-18.12,362.38],[-19.38,361.88],[-19.88,363.62],[-18.88,365.12],[-18.88,372.62]]);
    polygon([[-14.88,293.62],[-19.88,295.38],[-19.38,302.12],[-18.12,301.62],[-17.88,299.88],[-14.38,295.12]]);
    polygon([[-12.12,136.38],[-12.88,135.62],[-17.12,135.62],[-17.88,138.62],[-17.12,139.38],[-12.88,139.38]]);
    polygon([[-6.38,124.12],[-17.12,123.62],[-17.88,124.38],[-17.88,132.62],[-17.12,133.38],[-12.88,133.38],[-12.12,132.62],[-12.88,126.12],[-12.12,125.38],[-6.88,125.38]]);
    polygon([[-6.38,79.12],[-12.12,78.62],[-12.62,79.88],[-6.88,80.38]]);
    polygon([[-5.38,83.12],[-10.12,82.62],[-10.62,83.88],[-5.88,84.38]]);
    polygon([[-2.12,144.38],[-4.12,143.62],[-5.88,145.62],[-11.12,146.62],[-12.88,145.62],[-16.12,145.62],[-18.38,143.88],[-18.88,148.62],[-17.88,150.38],[-17.88,154.62],[-12.38,156.62],[-11.12,158.38],[-3.88,158.38],[-3.38,156.88],[-5.12,147.38],[-2.88,146.38],[-9.12,149.12],[-9.88,150.62],[-11.88,149.88],[-11.12,148.38],[-8.12,155.12],[-8.88,156.62],[-10.88,155.88],[-10.12,154.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],[16,17,18,19],[20,21,22,23]]);
    polygon([[-5.88,557.38],[2.12,554.38],[4.62,549.12],[3.38,548.88],[-2.88,552.62],[-5.12,552.62],[-6.12,551.62],[-6.12,534.38],[-3.12,532.62],[-3.12,520.38],[-3.88,519.62],[-9.12,519.62],[-9.88,520.38],[-9.88,531.62],[-8.88,533.38],[-8.88,556.62]]);
    polygon([[6.88,214.62],[6.88,213.38],[4.88,211.62],[3.62,208.88],[2.62,208.88],[1.12,210.62],[-1.12,210.62],[-4.88,208.62],[-5.88,204.62],[-8.12,204.62],[-9.88,202.62],[-12.12,202.62],[-16.38,195.62],[-19.38,192.88],[-20.88,193.38],[-20.88,196.62],[-17.88,200.38],[-18.88,203.38],[-18.12,207.88],[-18.88,213.62],[-18.12,214.38],[-12.88,214.38],[-10.12,212.38],[-9.62,213.88],[-7.62,215.12],[1.12,214.38],[2.88,215.38],[6.12,215.38],[-4.88,208.62],[-4.88,210.62],[-6.38,212.38],[-10.12,212.38],[-8.62,209.62],[-6.12,208.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27],[28,29,30,31,32,33]]);
    polygon([[10.62,83.12],[7.88,81.62],[6.88,79.38],[5.62,78.88],[2.38,83.88],[10.12,84.38]]);
    polygon([[11.12,121.38],[11.62,119.88],[10.12,118.12],[10.88,115.62],[10.88,105.38],[9.88,103.88],[10.88,101.62],[10.88,87.38],[-13.12,87.62],[-13.62,89.12],[-12.12,91.88],[-12.88,94.38],[-12.88,101.62],[-11.88,104.62],[-12.88,107.62],[-11.88,109.38],[-11.88,113.62],[-13.62,115.88],[-13.12,118.88],[-16.38,118.88],[-16.62,120.12],[-15.12,121.38],[3.12,102.62],[2.12,103.62],[-3.12,103.62],[-7.12,104.62],[-8.62,106.38],[-10.12,105.62],[-10.12,103.38],[-9.12,102.38],[-5.88,102.38],[-2.12,100.38],[0.12,100.38],[9.12,105.62],[6.88,106.62],[3.88,103.38],[4.88,102.38],[7.12,102.38],[9.12,104.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21],[22,23,24,25,26,27,28,29,30,31,32],[33,34,35,36,37,38]]);
    polygon([[10.12,546.38],[14.62,540.12],[14.62,538.88],[11.88,535.62],[11.38,517.88],[9.12,519.62],[1.88,519.62],[1.12,520.38],[1.12,529.62],[2.62,530.12],[5.12,529.38],[6.12,530.38],[6.12,538.62],[4.12,541.38],[4.12,543.62],[6.88,546.38]]);
    polygon([[3.88,123.62],[3.88,125.38],[11.12,125.38],[11.88,126.12],[11.12,132.62],[12.88,134.88],[11.12,136.38],[11.12,138.62],[17.12,140.38],[17.88,139.62],[17.88,124.38],[17.12,123.62]]);
    polygon([[19.88,220.38],[18.12,216.62],[13.88,216.62],[12.12,220.62],[-11.12,220.62],[-13.38,221.38],[-14.12,220.62],[-14.12,217.38],[-14.88,216.62],[-18.12,216.62],[-18.88,217.38],[-18.88,220.62],[-20.88,222.38],[-20.88,227.62],[-18.88,228.38],[-14.88,227.38],[-14.88,224.12],[-14.12,223.38],[-7.88,223.38],[-6.62,222.62],[2.12,223.38],[6.12,222.38],[7.88,223.38],[12.38,222.62],[13.12,223.38],[13.12,226.62],[18.12,228.38],[19.88,225.62],[17.38,220.62],[17.88,221.88],[16.62,222.38],[16.12,221.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27],[28,29,30,31]]);
    polygon([[20.38,184.88],[18.38,185.88],[19.12,191.62],[17.88,195.12],[12.38,200.12],[13.88,202.88],[13.12,203.62],[8.88,203.62],[3.38,205.12],[3.88,206.38],[6.12,207.38],[6.38,209.12],[9.88,212.88],[9.12,215.38],[9.62,217.12],[10.88,216.62],[11.88,214.38],[18.12,214.38],[18.88,213.62],[18.88,204.38],[16.88,203.62],[16.12,202.12],[16.88,201.38],[19.38,202.12],[20.88,201.62]]);
    polygon([[6.38,144.88],[5.12,146.38],[5.12,149.62],[4.12,151.38],[4.38,156.12],[5.38,157.12],[6.38,157.12],[7.88,155.38],[11.12,155.38],[13.12,156.38],[14.38,159.12],[18.12,163.38],[18.12,167.62],[19.12,170.62],[20.38,171.12],[20.88,145.38],[17.62,143.88],[18.12,148.62],[16.62,149.38],[15.62,145.88],[14.12,144.62],[11.12,145.62]]);
    polygon([[19.38,379.88],[14.12,382.38],[14.12,394.62],[14.88,395.88],[14.12,397.62],[11.88,396.62],[11.88,383.38],[9.88,382.62],[8.12,383.62],[1.88,383.62],[1.12,384.38],[1.88,389.12],[1.12,390.38],[1.12,400.62],[0.12,401.62],[-2.12,401.62],[-3.12,400.62],[-3.12,384.38],[-3.88,383.62],[-11.12,383.62],[-19.88,379.62],[-24.12,379.62],[-24.88,380.38],[-24.88,389.62],[-23.12,391.12],[-24.62,394.12],[-15.88,404.38],[-15.88,405.62],[-13.88,408.38],[-13.88,443.62],[-9.88,445.38],[-9.38,455.12],[-3.88,454.38],[-3.12,453.62],[-3.12,438.38],[-2.12,437.38],[0.12,437.38],[1.12,438.38],[1.12,454.62],[4.12,455.38],[6.38,453.62],[7.88,455.38],[11.38,457.12],[12.88,456.62],[12.88,404.38],[21.88,393.62],[21.88,392.38],[19.88,390.62],[6.38,387.62],[6.88,388.88],[5.62,389.38],[5.12,388.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47],[48,49,50,51]]);
    polygon([[14.62,377.12],[17.62,376.12],[19.62,372.62],[24.12,373.38],[25.62,371.12],[24.88,366.38],[22.12,364.12],[20.88,360.62],[21.88,357.38],[24.88,355.62],[24.88,346.38],[20.12,342.62],[18.12,343.38],[18.12,350.62],[19.12,353.62],[18.12,355.38],[18.12,362.62],[14.12,369.38],[17.38,370.62],[17.88,371.88],[16.62,372.38],[16.12,371.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17],[18,19,20,21]]);
    polygon([[25.38,431.88],[24.12,432.38],[24.62,442.12],[25.88,441.62]]);
    polygon([[30.62,445.88],[30.12,444.62],[27.38,444.12],[27.88,445.38]]);
    polygon([[19.88,324.62],[19.12,325.38],[19.38,336.12],[30.38,342.12],[30.88,325.38],[30.12,324.62],[23.38,328.62],[23.88,329.88],[22.62,330.38],[22.12,329.12]], [[0,1,2,3,4,5],[6,7,8,9]]);
    polygon([[15.62,275.88],[15.12,284.62],[16.88,286.88],[14.12,289.38],[14.12,298.62],[19.12,308.38],[19.12,321.62],[19.88,322.38],[21.88,321.62],[21.88,304.38],[19.88,302.62],[19.88,298.38],[21.88,296.62],[21.88,292.38],[20.12,290.12],[20.12,288.88],[21.88,287.38],[24.12,287.38],[24.88,288.12],[23.38,290.12],[24.12,296.62],[26.12,298.38],[26.12,300.62],[24.12,302.38],[24.12,321.62],[24.88,322.38],[30.12,322.38],[30.88,321.62],[30.88,283.38],[24.12,278.62],[18.12,292.38],[16.62,292.38],[16.12,291.12],[17.38,290.62],[18.12,292.38],[20.12,293.38],[19.38,295.38],[17.88,294.62],[27.38,283.62],[27.88,284.88],[26.62,285.38],[26.12,284.12]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29],[30,31,32,33],[34,35,36,37],[38,39,40,41]]);
    polygon([[50.62,83.12],[41.88,82.62],[41.38,83.88],[50.12,84.38]]);
    polygon([[59.12,144.62],[54.88,144.62],[54.12,145.38],[54.12,195.62],[54.88,196.38],[56.88,195.62],[56.88,167.38],[56.12,166.12],[56.88,161.38],[55.88,158.38],[57.88,152.38],[59.88,150.62],[59.88,145.38]]);
    polygon([[69.88,347.38],[68.38,346.88],[54.12,357.62],[44.88,357.62],[43.12,358.62],[35.88,357.62],[35.12,358.38],[35.12,378.62],[37.12,379.38],[39.62,377.12],[38.88,371.38],[39.88,370.38],[43.12,370.38],[44.62,372.12],[45.62,372.12],[49.62,369.12],[50.88,366.38],[54.62,365.12],[64.88,357.12],[67.88,353.38],[69.12,353.38],[69.88,352.62],[43.12,360.38],[44.12,361.38],[44.12,364.62],[43.12,365.62],[40.88,365.62],[39.88,364.62],[39.88,361.38],[40.88,360.38]], [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21],[22,23,24,25,26,27,28,29]]);
}
