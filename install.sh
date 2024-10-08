#!/bin/bash

# Constants
NC='\033[0m' # No Color

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

# Functions

function detect_package_manager() {
    # TODO

    declare -A osInfo;
    # osInfo[/etc/arch-release]=pacman
    osInfo[/etc/debian_version]=apt

    for f in ${!osInfo[@]}
    do
        if [[ -f $f ]];then
            echo Package manager: ${osInfo[$f]}
            PACKAGE_MANAGER=${osInfo[$f]}
        else
            echo "The installed distribution is not supported"
        fi
    done
}

# detect_package_manager
# echo $PACKAGE_MANAGER

function install_if_not_exist() {
    if dpkg -s "$1" &>/dev/null; then
        PKG_EXIST=$(dpkg -s "$1" | grep "install ok installed")
        if [[ -n "$PKG_EXIST" ]]; then
            echo -e "$GREEN [ INFO ] $NC $1 - is already installed."
            return
        fi
    fi
    echo -e "$YELLOW [ INFO ] $NC $1 - installation..."
    sudo apt --install-suggests --install-recommends install "$1" -y
}


# ------------------------------------------------------------------------------

echo
echo '     __                         _            __        ____          '
echo '    / /   ____ _____  __  __   (_)___  _____/ /_____ _/ / /__  _____ '
echo '   / /   / __ `/_  / / / / /  / / __ \/ ___/ __/ __ `/ / / _ \/ ___/ '
echo '  / /___/ /_/ / / /_/ /_/ /  / / / / (__  ) /_/ /_/ / / /  __/ /     '
echo ' /_____/\__,_/ /___/\__, /  /_/_/ /_/____/\__/\__,_/_/_/\___/_/      '
echo '                   /____/                                            '
echo
sudo echo # sudo Permissions

# Check operating system
if [ "$(uname)" != "Linux" ]; then
    echo -e "$RED [ ERROR ] $NC Script designed for Linux."
    echo
    exit 1
fi

# Add User to Group
sudo usermod -aG audio $USER
# Arduino
# sudo groupadd plugdev
sudo groupadd dialout
# sudo usermod -aG tty $USER
sudo usermod -aG dialout $USER
# sudo usermod -aG uucp $USER
# sudo usermod -aG plugdev $USER

SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
RAM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$RAM_TOTAL" -gt "$SWAP_TOTAL" ]; then

    echo
    echo -e "$BLUE [ INFO ] $NC Disable Suspend and Hibernation"
    echo

    # sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
    if [[ $(sudo systemctl status hibernate.target | grep -w loaded) ]]; then
        sudo systemctl mask hibernate.target
    fi
    if [[ $(sudo systemctl status hybrid-sleep.target | grep -w loaded) ]]; then
        sudo systemctl mask hybrid-sleep.target
    fi
fi

echo
echo -e "$BLUE [ INFO ] $NC Swappiness settings"
echo

# cat /proc/sys/vm/swappiness # Check system swappiness value
sudo sysctl -w vm.swappiness=10


# WIP ##########################################################################
mkdir ~/.local/bin
mkdir ~/.local/share/themes
mkdir ~/.local/share/icons
mkdir ~/.local/share/fonts
# WIP ##########################################################################


echo
echo -e "$BLUE [ INFO ] $NC Checking the packege manager"
echo

