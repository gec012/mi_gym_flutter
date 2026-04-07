// ignore_for_file: avoid_print
import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://obbvowajkzpepahmzebb.supabase.co',
    'sb_publishable_NRIZEz-E0OUIDDCAwZJc8A_F6V0F3vD',
  );

  print('Fetching categories...');
  final resCategories = await supabase.from('categories').select();
  final categories = resCategories as List<dynamic>;

  print('Fetching classes...');
  final resClasses = await supabase.from('classes').select();
  final classes = resClasses as List<dynamic>;

  for (final cls in classes) {
    print('Class: \${cls["name"]} - Current category: \${cls["category_id"]}');
    
    // Assign a matching category
    String className = (cls['name'] as String).toLowerCase();
    String? newCategoryId;

    for (final cat in categories) {
      String catName = (cat['name'] as String).toLowerCase();
      // Heuristic: If class name contains category name or vice versa
      if (className.contains(catName) || catName.contains(className)) {
        newCategoryId = cat['id'];
        break;
      }
    }
    
    // Hardcoded some popular matches if heuristic fails
    if (newCategoryId == null) {
        if (className.contains('hit') || className.contains('hiit')) {
            final hiitCats = categories.where((c) => (c['name'] as String).toLowerCase().contains('hit') || (c['name'] as String).toLowerCase().contains('hiit'));
            if(hiitCats.isNotEmpty) newCategoryId = hiitCats.first['id'];
        }
        else if (className.contains('spin') || className.contains('indoor')) {
            final spinCats = categories.where((c) => (c['name'] as String).toLowerCase().contains('spin'));
            if(spinCats.isNotEmpty) newCategoryId = spinCats.first['id'];
        }
        else if (className.contains('yoga')) {
            final yogaCats = categories.where((c) => (c['name'] as String).toLowerCase().contains('yoga'));
            if(yogaCats.isNotEmpty) newCategoryId = yogaCats.first['id'];
        }
        else if (categories.isNotEmpty) {
           // Default to first category if no match
           newCategoryId = categories.first['id'];
        }
    }

    if (newCategoryId != null && cls['category_id'] != newCategoryId) {
      print('Updating \${cls["name"]} to category_id \$newCategoryId');
      await supabase.from('classes').update({'category_id': newCategoryId}).eq('id', cls['id']);
    } else {
      print('No update needed for \${cls["name"]}');
    }
  }

  print('Done updating categories.');
}
