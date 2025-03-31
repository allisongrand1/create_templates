# Генератор шаблонов для проектов на Dart


## Установка

### Глобально

Если вы хотите использовать утилиту глобально (не привязываясь к конкретному проекту), то необходимо выполнить команду:

```bash
dart pub global activate --source git https://github.com/allisongrand1/create_templates.git
```

Чтобы сгенерировать шаблоны, необходимо выполнить команду:

```bash
create_templates <template_name> <target_path> <replace_name>
```

где `template_name` - название шаблона, `target_path` - путь куда будет сгенерирован шаблон, `replace_name` - 
название, которое будет использовано вместо названия шаблона.

Пример:
    
```bash
 create_templates feature lib/features auth
```

### Локально

Для использования генератора необходимо указать путь к гиту через pubspec.yaml

```yaml

dev_dependencies:
  create_templates:
    git:
      url: https://github.com/allisongrand1/create_templates.git
      ref: main

```
Чтобы сгенерировать шаблоны, необходимо выполнить команду:

```bash
dart run create_templates:create_templates <template_name> <target_path> <replace_name>
```

где `template_name` - название шаблона, `target_path` - путь куда будет сгенерирован шаблон, `replace_name` -
название, которое будет использовано вместо названия шаблона.
