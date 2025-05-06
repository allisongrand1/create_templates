import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  if (args.contains('-h')) {
    print('Для использования шаблона необходимо 3 тега: create_templates <template_name> <target_path> <replace_name>, '
        'где\n'
        'template_name - название шаблона,\n'
        'target_path - путь куда будет сгенерирован шаблон,\n'
        'replace_name - название, которое будет использовано вместо названия шаблона.\n'
        '\n'
        'Дополнительные флаги:\n'
        '-l или --list — выводит список доступных шаблонов\n'
        '-h — справка');

    exit(0);
  }

  // Получаем реальный путь к пакету через package URI
  final resolvedUri = await Isolate.resolvePackageUri(Uri.parse('package:create_templates/create_templates.dart'));
  if (resolvedUri == null) {
    print('❌ Не удалось определить путь до пакета create_templates.');
    exit(1);
  }

  // Определяем путь к проекту и скрипту
  final scriptPath = resolvedUri.toFilePath();
  final projectPath = path.normalize(path.join(scriptPath, '..', '..'));

  // Определяем директорию скрипта и проекта
  final projectDir = Directory(projectPath);

  // Определяем путь к папке шаблонов
  final templatesPath = path.join(projectDir.path, '.templates');

  // Если пользователь хочет список шаблонов
  if (args.contains('-l') || args.contains('--list')) {
    final templatesDir = Directory(templatesPath);

    if (!templatesDir.existsSync()) {
      print('❌ Папка с шаблонами не найдена: $templatesPath');
      exit(1);
    }

    final templates = templatesDir.listSync().whereType<Directory>().toList();

    if (templates.isEmpty) {
      print('ℹ️ Шаблоны не найдены в $templatesPath');
    } else {
      print('📦 Доступные шаблоны:');
      for (var template in templates) {
        final templatesPath = path.basename(template.path);

        final metaFile = File(path.join(template.path, 'meta.yaml'));

        final content = metaFile.readAsStringSync();
        final meta = loadYaml(content);

        final description = meta['description']?.toString() ?? '';

        print('• $templatesPath - $description');
      }
    }

    exit(0);
  }

  // Проверка аргументов
  if (args.length < 3) {
    print('Использование: create_templates <template_name> <target_path> <replace_name>');
    print('Используйте -h для справки');
    exit(1);
  }

  final templateName = args[0];
  final targetPath = args[1];
  final replaceName = args[2];

  // Определяем путь к папке определенного шаблона через [templateName]
  final templatePath = path.join(templatesPath, templateName);

  // Определяем директорию папки шаблонов
  final templateDir = Directory(templatePath);

  // Абсолютный путь к целевой директории
  var targetDir = Directory(path.absolute(path.join(targetPath, replaceName)));

  // Проверяем, существует ли шаблон
  if (!templateDir.existsSync()) {
    print('❌ Шаблон "$templateName" не найден в "$templatesPath"');
    exit(1);
  }

  // Проверяем, существует ли aбсолютный путь к целевой директории
  if (!Directory(path.absolute(targetPath)).existsSync()) {
    print('❌ Папка назначения "$targetPath" не существует.');
    exit(1);
  }

  // Проверяем, необходимо ли создать папку
  if (!targetDir.existsSync()) {
    targetDir = await createDirectory(targetDir);
  }

  // Копируем содержимое шаблона в целевую папку
  await copyDirectory(templateDir, targetDir);

  print('✅ Шаблон "$templateName" скопирован в "${targetDir.path}"');

  // Замена содержимого файлов: "Feature" → с заглавной буквы, например "Auth"
  await replaceFeatureInFileContent(targetDir, replaceName);

  print('✅ Замена содержимого в файлах завершена');

  // Замена в именах файлов и папок: "feature" (в нижнем регистре) → replaceName (без изменения регистра)
  await renameFeatureInNames(targetDir, replaceName);

  print('✅ Замена имен файлов и папок завершена');
}

Future<Directory> createDirectory(Directory targetDir) async {
  return await targetDir.create(recursive: true);
}

/// Рекурсивно копирует содержимое [source] в директорию [destination].
Future<void> copyDirectory(Directory source, Directory destination) async {
  await for (var entity in source.list(recursive: false)) {
    final entityName = path.basename(entity.path);

    // ❌ Пропустить meta.yaml
    if (entityName == 'meta.yaml') continue;

    final newPath = path.join(destination.path, path.basename(entity.path));

    if (entity is Directory) {
      var newDir = Directory(newPath);
      await newDir.create();
      await copyDirectory(entity, newDir);
    } else if (entity is File) {
      await entity.copy(newPath);
    }
  }
}

/// Рекурсивно проходит по файлам в [dir] и заменяет в их содержимом все вхождения "Feature"
/// на значение [replaceName] с заглавной первой буквой.
Future<void> replaceFeatureInFileContent(Directory dir, String replaceName) async {
  // Преобразуем replaceName, чтобы первая буква была заглавной
  final capitalizedReplaceName = replaceName[0].toUpperCase() + replaceName.substring(1);
  await for (var entity in dir.list(recursive: true)) {
    if (entity is File) {
      String content = await entity.readAsString();
      content = content.replaceAll('Feature', capitalizedReplaceName);
      await entity.writeAsString(content);
    }
  }
}

/// Рекурсивно переименовывает файлы и папки, в именах которых встречается "feature"
/// на значение [replaceName] (без изменения регистра).
Future<void> renameFeatureInNames(Directory dir, String replaceName) async {
  // Получаем список элементов в текущей директории
  final entries = dir.listSync();

  for (var entity in entries) {
    // Если это папка, сначала обрабатываем её содержимое
    if (entity is Directory) {
      await renameFeatureInNames(entity, replaceName);

      final baseName = path.basename(entity.path);
      if (baseName.contains('feature')) {
        final newName = baseName.replaceAll('feature', replaceName);
        final newPath = path.join(path.dirname(entity.path), newName);
        await entity.rename(newPath);
      }
    }
    // Если это файл, проверяем имя и переименовываем, если нужно
    else if (entity is File) {
      final baseName = path.basename(entity.path);
      if (baseName.contains('feature')) {
        final newName = baseName.replaceAll('feature', replaceName);
        final newPath = path.join(path.dirname(entity.path), newName);
        await entity.rename(newPath);
      }
    }
  }
}
