# Автоматическая установка Kubernetes

Bash скрипты для быстрой установки Kubernetes кластера.

## Что делают скрипты

- Проверка системных требований
- Отключение SWAP
- Установка containerd
- Установка Kubernetes компонентов
- Инициализация кластера (master) / Присоединение к кластеру (worker)
- Установка Calico CNI (master)
- Логирование в `/var/log/k8s-*-install.log`

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

## Логи

```bash
# Master
tail -f /var/log/k8s-master-install.log

# Worker
tail -f /var/log/k8s-worker-install.log
```

## Возможные проблемы

### Нода не Ready
```bash
kubectl get pods -n kube-system | grep calico
kubectl logs -n kube-system <calico-pod>
```

### Token expired
```bash
sudo kubeadm token create --print-join-command
```

### containerd не запускается
```bash
sudo systemctl restart containerd
sudo journalctl -u containerd -n 50
```
