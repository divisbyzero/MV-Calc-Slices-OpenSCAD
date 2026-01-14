///////////////////////////////////////////////////////////////
// TRACE SLICES + STAND (single-file workflow)
// Updated per request:
//  - Slice has TWO bottom slots at 1/4 and 3/4 along length
//  - Slice and stand have SAME thickness = slice_thickness
//  - Slot opening width (mating) = slice_thickness + clearance
///////////////////////////////////////////////////////////////

//////////////////// USER PARAMETERS //////////////////////////
MODE = "slice";          // "slice" | "stand" | "both"

length     = 120;        // mm, corresponds to y-interval size

xmin       = 0;          // math x-min
ymin       = 0;          // math y-min
x_span     = 4;          // math width in x-direction
y_span     = 4;          // math width in y-direction

numslices  = 7;          // number of x-traces
k          = 4;          // 1..numslices

slice_thickness = 3.0;   // mm (SAME for slice and stand)
clearance       = 0.25;  // mm (fit tolerance)

slot_h     = 20;          // mm (height of the slice notch / stand key)

n_samples  = 180;        // curve sampling resolution

// Vertical scaling/offset: z_mm = z_offset + z_scale * f(x,y)
z_scale    = 15;         // mm per math-unit
z_offset   = 12;         // mm
z_floor    = 0;          // mm (clamp below)

//////////////////// DERIVED PARAMETERS ///////////////////////
// Slot opening (in the mating direction) = slice thickness + clearance
slot_opening_w = slice_thickness + clearance;

// Slots are located at 1/4 and 3/4 of the slice length
slot_positions = [0.25, 0.75];

// Stand sizing (as before, but thickness now equals slice_thickness)
stand_height  = 2*slot_opening_w;  // you originally wanted 2*width; here width=slot_opening_w
stand_margin  = 6;                 // mm extra length beyond `length` on both ends
stand_N       = numslices;         // positions

///////////////////////////////////////////////////////////////
// DEFINE YOUR FUNCTION HERE
function f(x,y) = x*x - y*y;

///////////////////////////////////////////////////////////////
// Helpers
function lerp(a,b,t) = a + (b-a)*t;
function clamp(v, lo, hi) = (v<lo)?lo : (v>hi)?hi : v;

// Map y_mm in [0,length] to y_math in [ymin, ymin+y_span]
function y_math_from_mm(y_mm) = lerp(ymin, ymin + y_span, y_mm/length);

// Evenly spaced x_k in [xmin, xmin+x_span]
function xk_from_k(k_) =
    (numslices<=1) ? xmin :
    lerp(xmin, xmin + x_span, (k_-1)/(numslices-1));

// Convert f(x,y) to printable z(mm), clamped
function z_mm(xm, ym) = max(z_floor, z_offset + z_scale * f(xm, ym));

// Backwards-compatible list reverse (also fine on new versions)
function reverse_list(v) = [ for (i = [len(v)-1 : -1 : 0]) v[i] ];

///////////////////////////////////////////////////////////////
// Slice: 2D outline in (Y,Z), extruded in X by slice_thickness
module slice2D_outline(k_=k) {
    xk = xk_from_k(k_);

    top = [
        for (i=[0:n_samples])
            let(y_mm = length * i / n_samples,
                ym   = y_math_from_mm(y_mm),
                z    = z_mm(xk, ym))
            [y_mm, z]
    ];

    bottom_left  = [0, 0];
    bottom_right = [length, 0];

    polygon(points = concat([bottom_left, bottom_right], reverse_list(top)));
}

module slice3D(k_=k) {
    difference() {
        linear_extrude(height = slice_thickness, center=false, convexity=10)
            slice2D_outline(k_);

        // Two bottom slots (notches): opening width = slot_opening_w,
        // height = slot_h, centered at 1/4 and 3/4 of the length.
        for (p = slot_positions) {
            // In this model, the slice outline is in the XY plane:
            //   X = along the slice length (0..length)
            //   Y = vertical height (0..z)
            // and the slice thickness is extruded along Z.
            // So the notch should be positioned along X, rise in Y, and cut through Z.
            translate([ p*length - slot_opening_w/2, -1, -1 ]) // -1 ensures full cut
                cube([ slot_opening_w, slot_h + 1, slice_thickness + 2 ], center=false);
        }
    }
}

///////////////////////////////////////////////////////////////
// Stand: same thickness as slice (slice_thickness)
// We create a base block and TWO KEYS per position.
// Keys have thickness slice_thickness and width slot_opening_w, so they
// fit into the slice notches with clearance.
module stand3D() {
    stand_len = length + 2*stand_margin;

    // Position centers along Y
    function posY(i) =
        (stand_N<=1) ? (stand_len/2) :
        stand_margin + (stand_len - 2*stand_margin) * (i/(stand_N-1));

    union() {
        // Base block: thickness=X=slice_thickness
        translate([0, -stand_margin, 0])
            cube([ slice_thickness, stand_len, stand_height ], center=false);

        // Keys: two per position, aligned to the slice notch spacing
        for (i=[0:stand_N-1]) {
            y0 = posY(i);

            // Put first key at y0, second key offset by (0.75-0.25)*length = 0.5*length
            key1_center = y0;
            key2_center = y0 + (slot_positions[1] - slot_positions[0]) * length;

            for (yc = [key1_center, key2_center]) {
                translate([0, yc - slot_opening_w/2, stand_height])
                    cube([ slice_thickness, slot_opening_w, slot_h ], center=false);
            }
        }
    }
}

///////////////////////////////////////////////////////////////
// Build / preview
if (MODE=="slice") {
    slice3D(k);
} else if (MODE=="stand") {
    stand3D();
} else if (MODE=="both") {
    stand3D();
    translate([0, 0, stand_height + slot_h + 2])
        slice3D(k);
} else {
    echo("Unknown MODE. Use: slice | stand | both");
}
