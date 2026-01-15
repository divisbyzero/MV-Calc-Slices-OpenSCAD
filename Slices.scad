///////////////////////////////////////////////////////////////
// TRACE SLICES + STAND (single-file workflow)
// Updated per request:
//  - Slice has TWO bottom slots at 1/4 and 3/4 along length
//  - Slice and stand have SAME thickness = slice_thickness
//  - Slot opening width (mating) = slice_thickness + clearance
///////////////////////////////////////////////////////////////

//////////////////// USER PARAMETERS //////////////////////////

///////////////////////////////////////////////////////////////
MODE = "slice_x";        // "slice_x" | "slice_y" | "stand_x" | "stand_y" | "solid"
                         // "slice_x" produces a slice in which x=constant
                         // "slice_y" produces a slice in which y=constant
                         // "stand_x" produces a stand for slice_x
                         // "stand_y" produces a stand for slice_y
                         // "solid" produces the full 3D surface solid

//////
// Function definition and parameters
//////
function f(x,y) = x*x - y*y+5;
// Domain: [xmin,xmin+x_span] x [ymin,ymin+y_span]
xmin       = -2;         // math x-min
ymin       = -2;         // math y-min
x_span     = 4;          // math width in x-direction
y_span     = 4;          // math width in y-direction
n_samples  = 180;        // curve sampling resolution

//////
// Solid (full surface) parameters
//////
solid_nx   = 120;        // surface sampling in X (higher = smoother, slower)
solid_ny   = 120;        // surface sampling in Y (higher = smoother, slower)

//////
// Slice parameters
//////
numslices  = 7;          // number of traces
k          = 1;          // slice number to generate: 1...numslices
slice_thickness = 3.0;   // mm 
clearance       = 0.25;  // mm — fit tolerance

//////
// Size parameters
//////
// Physical size of the final object
x_length   = 100;        // mm
y_length   = 100;        // mm

// Vertical scaling/offset: z_mm = z_offset + z_scale * f(x,y)
z_scale    = 10;         // mm per math-unit
z_offset   = 40;         // mm
z_floor    = 0;          // mm (clamp below)

//////
// Slot parameters
//////
// Slots are located as described. For instance, slot_positions = [0.25, 0.75] would yield slots at 1/4 and 3/4 of the slice length.
slot_h     = 20;          // mm — height of the slice notch
slot_positions = [0.5];

// Slot opening (in the mating direction) = slice thickness + clearance
slot_opening_w = slice_thickness + clearance;

//////
// Stand parameters
//////
// Height is 2*slot_h; slots cut down from the top by slot_h.
stand_height  = 2*slot_h;
stand_margin  = 6;                 // mm extra length beyond the slice length on both ends
stand_N       = numslices;         // positions


///////////////////////////////////////////////////////////////
// Helpers
function lerp(a,b,t) = a + (b-a)*t;
function clamp(v, lo, hi) = (v<lo)?lo : (v>hi)?hi : v;

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

// Convert f(x,y) to printable z(mm), clamped
function z_mm(xm, ym) = max(z_floor, z_offset + z_scale * f(xm, ym));

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
                    z    = z_mm(xm, ym))
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
module slice2D_outline(k_=k, const_axis) {
    xk = xk_from_k(k_);
    yk = yk_from_k(k_);
    slice_len = slice_length_mm(const_axis);

    top = [
        for (i=[0:n_samples])
            let(s_mm = slice_len * i / n_samples,
                xm   = (const_axis=="x") ? xk : x_math_from_mm(s_mm),
                ym   = (const_axis=="x") ? y_math_from_mm(s_mm) : yk,
                z    = z_mm(xm, ym))
            [s_mm, z]
    ];

    bottom_left  = [0, 0];
    bottom_right = [slice_len, 0];

    polygon(points = concat([bottom_left, bottom_right], reverse_list(top)));
}

module slice3D(k_=k, const_axis) {
    // Some parameter combos clamp the profile to z_floor before reaching the slice end.
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
                z    = z_mm(xm, ym))
            if (z > z_floor + eps) i
    ];
    slot_ref_len = (len(nonzero_idx) == 0) ? slice_len : (slice_len * max(nonzero_idx) / n_samples);

    difference() {
        linear_extrude(height = slice_thickness, center=false, convexity=10)
            slice2D_outline(k_, const_axis);

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
} else if (MODE=="solid") {
    solid3D();
} else {
    echo("Unknown MODE. Use: slice_x | slice_y | stand_x | stand_y | solid");
}
