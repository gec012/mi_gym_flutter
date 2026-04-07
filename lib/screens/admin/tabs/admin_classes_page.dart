import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/models/category_model.dart';
import 'package:mi_gym_flutter/models/class_model.dart';
import 'package:mi_gym_flutter/screens/admin/create_edit_class_page.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/shared/glass_card.dart';
import 'package:mi_gym_flutter/widgets/shared/status_badge.dart';

class AdminClassesPage extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<ClassModel> classes;
  final VoidCallback onRefresh;

  const AdminClassesPage({
    super.key,
    required this.categories,
    required this.classes,
    required this.onRefresh,
  });

  @override
  State<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<AdminClassesPage> {
  final Color surfaceColor = AppColors.surfaceDark;
  final Color slate400 = AppColors.slate400;
  final Color slate800 = AppColors.slate800;
  final Color primaryColor = AppColors.primary;
  final Color backgroundDark = AppColors.backgroundDark;

  String selectedCategory = 'Todas';

  @override
  Widget build(BuildContext context) {
    final filteredClasses = selectedCategory == 'Todas'
        ? widget.classes
        : widget.classes
              .where((c) => c.category?.name == selectedCategory)
              .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Catálogo de Clases',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _navigateToCreateClass,
                  icon: Icon(Icons.add_circle, color: primaryColor, size: 32),
                ),
              ],
            ),
          ),
          _buildCategoryFilters(),
          if (filteredClasses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, color: slate400, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No hay clases en esta categoría',
                      style: TextStyle(color: slate400, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredClasses.length,
              itemBuilder: (context, index) {
                final cls = filteredClasses[index];
                final intensityColor = cls.intensity == 'High'
                    ? const Color(0xFF7C3AED)
                    : (cls.intensity == 'Medium'
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF22C55E));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 20,
                    child: SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                          child: cls.imageUrl != null
                              ? Image.network(
                                  cls.imageUrl!,
                                  width: 110,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _imagePlaceholder(),
                                )
                              : _imagePlaceholder(),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cls.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                      StatusBadge(
                                        text: cls.intensity,
                                        color: intensityColor,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${cls.durationMinutes} min',
                                      style: TextStyle(
                                        color: slate400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white70,
                              ),
                              onPressed: () => _navigateToEditClass(cls),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmDeleteClass(cls),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
              },
            ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 110,
      height: 120,
      color: slate800,
      child: const Icon(Icons.image, color: Colors.white),
    );
  }

  Widget _buildCategoryFilters() {
    final allCategories = ['Todas', ...widget.categories.map((c) => c.name)];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final cat = allCategories[index];
          final isSelected = selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedCategory = cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryColor : slate800,
                  ),
                ),
                child: Center(
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? backgroundDark : slate400,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToCreateClass() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateEditClassPage()));
    if (result == true) {
      widget.onRefresh();
    }
  }

  void _navigateToEditClass(ClassModel classData) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEditClassPage(classData: classData),
      ),
    );
    if (result == true) {
      widget.onRefresh();
    }
  }

  void _confirmDeleteClass(ClassModel cls) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Clase',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro que quieres eliminar "${cls.name}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: slate400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: slate400)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await SupabaseService.deleteClass(cls.id);
                if (!mounted) return;
                widget.onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Clase "${cls.name}" eliminada.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
