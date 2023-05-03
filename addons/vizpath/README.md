# Visualized Path plugin

A plugin for Godot 4 to visualize a path

## Overview

This plugin is designed to create a 3D mesh to visualize a path.  It generates that mesh using  
an array of spots, where each spot has a normal defining the mesh face at that spot.

The path created will be directly between each spot and in the order specified.  The direction 
between the spots is direct but the path can be bent based on the normals at each spot.

An optional tail and head can be placed at the beginning and ending of the path, to provide a
decoration.

## Installation

The plugin is written in 100% GDScript so no compilation is required and should work on any
platform. 

To install it from the Godot Asset Library, select: TBD

There are 3 main directories
- addons/vizpath
- examples/vizpath
- source/vizpath

When loading as an asset in another project (as opposed to working on this asset) the following files
should NOT be imported, they will likely conflict with your project
- README.md
- LICENSE
- icon.svg
- icon.svg.import
- project.godot

After using this asset, the examples/vizpath and source/vizpath folders can be removed so as not
to pollute your project.

## Usage

The typical use of this asset is to create the path from an array of VisualizationSpot resources
in response to user input or actions by the AI during game play.  The plugin does support manually
creating a path in the editor and editing in the 3D view. 

### Programatically through a script

To change the path, simply construct an array of VisualizationSpot objects (which define the 
point in local space to the VisualizedPath and the normal in local space).  There are changed signals
that detect the resource being updated and the path will be reconstructed.  

#### Handling errors

If the path cannot be constructed (because the spots are too close to create a bend with the curve 
specified), the underlying mesh will not be created and the error list will be updated.  To retrieve 
these errors a call to get_errors() can be made.

Based on the properties and how close the spots are allowed to be, you can guarantee that the path will
always be constructed.  If you allow unrestrained movement of the spots and the normals, you will
need to report the error (which is what is done when using the Godot Editor)

### Directly in the editor

The VisualizedPath class supports editing all the properties through the Inspector and updating
the view immediately.  It also allows a VisualizationSpot to be moved and its normal rotated using
a subgizmo.

### Using subgizmo

To use the subgizmo, click on the VisualizedPath and in the 3D view click on the yellow cone for
one of the spots.  The manipulation gizmo changes to that spot and then it can be moved (changing
the position of the spot), or rotated (changing the normal at that spot)

## Examples

Examples of using the plugin can be found in the "example/vizpath" directory.  Feel free to
delete this directory for your project.

## Source

Blender and Inkscape files used to create the meshes and the icon are included in the "source/vizpath"
directory, which can also be removed without impacting its usage.
