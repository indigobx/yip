@tool
extends Control

@onready var folder_path = $VBoxContainer/Folder/FolderPath
@onready var folder_browse = $VBoxContainer/Folder/BrowseFolderButton
@onready var frame_size_x = $VBoxContainer/Frame/FrameSizeX
@onready var frame_size_y = $VBoxContainer/Frame/FrameSizeY
@onready var output_path = $VBoxContainer/Output/OutputPath
@onready var output_browse = $VBoxContainer/Output/BrowseOutputButton
@onready var import_button = $VBoxContainer/ImportButton
@onready var message_label = $VBoxContainer/Message

# Добавляем диалоги
var folder_dialog := FileDialog.new()
var output_dialog := FileDialog.new()

func _ready():
  # Настройка диалога выбора папки
  folder_dialog.access = FileDialog.ACCESS_RESOURCES
  folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
  folder_dialog.visible = false
  folder_dialog.file_selected.connect(func(path): folder_path.text = path)
  add_child(folder_dialog)

  # Настройка диалога сохранения файла
  output_dialog.access = FileDialog.ACCESS_RESOURCES
  output_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
  output_dialog.filters = ["*.tres"]
  output_dialog.visible = false
  output_dialog.file_selected.connect(func(path): output_path.text = path)
  add_child(output_dialog)

  folder_browse.pressed.connect(func(): folder_dialog.popup_centered())
  output_browse.pressed.connect(func(): output_dialog.popup_centered())
  import_button.pressed.connect(_on_import_pressed)

func _on_import_pressed():
  var dir = folder_path.text
  var size = Vector2i(frame_size_x.value, frame_size_y.value)
  var out = output_path.text
  _import_sheets(dir, size, out)

func _import_sheets(folder_path: String, frame_size: Vector2i, output_path: String):
  print(folder_path, frame_size, output_path)
  var sprite_frames = SpriteFrames.new()
  var files = DirAccess.get_files_at(folder_path)

  for file in files:
    if file.ends_with(".png"):
      var tex: Texture2D = load(folder_path + "/" + file)
      var anim_name = file.get_basename()
      sprite_frames.add_animation(anim_name)
      sprite_frames.set_animation_loop(anim_name, true)

      var tex_size = tex.get_size()
      var cols = tex_size.x / frame_size.x
      var rows = tex_size.y / frame_size.y
      print("%s (%d x %d)" % [anim_name, cols, rows])
      for y in range(rows):
        for x in range(cols):
          var region := Rect2(x * frame_size.x, y * frame_size.y, frame_size.x, frame_size.y)
          var atlas := AtlasTexture.new()
          atlas.atlas = tex
          atlas.region = region
          sprite_frames.add_frame(anim_name, atlas)

  var err = ResourceSaver.save(sprite_frames, output_path)
  if err == OK:
    print("SpriteFrames сохранены в:\n" + output_path)
    message_label.text = "✅ SpriteFrames сохранены:\n" + output_path
  else:
    push_error("Ошибка сохранения SpriteFrames!")
    message_label.text = "❌ Ошибка сохранения SpriteFrames!"
