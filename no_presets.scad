// No-presets mode (use custom function/parameters in Slices.scad)
//
// When this file is the ONLY included preset file in Slices.scad:
// - SOURCE is set to "CUSTOM"
// - preset_f/preset_params exist as safe stubs

SOURCE = "CUSTOM";

function preset_f(x, y) = 0;

// [xmin, ymin, x_span, y_span, z_scale, z_buffer, column_size_x, column_size_y, column_centers_mm]
function preset_params() = [
    -2,
    -2,
     4,
     4,
    10,
     0,
     3,
     3,
     []
];
