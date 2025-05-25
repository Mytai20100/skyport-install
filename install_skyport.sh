#!/bin/bash

show_info() {
  echo "######################################################################################"
  echo "#                                                                                    #"
  echo "# Project 'skyport-installer'                                                        #"
  echo "#                                                                                    #"
  echo "# Copyright (C) 2024, Ismam Ilahi, <ismamilahi@gmail.com>                            #"
  echo "#                                                                                    #"
  echo "#   This program is free software: you can redistribute it and/or modify             #"
  echo "#   it under the terms of the GNU General Public License as published by             #"
  echo "#   the Free Software Foundation, either version 3 of the License, or                #"
  echo "#   (at your option) any later version.                                              #"
  echo "#                                                                                    #"
  echo "#   This program is distributed in the hope that it will be useful,                  #"
  echo "#   but WITHOUT ANY WARRANTY; without even the implied warranty of                   #"
  echo "#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                    #"
  echo "#   GNU General Public License for more details.                                     #"
  echo "#                                                                                    #"
  echo "#   You should have received a copy of the GNU General Public License                #"
  echo "#   along with this program.  If not, see <https://www.gnu.org/licenses/>.           #"
  echo "#                                                                                    #"
  echo "#   https://github.com/ismamilahi/skyport-installer/blob/master/LICENSE              #"
  echo "#                                                                                    #"
  echo "# This script is not associated with the official Skyport Project.                   #"
  echo "# https://github.com/ismamilahi/skyport-installer                                    #"
  echo "#                                                                                    #"
  echo "######################################################################################"
}

check_error() {
  if [ $? -ne 0 ]; then
    echo "Error: $1. Exiting..."
    exit 1
  fi
}

install_nodejs() {
  if ! command -v node &> /dev/null; then
    read -p "Node.js is not installed. Would you like to install it now? (y/n): " install_node
    if [ "$install_node" == "y" ]; then
      if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
          source /etc/os-release
          case "$ID" in
            ubuntu)
              if [[ "$VERSION_ID" == "24.04" || "$VERSION_ID" == "22.04" || "$VERSION_ID" == "25.04"  ]]; then
                echo "Ubuntu $VERSION_ID is supported."
              else
                echo "Error: Ubuntu $VERSION_ID is not supported."
                exit 1
              fi
              ;;
            debian)
              if [[ "$VERSION_ID" == "11" || "$VERSION_ID" == "12" ]]; then
                echo "Debian $VERSION_ID is supported."
              else
                echo "Error: Debian $VERSION_ID is not supported."
                exit 1
              fi
              ;;
            centos)
              if [[ "$VERSION_ID" == "7" || "$VERSION_ID" == "8" ]]; then
                echo "CentOS $VERSION_ID is supported."
              else
                echo "Error: CentOS $VERSION_ID is not supported."
                exit 1
              fi
              ;;
            *)
              echo "Error: Unsupported Linux distribution. Exiting..."
              exit 1
              ;;
          esac
        else
          echo "Error: Unsupported Linux distribution. Exiting..."
          exit 1
        fi
      elif [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ $(sw_vers -productVersion | cut -d '.' -f 2) -ge 15 ]]; then
          echo "macOS $(sw_vers -productVersion) is supported."
        else
          echo "Error: Unsupported macOS version. Exiting..."
          exit 1
        fi
      elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "Windows is supported."
      else
        echo "Error: Unsupported operating system. Exiting..."
        exit 1
      fi

      install_nodejs_actual
    else
      echo "Error: Node.js is required for this script to run. Exiting..."
      exit 1
    fi
  else
    echo "Node.js version $(node -v) is already installed."
  fi
}

install_nodejs_actual() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    case "$ID" in
      ubuntu|debian)
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        ;;
      centos)
        curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo -E bash -
        sudo yum install -y nodejs
        ;;
      *)
        echo "Error: Unsupported Linux distribution. Exiting..."
        exit 1
        ;;
    esac
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install node@20
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    choco install nodejs-lts -y --version 20
  fi
  check_error "Node.js installation"
  echo "Node.js version $(node -v) installed."
}


