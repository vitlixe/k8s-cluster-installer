# Настройка Calico Network Policies

Как разрешить доступ между namespace в Kubernetes.

## Проблема

По умолчанию Calico может блокировать трафик между namespace. Если нужно разрешить доступ из одного namespace в другой, настройте NetworkPolicy.

## Решение

### Пример: разрешить доступ из namespace-A в namespace-B

1. **Открыть редактирование политики:**

```bash
kubectl edit networkpolicy <policy-name> -n <target-namespace>
```

2. **Добавить правило в spec.ingress:**

```yaml
spec:
  egress:
  - {}
  ingress:
  # Существующие правила...

  # Добавить новое правило:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: source-namespace
    ports:
    - port: 8080
      protocol: TCP

  podSelector:
    matchLabels:
      app: target-app
  policyTypes:
  - Egress
  - Ingress
```

3. **Сохранить и выйти**

## Полный пример NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-another-namespace
  namespace: target-namespace
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Разрешить из того же namespace
  - from:
    - podSelector:
        matchLabels:
          app: my-app
    ports:
    - port: 8080
      protocol: TCP

  # Разрешить из другого namespace
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: source-namespace
    ports:
    - port: 8080
      protocol: TCP

  egress:
  - {}
```

## Применение политики

```bash
# Создать из файла
kubectl apply -f network-policy.yaml

# Проверить
kubectl get networkpolicy -n target-namespace
kubectl describe networkpolicy <policy-name> -n target-namespace
```

## Полезные команды

```bash
# Посмотреть все политики
kubectl get networkpolicy --all-namespaces

# Удалить политику
kubectl delete networkpolicy <policy-name> -n <namespace>

# Проверить метки namespace
kubectl get namespace --show-labels
```

## Примечания

- Метка `kubernetes.io/metadata.name` создается автоматически для namespace в Kubernetes 1.21+
- `egress: - {}` означает "разрешить весь исходящий трафик"
- Если не указать egress правила, исходящий трафик будет заблокирован
