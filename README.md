# Kubernetes Cluster Installer

**Полный набор инструментов для развертывания production-ready Kubernetes кластера.**

Автоматизированные скрипты и подробные инструкции для установки Kubernetes кластера с нуля.

## Для кого?

- **Изучающие Kubernetes** — подробные инструкции с объяснением каждого шага
- **DevOps инженеры** — автоматизированные скрипты для быстрого развертывания
- **On-premise окружения** — полный контроль над инфраструктурой
- **Эксперименты** — простое создание и удаление кластеров

## Системные требования

| | Master | Worker |
|---|---|---|
| CPU | 2+ ядра | 1+ ядро |
| RAM | 2+ GB | 1+ GB |
| Диск | 20+ GB | 10+ GB |

[Протестированные ОС](TESTED_OS.md)

## Способы установки

### Способ 1: Автоматическая (рекомендуется)

**Преимущества:** быстро (5 мин), проверка требований, логирование, обработка ошибок

```bash
# Master
cd automatic-installation
sudo ./install-master.sh

# Worker
cd automatic-installation
sudo ./install-worker.sh
# Введите команду join с master ноды
```

[Подробнее](automatic-installation/README.md)

### Способ 2: Ручная

**Преимущества:** понимание каждого шага, полная кастомизация, обучение

- [Установка Master ноды](manual-installation/master-node-setup.md)
- [Установка Worker ноды](manual-installation/worker-node-setup.md)

## Компоненты

| Компонент | Версия | Назначение |
|---|---|---|
| Kubernetes | v1.34.x | Оркестрация контейнеров |
| Calico | v3.28.0 | Сетевой плагин (CNI) |
| containerd | latest | Container runtime |
| kubeadm | latest | Инициализация кластера |

## Структура

```
k8s-cluster-installer/
├── automatic-installation/    # Автоматическая установка
├── manual-installation/       # Ручная установка
├── troubleshooting/           # Фиксы и дополнения
└── TESTED_OS.md              # Протестированные ОС
```

## Troubleshooting & Extras

После установки базового кластера:

- [Calico Network Policies](troubleshooting/calico-network-policies.md) - контроль трафика между namespace

## Полезные команды

```bash
# Проверка
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Логи установки
tail -f /var/log/k8s-master-install.log
tail -f /var/log/k8s-worker-install.log

# Отладка
journalctl -u kubelet -f
journalctl -u containerd -f
```

## Удаление кластера

```bash
# Master
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/ ~/.kube/ /var/lib/etcd

# Worker (сначала на master: kubectl drain/delete node)
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/ /etc/cni/net.d
```
