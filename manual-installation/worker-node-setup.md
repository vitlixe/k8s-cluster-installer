# Установка Kubernetes Worker Node

Данная инструкция описывает процесс ручной установки рабочей ноды (worker node) кластера Kubernetes.

## Предварительные требования

- Операционная система: Debian-based Linux
- Минимум 1 CPU, 1GB RAM
- Права суперпользователя (sudo)
- Доступ к интернету
- **Уже развернутая master нода с полученной командой `kubeadm join`**

## Шаг 1: Подготовка системы

### 1.1. Отключение SWAP

SWAP должен быть отключен для корректной работы kubelet.

```bash
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab
```

**Описание:**
- `swapoff -a` — отключает все swap-разделы
- `sed -i '/swap/s/^/#/' /etc/fstab` — комментирует строки со swap в fstab, чтобы отключение сохранилось после перезагрузки

### 1.2. Загрузка необходимых модулей ядра

Создаем конфигурацию для автоматической загрузки модулей:

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

**Описание:**
- `overlay` — модуль для поддержки overlay файловой системы (используется containerd)
- `br_netfilter` — модуль для работы сетевого моста и фильтрации трафика

Проверяем, загружены ли модули:

```bash
lsmod | grep overlay
lsmod | grep br_netfilter
```

Если модули не загружены, загружаем их вручную:

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

Добавляем модули в автозагрузку:

```bash
sudo echo "overlay" >> /etc/modules
sudo echo "br_netfilter" >> /etc/modules
```

### 1.3. Настройка параметров sysctl

Настраиваем параметры сети для Kubernetes:

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```

**Описание параметров:**
- `net.bridge.bridge-nf-call-iptables = 1` — разрешает iptables обрабатывать трафик моста
- `net.bridge.bridge-nf-call-ip6tables = 1` — то же для IPv6
- `net.ipv4.ip_forward = 1` — включает forwarding IP-пакетов

Применяем настройки:

```bash
sudo sysctl --system
```

## Шаг 2: Установка Container Runtime (containerd)

### 2.1. Установка containerd

```bash
sudo apt-get update
sudo apt-get install -y containerd
```

**Описание:**
containerd — это container runtime, который управляет жизненным циклом контейнеров.

### 2.2. Настройка containerd

Создаем директорию для конфигурации и генерируем дефолтный конфиг:

```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

Включаем использование systemd cgroup driver (рекомендуется для Kubernetes):

```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

**Описание:**
Systemd cgroup driver обеспечивает лучшую интеграцию с systemd и рекомендуется для production окружений.

Перезапускаем и включаем containerd:

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd
```

Проверяем статус:

```bash
sudo systemctl status containerd
```

## Шаг 3: Установка компонентов Kubernetes

### 3.1. Установка зависимостей

```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

### 3.2. Добавление репозитория Kubernetes

Скачиваем и добавляем GPG ключ:

```bash
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

Добавляем репозиторий:

```bash
sudo echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
```

### 3.3. Установка kubelet, kubeadm, kubectl

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

**Описание компонентов:**
- `kubelet` — агент, который работает на каждой ноде и управляет контейнерами
- `kubeadm` — утилита для присоединения к кластеру
- `kubectl` — CLI для взаимодействия с кластером (опционально на worker ноде)
- `apt-mark hold` — фиксирует версии пакетов, предотвращая автоматическое обновление

### 3.4. Установка NFS клиента

```bash
sudo apt-get install nfs-common -y
```

**Описание:**
NFS клиент может понадобиться для монтирования сетевых хранилищ (persistent volumes).

## Шаг 4: Присоединение к кластеру

### 4.1. Получение команды join с master ноды

На **master ноде** выполните:

```bash
sudo kubeadm token create --print-join-command
```

Команда выведет что-то вроде:

```bash
kubeadm join 192.168.145.141:6443 --token TOKEN --discovery-token-ca-cert-hash sha256:HASH
```

### 4.2. Выполнение команды join на worker ноде

Скопируйте полученную команду и выполните её на worker ноде с sudo:

```bash
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

**Пример:**

```bash
sudo kubeadm join 192.168.145.141:6443 --token exud5e.qi21oov9ce8vtkeb --discovery-token-ca-cert-hash sha256:8abc8fa9de7c515ebbab65ce224b5ea48b4bb26ec766332a72eee495365c5a52
```

**Описание параметров:**
- `<MASTER_IP>:6443` — адрес и порт API сервера master ноды
- `--token` — токен аутентификации для присоединения
- `--discovery-token-ca-cert-hash` — хеш CA сертификата для проверки подлинности кластера

### 4.3. Проверка подключения

После успешного выполнения команды, на **master ноде** проверьте список нод:

```bash
kubectl get nodes -o wide
```

Worker нода должна появиться в списке. Через некоторое время (1-2 минуты) её статус изменится с `NotReady` на `Ready`.

## Проверка установки

### На worker ноде

Проверьте статус kubelet:

```bash
sudo systemctl status kubelet
```

Проверьте логи kubelet:

```bash
journalctl -u kubelet -f
```

### На master ноде

Проверьте поды на worker ноде:

```bash
kubectl get pods --all-namespaces -o wide | grep <worker-node-name>
```

Должны быть запущены системные поды (calico-node, kube-proxy).

## Возможные проблемы и решения

### Worker нода не переходит в статус Ready

Проверьте статус Calico на worker ноде:

```bash
kubectl get pods -n kube-system -o wide | grep calico
```

Проверьте логи calico-node на worker ноде:

```bash
kubectl logs -n kube-system <calico-node-pod-name>
```

### Ошибка при выполнении kubeadm join

**Ошибка:** `error execution phase preflight: couldn't validate the identity of the API Server`

**Решение:** Проверьте доступность master ноды по IP и порту 6443:

```bash
telnet <MASTER_IP> 6443
```

**Ошибка:** `token has expired`

**Решение:** Токены действительны 24 часа. Создайте новый токен на master ноде:

```bash
sudo kubeadm token create --print-join-command
```

### Проблемы с сетью

Убедитесь, что firewall не блокирует необходимые порты:

**На worker ноде должны быть открыты:**
- 10250 (Kubelet API)
- 30000-32767 (NodePort Services)

## Удаление ноды из кластера

Если нужно удалить worker ноду из кластера:

### На master ноде

```bash
# Пометить ноду как неспособную планировать новые поды
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Удалить ноду из кластера
kubectl delete node <node-name>
```

### На worker ноде

```bash
# Сбросить конфигурацию kubeadm
sudo kubeadm reset

# Очистить iptables правила
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

# Удалить CNI конфигурацию
sudo rm -rf /etc/cni/net.d
```

## Полезные команды

### Проверка логов (на worker ноде)

```bash
journalctl -u kubelet -f
journalctl -u containerd -f
```

### Проверка статуса (на master ноде)

```bash
kubectl get nodes
kubectl describe node <worker-node-name>
kubectl top node <worker-node-name>  # требует metrics-server
```

## Следующие шаги

После успешного присоединения worker ноды:

1. Повторите процесс для добавления дополнительных worker нод при необходимости
2. Разверните приложения в кластер
3. Настройте мониторинг и логирование
4. Настройте network policies при необходимости
