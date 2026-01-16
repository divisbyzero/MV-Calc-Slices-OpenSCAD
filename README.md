# MV-Calc Slices (OpenSCAD)

An OpenSCAD model for generating **3D-printable multivariable calculus surfaces** and either:

- a **modular** set of interlocking slices + stands, or
- a **one-piece assembled** “stand + all slices” print.

You define a function `f(x,y)` over a rectangular domain. The script can generate:

- the full surface as a watertight solid (`MODE="solid"`), and/or
- a family of constant-\(x\) or constant-\(y\) slices (`MODE="slice_x"` / `MODE="slice_y"`) with matching stands (`MODE="stand_x"` / `MODE="stand_y"`).

Everything is parameterized in the top section of [Slices.scad](Slices.scad).

## Preset surfaces

This repo supports preset surfaces defined in separate `.scad` files.

- Preset file added: [hyperbolic_paraboloid.scad](hyperbolic_paraboloid.scad)
- Preset file added: [elliptic_paraboloid.scad](elliptic_paraboloid.scad)
- Preset file added: [sombrero.scad](sombrero.scad)
- In [Slices.scad](Slices.scad):
   - Uncomment exactly one preset `include <...>;` line near the top.
     - For custom mode, include [no_presets.scad](no_presets.scad)
     - For a preset surface, include that preset file (e.g. [hyperbolic_paraboloid.scad](hyperbolic_paraboloid.scad))

Preset files use a simple, consistent interface:

```scad
function preset_f(x,y) = ...;
function preset_params() = [xmin, ymin, x_span, y_span, z_scale, z_buffer];
function preset_column_params() = [column_size_x, column_size_y, column_centers_mm];
```

## Requirements

