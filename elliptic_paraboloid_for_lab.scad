// Preset surface: elliptic paraboloid (dome)
//
// Included by Slices.scad and selected with the SURFACE dropdown ("elliptic_paraboloid_for_lab").
//
// Interface expected by Slices.scad:
//   - function elliptic_paraboloid_for_lab_f(x,y)
//   - function elliptic_paraboloid_for_lab_params() = [xmin, ymin, zmin, x_span, y_span, z_span, column_size_x, column_size_y, column_centers]

function elliptic_paraboloid_for_lab_f(x, y) = -x*x/2 - y*y + 11;

function elliptic_paraboloid_for_lab_params() = [
    -3,  // xmin
    -3,  // ymin
     0,  // zmin (bottom of the model)
     6,  // x_span
     6,  // y_span
     6,  // z_span (all_slices_z levels run from zmin to zmin+z_span)
     3,  // column_size_x
     3,  // column_size_y
    [[0,0]]  // column_centers (relative; 0 = center)
];
