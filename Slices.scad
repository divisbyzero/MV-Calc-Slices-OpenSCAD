///////////////////////////////////////////////////////////////
// MULTIVARIABLE CALCULUS SURFACE SLICER
///////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////
///////////////////////// PARAMETERS //////////////////////////
///////////////////////////////////////////////////////////////

// Choose the type of object to generate
MODE = "all_slices_z";          // "slice_x" | "slice_y" | "stand_x" | "stand_y" | "all_slices_x" | "all_slices_y" | "all_slices_z" | "solid"
                         // "slice_x" produces a slice in which x=constant
                         // "slice_y" produces a slice in which y=constant
                         // "stand_x" produces a stand for slice_x
                         // "stand_y" produces a stand for slice_y
                         // "all_slices_x" produces the stand_x plus all slice_x pieces as a single model
                         // "all_slices_y" produces the stand_y plus all slice_y pieces as a single model
                         // "all_slices_z" produces a solid cut into horizontal slices (proof-of-concept via deleting gap boxes)
                         // "solid" produces the full 3D surface solid


//////
// The function and related parameters
//////

// Uncomment exactly one of these files
// Use no_presets.scad if you plan to enter your own function and custom parameters
include <no_presets.scad>;
//include <hyperbolic_paraboloid.scad>;
//include <elliptic_paraboloid.scad>;
//include <sombrero.scad>;

// Custom parameters
// These only apply when using no_presets.scad
// Custom function
function f_user(x,y) = -x*x-2*y*y; // Note: sin_rad, cos_rad, tan_rad are trig functions that accept radians

// Domain: [xmin,xmin+x_span] x [ymin,ymin+y_span]
// Note: if the domain is not a square, then keeping the same number of traces will yield traces that are spaced by different amounts in the two directions
xmin       = -sqrt(2);         // math x-min
ymin       = -1;         // math y-min
x_span     = 2*sqrt(2);          // math width in x-direction
y_span     = 2;          // math width in y-direction
// Function in mm: z = -z_min + z_buffer + z_scale*f(x,y)
// z_min is the minimum of z_scale*f over the domain
z_scale    = 30;         // mm - z_scale * f(x,y) is the function value in mm
z_buffer   = 0;          // mm - additional vertical translation above the minimum
                         // z_buffer=0 will put the lowest point of the surface at z=0
                         // z_buffer=stand_height will put the lowest point at the top of the stand
// Vertical columns to support the horizontal slices when using MODE="all_slices_z"
// Column centers are specified in model XY coordinates (mm) where the solid is centered on the origin.
column_size_x = 3;        // mm - column size in X
column_size_y = 3;        // mm - column size in Y
column_centers_mm = [[0,0]];   // list of [x_mm, y_mm] centers; empty => no columns
// End custom parameters
// The parameters below will apply to any model

//////
// Slice parameters
//////
numslices  = 11;          // the total number of traces (for MODE="slice_x" or "slice_y" or "all_slices_x" or "all_slices_y". It will also determine the spacing of horizontal slices in MODE="all_slices_z")
k          = 4;          // slice number to generate: 1...numslices (for MODE="slice_x" or "slice_y")
stand_locations = [0.25, 0.75];  // locations for the stands: for instance, stand_locations = [0.25, 0.75] would yield stands at 1/4 and 3/4 of the slice length (for the MODE="stand_x" or "stand_y" or "all_slices_x" or "all_slices_y")

//////
// Size parameters
//////
x_length   = 80;        // mm - size of the final object in X direction
// y_length is computed to maintain the correct aspect ratio based on x_span and y_span
slice_thickness = 2.0;   // mm 
clearance       = 0.25;  // mm - slot fit tolerance (for MODE="slice_x", "slice_y", "stand_x", "stand_y")
stand_height   = 15;         // mm - height of the slice stands (for MODE="slice_x", "slice_y", "stand_x", "stand_y", "all_slices_x", "all_slices_y")
stand_margin  = 0;       // mm - distance the stand extends beyond the last slice (for MODE="stand_x", "stand_y")

