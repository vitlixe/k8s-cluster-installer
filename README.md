# Kubernetes Cluster Deployment Guide

Полное руководство по развертыванию Kubernetes кластера с поддержкой ручной и автоматической установки.

## Описание

Этот репозиторий содержит комплексное решение для развертывания production-ready Kubernetes кластера с использованием:

- **kubeadm** — официальный инструмент для инициализации кластера
- **containerd** — container runtime
- **Calico** — сетевой плагин (CNI) и network policies

## Возможности

- ✅ Ручная установка с подробными инструкциями
- ✅ Автоматическая установка с помощью bash скриптов
- ✅ Поддержка master и worker нод
- ✅ Настройка Calico network policies
- ✅ Jinja2 шаблоны для генерации NetworkPolicy
- ✅ Детальное логирование процесса установки
- ✅ Проверка системных требований
- ✅ Документация на русском языке

## Структура репозитория

```
.
├── README.md                      # Этот файл
├── TESTED_OS.md                   # Список протестированных ОС
├── manual-installation/           # Ручная установка
│   ├── master-node-setup.md       # Инструкция для master ноды
│   ├── worker-node-setup.md       # Инструкция для worker ноды
│   └── calico-network-policies.md # Руководство по Network Policies
├── automatic-installation/        # Автоматическая установка
│   ├── README.md                  # Документация по автоматической установке
│   ├── install-master.sh          # Скрипт установки master ноды
│   └── install-worker.sh          # Скрипт установки worker ноды
└── templates/                     # Jinja2 шаблоны
    ├── README.md                  # Документация по шаблонам
    ├── network-policy.yaml.j2     # Шаблон NetworkPolicy
    ├── example-config.yaml        # Пример конфигурации
    └── generate-policy.py         # Генератор политик
```

## Быстрый старт

### Автоматическая установка (рекомендуется)

#### Шаг 1: Установка master ноды

```bash
cd automatic-installation
sudo ./install-master.sh
```

Скрипт автоматически:
- Проверит системные требования
- Отключит SWAP
- Установит и настроит containerd
- Установит Kubernetes компоненты
- Инициализирует кластер
- Установит Calico CNI
- Выведет команду для подключения worker нод

#### Шаг 2: Установка worker ноды

На каждой worker ноде:

```bash
cd automatic-installation
sudo ./install-worker.sh
```

Скрипт запросит команду `kubeadm join`, полученную после установки master ноды.

#### Шаг 3: Проверка кластера

На master ноде:

```bash
kubectl get nodes -o wide
kubectl get pods --all-namespaces
```

### Ручная установка

Подробные инструкции для ручной установки:

- [Установка Master ноды](manual-installation/master-node-setup.md)
- [Установка Worker ноды](manual-installation/worker-node-setup.md)
- [Настройка Network Policies](manual-installation/calico-network-policies.md)

## Системные требования

### Master нода

- **CPU:** минимум 2 ядра
- **RAM:** минимум 2GB
- **Диск:** минимум 20GB свободного пространства
- **ОС:** Debian-based Linux
- **Сеть:** статический IP адрес (рекомендуется)

### Worker нода

- **CPU:** минимум 1 ядро
- **RAM:** минимум 1GB
- **Диск:** минимум 10GB свободного пространства
- **ОС:** Debian-based Linux
- **Сеть:** доступность master ноды

См. [TESTED_OS.md](TESTED_OS.md) для полного списка протестированных операционных систем.

## Компоненты

| Компонент | Версия | Описание |
|-----------|--------|----------|
| Kubernetes | v1.34.x | Система оркестрации контейнеров |
| containerd | Latest | Container runtime |
| Calico | v3.28.0 | Сетевой плагин и network policies |
| kubeadm | Latest | Инструмент для инициализации кластера |
| kubectl | Latest | CLI для управления кластером |
| kubelet | Latest | Агент на каждой ноде |

## Возможности Network Policies

С помощью Calico и предоставленных инструментов вы можете:

- Контролировать входящий (ingress) трафик к подам
- Контролировать исходящий (egress) трафик от подов
- Разрешать/блокировать трафик между namespace
- Использовать селекторы подов и namespace для точной настройки
- Генерировать политики из Jinja2 шаблонов

Подробнее см. [calico-network-policies.md](manual-installation/calico-network-policies.md) и [templates/README.md](templates/README.md)

## Генерация Network Policies