install_panel() {
  echo "Installing Skyport Panel..."
  sudo apt install git
  cd
  sudo git clone https://github.com/Mytai20100/skyport-install /var/www/skyport/panel
  check_error "Cloning Skyport Panel repository"

  cd /var/www/skyport/panel
  npm install
  check_error "Installing npm dependencies for Skyport Panel"
  npm run seed
  check_error "Running seed for Skyport Panel"

  read -p "Enter the Panel port (default 3001): " panel_port
  panel_port=${panel_port:-3001}
  read -p "Enter the Panel domain (default localhost): " panel_domain
  panel_domain=${panel_domain:-localhost}

  sudo bash -c "cat > /var/www/skyport/panel/config.json" <<EOL
{
  "port": $panel_port,
  "domain": "$panel_domain",
  "version": "Latest"
}
EOL
  check_error "Writing config.json for Skyport Panel"

npm run createUser

  echo "Starting the Panel with pm2..."
  npm install pm2
  pm2 start index.js --name skyport-panel
  pm2 save
  pm2 startup
  check_error "Starting Skyport Panel with pm2"

  check_and_open_firewall_ports $panel_port
  echo "Skyport Panel installation complete."
  read -p "Press Enter to continue..."
}

install_daemon() {
  echo "Installing Skyport Daemon..."
  sudo apt install git
  cd
  sudo git clone https://github.com/Mytai20100/skyport-install  /var/www/skyport/daemon
  check_error "Cloning Skyport Daemon repository"

  curl -sSL https://get.docker.com/ | CHANNEL=stable bash
  sudo mkdir -p /etc/apt/keyrings
  cd /var/www/skyport/daemon
  npm install
  check_error "Installing npm dependencies for Skyport Daemon"

  read -p "Enter the Panel's remote URL (default http://localhost:3001): " daemon_remote
  daemon_remote=${daemon_remote:-http://localhost:3001}
  read -p "Enter the Panel's access key: " daemon_access_key
  read -p "Enter the Daemon port (default 3000): " daemon_port
  daemon_port=${daemon_port:-3000}
  read -p "Enter the FTP IP (default localhost): " ftp_ip
  ftp_ip=${ftp_ip:-localhost}
  read -p "Enter the FTP port (default 3002): " ftp_port
  ftp_port=${ftp_port:-3002}

  sudo bash -c "cat > /var/www/skyport/daemon/config.json" <<EOL
{
  "remote": "$daemon_remote",
  "key": "$daemon_access_key",
  "port": $daemon_port,
  "ftp": {
    "ip": "$ftp_ip",
    "port": $ftp_port
  },
  "version": "Latest"
}
EOL
  check_error "Writing config.json for Skyport Daemon"

  echo "Starting the Daemon with pm2..."
  npm install pm2
  pm2 start index.js --name skyport-daemon
  pm2 save
  pm2 startup
  check_error "Starting Skyport Daemon with pm2"

  check_and_open_firewall_ports $daemon_port $ftp_port
  echo "Skyport Daemon installation complete."
  read -p "Press Enter to continue..."
}

check_and_open_firewall_ports() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v ufw &> /dev/null; then
      for port in "$@"; do
        echo "Opening port $port in firewall..."
        sudo ufw allow $port
      done
    fi
  else
    echo "Firewall configuration not supported on this OS."
  fi
}

uninstall_panel() {
  echo "Uninstalling Skyport Panel..."
  pm2 stop skyport-panel
  pm2 delete skyport-panel
  sudo rm -rf /var/www/skyport/panel
  echo "Skyport Panel uninstalled."

  panel_port=$(sudo jq -r '.port' /var/www/skyport/panel/config.json 2>/dev/null)

  if [[ -n "$panel_port" ]]; then
    echo "Deleting firewall rule for panel port $panel_port..."
    sudo ufw delete allow $panel_port
  else
    echo "No specific panel port found in config.json. Skipping firewall rule deletion."
  fi

  read -p "Press Enter to continue..."
}

