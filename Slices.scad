///////////////////////////////////////////////////////////////
// MULTIVARIABLE CALCULUS SURFACE SLICER
///////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////
///////////////////////// PARAMETERS //////////////////////////
///////////////////////////////////////////////////////////////

// MODE options:
//   "slice_x" produces a slice in which x=constant; it has a slot to fit onto stand_x
//   "slice_y" produces a slice in which y=constant; it has a slot to fit onto stand_y
//   "stand_x" produces a stand for slice_x
//   "stand_y" produces a stand for slice_y
//   "all_slices_x" produces the stand_x plus all slice_x pieces as a single model
//   "all_slices_y" produces the stand_y plus all slice_y pieces as a single model
//   "all_slices_z" produces a solid cut into horizontal slices (proof-of-concept via deleting gap boxes)
//   "solid" produces the full 3D surface solid

// Choose the type of object to generate
MODE = "solid"; // [slice_x, slice_y, stand_x, stand_y, all_slices_x, all_slices_y, all_slices_z, solid]

// Punch text-shaped holes near the bottom of the slice (MODE="slice_x" or "slice_y")
show_text = true;
// Text to punch out. Supports x^2, x^{10}, x_1, x_{12}, \frac{num}{den} (in a .scad file, write \\frac)
text_for_slice = "z=x^2";
// mm - approximate height of a capital letter
text_size = 4;
// mm - distance from the bottom edge of the slice to the lowest point of the text
text_offset = 1.5;
// location along the slice (0 = left end, 1 = right end); keep away from stand_locations
text_location = 0.5;


//////
// The function and related parameters
//////

// Choose the surface. "custom" uses f_user and the custom parameters below.
SURFACE = "hyperbolic_paraboloid2"; // [custom, hyperbolic_paraboloid, hyperbolic_paraboloid2, elliptic_paraboloid, sombrero]

include <hyperbolic_paraboloid.scad>;
include <hyperbolic_paraboloid2.scad>;
include <elliptic_paraboloid.scad>;
include <sombrero.scad>;

// Custom parameters
// These only apply when SURFACE = "custom"
// Custom function. The coefficient preserves the previous default model height
// while using the same physical scale for X, Y, and Z.
function f_user(x,y) = (30*2*sqrt(2)/80)*(-x*x-2*y*y+2); // Note: sin_rad, cos_rad, tan_rad are trig functions that accept radians

// Domain: [xmin,xmin+x_span] x [ymin,ymin+y_span]
// Note: if the domain is not a square, then keeping the same number of traces will yield traces that are spaced by different amounts in the two directions
xmin       = -sqrt(2);         // math x-min
ymin       = -1;         // math y-min
x_span     = 2*sqrt(2);          // math width in x-direction
y_span     = 2;          // math width in y-direction
// Vertical columns to support the horizontal slices when using MODE="all_slices_z"
// Column centers are specified in model XY coordinates (mm) where the solid is centered on the origin.
column_size_x = 3;        // mm - column size in X
column_size_y = 3;        // mm - column size in Y
// Column centers are relative to the object size: [0,0] is the center, and -1 or 1 puts the column
// flush against the left/right (x) or front/back (y) edge. Positions scale with x_length.
column_centers = [[0,0]];   // list of [x_rel, y_rel] centers in [-1,1]; empty => no columns
// End custom parameters
// The parameters below will apply to any model

//////
// Slice parameters
//////
numslices  = 9;          // the total number of traces (for MODE="slice_x" or "slice_y" or "all_slices_x" or "all_slices_y". It will also determine the spacing of horizontal slices in MODE="all_slices_z")
k          = 4;          // slice number to generate: 1...numslices (for MODE="slice_x" or "slice_y")
stand_locations = [0.3, 0.7];  // locations for the stands: for instance, stand_locations = [0.25, 0.75] would yield stands at 1/4 and 3/4 of the slice length (for the MODE="stand_x" or "stand_y" or "all_slices_x" or "all_slices_y")

//////
// Size parameters
//////
x_length   = 60;        // mm - size of the final object in X direction
// y_length is computed to maintain the correct aspect ratio based on x_span and y_span
slice_thickness = 1.5;   // mm 
clearance       = 0.25;  // mm - slot fit tolerance (for MODE="slice_x", "slice_y", "stand_x", "stand_y")
stand_height   = 10;         // mm - height of the slice stands (for MODE="slice_x", "slice_y", "stand_x", "stand_y", "all_slices_x", "all_slices_y")
stand_margin  = 5;       // mm - distance the stand extends beyond the last slice (for MODE="stand_x", "stand_y")
assembled_stand_margin = 0; // mm - extra overhang for stand beams in MODE="all_slices_x"/"all_slices_y" (0 = flush with outermost slices)

// Horizontal-slab pitch fudge factor (used by MODE="all_slices_z")
// Use this to adjust the spacing between horizontal slabs to avoid tiny top slices.
slab_pitch_mult = 1;  // 1.00 = same spacing as the vertical slices, 1.01 = 1% larger spacing

