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

**Преимущества:** быстро, проверка требований, логирование, обработка ошибок

Bash скрипты для быстрой установки Kubernetes кластера.

**Файлы:**
- `install-master.sh` - автоматическая установка и настройка master ноды с проверками и логированием
- `install-worker.sh` - автоматическая установка worker ноды и присоединение к кластеру

**Установка:**

```bash
# Master нода
cd automatic-installation
sudo ./install-master.sh
```

Сохраните команду `kubeadm join` из вывода!

```bash
# Worker нода
cd automatic-installation
sudo ./install-worker.sh
```

Введите команду `kubeadm join` с master ноды.

**Проверка:**

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

### Способ 2: Ручная

**Преимущества:** понимание каждого шага, полная кастомизация, обучение

Подробные пошаговые инструкции для установки Kubernetes кластера вручную.

**Файлы:**
- `master-node-setup.md` - пошаговая инструкция по установке и настройке master ноды с объяснением каждой команды
- `worker-node-setup.md` - пошаговая инструкция по установке worker ноды и присоединению её к кластеру

**Порядок установки:**

1. **Сначала Master нода** - управляет кластером
2. **Затем Worker ноды** - исполняют рабочую нагрузку
3. **Повторить для каждой Worker ноды** - можно добавлять сколько угодно

**Инструкции:**
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

Дополнительные материалы, фиксы и настройки для Kubernetes кластера.

### Network Policies

- [Calico Network Policies](troubleshooting/calico-network-policies.md) - настройка сетевых политик для контроля трафика между namespace

### Планируется добавить

- Мониторинг и логирование
- Настройка Ingress
- Persistent Volumes
- Backup и восстановление
- Обновление компонентов кластера
