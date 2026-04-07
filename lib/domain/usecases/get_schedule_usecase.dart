import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';
import 'package:mi_gym_flutter/domain/repositories/class_repository.dart';

class GetScheduleUseCase {
  final ClassRepository _repository;

  GetScheduleUseCase(this._repository);

  Future<ScheduleEntity?> execute(String id) {
    return _repository.getScheduleById(id);
  }
}
