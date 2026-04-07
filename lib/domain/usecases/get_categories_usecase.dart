import 'package:mi_gym_flutter/domain/entities/category_entity.dart';
import 'package:mi_gym_flutter/domain/repositories/class_repository.dart';

class GetCategoriesUseCase {
  final ClassRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<List<CategoryEntity>> execute() {
    return _repository.getCategories();
  }
}
