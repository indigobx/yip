# Настройка стиля
# plt.style.use('seaborn-v0_8-whitegrid')  # Чистый стиль с сеткой

fig = plt.figure(figsize=(18, 9), dpi=96)
ax = fig.add_subplot(111, projection='3d')

for uid in df['uid'].unique():
  q = f"uid == '{uid}'"
# Данные (уже загружены в df)
  x = df.query(q)['position.x']
  y = df.query(q)['position.z']
  z = df.query(q)['position.y']
  c = df.query(q)['velocity_length']
  ammo_name = df.query(q)['ammo.name'].head(1)

  # Основная линия траектории
  main_line = ax.plot(x, y, z, alpha=0.5, linewidth=1.5, label=ammo_name)[0]

  # Точечная визуализация с цветом по скорости
  sc = ax.scatter(x, y, z, c=c, cmap='jet', alpha=1.0, s=10, 
                  edgecolors='none', linewidth=0.0, label='Velocity points')
  main_line.set_zorder(1)
  sc.set_zorder(2)

  # Вертикальные линии к плоскости Z=0
  # n = 25  # Увеличиваем шаг для меньшей загроможденности
  n = int(len(x) / 10)
  for i in range(0, len(x), n):
    ax.plot([x.iloc[i], x.iloc[i]], 
            [y.iloc[i], y.iloc[i]], 
            [0, z.iloc[i]], 
            color='gray', linestyle=':', alpha=0.8, linewidth=0.7)

# Настройка осей
ax.invert_yaxis()  # Соответствие системе координат Godot
ax.set_xlabel('X (Right)', fontsize=8, labelpad=4)
ax.set_ylabel('Z (Forward)', fontsize=8, labelpad=4)
ax.set_zlabel('Y (Up)', fontsize=8, labelpad=4)


# Координатные оси (упрощенные)
axis_length = max(max(x)-min(x), max(y)-min(y), max(z)-min(z)) * 0.3
ax.quiver(0, 0, 0, axis_length, 0, 0, color='r', linewidth=2, arrow_length_ratio=0.1)
ax.quiver(0, 0, 0, 0, axis_length, 0, color='b', linewidth=2, arrow_length_ratio=0.1)
ax.quiver(0, 0, 0, 0, 0, axis_length, color='g', linewidth=2, arrow_length_ratio=0.1)

# Автоматическое выравнивание масштаба
def set_axes_equal(ax):
  limits = np.array([ax.get_xlim3d(), ax.get_ylim3d(), ax.get_zlim3d()])
  origin = np.mean(limits, axis=1)
  radius = 0.5 * np.max(np.abs(limits[:, 1] - limits[:, 0]))
  ax.set_xlim3d([origin[0] - radius, origin[0] + radius])
  ax.set_ylim3d([origin[1] - radius, origin[1] + radius])
  ax.set_zlim3d([origin[2] - radius, origin[2] + radius])

set_axes_equal(ax)

# Плоскость Z=0 для референса
xx, yy = np.meshgrid(np.linspace(min(x), max(x), 2), 
                    np.linspace(min(y), max(y), 2))
ax.plot_surface(xx, yy, np.zeros_like(xx), color='gray', alpha=0.05)

# Угол обзора и легенда
ax.view_init(elev=0, azim=180)  # Более информативный ракурс

# Создаём кастомные элементы для легенды
legend_elements = [
    Line2D([0], [0], color='gray', lw=1.5, label='Траектория'),
    Line2D([0], [0], marker='o', color='w', markerfacecolor='red', 
           markersize=8, label='Точки скорости'),
    Line2D([0], [0], color='gray', linestyle=':', lw=1, label='Высота')
]

# Добавляем цветовую шкалу как элемент легенды
cbar_elem = plt.cm.ScalarMappable(cmap='jet')
cbar_elem.set_array(df['velocity_length'])

legend = ax.legend(
    handles=legend_elements,
    loc='upper right',
    framealpha=0.9,
    fontsize=9
)

# Ручная добавка colorbar в легенду
cax = fig.add_axes([0.82, 0.7, 0.02, 0.2])  # Позиция внутри легенды
cbar = fig.colorbar(cbar_elem, cax=cax)
cbar.set_label('Скорость (м/с)', fontsize=8)
cbar.ax.tick_params(labelsize=7)
ax.xaxis.label.set_size(9)
ax.yaxis.label.set_size(9)
ax.zaxis.label.set_size(9)
# Критически важная настройка - минимизация отступов
plt.subplots_adjust(left=0.01, right=0.99, top=0.99, bottom=0.01)

# Убедитесь, что это идёт ПОСЛЕ всех элементов графика
ax.set_position([0, 0, 1, 1])
plt.show()