// Sampling resolutions
zmin_nx    = 80;         // sampling resolution for z_min estimate (x)
zmin_ny    = 80;         // sampling resolution for z_min estimate (y)
n_samples  = 180;        // curve sampling resolution
solid_nx   = 120;        // surface sampling in X (higher = smoother, slower)
solid_ny   = 120;        // surface sampling in Y (higher = smoother, slower)














///////////////////////////////////////////////////////////////
//////////////////////////// CODE /////////////////////////////
///////////////////////////////////////////////////////////////


// Parameter bundle selected by SURFACE.
// Each preset file provides <name>_params() = [xmin, ymin, x_span, y_span,
//                                              column_size_x, column_size_y, column_centers]
params_user = [xmin, ymin, x_span, y_span, column_size_x, column_size_y, column_centers];
params =
    (SURFACE=="hyperbolic_paraboloid")  ? hyperbolic_paraboloid_params() :
    (SURFACE=="hyperbolic_paraboloid2") ? hyperbolic_paraboloid2_params() :
    (SURFACE=="elliptic_paraboloid")    ? elliptic_paraboloid_params() :
    (SURFACE=="sombrero")               ? sombrero_params() :
    params_user;

// Selected (effective) parameters used by the rest of the file.
// Domain: [xmin_eff,xmin_eff+x_span_eff] x [ymin_eff,ymin_eff+y_span_eff]
xmin_eff   = params[0];
ymin_eff   = params[1];
x_span_eff = params[2];
y_span_eff = params[3];

// Column sizing/placement (effective)
column_size_x_eff = (len(params) > 4) ? params[4] : 3;
column_size_y_eff = (len(params) > 5) ? params[5] : 3;
column_centers_eff = (len(params) > 6) ? params[6] : [];


// Selected surface function
function f(x,y) =
    (SURFACE=="hyperbolic_paraboloid")  ? hyperbolic_paraboloid_f(x,y) :
    (SURFACE=="hyperbolic_paraboloid2") ? hyperbolic_paraboloid2_f(x,y) :
    (SURFACE=="elliptic_paraboloid")    ? elliptic_paraboloid_f(x,y) :
    (SURFACE=="sombrero")               ? sombrero_f(x,y) :
    f_user(x,y);


// Stand height is 2*slot_h; slots cut down from the top by slot_h.
stand_N       = numslices;         // positions
slot_h     = stand_height/2;          // mm — height of slots cut into slices and stands

y_length   = x_length*y_span_eff/x_span_eff;        // mm - size of the final object in Y direction

// Slot opening (in the mating direction) = slice thickness + clearance
slot_opening_w = slice_thickness + clearance;

function lerp(a,b,t) = a + (b-a)*t;
function clamp(v, lo, hi) = (v<lo)?lo : (v>hi)?hi : v;

// Trig functions that accept radians (OpenSCAD's sin/cos/tan take degrees)
function rad2deg(r) = r * 180 / PI;
function sin_rad(r) = sin(rad2deg(r));
function cos_rad(r) = cos(rad2deg(r));
function tan_rad(r) = tan(rad2deg(r));

// Length of the generated slice in mm.
// Here, `const_axis` means which math/physical axis is held constant for the slice:
// - const_axis == "x" => x is constant, y varies => slice length uses y_length
// - const_axis == "y" => y is constant, x varies => slice length uses x_length
function slice_length_mm(const_axis) = (const_axis=="x") ? y_length : x_length;

// Map y_mm in [0,y_length] to y_math in [ymin_eff, ymin_eff+y_span_eff]
function y_math_from_mm(y_mm) = lerp(ymin_eff, ymin_eff + y_span_eff, y_mm/y_length);

// Map x_mm in [0,x_length] to x_math in [xmin_eff, xmin_eff+x_span_eff]
function x_math_from_mm(x_mm) = lerp(xmin_eff, xmin_eff + x_span_eff, x_mm/x_length);

// Evenly spaced x_k in [xmin_eff, xmin_eff+x_span_eff]
function xk_from_k(k_) =
    (numslices<=1) ? xmin_eff :
    lerp(xmin_eff, xmin_eff + x_span_eff, (k_-1)/(numslices-1));

// Evenly spaced y_k in [ymin_eff, ymin_eff+y_span_eff]
function yk_from_k(k_) =
    (numslices<=1) ? ymin_eff :
    lerp(ymin_eff, ymin_eff + y_span_eff, (k_-1)/(numslices-1));

// Apply the same physical scale to Z as to X and Y.
function f_mm(xm, ym) = (x_length/x_span_eff) * f(xm, ym);

// Estimate minimum of f_mm over the domain by sampling
function z_min_raw() =
    min([
        for (j=[0:zmin_ny])
            for (i=[0:zmin_nx])
                let(xm = lerp(xmin_eff, xmin_eff + x_span_eff, i/zmin_nx),
                    ym = lerp(ymin_eff, ymin_eff + y_span_eff, j/zmin_ny))
                f_mm(xm, ym)
    ]);

