#!/usr/bin/env python3
"""
Скрипт для генерации Kubernetes NetworkPolicy из Jinja2 шаблона.

Использование:
    python3 generate-policy.py -c config.yaml -o output.yaml

Требования:
    pip install jinja2 pyyaml
"""

import argparse
import sys
from pathlib import Path

try:
    import yaml
    from jinja2 import Environment, FileSystemLoader, Template
except ImportError as e:
    print(f"Ошибка: {e}")
    print("Установите необходимые зависимости:")
    print("  pip install jinja2 pyyaml")
    sys.exit(1)


def load_config(config_path):
    """Загрузить конфигурацию из YAML файла."""
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Ошибка: Файл {config_path} не найден")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Ошибка при парсинге YAML: {e}")
        sys.exit(1)


def render_template(template_path, config):
    """Рендер шаблона с конфигурацией."""
    try:
        template_dir = Path(template_path).parent
        template_name = Path(template_path).name

        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_name)

        return template.render(**config)
    except Exception as e:
        print(f"Ошибка при рендеринге шаблона: {e}")
        sys.exit(1)


def save_output(content, output_path):
    """Сохранить результат в файл."""
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"NetworkPolicy успешно сгенерирована: {output_path}")
    except Exception as e:
        print(f"Ошибка при сохранении файла: {e}")
        sys.exit(1)


def validate_config(config):
    """Базовая валидация конфигурации."""
    required_fields = ['policy_name', 'target_namespace', 'pod_selector_labels', 'policy_types']

    for field in required_fields:
        if field not in config:
            print(f"Ошибка: Обязательное поле '{field}' отсутствует в конфигурации")
            sys.exit(1)

    if not isinstance(config['pod_selector_labels'], dict):
        print("Ошибка: 'pod_selector_labels' должен быть словарем")
        sys.exit(1)

    if not isinstance(config['policy_types'], list):
        print("Ошибка: 'policy_types' должен быть списком")
        sys.exit(1)

    valid_policy_types = ['Ingress', 'Egress']
    for pt in config['policy_types']:
        if pt not in valid_policy_types:
            print(f"Ошибка: Неверный тип политики '{pt}'. Допустимые: {valid_policy_types}")
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description='Генератор Kubernetes NetworkPolicy из Jinja2 шаблона',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Примеры использования:

  # Использовать example-config.yaml и сохранить в policy.yaml
  python3 generate-policy.py

  # Использовать свой конфиг
  python3 generate-policy.py -c my-config.yaml -o my-policy.yaml

  # Вывести результат в stdout
  python3 generate-policy.py -c my-config.yaml

Структура конфигурационного файла:

  policy_name: имя-политики
  target_namespace: целевой-namespace
  pod_selector_labels:
    app: имя-приложения
  policy_types:
    - Ingress
    - Egress
  ingress_rules:
    - namespace_selector:
        kubernetes.io/metadata.name: source-namespace
      ports:
        - protocol: TCP
          port: 8080
  egress_rules:
    - {}
        """
    )

    parser.add_argument(
        '-c', '--config',
        default='example-config.yaml',
        help='Путь к файлу конфигурации (по умолчанию: example-config.yaml)'
    )
    parser.add_argument(
        '-t', '--template',
        default='network-policy.yaml.j2',
        help='Путь к Jinja2 шаблону (по умолчанию: network-policy.yaml.j2)'
    )
    parser.add_argument(
        '-o', '--output',
        help='Путь к выходному файлу (если не указан, вывод в stdout)'
    )
    parser.add_argument(
        '-v', '--validate-only',
        action='store_true',
        help='Только проверить конфигурацию, не генерировать файл'
    )

    args = parser.parse_args()

    # Загрузка конфигурации
    config = load_config(args.config)

    # Валидация
    validate_config(config)

    if args.validate_only:
        print(f"Конфигурация {args.config} валидна ✓")
        sys.exit(0)

    # Рендер шаблона
    result = render_template(args.template, config)

    # Сохранение или вывод
    if args.output:
        save_output(result, args.output)
    else:
        print(result)


if __name__ == '__main__':
    main()
