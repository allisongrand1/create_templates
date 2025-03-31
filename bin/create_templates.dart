import 'dart:io';

import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    print('Использование: create_templates <template_name> <target_path> <replace_name>');
    exit(1);
  }

  final templateName = args[0];
  final targetPath = args[1];
  final replaceName = args[2];

  // Определяем путь к проекту и скрипту
  final scriptPath = Platform.script.toFilePath();
  final projectPath = path.normalize(path.join(scriptPath, '..', '..'));

  // Определяем директорию скрипта и проекта
  final scriptDir = File(scriptPath).parent;
  final projectDir = Directory(projectPath);

  // Определяем пути папки шаблонов
  final templatesPath = path.join(projectDir.path, '.templates');
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