Для упрощения создания Network Policies используйте Jinja2 шаблоны:

```bash
cd templates

# Установить зависимости
pip3 install jinja2 pyyaml

# Создать конфигурацию
cp example-config.yaml my-policy-config.yaml
nano my-policy-config.yaml

# Сгенерировать политику
python3 generate-policy.py -c my-policy-config.yaml -o my-policy.yaml

# Применить в кластер
kubectl apply -f my-policy.yaml
```

## Логи и отладка

### Логи установки

- Master нода: `/var/log/k8s-master-install.log`
- Worker нода: `/var/log/k8s-worker-install.log`

### Полезные команды для отладки

```bash
# Проверка статуса компонентов
kubectl get componentstatuses
kubectl cluster-info

# Проверка подов
kubectl get pods --all-namespaces

# Логи системных компонентов
journalctl -u kubelet -f
journalctl -u containerd -f

# События в кластере
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Диагностика ноды
kubectl describe node <node-name>
```

## Дополнительная настройка

После базовой установки рекомендуется:

1. **Настроить Ingress контроллер**
   - NGINX Ingress
   - Traefik
   - HAProxy

2. **Установить мониторинг**
   - Prometheus + Grafana
   - Metrics Server

3. **Настроить логирование**
   - ELK Stack (Elasticsearch, Logstash, Kibana)
   - Loki + Grafana

4. **Настроить хранилище**
   - Storage Classes
   - Persistent Volumes
   - NFS, Ceph, или другие решения

5. **Настроить безопасность**
   - Network Policies (уже включены)
   - Pod Security Policies/Standards
   - RBAC (Role-Based Access Control)
   - Secrets management

## Поддерживаемые ОС

Протестировано на:
- ✅ Debian 12 (Bookworm)

Ожидается совместимость с:
- Debian 11 (Bullseye)
- Ubuntu 24.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 20.04 LTS

Полный список см. в [TESTED_OS.md](TESTED_OS.md)

## Устранение проблем

### Master нода не переходит в Ready

Проверьте Calico поды:

```bash
kubectl get pods -n kube-system | grep calico
kubectl logs -n kube-system <calico-pod-name>
```

### Worker нода не подключается

Проверьте доступность master ноды:

```bash
telnet <master-ip> 6443
```

Проверьте, что токен действителен (24 часа):

```bash
# На master ноде
sudo kubeadm token create --print-join-command
```

### containerd не запускается

```bash
sudo systemctl status containerd
sudo journalctl -u containerd -n 50
sudo systemctl restart containerd
```

Полный список решений см. в документации по [автоматической установке](automatic-installation/README.md).

## Удаление кластера

### Полный сброс master ноды

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/
sudo rm -rf /var/lib/etcd
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

### Полный сброс worker ноды

На master ноде сначала удалите ноду:

```bash
kubectl drain <worker-node-name> --ignore-daemonsets --delete-emptydir-data
kubectl delete node <worker-node-name>
```

Затем на worker ноде:

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/
sudo rm -rf /etc/cni/net.d
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

## Вклад в проект

Мы приветствуем вклад в проект! Если вы хотите помочь:

1. Сообщите о проблеме через Issues
2. Предложите улучшение через Pull Request
3. Поделитесь результатами тестирования на других ОС
4. Улучшите документацию

## Безопасность

Рекомендации по безопасности:

- ✅ Используйте Network Policies для ограничения трафика
- ✅ Настройте RBAC для управления доступом
- ✅ Используйте Secrets для хранения конфиденциальных данных
- ✅ Регулярно обновляйте компоненты кластера
- ✅ Используйте Pod Security Standards
- ✅ Настройте аудит событий в кластере
- ✅ Используйте TLS для всех коммуникаций

## Полезные ресурсы

### Официальная документация

- [Kubernetes](https://kubernetes.io/docs/)
- [Calico](https://docs.projectcalico.org/)
- [containerd](https://containerd.io/)
- [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)

### Инструменты

- [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Network Policy Editor](https://editor.networkpolicy.io/)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

### Сообщество

- [Kubernetes Slack](https://kubernetes.slack.com/)
- [CNCF Slack](https://slack.cncf.io/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/kubernetes)

## Лицензия

MIT License

## Авторы

Проект поддерживается сообществом.

---

**Примечание:** Данный репозиторий предназначен для образовательных и тестовых целей. Для production окружений рекомендуется дополнительная настройка безопасности и отказоустойчивости.
