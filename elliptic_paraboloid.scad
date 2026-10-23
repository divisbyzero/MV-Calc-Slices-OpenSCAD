// Preset surface: elliptic paraboloid
//
// Included by Slices.scad and selected with the SURFACE dropdown ("elliptic_paraboloid").
//
// Interface expected by Slices.scad:
//   - function elliptic_paraboloid_f(x,y)
//   - function elliptic_paraboloid_params() = [xmin, ymin, x_span, y_span, column_size_x, column_size_y, column_centers]

function elliptic_paraboloid_f(x, y) = ((2*sqrt(2)+0.2)/80)*(10 + 40*(2-x*x-2*y*y));

function elliptic_paraboloid_params() = [
    -sqrt(2)-.1,   // xmin
    -1.2,         // ymin
    2*sqrt(2)+.2,  // x_span
    2.4,          // y_span
    3,          // column_size_x
    3,          // column_size_y
    [[0,0]]     // column_centers (relative; 0 = center)
];
