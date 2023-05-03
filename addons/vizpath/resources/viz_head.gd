@tool
extends Resource
class_name VizHead

# The VizHead class is a resource that allows the creation
# of a simple arrow head at the end of the path showing the
# final destination of the path.  
#
# It is designed to be used interchangably with any resource
# that defineds an apply method with the signature defined
# below.

## The width of the arrow head as a percentage of the 
## path width it is associated with
@export var width_factor : float = 2.0 :
	set(w):
		width_factor = w
		emit_changed()

## The length of the arrow head as a percentage of the
## path width it is associated with
@export var length_factor : float = 1.20 :
	set(l):
		length_factor = l
		emit_changed()

## The apply function will be called when the path 
## mesh is created.
##
## This class can be overridden to provide a custom head to the path
## by defining a resource that has an apply method with the following
## definition.
##
## The [code]mesh_node[/code] parameter is the mesh instance of the visualized path.
## Its interior mesh can be updated (typically with [SurfaceTool]).
## The [code]u[/code] parameter is the U texture coordinate of the [code]left[/code] and
## [code]right[/code] positions of the end of the path, where the V texture coordinate
## is 0.0 for [code]left[/code] and 1.0 for [code]right[/code].  The [code]normal[/code] and
## the [code]direction[/code] define the position of the face and the direction that
## path is going.  The [code]path_mat[/code] is the material that was used
## in the original path definition [member VisualizedPath.path_mat].
func apply(mesh_node : MeshInstance3D, u : float, left : Vector3, right : Vector3, normal : Vector3, direction : Vector3, path_mat : Material):
	var segment := right - left
	var mid_segment := segment / 2.0
	var binormal := direction.cross(normal).normalized()
	var segment_len := segment.length()
	var arrow_base_len := segment_len * width_factor
	var extent_len := (arrow_base_len - segment_len)/2.0
	var arrow_left_extent := left - extent_len * binormal
	var arrow_right_extent := right + extent_len * binormal
	var arrow_point_len := segment_len * length_factor
	var arrow_fwd_extent := left + mid_segment + arrow_point_len * direction
	var v_extent = width_factor * 0.5

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 0, 0))
	st.set_normal(normal)
	st.set_material(path_mat)

	st.set_uv(Vector2(u, 0.5 + v_extent))
	st.add_vertex(arrow_right_extent)

	st.set_uv(Vector2(u, 0.5 - v_extent))
	st.add_vertex(arrow_left_extent)

	st.set_uv(Vector2(u+arrow_point_len, 0.5))
	st.add_vertex(arrow_fwd_extent)

	mesh_node.mesh = st.commit(mesh_node.mesh)
