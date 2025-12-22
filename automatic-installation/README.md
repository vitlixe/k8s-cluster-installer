# Автоматическая установка Kubernetes кластера

Данная директория содержит скрипты для автоматической установки Kubernetes кластера на Debian-based Linux системах.

## Содержимое

- `install-master.sh` — скрипт автоматической установки master ноды
- `install-worker.sh` — скрипт автоматической установки worker ноды

## Предварительные требования

### Для master ноды:
- Минимум 2 CPU
- Минимум 2GB RAM
- 20GB свободного дискового пространства
- Права суперпользователя (sudo/root)
- Доступ к интернету

### Для worker ноды:
- Минимум 1 CPU
- Минимум 1GB RAM
- 10GB свободного дискового пространства
- Права суперпользователя (sudo/root)
- Доступ к интернету
- Доступность master ноды по сети

## Что делают скрипты

Оба скрипта выполняют следующие операции:

1. **Проверка системы**
   - Проверка прав суперпользователя
   - Проверка операционной системы
   - Проверка системных требований (CPU, RAM)

2. **Подготовка системы**
   - Отключение SWAP
   - Загрузка необходимых модулей ядра (overlay, br_netfilter)
   - Настройка параметров sysctl для сети

3. **Установка container runtime**
   - Установка containerd
   - Настройка containerd с systemd cgroup driver

4. **Установка Kubernetes компонентов**
   - Добавление официального репозитория Kubernetes
   - Установка kubelet, kubeadm, kubectl
   - Фиксация версий пакетов

5. **Установка дополнительных компонентов**
   - Установка NFS клиента для поддержки persistent volumes

### Дополнительно для master ноды:

6. **Инициализация кластера**
   - Инициализация кластера с использованием kubeadm
   - Настройка kubectl для текущего пользователя
   - Установка Calico CNI (сетевой плагин)

7. **Генерация команды join**
   - Создание токена для подключения worker нод
   - Сохранение команды join в файл `/root/k8s-join-command.sh`

### Дополнительно для worker ноды:

6. **Присоединение к кластеру**
   - Интерактивный запрос команды join
   - Присоединение к кластеру

## Быстрый старт

### Шаг 1: Установка master ноды

На сервере, который будет master нодой:

```bash
# Скачать скрипт (если нужно)
wget https://raw.githubusercontent.com/YOUR_REPO/k8s-install/main/automatic-installation/install-master.sh

# Дать права на выполнение
chmod +x install-master.sh

# Запустить установку
sudo ./install-master.sh
```

**Важно:** Сохраните команду `kubeadm join`, которая будет выведена в конце установки! Она понадобится для подключения worker нод.

Команда также сохраняется в файл `/root/k8s-join-command.sh`.

### Шаг 2: Установка worker ноды

На каждом сервере, который будет worker нодой:

```bash
# Скачать скрипт (если нужно)
wget https://raw.githubusercontent.com/YOUR_REPO/k8s-install/main/automatic-installation/install-worker.sh

# Дать права на выполнение
chmod +x install-worker.sh

# Запустить установку
sudo ./install-worker.sh
```

Скрипт попросит вас ввести команду `kubeadm join`, которую вы получили после установки master ноды.

**Пример ввода:**

```
kubeadm join 192.168.1.100:6443 --token abc123.xyz789 --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

Вводите команду **без** `sudo`, так как скрипт уже запущен с правами суперпользователя.

## Проверка установки

### На master ноде

Проверить статус нод:

```bash
kubectl get nodes -o wide
```

Все ноды должны быть в статусе `Ready`.

Проверить системные поды:

```bash
kubectl get pods -n kube-system
```

Все поды должны быть в статусе `Running`.

### На worker ноде

Проверить статус kubelet:

```bash
sudo systemctl status kubelet
```

Посмотреть логи:

```bash
journalctl -u kubelet -f
```

## Логи установки

Логи сохраняются в следующих файлах:

- Master нода: `/var/log/k8s-master-install.log`
- Worker нода: `/var/log/k8s-worker-install.log`

Для просмотра логов:

```bash
sudo tail -f /var/log/k8s-master-install.log
# или
sudo tail -f /var/log/k8s-worker-install.log
```

## Возможные проблемы и решения

### Ошибка "SWAP is enabled"

**Решение:** Скрипт автоматически отключает SWAP. Если ошибка появляется, убедитесь, что скрипт запущен с правами root/sudo.

### Ошибка "containerd is not running"

**Решение:** Проверьте статус containerd:

```bash
sudo systemctl status containerd
sudo journalctl -u containerd -n 50
```

Перезапустите containerd:

```bash
sudo systemctl restart containerd
```

### Worker нода не переходит в статус Ready

**Возможные причины:**

1. **Calico еще не готов**
   - Подождите 1-2 минуты
   - Проверьте статус Calico: `kubectl get pods -n kube-system | grep calico`

2. **Проблемы с сетью**
   - Убедитесь, что worker нода может достучаться до master ноды
   - Проверьте firewall правила

3. **Недостаточно ресурсов**
   - Проверьте использование CPU и RAM: `top` или `htop`

### Ошибка при выполнении kubeadm join

**Ошибка:** `token has expired`

**Решение:** Токен действителен 24 часа. Создайте новый токен на master ноде:

```bash
sudo kubeadm token create --print-join-command
```

**Ошибка:** `couldn't validate the identity of the API Server`

**Решение:** Проверьте доступность master ноды:

```bash
telnet <MASTER_IP> 6443
# или
nc -zv <MASTER_IP> 6443
```

## Удаление и переустановка

### Сброс master ноды

```bash
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/
sudo rm -rf /var/lib/etcd
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

### Сброс worker ноды

На master ноде:

```bash
kubectl drain <worker-node-name> --ignore-daemonsets --delete-emptydir-data
kubectl delete node <worker-node-name>
```

На worker ноде:

```bash
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
sudo rm -rf /etc/cni/net.d
```

## Дополнительная настройка

После успешной установки кластера рекомендуется:

1. **Настроить Ingress контроллер** (например, NGINX Ingress)
2. **Установить мониторинг** (Prometheus, Grafana)
3. **Настроить логирование** (ELK, Loki)
4. **Настроить Storage Classes** для persistent volumes
5. **Настроить Network Policies** для безопасности (см. `../manual-installation/calico-network-policies.md`)

## Полезные команды

```bash
# Просмотр всех ресурсов в кластере
kubectl get all --all-namespaces

# Информация о кластере
kubectl cluster-info

# Просмотр событий
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Просмотр логов пода
kubectl logs <pod-name> -n <namespace>

# Выполнение команды в поде
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Просмотр использования ресурсов (требует metrics-server)
kubectl top nodes
kubectl top pods --all-namespaces
```

## Поддержка и вклад

Если вы обнаружили проблему или хотите предложить улучшение, пожалуйста, создайте issue в репозитории проекта.

## Лицензия

MIT License

## Авторы

Проект поддерживается сообществом.
