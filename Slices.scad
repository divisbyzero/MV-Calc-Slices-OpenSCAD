///////////////////////////////////////////////////////////////
// MULTIVARIABLE CALCULUS SURFACE SLICER
///////////////////////////////////////////////////////////////

// Optional preset surfaces
use <hyperbolic_paraboloid.scad>;

///////////////////////////////////////////////////////////////
///////////////////////// PARAMETERS //////////////////////////
///////////////////////////////////////////////////////////////

MODE = "all_slices_y";          // "slice_x" | "slice_y" | "stand_x" | "stand_y" | "all_slices_x" | "all_slices_y" | "solid"
                         // "slice_x" produces a slice in which x=constant
                         // "slice_y" produces a slice in which y=constant
                         // "stand_x" produces a stand for slice_x
                         // "stand_y" produces a stand for slice_y
                         // "all_slices_x" produces the stand_x plus all slice_x pieces as a single model (no slots)
                         // "all_slices_y" produces the stand_y plus all slice_y pieces as a single model (no slots)
                         // "solid" produces the full 3D surface solid

// Choose a built-in preset surface, or "custom" to edit the function/parameters below.
// Presets must be available via `use <...>` above.
PRESET = "custom"; // "custom" | "hyperbolic_paraboloid"

//////
// The function -- user defined or from a preset
//////
// Parameters for a custom function (not one of the predefined functions).
// Note: sin_rad, cos_rad, tan_rad are trig functions that accept radians
function f_custom(x,y) = 1.25*(x*x - y*y);
//function f(x,y) = let(r = sqrt(x*x + y*y))(r == 0) ? 2 : 2*sin_rad(r)/r; //use xmin=ymin=-10 and x_span=y_span=20
// Domain: [xmin,xmin+x_span] x [ymin,ymin+y_span]
xmin_custom       = -2;         // math x-min
ymin_custom       = -2;         // math y-min
x_span_custom     = 4;          // math width in x-direction
y_span_custom     = 4;          // math width in y-direction
// Function in mm: z = -z_min + z_buffer + z_scale*f(x,y)
// z_min is the minimum of z_scale*f over the domain 
z_scale_custom    = 10;         // mm - z_scale * f(x,y) is the function value in mm
                                //
z_buffer_custom   = 5;          // mm -additional vertical translation above the minimum
                         // z_buffer=0 will put the lowest point of the surface at z=0
                         // z_buffer=stand_height will put the lowest point at the top of the stand

//////
// Slice parameters
//////
numslices  = 11;          // number of traces
k          = 4;          // slice number to generate: 1...numslices
slot_positions = [0.25, 0.75];  // slot placement(s) for the stand: for instance, slot_positions = [0.25, 0.75] would yield slots at 1/4 and 3/4 of the slice length.

//////
// Size parameters
//////
x_length   = 80;        // mm - size of the final object in X direction
y_length   = 80;        // mm - size of the final object in Y direction
slice_thickness = 2.0;   // mm 
clearance       = 0.25;  // mm - slot fit tolerance
stand_height   = 15;         // mm - height of the slice stands
stand_margin  = 0;       // mm - distance the stand extends beyond the last slice



// Parameter bundle selected by preset (or custom).
params_custom = [xmin_custom, ymin_custom, x_span_custom, y_span_custom, z_scale_custom, z_buffer_custom];
params = (PRESET=="hyperbolic_paraboloid") ? params_hyperbolic_paraboloid() : params_custom;

// Domain: [xmin,xmin+x_span] x [ymin,ymin+y_span]
xmin   = params[0];
ymin   = params[1];
x_span = params[2];
y_span = params[3];

// Vertical scaling
z_scale  = params[4];
z_buffer = params[5];

// Sampling resolutions
zmin_nx    = 80;         // sampling resolution for z_min estimate (x)
zmin_ny    = 80;         // sampling resolution for z_min estimate (y)
n_samples  = 180;        // curve sampling resolution
solid_nx   = 120;        // surface sampling in X (higher = smoother, slower)
solid_ny   = 120;        // surface sampling in Y (higher = smoother, slower)

