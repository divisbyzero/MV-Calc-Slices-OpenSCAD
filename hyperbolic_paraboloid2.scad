// Preset surface: hyperbolic paraboloid (saddle)
//
// Included by Slices.scad and selected with the SURFACE dropdown ("hyperbolic_paraboloid2").
//
// Interface expected by Slices.scad:
//   - function hyperbolic_paraboloid2_f(x,y)
//   - function hyperbolic_paraboloid2_params() = [xmin,ymin,x_span,y_span,column_size_x,column_size_y,column_centers_mm]

function hyperbolic_paraboloid2_f(x, y) = -x*x/4 + y*y/2+3;

function hyperbolic_paraboloid2_params() = [
    -3,  // xmin
    -3,  // ymin
     6,  // x_span
     6,  // y_span
     3,  // column_size_x
     3,  // column_size_y
    [[-38.5,0],[38.5,0]]  // column_centers_mm
];
