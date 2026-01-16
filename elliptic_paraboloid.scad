// Preset surface: elliptic paraboloid
//
// Load from Slices.scad via:
//   include <elliptic_paraboloid.scad>;
//
// This file sets SOURCE="FROM_FILE" so the include alone selects the preset.
//
// Standard preset interface expected by Slices.scad:
//   - function preset_f(x,y)
//   - function preset_params() = [xmin, ymin, x_span, y_span, z_scale, z_buffer]

SOURCE = "FROM_FILE";

// Matches the current custom function in Slices.scad
function preset_f(x, y) = -x*x - 2*y*y;

// Matches the current custom parameter values in Slices.scad
function preset_params() = [
    -sqrt(2),   // xmin
    -1,         // ymin
    2*sqrt(2),  // x_span
    2,          // y_span
    30,         // z_scale
    0           // z_buffer
];

// Optional columns for MODE="all_slices_z": [column_size_x, column_size_y, column_centers_mm]
function preset_column_params() = [
    3,
    3,
    []
];