// Estimate maximum of f_mm over the domain by sampling
function z_max_raw() =
    max([
        for (j=[0:zmin_ny])
            for (i=[0:zmin_nx])
                let(xm = lerp(xmin_eff, xmin_eff + x_span_eff, i/zmin_nx),
                    ym = lerp(ymin_eff, ymin_eff + y_span_eff, j/zmin_ny))
                f_mm(xm, ym)
    ]);

// Surface height in mm (may be negative)
function z_surface_mm(xm, ym) = f_mm(xm, ym);

// Cache sampled min/max of the surface over the domain (mm)
z_surface_min = z_min_raw();
z_surface_max = z_max_raw();

// "z_min" and "z_max" are of the actual, clipped surface height over the domain (mm)
// (the solid only exists above the XY plane).
z_min = max(0, z_surface_min);
z_max = max(0, z_surface_max);

// Solid Z and slice Z as requested
// Keep only the positive-z portion of the surface.
function z_solid_mm(xm, ym) = max(0, z_surface_mm(xm, ym));
function z_slice_mm(xm, ym) = z_solid_mm(xm, ym);

// Backwards-compatible list reverse (also fine on new versions)
function reverse_list(v) = [ for (i = [len(v)-1 : -1 : 0]) v[i] ];

///////////////////////////////////////////////////////////////
// Solid: full 3D surface over (x,y) with a flat bottom at z=0.
// This creates a watertight mesh suitable for STL export.
module solid3D(nx=solid_nx, ny=solid_ny) {
    // Robust approach:
    // 1) Build a watertight solid from a Z "floor" (below any negative surface) up to the surface.
    // 2) Intersect with z>=0 half-space. This yields exactly the positive-z portion with no extra
    //    thin sheet outside the positive footprint, and avoids fragile 2D-mask booleans.

    z_floor = min(0, z_surface_min) - 1; // ensure below any negative surface; small pad helps CGAL

    module solid3D_raw() {
        // Vertex indexing for a (nx+1) x (ny+1) grid
        function vid(i, j) = i + (nx+1)*j;
        function top_vid(i, j) = vid(i, j);
        function bot_vid(i, j) = (nx+1)*(ny+1) + vid(i, j);

        // Center the solid on the origin in XY:
        // x in [-x_length/2, +x_length/2], y in [-y_length/2, +y_length/2]
        top_pts = [
            for (j=[0:ny])
                for (i=[0:nx])
                    let(x_pos = lerp(-x_length/2, x_length/2, i/nx),
                        y_pos = lerp(-y_length/2, y_length/2, j/ny),
                        xm    = x_math_from_mm(x_pos + x_length/2),
                        ym    = y_math_from_mm(y_pos + y_length/2),
                        z     = z_surface_mm(xm, ym))
                    [x_pos, y_pos, z]
        ];

        bot_pts = [
            for (j=[0:ny])
                for (i=[0:nx])
                    let(x_pos = lerp(-x_length/2, x_length/2, i/nx),
                        y_pos = lerp(-y_length/2, y_length/2, j/ny))
                    [x_pos, y_pos, z_floor]
        ];

        // Sampled top height at grid vertex (i,j). Used for robust triangulation.
        function z_at(i, j) =
            let(x_pos = lerp(-x_length/2, x_length/2, i/nx),
                y_pos = lerp(-y_length/2, y_length/2, j/ny),
                xm    = x_math_from_mm(x_pos + x_length/2),
                ym    = y_math_from_mm(y_pos + y_length/2))
            z_surface_mm(xm, ym);

        // Top surface triangles (CCW when viewed from outside / above)
        top_faces = [
            for (j=[0:ny-1])
                for (i=[0:nx-1])
                    let(h00 = z_at(i, j),
                        h10 = z_at(i+1, j),
                        h01 = z_at(i, j+1),
                        h11 = z_at(i+1, j+1),
                        use_diag_00_11 = (h00 + h11) >= (h10 + h01),
                        v00 = top_vid(i, j),
                        v10 = top_vid(i+1, j),
                        v01 = top_vid(i, j+1),
                        v11 = top_vid(i+1, j+1))
                    each (
                        use_diag_00_11
                            ? [ [v00, v10, v11], [v00, v11, v01] ]
                            : [ [v00, v10, v01], [v10, v11, v01] ]
                    )
        ];

        // Bottom surface triangles (reverse winding so normal points downward)
        bot_faces = [
            for (j=[0:ny-1])
                for (i=[0:nx-1])
                    each [
                        [ bot_vid(i, j+1),   bot_vid(i+1, j),   bot_vid(i, j) ],
                        [ bot_vid(i, j+1),   bot_vid(i+1, j+1), bot_vid(i+1, j) ]
                    ]
        ];

