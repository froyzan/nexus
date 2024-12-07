#!/bin/bash

# Обновление системы и установка необходимых пакетов
echo "Обновление списка пакетов..."
sudo apt update && sudo apt upgrade -y

# Список необходимых пакетов
PACKAGES=("openjdk-11-jdk" "wget" "curl")

install_packages() {
  for package in "${PACKAGES[@]}"; do
      if dpkg -s "$package" &> /dev/null; then
        echo "$package уже установлен."
      else
        echo "$package не установлен. Устанавливаю..."
        sudo apt install -y "$package"
      fi
  done
}

# Установка необходимых пакетов
install_packages

# Создание пользователя для Nexus
sudo adduser --system --no-create-home nexus

# Создание каталога для Nexus
sudo mkdir -p /opt/nexus
cd /opt

# Скачивание последней версии Nexus
sudo wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz
sudo tar -zxvf latest-unix.tar.gz
sudo mv /opt/nexus-* /opt/nexus

# Установка прав на директорию Nexus
sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work

# Настройка конфигурации для запуска от имени пользователя nexus
echo "run_as_user=nexus" | sudo tee /opt/nexus/bin/nexus.rc

# Создание systemd сервиса для управления Nexus
cat <<EOL | sudo tee /etc/systemd/system/nexus.service
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
User=nexus
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Перезагрузка systemd и запуск Nexus
# sudo systemctl daemon-reload
# sudo systemctl enable nexus
sudo systemctl start nexus

# Проверка статуса Nexus
echo "Ожидание запуска Nexus..."
# sleep 30  # Ждем, пока Nexus запустится

if sudo systemctl status nexus | grep "active (running)"; then
    echo "Nexus успешно запущен и доступен по адресу http://localhost:8081"
else
    echo "Произошла ошибка при запуске Nexus."
fi

# Вывод логов для проверки работы Nexus
echo "Последние логи..."
sudo tail -f /opt/sonatype-work/nexus3/log/nexus.log
