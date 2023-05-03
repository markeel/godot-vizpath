@tool
extends EditorPlugin

const VizpathGizmoPlugin = preload("res://addons/vizpath/vizpath_gizmo_plugin.gd")

var gizmo_plugin = VizpathGizmoPlugin.new()


func _enter_tree():
	gizmo_plugin.set_editor_plugin(self)
	add_node_3d_gizmo_plugin(gizmo_plugin)


func _exit_tree():
	remove_node_3d_gizmo_plugin(gizmo_plugin)