        // Side walls around the perimeter
        front_faces = [
            for (i=[0:nx-1])
                each [
                    [ bot_vid(i, 0),   bot_vid(i+1, 0), top_vid(i+1, 0) ],
                    [ bot_vid(i, 0),   top_vid(i+1, 0), top_vid(i, 0) ]
                ]
        ];

        back_faces = [
            for (i=[0:nx-1])
                each [
                    [ bot_vid(i+1, ny), bot_vid(i, ny),   top_vid(i, ny) ],
                    [ bot_vid(i+1, ny), top_vid(i, ny),   top_vid(i+1, ny) ]
                ]
        ];

        left_faces = [
            for (j=[0:ny-1])
                each [
                    [ bot_vid(0, j+1), bot_vid(0, j),   top_vid(0, j) ],
                    [ bot_vid(0, j+1), top_vid(0, j),   top_vid(0, j+1) ]
                ]
        ];

        right_faces = [
            for (j=[0:ny-1])
                each [
                    [ bot_vid(nx, j),   bot_vid(nx, j+1), top_vid(nx, j+1) ],
                    [ bot_vid(nx, j),   top_vid(nx, j+1), top_vid(nx, j) ]
                ]
        ];

        // OpenSCAD expects faces clockwise when viewed from outside; the lists above are
        // counter-clockwise, so reverse each face. Otherwise the Manifold backend treats
        // the solid as inside-out and fills the z<0 region with a flat z=0 face.
        all_faces = concat(top_faces, bot_faces, front_faces, back_faces, left_faces, right_faces);
        polyhedron(
            points = concat(top_pts, bot_pts),
            faces  = [for (f = all_faces) [f[2], f[1], f[0]]],
            convexity = 10
        );
    }

    // Clip to the positive-z half-space.
    // Use render() in preview mode to avoid OpenCSG artifacts.
    clip_pad = 2;
    if ($preview)
        render(convexity=10)
            intersection() {
                solid3D_raw();
                translate([-x_length/2 - clip_pad, -y_length/2 - clip_pad, 0])
                    cube([x_length + 2*clip_pad, y_length + 2*clip_pad, 100000], center=false);
            }
    else
        intersection() {
            solid3D_raw();
            translate([-x_length/2 - clip_pad, -y_length/2 - clip_pad, 0])
                cube([x_length + 2*clip_pad, y_length + 2*clip_pad, 100000], center=false);
        }
}

///////////////////////////////////////////////////////////////
// Slice: 2D outline in (S,Z) where S is distance along the slice.
// Extruded by slice_thickness.
// const_axis == "x" => x is constant (x = xk), y varies along the slice
// const_axis == "y" => y is constant (y = yk), x varies along the slice
module slice2D_outline(k_=k, const_axis, slot_lift=true) {
    xk = xk_from_k(k_);
    yk = yk_from_k(k_);
    slice_len = slice_length_mm(const_axis);

    // Center the slice on the origin: x in [-slice_len/2, +slice_len/2]
    top = [
        for (i=[0:n_samples])
            let(s_mm = -slice_len/2 + slice_len * i / n_samples,
                xm   = (const_axis=="x") ? xk : x_math_from_mm(s_mm + slice_len/2),
                ym   = (const_axis=="x") ? y_math_from_mm(s_mm + slice_len/2) : yk,
                z    = slot_lift ? z_slice_mm(xm, ym) : z_solid_mm(xm, ym))
            [s_mm, z]
    ];

    bottom_left  = [-slice_len/2, 0];
    bottom_right = [slice_len/2, 0];

    polygon(points = concat([bottom_left, bottom_right], reverse_list(top)));
}

///////////////////////////////////////////////////////////////
// Slice label: a tiny LaTeX-like subset rendered as 2D text.
// Supported: ^x, ^{...}, _x, _{...}, \frac{...}{...} (also written as frac{...}{...}), {...}
// A monospace font is used so glyph widths are known without textmetrics().
// Parse tree nodes: ["t", char] | ["sup", nodes] | ["sub", nodes] | ["frac", num, den] | ["grp", nodes]
label_font     = "Liberation Mono";
label_adv      = 0.8335;  // glyph advance per unit of text size (Liberation Mono)
label_cap      = 0.92;    // cap/digit height per unit of text size
label_script   = 0.6;     // scale for superscripts/subscripts
label_frac     = 0.75;    // scale for numerator/denominator
label_axis     = 0.45;    // fraction bar height above baseline, per unit of text size
label_gap      = 0.15;    // gap between fraction bar and num/den, per unit of text size
label_bar      = 0.1;     // fraction bar thickness, per unit of text size
label_desc     = 0.29;    // descender depth (g, j, p, q, y, comma), per unit of text size

function label_starts(s, i, w) =
    (i + len(w) <= len(s)) && (len([for (j=[0:len(w)-1]) if (s[i+j] != w[j]) j]) == 0);

// Returns [nodes, next_index]; stops at end of string or an unmatched "}".
function label_parse_seq(s, i=0, acc=[]) =
    (i >= len(s) || s[i] == "}") ? [acc, i] :
    let(r = label_parse_item(s, i)) label_parse_seq(s, r[1], concat(acc, [r[0]]));

