// Preset surface: "sombrero" (radial sinc)
//
// Load from Slices.scad via:
//   include <sombrero.scad>;
//
// This file sets SOURCE="FROM_FILE" so the include alone selects the preset.
//
// Standard preset interface expected by Slices.scad:
//   - function preset_f(x,y)
//   - function preset_params() = [xmin, ymin, x_span, y_span, z_scale, z_buffer, column_size_x, column_size_y, column_centers_mm]

SOURCE = "FROM_FILE";

// Radial sinc (sombrero): 2*sin(r)/r with removable singularity at r=0.
// This matches the common classroom version used in Slices.scad's custom example.
// OpenSCAD's sin() takes degrees, so we convert radians -> degrees.
function preset_f(x, y) =
    let(r = sqrt(x*x + y*y))
    (r == 0) ? 2 : 2 * sin(r * 180 / PI) / r;

function preset_params() = [
    -12, // xmin
    -12, // ymin
     24, // x_span
     24, // y_span
     15, // z_scale (mm per math unit)
     20, // z_buffer (mm)
     3,  // column_size_x
     3,  // column_size_y
     []  // column_centers_mm
];
