# Настройка сетевых политик Calico

Данная инструкция описывает настройку Calico NetworkPolicy для обеспечения сетевого доступа между различными namespace в кластере Kubernetes.

## Что такое NetworkPolicy

NetworkPolicy — это объект Kubernetes, который определяет правила сетевого доступа для подов. Calico реализует эти политики на уровне сети, контролируя входящий (ingress) и исходящий (egress) трафик.

## Основные концепции

### Типы политик

- **Ingress** — контролирует входящий трафик к подам
- **Egress** — контролирует исходящий трафик от подов

### Селекторы

- **podSelector** — выбирает поды по меткам (labels)
- **namespaceSelector** — выбирает namespace по меткам

## Базовый пример NetworkPolicy

### Разрешить доступ между namespace

Предположим, у вас есть два namespace:
- `source-namespace` — откуда идут запросы
- `target-namespace` — куда идут запросы

Чтобы разрешить доступ из `source-namespace` к подам в `target-namespace`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-source-namespace
  namespace: target-namespace
spec:
  podSelector:
    matchLabels:
      app: target-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: source-namespace
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - {}
```

### Описание полей

- `metadata.name` — имя политики
- `metadata.namespace` — namespace, где применяется политика
- `spec.podSelector` — к каким подам применяется политика (по меткам)
- `spec.policyTypes` — типы политик (Ingress, Egress)
- `spec.ingress` — правила для входящего трафика
- `spec.egress` — правила для исходящего трафика

## Практический пример

### Задача

Разрешить доступ из namespace `app-backend` к подам в namespace `database` на порт 5432 (PostgreSQL).

### Шаг 1: Проверка меток namespace

Убедитесь, что namespace имеет метку:

```bash
kubectl get namespace app-backend --show-labels
kubectl get namespace database --show-labels
```

Если метки `kubernetes.io/metadata.name` нет, она создается автоматически в Kubernetes 1.21+.

### Шаг 2: Создание NetworkPolicy

Создайте файл `database-network-policy.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-app-backend
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Разрешить доступ из того же namespace
  - from:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  # Разрешить доступ из app-backend namespace
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: app-backend
    ports:
    - protocol: TCP
      port: 5432
  egress:
  - {}
```

### Шаг 3: Применение политики

```bash
kubectl apply -f database-network-policy.yaml
```

### Шаг 4: Проверка политики

```bash
kubectl get networkpolicy -n database
kubectl describe networkpolicy allow-from-app-backend -n database
```

## Редактирование существующей политики

### Через kubectl edit

```bash
kubectl edit networkpolicy <policy-name> -n <namespace>
```

Пример:

```bash
kubectl edit networkpolicy allow-from-app-backend -n database
```

Откроется текстовый редактор, где можно внести изменения.

### Через kubectl apply

Измените файл YAML и примените изменения:

```bash
kubectl apply -f database-network-policy.yaml
```

## Сложный пример: Множественные правила

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: complex-policy
  namespace: application
spec:
  podSelector:
    matchLabels:
      app: web-server
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Правило 1: Разрешить доступ из того же namespace
  - from:
    - podSelector:
        matchLabels:
          app: web-server
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 8443
  # Правило 2: Разрешить доступ из namespace monitoring
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
    ports:
    - protocol: TCP
      port: 9090
  # Правило 3: Разрешить доступ из namespace ingress
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # Разрешить весь исходящий трафик
  - {}
```

## Общие шаблоны

### 1. Разрешить весь трафик внутри namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: my-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
```

### 2. Разрешить доступ к конкретному сервису

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-service
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: api-server
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
    - podSelector:
        matchLabels:
          app: web-app
    ports:
    - protocol: TCP
      port: 3000
```

### 3. Запретить весь входящий трафик (по умолчанию)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: secure-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### 4. Разрешить весь исходящий трафик

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-egress
  namespace: my-namespace
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - {}
```

## Отладка NetworkPolicy

### Проверка применения политики

```bash
# Просмотр всех политик в namespace
kubectl get networkpolicy -n <namespace>

# Детальная информация о политике
kubectl describe networkpolicy <policy-name> -n <namespace>

# Просмотр YAML политики
kubectl get networkpolicy <policy-name> -n <namespace> -o yaml
```

### Тестирование доступности

Создайте тестовый под для проверки:

```bash
kubectl run test-pod --image=busybox --rm -it --restart=Never -n source-namespace -- sh
```

Внутри пода проверьте доступность:

```bash
# Проверка доступности по TCP
wget -O- http://service-name.target-namespace:8080

# Проверка DNS
nslookup service-name.target-namespace
```

### Логи Calico

Проверьте логи Calico для отладки:

```bash
# Найти calico-node поды
kubectl get pods -n kube-system | grep calico

# Просмотр логов
kubectl logs -n kube-system <calico-node-pod> -c calico-node
```

## Полезные команды

```bash
# Получить все NetworkPolicy в кластере
kubectl get networkpolicy --all-namespaces

# Экспортировать NetworkPolicy в YAML
kubectl get networkpolicy <policy-name> -n <namespace> -o yaml > policy.yaml

# Удалить NetworkPolicy
kubectl delete networkpolicy <policy-name> -n <namespace>

# Проверить метки namespace
kubectl get namespace --show-labels

# Добавить метку к namespace
kubectl label namespace <namespace-name> environment=production
```

## Best Practices

1. **Принцип минимальных привилегий**: Разрешайте только необходимый трафик
2. **Явное определение политик**: Используйте deny-all по умолчанию, затем добавляйте разрешения
3. **Документирование**: Добавляйте комментарии и описания в манифесты
4. **Тестирование**: Всегда тестируйте политики перед применением в production
5. **Мониторинг**: Следите за логами Calico для выявления проблем

## Ограничения

- NetworkPolicy применяется только к трафику между подами внутри кластера
- Не влияет на трафик к/от хостовой сети
- Не фильтрует трафик на уровне приложения (L7)
- Требует поддержки CNI плагином (Calico, Cilium, и т.д.)

## Дополнительные ресурсы

- [Официальная документация Kubernetes NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Документация Calico](https://docs.projectcalico.org/)
- [Network Policy Editor (визуальный редактор)](https://editor.networkpolicy.io/)
