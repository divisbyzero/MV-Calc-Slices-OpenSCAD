// Preset surface: hyperbolic paraboloid (saddle)
//
// This file is intended to be loaded from Slices.scad via:
//   use <hyperbolic_paraboloid.scad>
//
// It provides:
//   - function f_hyperbolic_paraboloid(x,y)
//   - function params_hyperbolic_paraboloid() = [xmin,ymin,x_span,y_span,z_scale,z_buffer]

function f_hyperbolic_paraboloid(x, y) = 1.25*(x*x - y*y);

// Default parameter suggestion for this preset.
// Feel free to override by editing the values in Slices.scad (PRESET="custom").
function params_hyperbolic_paraboloid() = [
    -2,  // xmin
    -2,  // ymin
     4,  // x_span
     4,  // y_span
    10,  // z_scale
     5   // z_buffer
];
