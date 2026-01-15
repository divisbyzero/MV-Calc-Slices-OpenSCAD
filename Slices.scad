///////////////////////////////////////////////////////////////
// TRACE SLICES + STAND (single-file workflow)
// Updated per request:
//  - Slice has TWO bottom slots at 1/4 and 3/4 along length
//  - Slice and stand have SAME thickness = slice_thickness
//  - Slot opening width (mating) = slice_thickness + clearance
///////////////////////////////////////////////////////////////

//////////////////// USER PARAMETERS //////////////////////////

///////////////////////////////////////////////////////////////
MODE = "stand";          // "slice" | "stand" | "both"

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
// Slice parameters
//////
slice_axis = "y";        // "x" => x=constant slices
                         // "y" => y=constant slices
numslices  = 7;          // number of traces
k          = 4;          // slice number to generate: 1...numslices
slice_thickness = 3.0;   // mm 
clearance       = 0.25;  // mm — fit tolerance

//////
// Size parameters
//////
// Physical size of the final object
x_length   = 100;        // mm
y_length   = 100;        // mm

// Vertical scaling/offset: z_mm = z_offset + z_scale * f(x,y)
z_scale    = 15;         // mm per math-unit
z_offset   = 30;         // mm
z_floor    = 0;          // mm (clamp below)

//////
// Slot parameters
//////
// Slots are located at 1/4 and 3/4 of the slice length
slot_h     = 20;          // mm — height of the slice notch
slot_positions = [0.25, 0.75];

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

// Length of the generated slice in mm (depends on which axis varies).
function slice_length_mm() = (slice_axis=="x") ? y_length : x_length;

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
// Slice: 2D outline in (Y,Z), extruded in X by slice_thickness
module slice2D_outline(k_=k) {
    xk = xk_from_k(k_);
    yk = yk_from_k(k_);
    slice_len = slice_length_mm();

    top = [
        for (i=[0:n_samples])
            let(s_mm = slice_len * i / n_samples,
                xm   = x_math_from_mm(s_mm),
                ym   = y_math_from_mm(s_mm),
                z    = (slice_axis=="x") ? z_mm(xk, ym) : z_mm(xm, yk))
            [s_mm, z]
    ];

    bottom_left  = [0, 0];
    bottom_right = [slice_len, 0];

    polygon(points = concat([bottom_left, bottom_right], reverse_list(top)));
}

module slice3D(k_=k) {
    // Some parameter combos clamp the profile to z_floor before reaching the slice end.
    // If we place a slot beyond the last nonzero profile point, it won't appear.
    // So compute an effective length for slot placement based on the sampled curve.
    xk = xk_from_k(k_);
    yk = yk_from_k(k_);
    slice_len = slice_length_mm();
    eps = 0.001;
    nonzero_idx = [
        for (i=[0:n_samples])
            let(s_mm = slice_len * i / n_samples,
                xm   = x_math_from_mm(s_mm),
                ym   = y_math_from_mm(s_mm),
                z    = (slice_axis=="x") ? z_mm(xk, ym) : z_mm(xm, yk))
            if (z > z_floor + eps) i
    ];
    slot_ref_len = (len(nonzero_idx) == 0) ? slice_len : (slice_len * max(nonzero_idx) / n_samples);

    difference() {
        linear_extrude(height = slice_thickness, center=false, convexity=10)
            slice2D_outline(k_);

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
module stand3D() {
    stand_len = slice_length_mm() + 2*stand_margin;

    // Position centers along Y
    function posY(i) =
        (stand_N<=1) ? (stand_len/2) :
        stand_margin + (stand_len - 2*stand_margin) * (i/(stand_N-1));

    module stand_upright() {
        // Shift so the central usable span corresponds to y in [0, slice_length_mm()].
        translate([0, -stand_margin, 0])
            difference() {
                // Base block spans y in [-stand_margin, slice_length_mm()+stand_margin].
                cube([ slice_thickness, stand_len, stand_height ], center=false);

                // Slots: cut down from the top by slot_h.
                // Slot opening (mating) = slot_opening_w.
                for (i=[0:stand_N-1]) {
                    yc = posY(i);
                    translate([-1, yc - slot_opening_w/2, stand_height - slot_h])
                        cube([ slice_thickness + 2, slot_opening_w, slot_h + 1 ], center=false);
                }
            }
    }

    // Print-friendly orientation: lay the stand flat on the XY plane.
    // This keeps the geometry identical, but rotates it so Z height = slice_thickness.
    // (No Z lift here: the rotated solid already spans z=0..slice_thickness.)
    translate([0, stand_margin, 0])
        rotate([0, -90, 0])
            stand_upright();
}

///////////////////////////////////////////////////////////////
// Build / preview
if (MODE=="slice") {
    slice3D(k);
} else if (MODE=="stand") {
    stand3D();
} else if (MODE=="both") {
    stand3D();
    // Offset slice so it doesn't overlap the (flattened) stand preview.
    translate([stand_height + 5, 0, 0])
        slice3D(k);
} else {
    echo("Unknown MODE. Use: slice | stand | both");
}
