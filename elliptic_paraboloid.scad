// Preset surface: elliptic paraboloid
//
// Load from Slices.scad via:
//   include <elliptic_paraboloid.scad>;
//
// This file sets SOURCE="FROM_FILE" so the include alone selects the preset.
//
// Standard preset interface expected by Slices.scad:
//   - function preset_f(x,y)
//   - function preset_params() = [xmin, ymin, x_span, y_span, column_size_x, column_size_y, column_centers_mm]

SOURCE = "FROM_FILE";

// Includes the former vertical scale and offset, normalized to preserve the
// default 80 mm-wide model under uniform XYZ scaling.
function preset_f(x, y) = ((2*sqrt(2)+0.2)/80)*(10 + 40*(2-x*x-2*y*y));

function preset_params() = [
    -sqrt(2)-.1,   // xmin
    -1.2,         // ymin
    2*sqrt(2)+.2,  // x_span
    2.4,          // y_span
    3,          // column_size_x
    3,          // column_size_y
    [[0,0]]     // column_centers_mm
];
