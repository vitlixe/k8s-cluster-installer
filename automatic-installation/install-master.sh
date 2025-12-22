#!/bin/bash

# Скрипт автоматической установки Kubernetes Master Node
# Поддерживаемые ОС: Debian-based Linux

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Логирование
LOG_FILE="/var/log/k8s-master-install.log"

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# Проверка прав суперпользователя
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен быть запущен с правами суперпользователя (sudo)"
        exit 1
    fi
}

# Проверка ОС
check_os() {
    log "Проверка операционной системы..."
    if [[ -f /etc/debian_version ]]; then
        log "Обнаружена Debian-based система"
    else
        log_warning "Данная ОС может быть не полностью поддерживаемой. Продолжить? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Проверка системных требований
check_requirements() {
    log "Проверка системных требований..."

    # Проверка CPU
    cpu_count=$(nproc)
    if [[ $cpu_count -lt 2 ]]; then
        log_warning "Рекомендуется минимум 2 CPU. Обнаружено: $cpu_count"
    else
        log "CPU: $cpu_count ✓"
    fi

    # Проверка RAM (в MB)
    ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $ram_mb -lt 2048 ]]; then
        log_warning "Рекомендуется минимум 2GB RAM. Обнаружено: ${ram_mb}MB"
    else
        log "RAM: ${ram_mb}MB ✓"
    fi
}

# Шаг 1: Отключение SWAP
disable_swap() {
    log "Отключение SWAP..."
    swapoff -a
    sed -i '/swap/s/^/#/' /etc/fstab
    log "SWAP отключен ✓"
}

# Шаг 2: Загрузка модулей ядра
load_kernel_modules() {
    log "Настройка модулей ядра..."

    cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    # Проверка и загрузка модулей
    if ! lsmod | grep -q overlay; then
        log "Загрузка модуля overlay..."
        modprobe overlay
    else
        log "Модуль overlay уже загружен ✓"
    fi

    if ! lsmod | grep -q br_netfilter; then
        log "Загрузка модуля br_netfilter..."
        modprobe br_netfilter
    else
        log "Модуль br_netfilter уже загружен ✓"
    fi

    # Добавление в автозагрузку
    echo "overlay" >> /etc/modules
    echo "br_netfilter" >> /etc/modules

    log "Модули ядра настроены ✓"
}

# Шаг 3: Настройка sysctl
configure_sysctl() {
    log "Настройка параметров sysctl..."

    cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

    sysctl --system > /dev/null 2>&1
    log "Параметры sysctl применены ✓"
}

# Шаг 4: Установка containerd
install_containerd() {
    log "Установка containerd..."

    apt-get update > /dev/null 2>&1
    apt-get install -y containerd

    log "Настройка containerd..."
    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml > /dev/null

    # Включение SystemdCgroup
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

    systemctl restart containerd
    systemctl enable containerd > /dev/null 2>&1

    # Проверка статуса
    if systemctl is-active --quiet containerd; then
        log "containerd установлен и запущен ✓"
    else
        log_error "Ошибка запуска containerd"
        exit 1
    fi
}

# Шаг 5: Установка Kubernetes компонентов
install_kubernetes() {
    log "Установка зависимостей..."
    apt-get update > /dev/null 2>&1
    apt-get install -y apt-transport-https ca-certificates curl gpg

    log "Добавление репозитория Kubernetes..."

    # Скачивание GPG ключа
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    # Добавление репозитория
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
    chmod 644 /etc/apt/sources.list.d/kubernetes.list

    log "Установка kubelet, kubeadm, kubectl..."
    apt-get update > /dev/null 2>&1
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl > /dev/null 2>&1

    log "Kubernetes компоненты установлены ✓"

    # Вывод версий
    log "Версии установленных компонентов:"
    kubeadm version -o short | tee -a "$LOG_FILE"
}

# Шаг 6: Установка NFS клиента
install_nfs() {
    log "Установка NFS клиента..."
    apt-get install -y nfs-common > /dev/null 2>&1
    log "NFS клиент установлен ✓"
}

# Шаг 7: Инициализация кластера
init_cluster() {
    log "Инициализация Kubernetes кластера..."
    log "Это может занять несколько минут..."

    if kubeadm init --pod-network-cidr=10.244.0.0/16 | tee -a "$LOG_FILE"; then
        log "Кластер инициализирован ✓"
    else
        log_error "Ошибка инициализации кластера"
        exit 1
    fi
}

# Шаг 8: Настройка kubectl для пользователя
setup_kubectl() {
    log "Настройка kubectl..."

    # Определение пользователя, который запустил sudo
    if [[ -n "$SUDO_USER" ]]; then
        USER_HOME=$(eval echo ~$SUDO_USER)
        ACTUAL_USER=$SUDO_USER
    else
        USER_HOME=$HOME
        ACTUAL_USER=$(whoami)
    fi

    mkdir -p "$USER_HOME/.kube"
    cp -i /etc/kubernetes/admin.conf "$USER_HOME/.kube/config"
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.kube"

    log "kubectl настроен для пользователя $ACTUAL_USER ✓"
}

# Шаг 9: Установка Calico
install_calico() {
    log "Установка Calico CNI..."

    # Определение пользователя для kubectl
    if [[ -n "$SUDO_USER" ]]; then
        KUBECTL_CMD="sudo -u $SUDO_USER kubectl"
    else
        KUBECTL_CMD="kubectl"
    fi

    if $KUBECTL_CMD apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml; then
        log "Calico установлен ✓"
    else
        log_error "Ошибка установки Calico"
        exit 1
    fi

    log "Ожидание готовности нод (это может занять 1-2 минуты)..."
    sleep 30
}

# Шаг 10: Проверка статуса
check_status() {
    log "Проверка статуса кластера..."

    if [[ -n "$SUDO_USER" ]]; then
        KUBECTL_CMD="sudo -u $SUDO_USER kubectl"
    else
        KUBECTL_CMD="kubectl"
    fi

    log "Статус нод:"
    $KUBECTL_CMD get nodes -o wide | tee -a "$LOG_FILE"

    log ""
    log "Статус системных подов:"
    $KUBECTL_CMD get pods -n kube-system | tee -a "$LOG_FILE"
}

# Шаг 11: Вывод команды для подключения worker нод
print_join_command() {
    log ""
    log "=========================================="
    log "УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
    log "=========================================="
    log ""
    log "Для подключения worker нод выполните следующую команду на них:"
    log ""
    kubeadm token create --print-join-command | tee -a "$LOG_FILE"
    log ""
    log "Эта команда будет сохранена в файл: /root/k8s-join-command.sh"
    echo "#!/bin/bash" > /root/k8s-join-command.sh
    kubeadm token create --print-join-command >> /root/k8s-join-command.sh
    chmod +x /root/k8s-join-command.sh
    log ""
    log "Логи установки сохранены в: $LOG_FILE"
    log "=========================================="
}

# Основная функция
main() {
    log "=========================================="
    log "Kubernetes Master Node - Автоматическая установка"
    log "=========================================="
    log ""

    check_root
    check_os
    check_requirements

    log ""
    log "Начинаем установку..."
    log ""

    disable_swap
    load_kernel_modules
    configure_sysctl
    install_containerd
    install_kubernetes
    install_nfs
    init_cluster
    setup_kubectl
    install_calico
    check_status
    print_join_command

    log ""
    log "Установка завершена! Теперь вы можете подключать worker ноды."
}

# Запуск
main "$@"