// Horizontal-slab pitch fudge factor (used by MODE="all_slices_z")
// Use this to adjust the spacing between horizontal slabs to avoid tiny top slices.
slab_pitch_mult = 1.2;  // 1.00 = same spacing as the vertical slices, 1.01 = 1% larger spacing


// Sampling resolutions
zmin_nx    = 80;         // sampling resolution for z_min estimate (x)
zmin_ny    = 80;         // sampling resolution for z_min estimate (y)
n_samples  = 180;        // curve sampling resolution
solid_nx   = 120;        // surface sampling in X (higher = smoother, slower)
solid_ny   = 120;        // surface sampling in Y (higher = smoother, slower)

///////////////////////////////////////////////////////////////
//////////////////////////// CODE /////////////////////////////
///////////////////////////////////////////////////////////////


// Parameter bundle selected by SOURCE.
params_user = [xmin, ymin, x_span, y_span, z_scale, z_buffer];
params = (SOURCE=="FROM_FILE") ? preset_params() : params_user;

// Column bundle selected by SOURCE.
column_params_user = [column_size_x, column_size_y, column_centers_mm];
column_params = (SOURCE=="FROM_FILE") ? preset_column_params() : column_params_user;

// Selected (effective) parameters used by the rest of the file.
// Domain: [xmin_eff,xmin_eff+x_span_eff] x [ymin_eff,ymin_eff+y_span_eff]
xmin_eff   = params[0];
ymin_eff   = params[1];
x_span_eff = params[2];
y_span_eff = params[3];

// Vertical scaling
z_scale_eff  = params[4];
z_buffer_eff = params[5];

// Column sizing/placement (effective)
column_size_x_eff = column_params[0];
column_size_y_eff = column_params[1];
column_centers_mm_eff = column_params[2];


// Selected surface function
function f(x,y) = (SOURCE=="FROM_FILE") ? preset_f(x,y) : f_user(x,y);


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

// Convert f(x,y) to mm (unshifted)
function f_mm(xm, ym) = z_scale_eff * f(xm, ym);

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

// "z_min" per your definition: minimum of z_scale*f(x,y) over the domain (mm)
z_min = z_min_raw();

// Max height (mm) after applying the same vertical shift as the solid
z_max = (-z_min) + z_buffer_eff + z_max_raw();

// Solid Z and slice Z as requested
function z_solid_mm(xm, ym) = (-z_min) + z_buffer_eff + f_mm(xm, ym);
function z_slice_mm(xm, ym) = z_solid_mm(xm, ym);

// Backwards-compatible list reverse (also fine on new versions)
function reverse_list(v) = [ for (i = [len(v)-1 : -1 : 0]) v[i] ];

///////////////////////////////////////////////////////////////
// Solid: full 3D surface over (x,y) with a flat bottom at z=0.
// This creates a watertight mesh suitable for STL export.
module solid3D(nx=solid_nx, ny=solid_ny) {
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
                    z     = z_solid_mm(xm, ym))
                [x_pos, y_pos, z]
    ];

    bot_pts = [
        for (j=[0:ny])
            for (i=[0:nx])
                let(x_pos = lerp(-x_length/2, x_length/2, i/nx),
                    y_pos = lerp(-y_length/2, y_length/2, j/ny))
                [x_pos, y_pos, 0]
    ];

    // Top surface triangles (CCW when viewed from outside / above)
    top_faces = [
        for (j=[0:ny-1])
            for (i=[0:nx-1])
                each [
                    [ top_vid(i, j),     top_vid(i+1, j),   top_vid(i, j+1) ],
                    [ top_vid(i+1, j),   top_vid(i+1, j+1), top_vid(i, j+1) ]
                ]
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

    polyhedron(
        points = concat(top_pts, bot_pts),
        faces  = concat(top_faces, bot_faces, front_faces, back_faces, left_faces, right_faces),
        convexity = 10
    );
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

    top = [
        for (i=[0:n_samples])
            let(s_mm = slice_len * i / n_samples,
                xm   = (const_axis=="x") ? xk : x_math_from_mm(s_mm),
                ym   = (const_axis=="x") ? y_math_from_mm(s_mm) : yk,
                z    = slot_lift ? z_slice_mm(xm, ym) : z_solid_mm(xm, ym))
            [s_mm, z]
    ];

    bottom_left  = [0, 0];
    bottom_right = [slice_len, 0];

    polygon(points = concat([bottom_left, bottom_right], reverse_list(top)));
}