uninstall_daemon() {
  echo "Uninstalling Skyport Daemon..."
  pm2 stop skyport-daemon
  pm2 delete skyport-daemon
  sudo rm -rf /var/www/skyport/daemon
  echo "Skyport Daemon uninstalled."

  daemon_port=$(sudo jq -r '.port' /var/www/skyport/daemon/config.json 2>/dev/null)

  if [[ -n "$daemon_port" ]]; then
    echo "Deleting firewall rule for daemon port $daemon_port..."
    sudo ufw delete allow $daemon_port
  else
    echo "No specific daemon port found in config.json. Skipping firewall rule deletion."
  fi

  read -p "Press Enter to continue..."
}

update_panel() {
  echo "Updating Skyport Panel..."

  local panel_dir="/var/www/skyport/panel"
  local backup_dir="/var/www/skyport/backup"
  local backup_file="skyport_backup"
  local panel_db="skyport.db"

  echo "Creating backup directory $backup_dir if it doesn't exist..."
  mkdir -p "$backup_dir"
  check_error "Creating backup directory $backup_dir"

  echo "Backing up $panel_db to $backup_dir..."
  cp "$panel_dir/$panel_db" "$backup_dir/$backup_file.db"
  check_error "Backing up $panel_db"

  if [ -d "$panel_dir" ]; then
    echo "Removing existing $panel_dir directory..."
    sudo rm -rf "$panel_dir"
    check_error "Removing $panel_dir"
  fi

  echo "Cloning Skyport Panel repository into $panel_dir..."
  cd
  sudo git clone https://github.com/skyportlabs/panel /var/www/skyport/panel
  check_error "Cloning Skyport Panel repository"

  echo "Restoring $panel_db from $backup_dir to $panel_dir..."
  cp "$backup_dir/$backup_file.db" "$panel_dir/$panel_db"
  check_error "Restoring $panel_db"

  if [ -f "$backup_dir/$backup_file.db" ]; then
    echo "Deleting $backup_file.db from $backup_dir..."
    rm "$backup_dir/$backup_file.db"
    check_error "Deleting $backup_file.db from $backup_dir"
  fi

  echo "Installing npm dependencies for Skyport Panel..."
  npm install --prefix "$panel_dir"
  check_error "Installing npm dependencies for Skyport Panel"

  echo "Running seed for Skyport Panel..."
  npm run seed --prefix "$panel_dir"
  check_error "Running seed for Skyport Panel"

  echo "Restarting Skyport Panel with pm2..."
  pm2 restart skyport-panel
  check_error "Restarting Skyport Panel with pm2"

  echo "Skyport Panel updated."
  read -p "Press Enter to continue..."
}

update_daemon() {
  echo "Updating Skyport Daemon (Wings)..."

  local daemon_dir="/var/www/skyport/daemon"

  echo "Removing existing $daemon_dir directory..."
  sudo rm -rf "$daemon_dir"
  check_error "Removing $daemon_dir"

  echo "Cloning Skyport Daemon repository into $daemon_dir..."
  cd
  sudo git clone https://github.com/skyportlabs/skyportd "$daemon_dir"
  check_error "Cloning Skyport Daemon repository"

  echo "Installing npm dependencies for Skyport Daemon..."
  npm install --prefix "$daemon_dir"
  check_error "Installing npm dependencies for Skyport Daemon"

  echo "Restarting Skyport Daemon..."
  cd /var/www/skyport/deamon
  pm2 restart skyport-deamon

  echo "Skyport Daemon (Wings) updated."
  read -p "Press Enter to continue..."
}


while true; do
  clear
  show_info
  echo "Choose an option:"
  echo "1: Install Skyport Panel"
  echo "2: Install Skyport Daemon (Wings)"
  echo "3: Install both Skyport Panel and Daemon"
  echo "4: Uninstall Skyport Panel"
  echo "5: Uninstall Skyport Daemon"
  echo "6: Update Skyport Panel"
  echo "7: Update Skyport Daemon"
  echo "8: Exit"
  read -p "Enter your choice [1-8]: " choice

  case $choice in
    1)
      install_nodejs
      install_panel
      ;;
    2)
      install_nodejs
      install_daemon
      ;;
    3)
      install_nodejs
      install_panel
      install_daemon
      ;;
    4)
      uninstall_panel
      ;;
    5)
      uninstall_daemon
      ;;
    6)
      update_panel
      ;;
    7)
      update_daemon
      ;;
    8)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac

  read -p "Press Enter to return to the menu..."
done
