import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';
import 'package:mi_gym_flutter/domain/repositories/class_repository.dart';

class GetSchedulesUseCase {
  final ClassRepository _repository;

  GetSchedulesUseCase(this._repository);

  Future<List<ScheduleEntity>> execute({bool onlyLive = false}) {
    return _repository.getSchedules(onlyLive: onlyLive);
  }
}
