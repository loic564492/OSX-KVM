#!/bin/bash

# Fonction pour vérifier si un paquet est déjà installé
is_installed() {
    pacman -Qi "$1" &> /dev/null
}

# Vérification de la connexion Internet
check_internet() {
    echo "Vérification de la connexion Internet..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        echo "Erreur : Pas de connexion Internet. Veuillez vérifier votre réseau."
        exit 1
    fi
    echo "Connexion Internet détectée."
}

# Mise à jour des dépôts et du système
update_system() {
    echo "Mise à jour des dépôts et du système..."
    sudo pacman -Syu --noconfirm
}

# Installation d'un paquet s'il n'est pas déjà installé
install_package() {
    if ! is_installed "$1"; then
        echo "Installation de $1..."
        sudo pacman -S --noconfirm "$1"
    else
        echo "$1 est déjà installé."
    fi
}

# Installation de X11 et du gestionnaire de fenêtres choisi
install_graphics() {
    echo "Installation de l'environnement graphique..."
    install_package "xorg-server"
    install_package "xorg-xinit"

    case "$1" in
        "i3")
            install_package "i3"
            ;;
        "fluxbox")
            install_package "fluxbox"
            ;;
        "openbox")
            install_package "openbox"
            ;;
        *)
            echo "Erreur : Environnement de bureau non reconnu."
            exit 1
            ;;
    esac
    install_package "xterm"
}

# Installation et activation de LightDM
install_lightdm() {
    echo "Installation de LightDM..."
    install_package "lightdm"
    install_package "lightdm-gtk-greeter"
    sudo systemctl enable lightdm
}

# Installation de SSH et activation du service
install_ssh() {
    echo "Installation de SSH..."
    install_package "openssh"
    sudo systemctl enable --now sshd

    echo "Configuration du forwarding X11 pour SSH..."
    sudo sed -i 's/#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd

    echo "Vérification de l'état du service SSH..."
    if systemctl is-active --quiet sshd; then
        echo "Le service SSH est actif."
    else
        echo "Erreur : Le service SSH n'a pas pu être démarré."
        exit 1
    fi
}

# Installation des outils pour KVM/QEMU et configuration de libvirt
install_kvm_qemu() {
    echo "Installation de KVM/QEMU et des outils associés..."
    install_package "qemu"
    install_package "libvirt"
    install_package "virt-manager"
    install_package "ebtables"
    install_package "dnsmasq"
    install_package "bridge-utils"

    echo "Activation du service libvirtd..."
    sudo systemctl enable --now libvirtd
    sudo usermod -aG libvirt $(whoami)

    echo "Vérification de l'état du service libvirtd..."
    if systemctl is-active --quiet libvirtd; then
        echo "Le service libvirt est actif."
    else
        echo "Erreur : Le service libvirt n'a pas pu être démarré."
        exit 1
    fi
}

# Installation de Pip3, Git et Btop
install_python_tools() {
    echo "Installation de Pip3, Git et Btop..."
    install_package "python-pip"
    install_package "git"
    install_package "btop"
}

# Configuration des dotfiles pour démarrer l'environnement de bureau choisi avec startx
configure_dotfiles() {
    echo "Configuration du fichier .xinitrc pour démarrer l'environnement de bureau..."
    case "$1" in
        "i3")
            echo "exec i3" > ~/.xinitrc
            ;;
        "fluxbox")
            echo "exec fluxbox" > ~/.xinitrc
            ;;
        "openbox")
            echo "exec openbox-session" > ~/.xinitrc
            ;;
        *)
            echo "Erreur : Environnement de bureau non reconnu."
            exit 1
            ;;
    esac

    chmod +x ~/.xinitrc
}

# Fonction principale pour tout installer
main() {
    check_internet
    update_system

    echo "Choisissez un environnement de bureau à installer (i3, fluxbox, openbox) : "
    read -r desktop_env

    install_graphics "$desktop_env"
    install_lightdm
    install_ssh
    install_kvm_qemu
    install_python_tools
    configure_dotfiles "$desktop_env"

    echo "Le système est configuré. Vous pouvez redémarrer pour appliquer les changements."
}

# Appel de la fonction principale
main
