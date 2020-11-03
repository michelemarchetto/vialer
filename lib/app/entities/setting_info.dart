import 'package:meta/meta.dart';
import 'categorized_info.dart';
import '../../domain/entities/setting.dart';

import 'category.dart';

class SettingInfo extends CategorizedInfo<Setting> {
  @override
  final Setting item;

  @override
  final int order;

  @override
  final Category category;
  final String name;
  final String description;

  const SettingInfo({
    @required this.item,
    @required this.order,
    @required this.category,
    @required this.name,
    this.description,
  });
}
