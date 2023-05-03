@tool
extends Resource
class_name VizTail

## The number of segments in the semi-sphere of tail
@export var num_segs := 16 :
	set(s):
		num_segs = s
		emit_changed()

## The apply function will be called when the path 
## mesh is created.
##
## This class can be overridden to provide a custom tail to the path
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
	var mid_point := left + mid_segment
	var binormal := direction.cross(normal).normalized()
	var segment_len := segment.length()
	var mid_segment_len := mid_segment.length()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 0, 0))
	st.set_normal(normal)
	var rotation_dir := -signf(direction.dot(mid_segment.rotated(normal, PI/2.0)))
	var last_pos := right
	var last_pu := u
	var last_pv := 1.0
	for i in range(num_segs):
		var weight := rotation_dir * float(i+1) / float(num_segs)
		var angle := weight * PI
		var pv := (1.0 + cos(angle))/2.0
		var pu := u - rotation_dir * mid_segment_len * sin(angle)
		var pos := mid_point + mid_segment.rotated(normal, angle)
		st.set_uv(Vector2(u, 0.5))
		st.add_vertex(mid_point)
		st.set_uv(Vector2(last_pu, last_pv))
		st.add_vertex(last_pos)
		st.set_uv(Vector2(pu, pv))
		st.add_vertex(pos)
		last_pos = pos
		last_pu = pu
		last_pv = pv
	st.set_material(path_mat)
	mesh_node.mesh = st.commit(mesh_node.mesh)
