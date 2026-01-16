// Default "no preset" surface.
//
// Slices.scad includes exactly one preset file. This one provides safe defaults
// so that SOURCE can be switched without causing undefined-function warnings.

function preset_f(x, y) = 0;

// [xmin, ymin, x_span, y_span, z_scale, z_buffer]
function preset_params() = [
    -2,
    -2,
     4,
     4,
    10,
     0
];