- [OpenSCAD](https://openscad.org/) (recommended: a recent stable release)
- Optional: a slicer (PrusaSlicer, Cura, OrcaSlicer, etc.) and a 3D printer

## Quick start

1. Open [Slices.scad](Slices.scad) in OpenSCAD.
2. Edit the **PARAMETERS** section at the top.
3. Press **F5** (Preview) for quick iteration, then **F6** (Render) before exporting.
4. Export:
   - **File → Export → Export as STL** (for 3D printing)

## Modes

Set `MODE` to one of the following:

- `"solid"`: full 3D surface solid over the domain
- `"slice_x"`: a single slice with **x = constant** (y varies along the slice)
- `"slice_y"`: a single slice with **y = constant** (x varies along the slice)
- `"stand_x"`: stand that mates with `slice_x`
- `"stand_y"`: stand that mates with `slice_y`
- `"all_slices_x"`: one-piece assembled model: stand(s) + **all** `slice_x` slices (no slots)
- `"all_slices_y"`: one-piece assembled model: stand(s) + **all** `slice_y` slices (no slots)
- `"all_slices_z"`: proof-of-concept: full solid cut into `numslices` horizontal slabs by deleting thin horizontal boxes

The file’s last section automatically builds the geometry for the selected `MODE`.

Note on placement:

- `MODE="slice_*"` and `MODE="stand_*"` are oriented/placed in the first quadrant for easy STL exporting/printing.
- `MODE="solid"` and `MODE="all_slices_*"` are centered on the origin in XY (e.g. with `x_length=80`, `x` runs from `-40` to `+40`).

For `MODE="all_slices_z"`, the bottom slab sits on the XY plane (`z=0`). Each slab has thickness `slice_thickness`, the vertical pitch rule is based on the X-direction slice spacing (approximately `x_length/(numslices-1)` mm), and the number of slabs is computed automatically from the sampled maximum height of the surface.

`MODE="all_slices_z"` also supports optional vertical columns (useful as built-in supports). In [Slices.scad](Slices.scad), set:

- `column_size_x`, `column_size_y` (mm)
- `column_centers_mm = [[x0,y0], [x1,y1], ...]`

Column centers are in the model’s XY coordinates (mm), where the solid is centered on the origin.

The columns are generated as solids above each rectangular base footprint, under the surface, and capped at the top of the highest remaining horizontal slice (so their tops may be curved, and they will not extend into the deleted gap regions).

When using a preset surface file, the column settings come from that preset file’s `preset_column_params()`.

## Defining the function

If using custom mode (i.e. [no_presets.scad](no_presets.scad) is included), edit the custom function near the top:

```scad
function f_user(x,y) = 0.75*(x*x - y*y);
```

Notes:

- `x` and `y` are *mathematical* coordinates over your chosen domain.
- OpenSCAD’s `sin/cos/tan` expect **degrees**. This file includes helpers `sin_rad`, `cos_rad`, `tan_rad` for radians.
- If your function has a removable singularity (e.g. `sin(r)/r`), use `let(...)` and conditionals (see the commented example in [Slices.scad](Slices.scad)).

## Domain, scaling, and physical size

These parameters control how math coordinates map to millimeters:

- **Domain** (math units)
   - `xmin`, `ymin`
   - `x_span`, `y_span`
- **Physical size** (mm)
  - `x_length`, `y_length`
- **Vertical scaling**
   - `z_scale` (mm per math unit)
   - `z_buffer` (mm)

When using a preset surface file, the domain/scaling parameters come from that file’s `preset_params()` instead of the values you set in [Slices.scad](Slices.scad).

Internally, the script estimates the minimum value of `z_scale*f(x,y)` over the domain and shifts everything upward so the model has a flat base at `z=0`.

In terms of the math-defined height in millimeters,

- `f_mm(x,y) = z_scale * f(x,y)`
- `z_min = min(f_mm)` over the sampled domain
- surface height used for the solid is:
   - `z_solid_mm(x,y) = -z_min + z_buffer + f_mm(x,y)`

So the minimum of `z_solid_mm` is `z_buffer`.

Slice profiles (used by `MODE="slice_*"` and also by the assembled modes) use the same height map:

- `z_slice_mm(x,y) = z_solid_mm(x,y)`

If your surface looks clipped or overly tall/flat, adjust `z_scale` (or the preset’s `z_scale` in `preset_params()`).

## Generating a full surface solid

1. Set:
   - `MODE = "solid";`
2. Optionally increase smoothness (slower renders):
   - `solid_nx`, `solid_ny`
3. Press **F6** to render.
4. Export as STL.

## Generating slices (and stands)

### Slice family controls

- `numslices`: how many slices exist in the family
- `k`: which slice index to generate (`1 ... numslices`)

Slices are **evenly spaced** across the chosen domain:

- `slice_x`: holds \(x\) constant and varies \(y\)
- `slice_y`: holds \(y\) constant and varies \(x\)

### Workflow (recommended)

Pick one slice direction (you can do both, but start with one):

1. Choose:
   - `MODE = "slice_x";` (or `"slice_y"`)
2. Set `numslices`.
3. For each `k = 1..numslices`:
   - set `k`
   - **F6** render
   - export STL (name it something like `slice_x_k05_of_07.stl`)
4. Generate the matching stand:
   - set `MODE = "stand_x";` (or `"stand_y"`)
   - **F6** render
   - export STL (e.g. `stand_x.stl`)

Print the slices and the matching stand, then slide each slice into the corresponding slot.

## Generating a one-piece assembled model (stand + all slices)

If you want the “complete classroom object” as one STL (no assembly, no slots):

1. Set:
   - `MODE = "all_slices_x";` (or `"all_slices_y"`)
2. Set `numslices`.
3. Set `slot_positions` to control where the stand(s) sit along the slice length.
   - Example: `slot_positions = [0.5];` places the stand halfway along every slice.
   - Example: `slot_positions = [0.25, 0.75];` places two stands.
4. **F6** render, then export STL.

The assembled modes still use the same vertical shifting/lift as the individual slice profiles, but they omit the notch cutouts so everything is a single `union()`.

## Slot fit (tolerance) and layout

Slots are cut into the bottom of each slice, and matching slots are cut into the stand.

This section applies to `MODE="slice_*"` and `MODE="stand_*"`. The assembled modes (`MODE="all_slices_*"`) do **not** cut slots.

Key parameters:

- `slice_thickness` (mm): the extrusion thickness of each slice
- `clearance` (mm): extra width added to the slot opening for easier assembly
- `slot_h` (mm): slot depth/height
- `slot_positions`: where along the slice length slots are placed
  - Example: `slot_positions = [0.25, 0.75];` places two slots at 1/4 and 3/4 of the slice length.

In the assembled modes, `slot_positions` instead controls where the stand(s) are placed along the slice length.

The actual slot opening used is:

- `slot_opening_w = slice_thickness + clearance;`

If the fit is too tight, increase `clearance` (typical 0.15–0.40 mm depending on printer/material).

## Print notes

- The script orients stands in a print-friendly way; slices are simple extrusions and usually print well as-is.
- If you plan to laser-cut instead of 3D print, you can adapt the 2D profiles, but this repo currently targets STL output.

## Troubleshooting

- **Render is slow**: lower `solid_nx/solid_ny` (solid) or `n_samples` (slices).
- **Surface looks faceted**: increase `solid_nx/solid_ny`.
- **Slices have missing/not-visible slots**: try moving `slot_positions` inward (e.g. `[0.5]`), or increase `n_samples`. The script already computes an “effective” length so slots don’t land beyond the nonzero part of the slice, but extreme functions/domains can still benefit from tuning.
- **Assembled model is hard to print**: try fewer slices (`numslices`), reduce `x_length/y_length`, or add additional stands via `slot_positions` for stability.
- **Model appears shifted/scaled oddly**: re-check `xmin/ymin/x_span/y_span` vs `x_length/y_length` vs `z_scale` (or the preset’s `preset_params()` if using a preset file).

## Suggested classroom-friendly defaults

- Keep `x_length`/`y_length` around 80–140 mm so the model fits most printers.
- Use `numslices = 5` to `9` for a nice balance of clarity and print time.

## Contributing

Issues and pull requests are welcome—especially additional example surfaces, parameter presets, and print-verified tolerance recommendations.
