// Preset surface: hyperbolic paraboloid (saddle)
//
// Included by Slices.scad and selected with the SURFACE dropdown ("hyperbolic_paraboloid_for_lab").
//
// Interface expected by Slices.scad:
//   - function hyperbolic_paraboloid_for_lab_f(x,y)
//   - function hyperbolic_paraboloid_for_lab_params() = [xmin, ymin, zmin, x_span, y_span, z_span,column_size_x,column_size_y,column_centers]

function hyperbolic_paraboloid_for_lab_f(x, y) = -x*x/4 + y*y/2+4.5;

function hyperbolic_paraboloid_for_lab_params() = [
    -3,  // xmin
    -3,  // ymin
    1.5,  // zmin (bottom of the model)
     6,  // x_span
     6,  // y_span
     4,  // z_span (all_slices_z levels run from zmin to zmin+z_span)
     3,  // column_size_x
     3,  // column_size_y
    [[-1,0],[1,0]]  // column_centers (relative; +/-1 = flush with edge)
];