# TODO: Try to use: if [[ $(lsb_release -i | grep -e Debian -e Linuxmint -e Ubuntu) ]]; then
if [[ $(command -v apt) ]]; then
    echo
    echo -e "$BLUE [ INFO ] $NC APT detected"
    echo

    sudo apt update && sudo apt upgrade -y

    # --------------------------------------------------------------------------

    echo
    echo -e "$BLUE [ INFO ] $NC Removing unneeded packages"
    echo

    sudo apt remove gnome-games cheese gnome-sound-recorder gnote yelp pidgin brasero sound-juicer malcontent gnome-contacts evolution gnome-maps gnome-weather xsane xfce4-goodies hv3 exfalso thunderbird*

    sudo apt autoremove && sudo apt clean

    # --------------------------------------------------------------------------

    echo
    echo -e "$BLUE [ INFO ] $NC Installing some drivers"
    echo

    # microcode firmware
    if [[ $(lscpu | grep Intel) ]]; then
        install_if_not_exist intel-microcode
    elif [[ $(lscpu | grep AMD) ]]; then
        install_if_not_exist amd64-microcode
    fi

    # NVIDIA drivers
    # install_if_not_exist nvidia-driver

    # AMD drivers
    # install_if_not_exist firmware-linux
    # install_if_not_exist firmware-linux-nonfree
    # install_if_not_exist libdrm-amdgpu1
    # install_if_not_exist xserver-xorg-video-amdgpu

    # Vulkan
    # install_if_not_exist libvulkan1
    # install_if_not_exist mesa-vulkan-drivers
    # install_if_not_exist vulkan-utils
    # install_if_not_exist vulkan-tools
    # install_if_not_exist vulkan-validationlayers

    # --------------------------------------------------------------------------

    echo
    echo -e "$BLUE [ INFO ] $NC Installing and configuring a firewall"
    echo

    # https://christitus.com/linux-security-mistakes/
    install_if_not_exist ufw
    install_if_not_exist gufw
    if ! [[ $(sudo ufw status | grep -w active) ]]; then
        sudo ufw enable
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        # sudo ufw allow ssh
    fi

    # Battery life
    # install_if_not_exist tlp
    # install_if_not_exist powertop

    echo
    echo -e "$BLUE [ INFO ] $NC Installing packages for printers / scanners"
    echo

    install_if_not_exist system-config-printer
    install_if_not_exist simple-scan


    if ! [[ $(sudo systemctl status cups.service | grep -w active) ]]; then
        install_if_not_exist cups
        sudo systemctl enable cups.service
        sudo systemctl start cups.service
    fi

    install_if_not_exist printer-driver-all
    install_if_not_exist hp-ppd
    # install_if_not_exist hplip

    install_if_not_exist printer-driver-cups-pdf
    install_if_not_exist ghostscript
    sudo systemctl restart cups.service
    sudo systemctl unmask cups.service

    echo
    echo -e "$BLUE [ INFO ] $NC Installing packages for Bluetooth (TODO)"
    echo

    if [[ $(dmesg |grep Bluetooth) ]]; then
        echo
        echo -e "$BLUE [ INFO ] $NC Bluetooth detected"
        echo
        # install_if_not_exist bluez
        # install_if_not_exist blueman
        # sudo systemctl enable bluetooth.service
        # sudo systemctl start bluetooth.service
        # rfkill # Check status
        # rfkill unblock bluetooth
    fi


    echo
    echo -e "$BLUE [ INFO ] $NC Development tools installation"
    echo

    install_if_not_exist curl
    install_if_not_exist apt-transport-https
    install_if_not_exist build-essential
    install_if_not_exist cmake
    install_if_not_exist dkms
    install_if_not_exist stow
    # install_if_not_exist linux-headers-$(uname -r)
    install_if_not_exist git
    install_if_not_exist nano
    # install_if_not_exist neofetch # TODO
    install_if_not_exist uuid-runtime
    install_if_not_exist ruby-full
    install_if_not_exist dpkg-dev
    install_if_not_exist debhelper
    install_if_not_exist python3-venv

    # vim
    sudo apt purge vim-tiny vim && sudo apt install vim-nox

    echo
    echo -e "$BLUE [ INFO ] $NC Some tools installation"
    echo

    # Rootkit detector
    install_if_not_exist chkrootkit
    # install_if_not_exist rkhunter
    # install_if_not_exist clamav

    # System monitor
    install_if_not_exist htop
    # install_if_not_exist bashtop
    # install_if_not_exist btop
    # install_if_not_exist conky

    # Network monitor
    install_if_not_exist iftop
    # install_if_not_exist bmon
    # install_if_not_exist slurm
    # install_if_not_exist tcptrack
    # install_if_not_exist vnstat

    # Package manager / Graphical package manager
    # install_if_not_exist nala
    # install_if_not_exist synaptic

    # File manager
    # install_if_not_exist ranger

    # Disk Usage
    install_if_not_exist ncdu

    # Archive manager / Console Compression Tools
    install_if_not_exist rar
    install_if_not_exist unrar
    # install_if_not_exist unrar-free
    install_if_not_exist zip
    install_if_not_exist unzip
    install_if_not_exist p7zip
    install_if_not_exist lzop

    # Other tools
    install_if_not_exist tree
    install_if_not_exist exa
    install_if_not_exist bat
    # install_if_not_exist rofi
    # install_if_not_exist tmux
    # install_if_not_exist putty
    # install_if_not_exist fzf
    # install_if_not_exist fd-find
    # install_if_not_exist ripgrep

    echo
    echo -e "$BLUE [ INFO ] $NC Some apps installation"
    echo

    install_if_not_exist timeshift # Timeshift
    install_if_not_exist file-roller # GNOME File Roller
    install_if_not_exist gnome-disks # GNOME Disks
    # install_if_not_exist gparted # GNOME partition editor
    # install_if_not_exist simple-scan # GNOME Document Scanner
    install_if_not_exist virt-manager # Virtual Machine Manager
    install_if_not_exist liferea # RSS Readers
    # install_if_not_exist newsboat # CLI RSS Readers
    # install_if_not_exist thunderbird # E-Mails application
    # install_if_not_exist libreoffice # LibreOffice
    # install_if_not_exist transmission-gtk # Transmission
    # install_if_not_exist mintstick
    # install_if_not_exist xed # xed Text Editor
    install_if_not_exist gimp
    install_if_not_exist inkscape
    install_if_not_exist chromium
    install_if_not_exist f3d # 3D viewer
    # install_if_not_exist kazam # screencast and screenshot

    # Just for fun
    # install_if_not_exist fortune
    # install_if_not_exist cowsay
    # install_if_not_exist hollywood
    # install_if_not_exist cmatrix

    echo
    echo -e "$BLUE [ INFO ] $NC Fonts installation"
    echo

    # Fonts
    install_if_not_exist fonts-hack-ttf
    # install_if_not_exist fonts-firacode
    install_if_not_exist fonts-dejavu
    install_if_not_exist fonts-inconsolata
    install_if_not_exist ttf-mscorefonts-installer
    install_if_not_exist fonts-ubuntu
    # install_if_not_exist fonts-roboto
    # install_if_not_exist fonts-terminus
    # install_if_not_exist fonts-crosextra-caladea
    # install_if_not_exist fonts-crosextra-carlito
    # install_if_not_exist fonts-wine # ??
    # install_if_not_exist fonts-freefont-ttf


    echo
    echo -e "$BLUE [ INFO ] $NC ZSH and ZSH plugins installation"
    echo

    install_if_not_exist zsh
    install_if_not_exist zsh-syntax-highlighting
    install_if_not_exist zsh-autosuggestions

    # spaceship-prompt installation
    mkdir -p "$HOME/.zsh"
    if [ ! -d "$HOME/.zsh/spaceship" ]; then
        git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.zsh/spaceship"
    fi

    # zsh-shift-select plugin installation
    if [ ! -d "$HOME/.zsh/zsh-shift-select" ]; then
        git clone https://github.com/jirutka/zsh-shift-select "$HOME/.zsh/zsh-shift-select"
    fi

    if ! [ -n "$ZSH_VERSION" ]; then
        echo -e "$GREEN [ INFO ] $NC Setting zsh as default"
        chsh -s $(which zsh)
    fi

    # NeoVIM
    # xclip (X11) or wl-clipboard (Wayland)

    sudo apt autoclean -y && sudo apt autoremove -y

