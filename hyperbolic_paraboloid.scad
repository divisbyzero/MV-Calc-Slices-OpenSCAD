// Preset surface: hyperbolic paraboloid (saddle)
//
// This file is intended to be loaded from Slices.scad via:
//   include <hyperbolic_paraboloid.scad>;
//
// It sets SOURCE="FROM_FILE" so the include alone selects the preset.
//
// Standard preset interface expected by Slices.scad:
//   - function preset_f(x,y)
//   - function preset_params() = [xmin,ymin,x_span,y_span,column_size_x,column_size_y,column_centers_mm]

SOURCE = "FROM_FILE";

// Includes the former vertical scale and offset, normalized to preserve the
// default 80 mm-wide model under uniform XYZ scaling.
function preset_f(x, y) = 0.5 + 0.4*(1.25*(x*x - y*y)+5);

// Default parameter suggestion for this preset.
// To use custom values instead, include no_presets.scad in Slices.scad.
function preset_params() = [
    -2,  // xmin
    -3,  // ymin
     4,  // x_span
     6,  // y_span
     3,  // column_size_x
     3,  // column_size_y
    [[-38.5,0],[38.5,0]]  // column_centers_mm
];
