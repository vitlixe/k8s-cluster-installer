# Установка Kubernetes Master Node

Данная инструкция описывает процесс ручной установки управляющей ноды (master node) кластера Kubernetes.

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
- `kubeadm` — утилита для инициализации и управления кластером
- `kubectl` — CLI для взаимодействия с кластером
- `apt-mark hold` — фиксирует версии пакетов, предотвращая автоматическое обновление

### 3.4. Установка NFS клиента

```bash
sudo apt-get install nfs-common -y
```

**Описание:**
NFS клиент может понадобиться для монтирования сетевых хранилищ (persistent volumes).

## Шаг 4: Инициализация кластера

### 4.1. Инициализация master ноды

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

**Описание:**
- `--pod-network-cidr=10.244.0.0/16` — задает подсеть для pod-сети (используется Calico)

**Важно:** Сохраните вывод команды! Там будет команда `kubeadm join` для подключения worker нод.

### 4.2. Настройка kubectl для текущего пользователя

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Описание:**
Копируем конфигурацию кластера в домашнюю директорию пользователя для работы с kubectl.

## Шаг 5: Установка сетевого плагина (Calico)

### 5.1. Установка Calico

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

**Описание:**
Calico — это сетевой плагин (CNI), который обеспечивает сетевую связность между подами и реализует network policies.

### 5.2. Проверка статуса нод

```bash
kubectl get nodes -o wide
```

Дождитесь, пока статус master ноды изменится на `Ready`.

## Шаг 6: Получение команды для подключения worker нод

Для генерации команды подключения worker ноды выполните:

```bash
sudo kubeadm token create --print-join-command
```

**Описание:**
Эта команда создает новый токен и выводит полную команду для подключения worker нод к кластеру.

Пример вывода:
```bash
kubeadm join 192.168.1.100:6443 --token TOKEN --discovery-token-ca-cert-hash sha256:HASH
```

Используйте эту команду на worker нодах для их подключения к кластеру.

## Проверка установки

### Проверка компонентов кластера

```bash
kubectl get pods -n kube-system
```

Все поды должны быть в состоянии `Running`.

### Проверка версии

```bash
kubectl version --short
kubeadm version
```

## Полезные команды

### Просмотр токенов

```bash
kubeadm token list
```

### Просмотр состояния кластера

```bash
kubectl cluster-info
kubectl get all --all-namespaces
```

### Просмотр логов компонентов

```bash
journalctl -u kubelet -f
journalctl -u containerd -f
```

## Возможные проблемы и решения

### Нода не переходит в статус Ready

Проверьте статус Calico подов:

```bash
kubectl get pods -n kube-system | grep calico
```

Проверьте логи:

```bash
kubectl logs -n kube-system <calico-pod-name>
```

### Ошибки containerd

Проверьте статус и логи:

```bash
sudo systemctl status containerd
journalctl -u containerd -n 50
```

## Следующие шаги

После успешной установки master ноды:

1. Подключите worker ноды используя команду `kubeadm join`
2. Настройте network policies при необходимости (см. документацию по Calico)
3. Установите дополнительные компоненты (Ingress, Storage Classes, и т.д.)
