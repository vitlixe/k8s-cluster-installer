# Автоматическая установка Kubernetes

Bash скрипты для быстрой установки Kubernetes кластера.

## Файлы

### install-master.sh
Автоматическая установка и настройка master ноды кластера.

**Что делает:**
- Проверка системных требований (CPU, RAM)
- Отключение SWAP
- Установка и настройка containerd
- Установка Kubernetes компонентов (kubelet, kubeadm, kubectl)
- Инициализация кластера
- Установка Calico CNI
- Настройка kubectl для пользователя
- Генерация команды join для worker нод

**Логи:** `/var/log/k8s-master-install.log`

### install-worker.sh
Автоматическая установка и подключение worker ноды к кластеру.

**Что делает:**
- Проверка системных требований
- Отключение SWAP
- Установка и настройка containerd
- Установка Kubernetes компонентов
- Интерактивный запрос команды join
- Присоединение к кластеру

**Логи:** `/var/log/k8s-worker-install.log`

## Установка

### Master нода

```bash
cd automatic-installation
sudo ./install-master.sh
```

Сохраните команду `kubeadm join` из вывода!

### Worker нода

```bash
cd automatic-installation
sudo ./install-worker.sh
```

Введите команду `kubeadm join` с master ноды.

## Проверка

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```