elif [[ $(command -v packman) ]]; then
    echo
    echo -e "$BLUE [ INFO ] $NC packman detected"
    echo
    exit 1
else
    echo -e "$RED [ ERROR ] $NC Script only supports APT!"
    echo
    exit 1
fi

if [ $XDG_CURRENT_DESKTOP = "XFCE" ]; then
    echo
    echo -e "$BLUE [ INFO ] $NC XFCE detected"
    echo -e "$GREEN [ INFO ] $NC Starting XFCE configurations..."
    echo

    # thunar
    xfconf-query -c thunar -p "/default-view" -n -t string -s "ThunarCompactView"
    xfconf-query -c thunar -p "/misc-change-window-icon" -n -t bool -s true
    xfconf-query -c thunar -p "/misc-date-style" -n -t string -s "THUNAR_DATE_STYLE_YYYYMMDD"
    xfconf-query -c thunar -p "/misc-directory-specific-settings" -n -t bool -s false
    xfconf-query -c thunar -p "/misc-single-click" -n -t bool -s false
    xfconf-query -c thunar -p "/misc-small-toolbar-icons" -n -t bool -s true
    xfconf-query -c thunar -p "/misc-text-beside-icons" -n -t bool -s false
    xfconf-query -c thunar -p "/misc-thumbnail-draw-frames" -n -t bool -s false
    xfconf-query -c thunar -p "/misc-thumbnail-mode" -n -t string -s "THUNAR_THUMBNAIL_MODE_ALWAYS"
    xfconf-query -c thunar -p "/misc-volume-management" -n -t bool -s true
    xfconf-query -c thunar -p "/shortcuts-icon-emblems" -n -t bool -s true
    xfconf-query -c thunar -p "/shortcuts-icon-size" -n -t string -s "THUNAR_ICON_SIZE_16"
    xfconf-query -c thunar -p "/tree-icon-emblems" -n -t bool -s true
    xfconf-query -c thunar -p "/misc-recursive-search" -n -t string -s "THUNAR_RECURSIVE_SEARCH_ALWAYS"

    # xfce4-appfinder
    xfconf-query -c xfce4-appfinder -p "/always-center" -n -t bool -s true
    xfconf-query -c xfce4-appfinder -p "/category-icon-size" -n -t int -s 0
    xfconf-query -c xfce4-appfinder -p "/enable-service" -n -t bool -s true
    xfconf-query -c xfce4-appfinder -p "/hide-category-pane" -n -t bool -s false
    xfconf-query -c xfce4-appfinder -p "/icon-view" -n -t bool -s true
    xfconf-query -c xfce4-appfinder -p "/item-icon-size" -n -t int -s 0
    xfconf-query -c xfce4-appfinder -p "/single-window" -n -t bool -s true
    xfconf-query -c xfce4-appfinder -p "/text-beside-icons" -n -t bool -s true

    # xfce4-desktop
    xfconf-query -c xfce4-desktop -p "/desktop-icons/file-icons/show-filesystem" -n -t bool -s false
    xfconf-query -c xfce4-desktop -p "/desktop-icons/file-icons/show-home" -n -t bool -s false
    xfconf-query -c xfce4-desktop -p "/desktop-icons/file-icons/show-removable" -n -t bool -s false
    xfconf-query -c xfce4-desktop -p "/desktop-icons/file-icons/show-trash" -n -t bool -s false
    xfconf-query -c xfce4-desktop -p "/desktop-icons/icon-size" -n -t int -s 36
    xfconf-query -c xfce4-desktop -p "/desktop-icons/show-hidden-files" -n -t bool -s false
    xfconf-query -c xfce4-desktop -p "/desktop-icons/show-thumbnails" -n -t bool -s true
    xfconf-query -c xfce4-desktop -p "/desktop-icons/show-tooltips" -n -t bool -s false
    xfconf-query -c xfce4-desktop -p "/desktop-icons/primary" -n -t bool -s false
    xfconf-query -c xfce4-desktop -p "/desktop-icons/use-custom-font-size" -n -t bool -s true
    xfconf-query -c xfce4-desktop -p "/desktop-icons/font-size" -n -t int -s 9


    # xfce4-keyboard-shortcuts
    # Create commands
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/override" -s true
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>e" -n -t string -s "thunar"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>s" -n -t string -s "xfce4-popup-whiskermenu"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>l" -n -t string -s "xflock4"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>i" -n -t string -s "xfce4-settings-manager"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Alt>Delete" -n -t string -s "xfce4-taskmanager"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Alt>Escape" -n -t string -s "xkill"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Alt>t" -n -t string -s "x-terminal-emulator"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary>space" -n -t string -s "rofi -show drun"

    # Reset default shortcuts
    for property in $(xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom" -l)
    do xfconf-query -c xfce4-keyboard-shortcuts -p $property -r; done

    # Create shortcuts
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/override" -n -t bool -s true
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>d" -n -t string -s "show_desktop_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Tab" -n -t string -s "cycle_windows_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Shift><Super>Tab" -n -t string -s "cycle_reverse_windows_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Down" -n -t string -s "tile_down_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Left" -n -t string -s "tile_left_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Right" -n -t string -s "tile_right_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Up" -n -t string -s "tile_up_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Super>d" -n -t string -s "add_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Super>F4" -n -t string -s "del_active_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Super>Down" -n -t string -s "down_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Super>Left" -n -t string -s "left_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Super>Right" -n -t string -s "right_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Super>Up" -n -t string -s "up_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Control>F1" -n -t string -s "workspace_1_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Control>F2" -n -t string -s "workspace_2_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Control>F3" -n -t string -s "workspace_3_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Control>F4" -n -t string -s "workspace_4_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Alt><Super>Down" -n -t string -s "move_window_down_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Alt><Super>Left" -n -t string -s "move_window_left_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Alt><Super>Right" -n -t string -s "move_window_right_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Primary><Alt><Super>Up" -n -t string -s "move_window_up_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt><Control>Home" -n -t string -s "move_window_prev_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt><Control>End" -n -t string -s "move_window_next_workspace_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt><Control>KP_1" -n -t string -s "move_window_workspace_1_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt><Control>KP_2" -n -t string -s "move_window_workspace_2_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt><Control>KP_3" -n -t string -s "move_window_workspace_3_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt><Control>KP_4" -n -t string -s "move_window_workspace_4_key"

    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>space" -n -t string -s "popup_menu_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/Up" -n -t string -s "up_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/Down" -n -t string -s "down_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/Left" -n -t string -s "left_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/Right" -n -t string -s "right_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/Escape" -n -t string -s "cancel_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>F4" -n -t string -s "close_window_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>F10" -n -t string -s "maximize_window_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>F9" -n -t string -s "hide_window_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>F8" -n -t string -s "resize_window_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>F7" -n -t string -s "move_window_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>F6" -n -t string -s "stick_window_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Shift><Alt>Page_Up" -n -t string -s "raise_window_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Shift><Alt>Page_Down" -n -t string -s "lower_window_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>F11" -n -t string -s "fullscreen_key"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>F12" -n -t string -s "above_key"


    # xfce4-panel
    xfconf-query -c xfce4-panel -p "/panels/dark-mode" -n -t bool -s true

    # xfwm4 (TODO)
    xfconf-query -c xfwm4 -p "/general/click_to_focus" -s true
    xfconf-query -c xfwm4 -p "/general/double_click_action" -s "maximize"
    xfconf-query -c xfwm4 -p "/general/focus_hint" -s true
    xfconf-query -c xfwm4 -p "/general/focus_new" -s true
    xfconf-query -c xfwm4 -p "/general/show_dock_shadow" -s true

    # xsettings
    xfconf-query -c xsettings -p "/Gtk/ButtonImages" -s false
    xfconf-query -c xsettings -p "/Gtk/DialogsUseHeader" -s true
    xfconf-query -c xsettings -p "/Gtk/MenuImages" -s false

elif [ $XDG_CURRENT_DESKTOP = "GNOME" ]; then
    echo
    echo -e "$BLUE [ INFO ] $NC GNOME detected"
    echo -e "$GREEN [ INFO ] $NC Starting GNOME configurations..."
    echo -e "$RED [ ERROR ] $NC GNOME not supported :("
    echo
    # install_if_not_exist gnome-tweak-tool
    # install_if_not_exist chrome-gnome-shell
else
    echo -e "$RED [ ERROR ] $NC Script only supports XFCE!"
    echo
fi


echo
echo -e "$BLUE [ INFO ] $NC Downloading and installing dotfiles"
echo

mkdir -p "$HOME/Documents/GitHub"
if [ ! -d "$HOME/Documents/GitHub/dotfiles" ]; then
    git clone https://github.com/vec2pt/dotfiles.git "$HOME/Documents/GitHub/dotfiles"
    bash "$HOME/Documents/GitHub/dotfiles/install.sh"
    source $HOME/.bashrc
fi
