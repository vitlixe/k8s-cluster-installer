# Jinja2 шаблоны для Kubernetes NetworkPolicy

Эта директория содержит Jinja2 шаблоны и инструменты для генерации Kubernetes NetworkPolicy.

## Содержимое

- `network-policy.yaml.j2` — Jinja2 шаблон для NetworkPolicy
- `example-config.yaml` — пример конфигурационного файла
- `generate-policy.py` — Python скрипт для генерации политики из шаблона

## Предварительные требования

Установите необходимые Python библиотеки:

```bash
pip install jinja2 pyyaml
```

Или используйте pip3:

```bash
pip3 install jinja2 pyyaml
```

## Быстрый старт

### Генерация политики из примера

```bash
cd templates
python3 generate-policy.py -o output-policy.yaml
```

Это создаст файл `output-policy.yaml` на основе `example-config.yaml`.

### Применение политики в кластере

```bash
kubectl apply -f output-policy.yaml
```

## Использование

### Базовое использование

```bash
# Генерация с выводом в файл
python3 generate-policy.py -c my-config.yaml -o my-policy.yaml

# Генерация с выводом в stdout
python3 generate-policy.py -c my-config.yaml

# Только валидация конфигурации
python3 generate-policy.py -c my-config.yaml --validate-only
```

### Параметры командной строки

- `-c, --config` — путь к файлу конфигурации (по умолчанию: example-config.yaml)
- `-t, --template` — путь к Jinja2 шаблону (по умолчанию: network-policy.yaml.j2)
- `-o, --output` — путь к выходному файлу (если не указан, вывод в stdout)
- `-v, --validate-only` — только проверить конфигурацию, не генерировать файл
- `-h, --help` — справка

## Структура конфигурационного файла

Конфигурационный файл имеет следующую структуру:

```yaml
# Обязательные поля
policy_name: имя-политики              # Имя NetworkPolicy
target_namespace: целевой-namespace    # Namespace, где будет применена политика

pod_selector_labels:                   # Селектор подов (по меткам)
  app: имя-приложения
  tier: уровень

policy_types:                          # Типы политик
  - Ingress
  - Egress

# Опциональные поля
ingress_rules:                         # Правила входящего трафика
  - pod_selector:                      # Селектор подов-источников
      app: другое-приложение
    ports:
      - protocol: TCP
        port: 8080

  - namespace_selector:                # Селектор namespace-источников
      kubernetes.io/metadata.name: другой-namespace
    ports:
      - protocol: TCP
        port: 8080

egress_rules:                          # Правила исходящего трафика
  - {}                                 # Пустой объект = разрешить все
```

## Примеры конфигураций

### Пример 1: Разрешить доступ из другого namespace

```yaml
policy_name: allow-from-frontend
target_namespace: backend

pod_selector_labels:
  app: api-server

policy_types:
  - Ingress
  - Egress

ingress_rules:
  - namespace_selector:
      kubernetes.io/metadata.name: frontend
    ports:
      - protocol: TCP
        port: 8080

egress_rules:
  - {}
```

### Пример 2: Разрешить доступ только из определенных подов

```yaml
policy_name: allow-from-web
target_namespace: database

pod_selector_labels:
  app: postgres
  tier: database

policy_types:
  - Ingress

ingress_rules:
  - pod_selector:
      app: web-app
      tier: frontend
    ports:
      - protocol: TCP
        port: 5432
```

### Пример 3: Множественные правила

```yaml
policy_name: complex-policy
target_namespace: application

pod_selector_labels:
  app: web-server

policy_types:
  - Ingress
  - Egress

ingress_rules:
  # Из того же namespace
  - pod_selector:
      app: web-server
    ports:
      - protocol: TCP
        port: 8080

  # Из namespace monitoring
  - namespace_selector:
      kubernetes.io/metadata.name: monitoring
    ports:
      - protocol: TCP
        port: 9090

  # Из namespace ingress
  - namespace_selector:
      kubernetes.io/metadata.name: ingress
    ports:
      - protocol: TCP
        port: 8080

egress_rules:
  - {}
```

## Workflow

Типичный workflow для создания NetworkPolicy:

1. **Создать конфигурационный файл**

   ```bash
   cp example-config.yaml my-app-policy-config.yaml
   nano my-app-policy-config.yaml
   ```

2. **Валидировать конфигурацию**

   ```bash
   python3 generate-policy.py -c my-app-policy-config.yaml --validate-only
   ```

3. **Сгенерировать YAML**

   ```bash
   python3 generate-policy.py -c my-app-policy-config.yaml -o my-app-policy.yaml
   ```

4. **Проверить сгенерированный файл**

   ```bash
   cat my-app-policy.yaml
   ```

5. **Применить в кластер**

   ```bash
   kubectl apply -f my-app-policy.yaml
   ```

6. **Проверить применение**

   ```bash
   kubectl get networkpolicy -n <namespace>
   kubectl describe networkpolicy <policy-name> -n <namespace>
   ```

## Расширение шаблона

Вы можете изменить шаблон `network-policy.yaml.j2` под свои нужды. Jinja2 поддерживает:

- Условия: `{% if condition %} ... {% endif %}`
- Циклы: `{% for item in items %} ... {% endfor %}`
- Фильтры: `{{ variable | filter }}`
- Комментарии: `{# комментарий #}`

Пример добавления комментария в шаблон:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ policy_name }}
  namespace: {{ target_namespace }}
  annotations:
    description: "Generated from template on {{ generated_date }}"
```

Затем добавьте `generated_date` в конфигурацию:

```python
import datetime
config['generated_date'] = datetime.datetime.now().isoformat()
```

## Полезные ссылки

- [Jinja2 документация](https://jinja.palletsprojects.com/)
- [PyYAML документация](https://pyyaml.org/wiki/PyYAMLDocumentation)
- [Kubernetes NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Calico NetworkPolicy](https://docs.projectcalico.org/security/calico-network-policy)

## Устранение проблем

### Ошибка: ModuleNotFoundError: No module named 'jinja2'

**Решение:** Установите зависимости:

```bash
pip3 install jinja2 pyyaml
```

### Ошибка: yaml.scanner.ScannerError

**Решение:** Проверьте синтаксис YAML файла. YAML чувствителен к отступам (должны быть пробелы, не табы).

### Ошибка: Обязательное поле отсутствует

**Решение:** Убедитесь, что все обязательные поля присутствуют в конфигурации:
- policy_name
- target_namespace
- pod_selector_labels
- policy_types

## Примечания

- Используйте пробелы для отступов в YAML, не табы
- Метка `kubernetes.io/metadata.name` создается автоматически для namespace в Kubernetes 1.21+
- Пустой объект `{}` в egress_rules означает "разрешить весь исходящий трафик"
- Если не указать egress_rules вообще, исходящий трафик будет заблокирован (если Egress в policy_types)
