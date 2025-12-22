# Автоматическая установка Kubernetes

Bash скрипты для быстрой установки Kubernetes кластера.

## Файлы

### install-master.sh
Автоматическая установка и настройка master ноды с проверками и логированием.

### install-worker.sh
Автоматическая установка worker ноды и присоединение к кластеру.

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
