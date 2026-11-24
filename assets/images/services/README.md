# Service artwork

## 3D renders (`3d/`)

One 3D object render for each service and for each package group: 23 files.
They are the same files as `GRID/assets/images/services/3d/`. Keep the two
folders identical.

- 512 × 512 opaque PNG. The flat warm off-white `#F7F3EC` background is part
  of the image. Show the render as the tile itself, clipped to the tile's
  corner radius, or on a `#F7F3EC` surface.
- Services are named by category slug, such as `cleaning.png`. Packages are
  named `<category>-<group>.png`, the start of the API package slug, such as
  `plumbing-call-out.png`. A package without its own render uses its
  category's render.

The full guide is
[`DOCUMENTATION/service-artwork.md`](../../../../DOCUMENTATION/service-artwork.md).
It covers the style rules, the exact prompt and model, the post-processing
script, the Figma file, how to add a render, and an index of every file. The
index also lists the 48-render library of future services kept in
`DOCUMENTATION/service-artwork/library/`, which is not bundled in the app.

## Photographs

The `.jpg` files are one landscape photograph per service, shown at the top
of a service's page. Confirm the licence for each before public launch.
