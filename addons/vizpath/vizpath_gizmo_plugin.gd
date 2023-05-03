extends EditorNode3DGizmoPlugin

const vizpath_gizmo = preload("res://addons/vizpath/vizpath_gizmo.gd")
const spot_mesh = preload("res://addons/vizpath/mesh/spot.obj")

var editor_plugin : EditorPlugin

func _init():
	create_material("line", Color(1, 1, 0))
	create_handle_material("handles")

func _create_gizmo(node):
	if node is VisualizedPath:
		var viz_path_node := node as VisualizedPath
		var gizmo = vizpath_gizmo.new()
		return gizmo
	else:
		return null

func _get_gizmo_name():
	return "VizPath Gizmo"

func set_editor_plugin(p_plugin : EditorPlugin):
	editor_plugin = p_plugin
