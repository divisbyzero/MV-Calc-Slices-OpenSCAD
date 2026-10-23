// Preset surface: "sombrero" (radial sinc)
//
// Included by Slices.scad and selected with the SURFACE dropdown ("sombrero").
//
// Interface expected by Slices.scad:
//   - function sombrero_f(x,y)
//   - function sombrero_params() = [xmin, ymin, zmin, x_span, y_span, z_span, column_size_x, column_size_y, column_centers]

// Radial sinc (sombrero): 2*sin(r)/r with removable singularity at r=0.
// OpenSCAD's sin() takes degrees, so we convert radians -> degrees.
function sombrero_f(x, y) =
    let(r = sqrt(x*x + y*y))
    6 + 4.5*((r == 0) ? 3 : 3 * sin(r * 180 / PI) / r);

function sombrero_params() = [
    -12,   // xmin
    -12,   // ymin
     0,    // zmin (bottom of the model)
     24,   // x_span
     24,   // y_span
     19.5, // z_span (all_slices_z levels run from zmin to zmin+z_span)
     3,    // column_size_x
     3,    // column_size_y
     []    // column_centers
];
