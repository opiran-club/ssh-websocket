#!/bin/bash
fun_wsproxy () {
    CYAN=$(tput setaf 6)
    GREEN=$(tput setaf 2)
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)

    install_packages() {
        echo "${YELLOW}Installing required packages...${RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get -qq update
            sudo apt-get -qq -y install python3 python3-pip
        elif command -v yum &>/dev/null; then
            sudo yum -q -y update
            sudo yum -q -y install python3 python3-pip
        else
            echo "${RED}Unsupported package manager. Please install Python3 and pip manually.${RESET}"
            exit 1
        fi
    }

    download_wsproxy() {
        echo "${yellow}Downloading WebSocket proxy script...${reset}"
        wget -O /root/wsproxy.py https://github.com/opiran-club/ssh-websocket/raw/main/wsproxy.py
    }
clear
    # Function to configure the WebSocket proxy
    configure_wsproxy() {
    pip install websockets
        echo "${cyan}Configuring WebSocket proxy...${reset}"

        # Ask for CDN host
        read -p "${cyan}Enter the hostname as CDN host: ${reset}" cdn_host

        # Ask for SNI host
        read -p "${cyan}Enter the SNI Host: ${reset}" sni_host

        # Ask for SSH port
        read -p "${cyan}Enter your SSH port: ${reset}" ssh_port

        # Function to ask for HTTP/HTTPS port
        ask_http_port() {
            while true; do
                read -p "${cyan}Enter your desired HTTP/HTTPS port (e.g., 443): ${reset}" http_port

                if ! [[ "$http_port" =~ ^[0-9]+$ ]]; then
                    echo "Invalid input. Please enter a valid port number."
                elif ((http_port < 1 || http_port > 65535)); then
                    echo "Port number must be between 1 and 65535."
                else
                    break
                fi
            done
        }

        # Ask for HTTP/HTTPS ports
        echo "${cyan}Please select the HTTP/HTTPS ports:${reset}"
        echo "${yellow}Common HTTP ports: 80, 8080, 8880, 2052, 2082, 2086, 2095${reset}"
        echo "${yellow}Common HTTPS ports: 443, 2053, 2083, 2087, 2096, 8443${reset}"

        ask_http_port

        # Set up the WebSocket proxy configuration
        echo "RESPONSE = \"HTTP/1.1 101 <font color='null'></font>\"\r" >> /root/wsproxy.py
        echo "DEFAULT_HOST = \"$sni_host:$ssh_port\"\r" >> /root/wsproxy.py

        # Set up the service file
        echo "[Unit]
    Description=WebSocket Proxy Server
    After=network.target

    [Service]
    Type=simple
    User=$USER
    WorkingDirectory=$(pwd)
    ExecStart=/usr/bin/python3 wsproxy.py -p $http_port -s $ssh_port
    Restart=always

    [Install]
    WantedBy=multi-user.target" | sudo tee /etc/systemd/system/wsproxy.service > /dev/null

        # Start the WebSocket proxy service
        sudo systemctl enable wsproxy
        sudo systemctl start wsproxy

        echo "${yellow}WebSocket proxy service has been started and enabled.${reset}"
    }

    # Function to provide the payload for HTTP injector
    generate_httpinjector_payload() {
        echo "Generating HTTP Injector payload..."
        echo "================ HTTP Injector Payload ================"
        echo "Hostname: $cdn_host"
        echo "Port: $http_port"
        echo "SNI: $sni_host"
        echo ""
        echo "Payload: GET / HTTP/1.1 [lf]Host: $cdn_host [lf][lf]"
        echo "======================================================"
    }

    # Function to start the WebSocket proxy service
    start_wsproxy() {
        sudo systemctl start wsproxy
        echo "${yellow}WebSocket proxy service has been started.${reset}"
    }

    # Function to stop the WebSocket proxy service
    stop_wsproxy() {
        sudo systemctl stop wsproxy
        echo "${yellow}WebSocket proxy service has been stopped.${reset}"
    }

    # Function to restart the WebSocket proxy service
    restart_wsproxy() {
        sudo systemctl restart wsproxy
        echo "${yellow}WebSocket proxy service has been restarted.${reset}"
    }

    # Function to uninstall the WebSocket proxy
    uninstall_wsproxy() {
        sudo systemctl stop wsproxy
        sudo systemctl disable wsproxy
        sudo rm /etc/systemd/system/wsproxy.service
        echo "${yellow}WebSocket proxy has been uninstalled.${RESET}"
    }

    # Main script
    install_packages

    # Check if Python is installed
        if ! command -v python3 &>/dev/null; then
            echo -e "${RED}Python3 is not installed. Aborting...${RESET}"
            exit 1
        fi
clear
    PS3="${CYAN}Please select an option: ${RESET}"
    select opt in "Install WebSocket Proxy" "Start WebSocket Proxy" "Stop WebSocket Proxy" "Restart WebSocket Proxy" "Uninstall WebSocket Proxy" "Generate HTTP Injector Payload" "Exit"; do
        case $opt in
            "Install WebSocket Proxy")
                download_wsproxy
                configure_wsproxy
                ;;
            "Start WebSocket Proxy")
                start_wsproxy
                ;;
            "Stop WebSocket Proxy")
                stop_wsproxy
                ;;
            "Restart WebSocket Proxy")
                restart_wsproxy
                ;;
            "Uninstall WebSocket Proxy")
                uninstall_wsproxy
                ;;
            "Generate HTTP Injector Payload")
                generate_httpinjector_payload
                ;;
            "Cloudflare WSProxy")
                fun_wsproxy  # Call the new function
                ;;
            "Exit")
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please select again.${RESET}"
                ;;
            esac
        done

        echo -e "${GREEN}WebSocket proxy installation and configuration completed successfully.${RESET}"
    }
fun_wsproxy
