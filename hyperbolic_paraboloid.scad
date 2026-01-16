// Preset surface: hyperbolic paraboloid (saddle)
//
// This file is intended to be loaded from Slices.scad via:
//   include <hyperbolic_paraboloid.scad>;
//
// It sets SOURCE="FROM_FILE" so the include alone selects the preset.
//
// Standard preset interface expected by Slices.scad:
//   - function preset_f(x,y)
//   - function preset_params() = [xmin,ymin,x_span,y_span,z_scale,z_buffer]

SOURCE = "FROM_FILE";

function preset_f(x, y) = 1.25*(x*x - y*y);

// Default parameter suggestion for this preset.
// To use custom values instead, include no_presets.scad in Slices.scad.
function preset_params() = [
    -2,  // xmin
    -2,  // ymin
     4,  // x_span
     4,  // y_span
    10,  // z_scale
     5   // z_buffer
];

// Backwards-compatible aliases (older Slices.scad versions)
function f_hyperbolic_paraboloid(x, y) = preset_f(x, y);
function params_hyperbolic_paraboloid() = preset_params();