module slice3D(k_=k, const_axis) {
    // Some parameter combos place the profile at/near z=0 before reaching the slice end.
    // If we place a slot beyond the last nonzero profile point, it won't appear.
    // So compute an effective length for slot placement based on the sampled curve.
    xk = xk_from_k(k_);
    yk = yk_from_k(k_);
    slice_len = slice_length_mm(const_axis);
    eps = 0.001;
    nonzero_idx = [
        for (i=[0:n_samples])
            let(s_mm = slice_len * i / n_samples,
                xm   = (const_axis=="x") ? xk : x_math_from_mm(s_mm),
                ym   = (const_axis=="x") ? y_math_from_mm(s_mm) : yk,
                z    = z_slice_mm(xm, ym))
            if (z > eps) i
    ];
    slot_ref_len = (len(nonzero_idx) == 0) ? slice_len : (slice_len * max(nonzero_idx) / n_samples);

    difference() {
        linear_extrude(height = slice_thickness, center=false, convexity=10)
            slice2D_outline(k_, const_axis, slot_lift=true);

        // Two bottom slots (notches): opening width = slot_opening_w,
        // height = slot_h, centered at 1/4 and 3/4 of the length.
        for (p = stand_locations) {
            // In this model, the slice outline is in the XY plane:
            //   X = along the slice length (0..slice_len)
            //   Y = vertical height (0..z)
            // and the slice thickness is extruded along Z.
            // So the notch should be positioned along X, rise in Y, and cut through Z.
            translate([ p*slot_ref_len - slot_opening_w/2, -1, -1 ]) // -1 ensures full cut
                cube([ slot_opening_w, slot_h + 1, slice_thickness + 2 ], center=false);
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
                translate([x0 - slice_thickness/2, -y_length/2 - stand_margin, 0])
                    cube([slice_thickness, y_length + 2*stand_margin, stand_height], center=false);
            }
        } else {
            // x is constant per slice => slices are placed along X
            for (p = stand_locations) {
                y0 = lerp(-y_length/2, y_length/2, p);
                translate([-x_length/2 - stand_margin, y0 - slice_thickness/2, 0])
                    cube([x_length + 2*stand_margin, slice_thickness, stand_height], center=false);
            }
        }

        // Slices
        for (i=[0:stand_N-1]) {
            pos = slice_pos_mm(i);

            if (const_axis=="y") {
                // slice_y: plane is XZ, thickness is Y
                translate([-slice_len/2, pos + slice_thickness/2, 0])
                    slice3D_upright_no_slots(i+1, "y");
            } else {
                // slice_x: plane is YZ, thickness is X
                translate([pos - slice_thickness/2, -slice_len/2, 0])
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

        polyhedron(
            points = concat(top_pts, bot_pts),
            faces  = concat(top_faces, bot_faces, front_faces, back_faces, left_faces, right_faces),
            convexity = 10
        );
    }

    module columns_capped(z_height) {
        if (column_size_x_eff > 0 && column_size_y_eff > 0 && len(column_centers_mm_eff) > 0 && z_height > 0) {
            for (c = column_centers_mm_eff) {
                column_capped_under_surface(c[0], c[1], z_height);
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
    all_slices_z();
} else if (MODE=="solid") {
    solid3D();
} else {
    echo("Unknown MODE. Use: slice_x | slice_y | stand_x | stand_y | all_slices_x | all_slices_y | all_slices_z | solid");
}
