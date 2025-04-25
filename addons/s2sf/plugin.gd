@tool
extends EditorPlugin

var panel : Control

func _enter_tree():
  panel = preload("res://addons/s2sf/import_panel.tscn").instantiate()
  add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)
  panel.name = "S2SF"

func _exit_tree():
  remove_control_from_docks(panel)
  panel.queue_free()