// A braced group or a single item.
function label_parse_group(s, i) =
    (i >= len(s)) ? [[], i] :
    (s[i] == "{") ? let(r = label_parse_seq(s, i+1)) [r[0], r[1]+1] :
    let(r = label_parse_item(s, i)) [[r[0]], r[1]];

function label_parse_item(s, i) =
    (s[i] == "^" || s[i] == "_") ?
        let(g = label_parse_group(s, i+1)) [[s[i] == "^" ? "sup" : "sub", g[0]], g[1]] :
    (label_starts(s, i, "\\frac") || label_starts(s, i, "frac{")) ?
        let(i0 = (s[i] == "\\") ? i+5 : i+4,
            a = label_parse_group(s, i0),
            b = label_parse_group(s, a[1]))
        [["frac", a[0], b[0]], b[1]] :
    (s[i] == "{") ?
        let(r = label_parse_seq(s, i+1)) [["grp", r[0]], r[1]+1] :
    [["t", s[i]], i+1];

function label_sum(v) = len(v) == 0 ? 0 : v[0] + label_sum([for (j=[1:1:len(v)-1]) v[j]]);

// Widths/heights/depths in units of text size, for a node list drawn at scale sc.
function label_width(nodes, sc) = label_sum([for (n = nodes) label_node_width(n, sc)]);
function label_node_width(n, sc) =
    (n[0] == "t")    ? label_adv*sc :
    (n[0] == "sup" || n[0] == "sub") ? label_width(n[1], sc*label_script) :
    (n[0] == "frac") ? max(label_width(n[1], sc*label_frac), label_width(n[2], sc*label_frac)) + 0.2*sc :
    label_width(n[1], sc);

function label_height(nodes, sc) = max(concat([0], [for (n = nodes) label_node_height(n, sc)]));
function label_node_height(n, sc) =
    (n[0] == "t")    ? label_cap*sc :
    (n[0] == "sup")  ? 0.5*label_cap*sc + label_height(n[1], sc*label_script) :
    (n[0] == "sub")  ? label_height(n[1], sc*label_script) - 0.25*label_cap*sc :
    (n[0] == "frac") ? (label_axis + label_gap)*sc + label_depth(n[1], sc*label_frac) + label_height(n[1], sc*label_frac) :
    label_height(n[1], sc);

function label_depth(nodes, sc) = max(concat([0], [for (n = nodes) label_node_depth(n, sc)]));
function label_node_depth(n, sc) =
    (n[0] == "t")    ? (len(search(n[1], "gjpqy,;")) > 0 ? label_desc*sc : 0) :
    (n[0] == "sup")  ? label_depth(n[1], sc*label_script) - 0.5*label_cap*sc :
    (n[0] == "sub")  ? 0.25*label_cap*sc + label_depth(n[1], sc*label_script) :
    (n[0] == "frac") ? label_height(n[2], sc*label_frac) + label_depth(n[2], sc*label_frac) - (label_axis - label_gap)*sc :
    label_depth(n[1], sc);

// Draw a node list with its baseline at y=0 starting at x=0 (units of text size).
module label_nodes2D(nodes, sc) {
    for (j = [0:1:len(nodes)-1]) {
        x0 = label_width([for (m=[0:1:j-1]) nodes[m]], sc);
        translate([x0, 0]) label_node2D(nodes[j], sc);
    }
}

module label_node2D(n, sc) {
    if (n[0] == "t") {
        text(n[1], size=sc, font=label_font, halign="left", valign="baseline");
    } else if (n[0] == "sup") {
        translate([0, 0.5*label_cap*sc]) label_nodes2D(n[1], sc*label_script);
    } else if (n[0] == "sub") {
        translate([0, -0.25*label_cap*sc]) label_nodes2D(n[1], sc*label_script);
    } else if (n[0] == "frac") {
        fs = sc*label_frac;
        w  = label_node_width(n, sc);
        wn = label_width(n[1], fs);
        wd = label_width(n[2], fs);
        translate([(w - wn)/2, (label_axis + label_gap)*sc + label_depth(n[1], fs)])
            label_nodes2D(n[1], fs);
        translate([(w - wd)/2, (label_axis - label_gap)*sc - label_height(n[2], fs)])
            label_nodes2D(n[2], fs);
        translate([0.05*sc, (label_axis - label_bar/2)*sc])
            square([w - 0.1*sc, label_bar*sc]);
    } else {
        label_nodes2D(n[1], sc);
    }
}

// The label, centered horizontally at x=0, with its lowest point at y=0, in mm.
module slice_label2D(str, size) {
    nodes = label_parse_seq(str)[0];
    scale(size)
        translate([-label_width(nodes, 1)/2, label_depth(nodes, 1)])
            label_nodes2D(nodes, 1);
}

