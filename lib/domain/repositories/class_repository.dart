import 'package:mi_gym_flutter/domain/entities/gym_class_entity.dart';
import 'package:mi_gym_flutter/domain/entities/category_entity.dart';
import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';
import 'package:mi_gym_flutter/domain/entities/instructor_entity.dart';

abstract class ClassRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<List<GymClassEntity>> getClasses();
  Future<List<ScheduleEntity>> getSchedules({bool onlyLive = false});
  Future<List<InstructorEntity>> getInstructors();
  Future<GymClassEntity?> getClassById(String id);
  Future<ScheduleEntity?> getScheduleById(String id);
}