///////////////////////////////////////////////////////////////
//////////////////////////// CODE /////////////////////////////
///////////////////////////////////////////////////////////////

// Inputs a function from a file based on PRESET
function f(x,y) =
    (PRESET=="hyperbolic_paraboloid") ? f_hyperbolic_paraboloid(x,y) :
    f_custom(x,y);


// Stand height is 2*slot_h; slots cut down from the top by slot_h.
stand_N       = numslices;         // positions
slot_h     = stand_height/2;          // mm — height of slots cut into slices and stands


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

// Map y_mm in [0,y_length] to y_math in [ymin, ymin+y_span]
function y_math_from_mm(y_mm) = lerp(ymin, ymin + y_span, y_mm/y_length);

// Map x_mm in [0,x_length] to x_math in [xmin, xmin+x_span]
function x_math_from_mm(x_mm) = lerp(xmin, xmin + x_span, x_mm/x_length);

// Evenly spaced x_k in [xmin, xmin+x_span]
function xk_from_k(k_) =
    (numslices<=1) ? xmin :
    lerp(xmin, xmin + x_span, (k_-1)/(numslices-1));

// Evenly spaced y_k in [ymin, ymin+y_span]
function yk_from_k(k_) =
    (numslices<=1) ? ymin :
    lerp(ymin, ymin + y_span, (k_-1)/(numslices-1));

// Convert f(x,y) to mm (unshifted)
function f_mm(xm, ym) = z_scale * f(xm, ym);

// Estimate minimum of f_mm over the domain by sampling
function z_min_raw() =
    min([
        for (j=[0:zmin_ny])
            for (i=[0:zmin_nx])
                let(xm = lerp(xmin, xmin + x_span, i/zmin_nx),
                    ym = lerp(ymin, ymin + y_span, j/zmin_ny))
                f_mm(xm, ym)
    ]);

// "z_min" per your definition: minimum of z_scale*f(x,y) over the domain (mm)
z_min = z_min_raw();

// Solid Z and slice Z as requested
function z_solid_mm(xm, ym) = (-z_min) + z_buffer + f_mm(xm, ym);
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

    top_pts = [
        for (j=[0:ny])
            for (i=[0:nx])
                let(x_mm = x_length * i / nx,
                    y_mm = y_length * j / ny,
                    xm   = x_math_from_mm(x_mm),
                    ym   = y_math_from_mm(y_mm),
                    z    = z_solid_mm(xm, ym))
                [x_mm, y_mm, z]
    ];

    bot_pts = [
        for (j=[0:ny])
            for (i=[0:nx])
                let(x_mm = x_length * i / nx,
                    y_mm = y_length * j / ny)
                [x_mm, y_mm, 0]
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
        for (p = slot_positions) {
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

// One-piece assembly: upright stand + all slices, no slots.
module all_slices_assembled(const_axis) {
    slice_len = slice_length_mm(const_axis);
    stand_len = slice_length_mm(const_axis) + 2*stand_margin;

    function posY(i) =
        (stand_N<=1) ? (stand_len/2) :
        stand_margin + (stand_len - 2*stand_margin) * (i/(stand_N-1));

    union() {
        // Place one stand for each slot position along the slice length.
        // Example: slot_positions=[0.5] centers the stand halfway along the slice.
        for (p = slot_positions) {
            translate([ p*slice_len - slice_thickness/2, 0, 0 ])
                stand3D_upright_no_slots(const_axis);
        }
        for (i=[0:stand_N-1]) {
            yc = posY(i);
            // Center the slice thickness around yc (rotation makes extrusion go in -Y).
            translate([0, yc + slice_thickness/2, 0])
                slice3D_upright_no_slots(i+1, const_axis);
        }
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
} else if (MODE=="solid") {
    solid3D();
} else {
    echo("Unknown MODE. Use: slice_x | slice_y | stand_x | stand_y | all_slices_x | all_slices_y | solid");
}