module slice3D(k_=k, const_axis) {
    // Some parameter combos place the profile at/near z=0 before reaching the slice end.
    // If we place a slot beyond the last nonzero profile point, it won't appear.
    // So compute an effective length for slot placement based on the sampled curve.
    xk = xk_from_k(k_);
    yk = yk_from_k(k_);
    slice_len = slice_length_mm(const_axis);
    eps = 0.001;

    // If the clipped surface never rises above z=0 along this slice, the outline
    // degenerates to a zero-area polygon and OpenSCAD will render/export nothing.
    // Emit a helpful message in that case.
    slice_max_z = max([
        for (i=[0:n_samples])
            let(s_mm = slice_len * i / n_samples,
                xm   = (const_axis=="x") ? xk : x_math_from_mm(s_mm),
                ym   = (const_axis=="x") ? y_math_from_mm(s_mm) : yk)
            z_slice_mm(xm, ym)
    ]);
    nonzero_idx = [
        for (i=[0:n_samples])
            let(s_mm = slice_len * i / n_samples,
                xm   = (const_axis=="x") ? xk : x_math_from_mm(s_mm),
                ym   = (const_axis=="x") ? y_math_from_mm(s_mm) : yk,
                z    = z_slice_mm(xm, ym))
            if (z > eps) i
    ];
    slot_ref_len = (len(nonzero_idx) == 0) ? slice_len : (slice_len * max(nonzero_idx) / n_samples);

    if (slice_max_z <= eps) {
        echo("Empty slice after z>=0 clipping. Change the function or choose a different k.",
             MODE=MODE, const_axis=const_axis, k=k_, xk=xk, yk=yk, z_max_along_slice=slice_max_z);
    } else {
        difference() {
            linear_extrude(height = slice_thickness, center=false, convexity=10)
                slice2D_outline(k_, const_axis, slot_lift=true);

            // Place slots using lerp to ensure correct proportional placement
            for (p = stand_locations) {
                slot_x = lerp(-slice_len/2, slice_len/2, p);
                translate([ slot_x - slot_opening_w/2, -1, -1 ])
                    cube([ slot_opening_w, slot_h + 1, slice_thickness + 2 ], center=false);
            }

            if (show_text && len(text_for_slice) > 0)
                translate([ lerp(-slice_len/2, slice_len/2, text_location), text_offset, -1 ])
                    linear_extrude(height = slice_thickness + 2, convexity=10)
                        slice_label2D(text_for_slice, text_size);
        }
    }
}

// Slot-free slice, used for "all_slices_*" assembly.
module slice3D_no_slots(k_=k, const_axis) {
    linear_extrude(height = slice_thickness, center=false, convexity=10)
    slice2D_outline(k_, const_axis, slot_lift=true);
}

// Upright slice oriented perpendicular to the upright stand:
// - Stand lies in the YZ plane (thickness in X)
// - Slice lies in the XZ plane (thickness in Y)
module slice3D_upright_no_slots(k_=k, const_axis) {
    rotate([90, 0, 0])
        slice3D_no_slots(k_, const_axis);
}

///////////////////////////////////////////////////////////////
// Stand: same thickness as slice (slice_thickness)
// Stand is a solid block with slots removed (i.e., the inverse of the old key comb).
module stand3D_for(const_axis) {
    // const_axis must match the corresponding slice mode.
    // - stand_x goes with slice_x  => const_axis = "x" => length uses y_length
    // - stand_y goes with slice_y  => const_axis = "y" => length uses x_length
    stand_len = slice_length_mm(const_axis) + 2*stand_margin;

    function posY(i) =
        (stand_N<=1) ? (stand_len/2) :
        stand_margin + (stand_len - 2*stand_margin) * (i/(stand_N-1));

    module stand_upright() {
        translate([0, -stand_margin, 0])
            difference() {
                cube([ slice_thickness, stand_len, stand_height ], center=false);
                for (i=[0:stand_N-1]) {
                    yc = posY(i);
                    translate([-1, yc - slot_opening_w/2, stand_height - slot_h])
                        cube([ slice_thickness + 2, slot_opening_w, slot_h + 1 ], center=false);
                }
            }
    }

    // Print-friendly orientation:
    // - Flat on XY plane with thickness in +Z (0..slice_thickness)
    // - Sits on x-axis (y=0..stand_height)
    // - Long axis along +X (x=0..stand_len)
    translate([stand_margin, 0, 0])
        rotate([-90, 0, 0])
            rotate([0, 0, -90])
                stand_upright();
}

module stand3D_x() stand3D_for("x");
module stand3D_y() stand3D_for("y");

// Upright, slot-free stand block for the one-piece assembly modes.
module stand3D_upright_no_slots(const_axis) {
    stand_len = slice_length_mm(const_axis) + 2*stand_margin;
    translate([0, -stand_margin, 0])
        cube([ slice_thickness, stand_len, stand_height ], center=false);
}

