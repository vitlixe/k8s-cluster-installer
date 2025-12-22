# Kubernetes Cluster Installer

Автоматическая и ручная установка Kubernetes кластера с Calico CNI.

## Возможности

- ✅ Автоматическая установка через bash скрипты
- ✅ Подробные инструкции для ручной установки
- ✅ Настройка Calico Network Policies
- ✅ Jinja2 шаблоны для генерации NetworkPolicy

## Быстрый старт

### Автоматическая установка

**Master нода:**
```bash
cd automatic-installation
sudo ./install-master.sh
```

**Worker нода:**
```bash
cd automatic-installation
sudo ./install-worker.sh
```

Подробнее: [automatic-installation/README.md](automatic-installation/README.md)

### Ручная установка

- [Установка Master ноды](manual-installation/master-node-setup.md)
- [Установка Worker ноды](manual-installation/worker-node-setup.md)
- [Настройка Network Policies](manual-installation/calico-network-policies.md)

## Системные требования

| Компонент | Master | Worker |
|-----------|--------|--------|
| CPU | 2+ cores | 1+ core |
| RAM | 2+ GB | 1+ GB |
| Диск | 20+ GB | 10+ GB |
| ОС | Debian-based Linux | Debian-based Linux |

Протестированные ОС: [TESTED_OS.md](TESTED_OS.md)

## Компоненты

- **Kubernetes** v1.34.x
- **containerd** (latest)
- **Calico** v3.28.0
- **kubeadm/kubectl/kubelet** (latest)

## Network Policies

### Ручная настройка
См. [manual-installation/calico-network-policies.md](manual-installation/calico-network-policies.md)

### Генерация из шаблонов
```bash
cd templates
pip3 install jinja2 pyyaml
python3 generate-policy.py -c example-config.yaml -o policy.yaml
kubectl apply -f policy.yaml
```

Подробнее: [templates/README.md](templates/README.md)

## Структура репозитория

```
├── README.md                      # Этот файл
├── TESTED_OS.md                   # Протестированные ОС
├── manual-installation/           # Ручная установка
│   ├── master-node-setup.md
│   ├── worker-node-setup.md
│   └── calico-network-policies.md
├── automatic-installation/        # Автоматическая установка
│   ├── README.md
│   ├── install-master.sh
│   └── install-worker.sh
└── templates/                     # Jinja2 шаблоны
    ├── README.md
    ├── network-policy.yaml.j2
    ├── example-config.yaml
    └── generate-policy.py
```

## Полезные команды

```bash
# Проверка кластера
kubectl get nodes
kubectl get pods --all-namespaces

# Логи установки
tail -f /var/log/k8s-master-install.log
tail -f /var/log/k8s-worker-install.log

# Отладка
journalctl -u kubelet -f
journalctl -u containerd -f
```

## Удаление кластера

**Master:**
```bash
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/ ~/.kube/ /var/lib/etcd
```

**Worker:**
```bash
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl delete node <node>
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/ /etc/cni/net.d
```

## Ресурсы

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Calico Docs](https://docs.projectcalico.org/)
- [Network Policy Editor](https://editor.networkpolicy.io/)

## Лицензия

MIT License
