import 'dart:collection';

import 'package:get/get.dart';
import 'package:json_to_dart/utils/error_check/text_editing_controller.dart';
import 'package:json_to_dart_library/json_to_dart_library.dart';

import 'dart_property.dart';

// ignore: must_be_immutable
class FFDartObject extends DartObject with FFDartObjectMixin, FFDartPropertyMixin {
  FFDartObject({
    required super.uid,
    required super.keyValuePair,
    required super.depth,
    required super.nullable,
    super.dartObject,
  }) {
    classNameTextEditingController.text = className;
  }

  /// 根据父对象生成层级类名
  void generateHierarchicalClassName() {
    if (dartObject == null) {
      // 这是根对象，不需要修改
      return;
    }

    // 获取父对象的类名作为前缀
    final String parentClassName = (dartObject as FFDartObject).className;
    if (parentClassName.isEmpty) {
      return;
    }

    // 当前对象的原始类名
    String originalClassName = className;
    if (originalClassName.isEmpty) {
      // 如果当前类名为空，使用键名作为类名
      originalClassName = key;
      if (originalClassName.isEmpty) {
        return;
      }
    }

    // 确保类名首字母大写
    if (originalClassName.isNotEmpty) {
      originalClassName = originalClassName[0].toUpperCase() + originalClassName.substring(1);
    }

    // 设置新的类名，格式为：父类名+当前类名
    className = parentClassName + originalClassName;

    // 更新文本控制器的文本，确保UI显示正确
    classNameTextEditingController.text = className;

    // 递归处理所有子对象
    processChildObjects();
  }

  /// 处理所有子对象的层级命名
  void processChildObjects() {
    // 处理直接子属性
    for (final DartProperty property in properties) {
      if (property is DartObject && objectKeys.containsKey(property.key)) {
        final FFDartObject childObject = objectKeys[property.key] as FFDartObject;
        childObject.generateHierarchicalClassName();
      }
    }

    // 处理数组对象和其他可能的子对象
    for (final String key in objectKeys.keys) {
      final DartObject childObject = objectKeys[key]!;
      if (childObject is FFDartObject && !properties.contains(childObject)) {
        childObject.generateHierarchicalClassName();
      }
    }
  }
}

mixin FFDartObjectMixin on DartObject {
  late ClassNameCheckerTextEditingController classNameTextEditingController =
      ClassNameCheckerTextEditingController(this);

  RxString classNameObs = ''.obs;
  @override
  String get className => classNameObs.value;

  @override
  set className(String value) {
    classNameObs.value = value;
    // 确保UI显示与数据同步
    if (classNameTextEditingController.text != value) {
      classNameTextEditingController.text = value;
    }
  }

  final RxSet<String> _classError = <String>{}.obs;
  @override
  SetBase<String> get classError => _classError;
}