// One-piece assembly: place all slices at their true x/y positions.
//
// - Sits on the XY plane (z>=0) like the other modes.
// - Centered on the origin:
//     x in [-x_length/2, +x_length/2], y in [-y_length/2, +y_length/2]
// - No swapping of x/y roles.
//
// Stand(s) are simple beams that connect all slices:
// - For all_slices_y (const_axis="y"), stands run along +Y and are placed at X positions.
// - For all_slices_x (const_axis="x"), stands run along +X and are placed at Y positions.
module all_slices_assembled(const_axis) {
    slice_len = slice_length_mm(const_axis);
    beam_margin = assembled_stand_margin;

    function slice_pos_mm(i) =
        (stand_N<=1) ? 0 :
        (const_axis=="x")
            ? lerp(-x_length/2 + slice_thickness/2, x_length/2 - slice_thickness/2, i/(stand_N-1))
            : lerp(-y_length/2 + slice_thickness/2, y_length/2 - slice_thickness/2, i/(stand_N-1));

    union() {
        // Stands (beams)
        if (const_axis=="y") {
            // y is constant per slice => slices are placed along Y
            for (p = stand_locations) {
                x0 = lerp(-x_length/2, x_length/2, p);
                translate([x0 - slice_thickness/2, -y_length/2 - beam_margin, 0])
                    cube([slice_thickness, y_length + 2*beam_margin, stand_height], center=false);
            }
        } else {
            // x is constant per slice => slices are placed along X
            for (p = stand_locations) {
                y0 = lerp(-y_length/2, y_length/2, p);
                translate([-x_length/2 - beam_margin, y0 - slice_thickness/2, 0])
                    cube([x_length + 2*beam_margin, slice_thickness, stand_height], center=false);
            }
        }

        // Slices
        for (i=[0:stand_N-1]) {
            pos = slice_pos_mm(i);

            if (const_axis=="y") {
                // slice_y: plane is XZ, thickness is Y
                translate([0, pos + slice_thickness/2, 0])
                    slice3D_upright_no_slots(i+1, "y");
            } else {
                // slice_x: plane is YZ, thickness is X
                translate([pos - slice_thickness/2, 0, 0])
                    rotate([90, 0, 90])
                        slice3D_no_slots(i+1, "x");
            }
        }
    }
}

// Proof-of-concept horizontal slicing:
// Cut the full solid into numslices horizontal slabs by deleting thin horizontal boxes.
// Spacing rule (as requested): use the same spacing as the X-direction slice spacing.
// In this file, that spacing is x_length/(numslices-1) mm.
module all_slices_z() {
    dz_base = (numslices<=1) ? x_length : (x_length/(numslices-1));
    dz_mm = max(0.001, dz_base * slab_pitch_mult);

    // Keep slabs at exactly slice_thickness.
    slab_t = slice_thickness;
    // Delete everything between slabs. If dz_mm <= slab_t, slabs will touch/overlap.
    z_gap = max(0, dz_mm - slab_t);

    // Cutting boxes need to fully cover the solid's XY footprint.
    cut_pad = 2;
    cut_x = x_length + 2*cut_pad;
    cut_y = y_length + 2*cut_pad;

    // Choose how many slabs are needed to reach the top of the surface.
    // Slab i spans z in [i*dz_mm, i*dz_mm + slab_t].
    n_slabs = (dz_mm <= 0) ? 1 : max(1, ceil((z_max - slab_t)/dz_mm) + 1);

    // Top cutoff ensures we end up with exactly n_slabs slabs.
    z_top = (n_slabs<=1) ? 1e9 : ((n_slabs-1)*dz_mm + slab_t);

    module sliced_slabs() {
        difference() {
            solid3D();

            // Delete horizontal gaps between slabs
            if (n_slabs>1 && z_gap>0) {
                for (i=[0:n_slabs-2]) {
                    translate([-x_length/2 - cut_pad, -y_length/2 - cut_pad, i*dz_mm + slab_t])
                        cube([cut_x, cut_y, z_gap], center=false);
                }
            }

            // Delete everything above the top slab so there are exactly numslices pieces
            if (n_slabs>1) {
                translate([-x_length/2 - cut_pad, -y_length/2 - cut_pad, z_top])
                    cube([cut_x, cut_y, 10000], center=false);
            }
        }
    }

    // Columns: a solid over a rectangular base footprint, under the surface,
    // and capped at the top of the highest *remaining* horizontal slice at each (x,y).
    // This avoids columns extending into the deleted gap regions.
    function slab_cap_z(z) =
        (dz_mm <= 0) ? z :
        min(z, floor(z/dz_mm)*dz_mm + slab_t);

    function column_top_z_at(x_pos, y_pos) =
        let(x_mm = clamp(x_pos + x_length/2, 0, x_length),
            y_mm = clamp(y_pos + y_length/2, 0, y_length),
            xm   = x_math_from_mm(x_mm),
            ym   = y_math_from_mm(y_mm),
            z    = max(0, z_solid_mm(xm, ym)),
            zcap = slab_cap_z(z))
        min(z_top, zcap);

    module column_capped_under_surface(cx, cy, z_height) {
        // Sampling resolution for the column top surface
        nx = 16;
        ny = 16;

        x0 = cx - column_size_x_eff/2;
        x1 = cx + column_size_x_eff/2;
        y0 = cy - column_size_y_eff/2;
        y1 = cy + column_size_y_eff/2;

        function vid(i, j) = i + (nx+1)*j;
        function top_vid(i, j) = vid(i, j);
        function bot_vid(i, j) = (nx+1)*(ny+1) + vid(i, j);

        top_pts = [
            for (j=[0:ny])
                for (i=[0:nx])
                    let(x_pos = lerp(x0, x1, i/nx),
                        y_pos = lerp(y0, y1, j/ny),
                        zpos  = min(z_height, column_top_z_at(x_pos, y_pos)))
                    [x_pos, y_pos, zpos]
        ];

        bot_pts = [
            for (j=[0:ny])
                for (i=[0:nx])
                    let(x_pos = lerp(x0, x1, i/nx),
                        y_pos = lerp(y0, y1, j/ny))
                    [x_pos, y_pos, 0]
        ];

        top_faces = [
            for (j=[0:ny-1])
                for (i=[0:nx-1])
                    each [
                        [ top_vid(i, j),     top_vid(i+1, j),   top_vid(i, j+1) ],
                        [ top_vid(i+1, j),   top_vid(i+1, j+1), top_vid(i, j+1) ]
                    ]
        ];

        bot_faces = [
            for (j=[0:ny-1])
                for (i=[0:nx-1])
                    each [
                        [ bot_vid(i, j+1),   bot_vid(i+1, j),   bot_vid(i, j) ],
                        [ bot_vid(i, j+1),   bot_vid(i+1, j+1), bot_vid(i+1, j) ]
                    ]
        ];

        front_faces = [
            for (i=[0:nx-1])
                each [
                    [ bot_vid(i, 0),   bot_vid(i+1, 0), top_vid(i+1, 0) ],
                    [ bot_vid(i, 0),   top_vid(i+1, 0), top_vid(i, 0) ]
                ]
        ];

        back_faces = [
            for (i=[0:nx-1])
                each [
                    [ bot_vid(i+1, ny), bot_vid(i, ny),   top_vid(i, ny) ],
                    [ bot_vid(i+1, ny), top_vid(i, ny),   top_vid(i+1, ny) ]
                ]
        ];

        left_faces = [
            for (j=[0:ny-1])
                each [
                    [ bot_vid(0, j+1), bot_vid(0, j),   top_vid(0, j) ],
                    [ bot_vid(0, j+1), top_vid(0, j),   top_vid(0, j+1) ]
                ]
        ];

        right_faces = [
            for (j=[0:ny-1])
                each [
                    [ bot_vid(nx, j),   bot_vid(nx, j+1), top_vid(nx, j+1) ],
                    [ bot_vid(nx, j),   top_vid(nx, j+1), top_vid(nx, j) ]
                ]
        ];

        // Reverse winding: OpenSCAD expects faces clockwise when viewed from outside.
        all_faces = concat(top_faces, bot_faces, front_faces, back_faces, left_faces, right_faces);
        polyhedron(
            points = concat(top_pts, bot_pts),
            faces  = [for (f = all_faces) [f[2], f[1], f[0]]],
            convexity = 10
        );
    }

    module columns_capped(z_height) {
        if (column_size_x_eff > 0 && column_size_y_eff > 0 && len(column_centers_eff) > 0 && z_height > 0) {
            for (c = column_centers_eff) {
                // Relative position: +/-1 places the column flush with the object's edge
                column_capped_under_surface(c[0]*(x_length - column_size_x_eff)/2,
                                            c[1]*(y_length - column_size_y_eff)/2,
                                            z_height);
            }
        }
    }

    union() {
        sliced_slabs();
        if (n_slabs>1)
            columns_capped(z_top);
    }
}

///////////////////////////////////////////////////////////////
// Build / preview
if (MODE=="slice_x") {
    slice3D(k, "x");
} else if (MODE=="slice_y") {
    slice3D(k, "y");
} else if (MODE=="stand_x") {
    stand3D_x();
} else if (MODE=="stand_y") {
    stand3D_y();
} else if (MODE=="all_slices_x") {
    all_slices_assembled("x");
} else if (MODE=="all_slices_y") {
    all_slices_assembled("y");
} else if (MODE=="all_slices_z") {
    if (z_max <= 0)
        echo("Surface never rises above z=0; clipped solid will be empty. Change f(x,y).", z_max=z_max);
    all_slices_z();
} else if (MODE=="solid") {
    if (z_max <= 0)
        echo("Surface never rises above z=0; clipped solid will be empty. Change f(x,y).", z_max=z_max);
    solid3D();
} else {
    echo("Unknown MODE. Use: slice_x | slice_y | stand_x | stand_y | all_slices_x | all_slices_y | all_slices_z | solid");
}
