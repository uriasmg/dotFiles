#!/usr/bin/env bash

declare -A install_decisions

install_common_packages() {
  echo "(re)Installing common packages (curl pass, gcc, stow...) ..."
  sudo apt update >/dev/null 2>&1
  sudo apt install curl gnupg gcc pass unzip stow ca-certificates python3 g++ make -y >/dev/null 2>&1 && echo "Common packages installed" || echo "Failed to install common packages."
}

install_ansible() {
  echo "Installing ansible..."
  sudo apt install software-properties-common ansible -y >/dev/null 2>&1 && echo "Ansible packages installed" || echo "Failed to install ansible packages."
}

add_ansiblerepo() {
  echo "Adding ansible repos..."
  sudo apt-add-repository --yes --update ppa:ansible/ansible
  sudo apt update >/dev/null 2>&1
}

add_gitrepo() {
  echo "Adding git repos..."
  sudo add-apt-repository ppa:git-core/ppa -y
  sudo apt update >/dev/null 2>&1
}

install_git() {
  echo "Installing git..."
  sudo apt install -y git >/dev/null 2>&1
}

add_sublimekeys() {
  echo "Adding sublime repos..."
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg >/dev/null
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  sudo apt update >/dev/null 2>&1
}

install_sublime() {
  echo "Installing sublime (nice for BIG files)..."
  sudo apt install -y sublime-text >/dev/null 2>&1
}

install_catppuccin_gnome_terminal() {
  echo "Installing catppuccin gnome terminal theme..."
  curl -L https://raw.githubusercontent.com/catppuccin/gnome-terminal/v0.2.0/install.py | python3 -
  rm install.py
}

install_tmux() {
  echo "Installing tmux..."
  sudo apt install -y tmux >/dev/null 2>&1
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

install_gparted() {
  echo "Installing gparted..."
  sudo apt install -y gparted >/dev/null 2>&1
}

install_docker() {
  sudo apt update
  echo "Installing docker..."
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y >/dev/null 2>&1
}

install_node() {
  read -p "Which version of node you want to install (20 is LTS): " choice
  NODE_CHOICE=$choice
  sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  nvm --install $NODE_CHOICE
}

add_dockerkeys() {
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt remove $pkg; done

  sudo install -m 0755 -d /etc/apt/keyrings >/dev/null 2>&1
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
}

install_gitcredentialmanager() {
  echo "Installing git credential manager..."
  curl -LO https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.3.2/gcm-linux_amd64.2.3.2.tar.gz
  sudo tar -xvf gcm-linux_amd64.2.3.2.tar.gz -C /usr/local/bin
  git-credential-manager configure
  rm gcm-linux_amd64.2.3.2.tar.gz
}

install_neovim() {
  echo "Installing neovim..."
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf nvim-linux64.tar.gz

  export PATH="$PATH:/opt/nvim-linux64/bin"

  sudo apt install ripgrep fd-find -y
  pip3 install neovim
  npm i -g neovim
}

install_nerdfonts() {
  if [ "$env_choice" == "Linux" ]; then
    echo "Installing my nerdfont 99mb, be patient)..."
    curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
    # mkdir ~/.fonts
    sudo mkdir -p /usr/share/fonts/truetype/JetBrainsMono
    sudo unzip -o JetBrainsMono.zip -d /usr/share/fonts/truetype/JetBrainsMono/
    sudo fc-cache -f -v
    rm ./JetBrainsMono.zip
  fi
}

install_lazygit() {
  echo "Installing lazygit..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  if ! curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"; then
    echo "Failed to download the 'teste' package."
    return 1
  fi
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  rm lazygit.tar.gz
  rm lazygit
}

prompt_to_go_on() {
  read -p "Do you want to go on? (y/n): " choice
  if [ "$choice" == "n" ]; then
    exit 1
  fi
}

prompt_for_installation() {
  local pkg="$1"

  read -p "Do you want to install $pkg? (y/n): " choice
  if [ "$choice" == "y" ]; then
    install_decisions["$pkg"]=1
  fi
}

prompt_for_stow() {
  read -p "Do you want to stow your files(y/n): " choice
  if [ "$choice" == "y" ]; then
    # create a tmux session, install their plugins before stowing the files
    # otherwise it will bug the catpuccin installation
    echo "Installing tmux plugins beforehand..."
    mv ~/.tmux.conf ~/.tmux.conf.bak && echo "backing up tmux conf" || echo "no previous tmux conf founded"
    tmux source ~/.tmux.conf
    tmux new-session -d -s temp-session
    tmux send-keys -t temp-session 'C-b I' C-m
    # wait for the install to be completed...
    # a more naive approach:
    sleep 10
    # a more complex approach:
    # tmux send-keys -t temp-session 'tmux wait-for -S install_done' C-m
    # tmux wait-for install_done
    tmux kill-session -t temp-session

    stow -t ~ */
  fi
}

prompt_for_gcmconfig() {
  read -p "Do you want to set GCM (y/n): " choice
  if [ "$choice" == "y" ]; then
    if [ "$env_choice" == "WSL" ]; then
      git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
    else
      git config --global credential.credentialStore gpg
      gpg --gen-key
    fi
  fi
}

detect_environment() {
  if uname -a | grep -qi "microsoft"; then
    echo "WSL"
  else
    echo "Linux"
  fi
}

main() {
  echo "###################################"
  echo "#   MySurgicalToolbox             #"
  echo "#   Müller Urias                  #"
  echo "#   contato@drmuller.com.br       #"
  echo "###################################"

  env_choice=$(detect_environment)

  if [ "$env_choice" == "WSL" ]; then
    echo "Smells like WSL..."
    echo "It will be easier to install Git on windows to use GCM, ok?"
    echo "I also suggest you to install docker desktop in your windows host"
    echo "Oh, BTW, set up a nerdFont for this terminal!"
  elif [ "$env_choice" == "Linux" ]; then
    echo "Detected environment: Linux (even Mac is maybe ok here...)"
  else
    echo "Did not understand... Bye!"
    exit 1
  fi

  prompt_to_go_on

  prompt_for_installation "git"
  prompt_for_installation "git-credential-manager"
  prompt_for_installation "tmux"
  prompt_for_installation "neovim"
  prompt_for_installation "ansible"
  prompt_for_installation "node"
  if [ "$env_choice" == "Linux" ]; then
    prompt_for_installation "docker"
    prompt_for_installation "gparted"
    prompt_for_installation "catppuccin"
    prompt_for_installation "sublime"
  fi

  # Install my beloved packages
  echo "Installing selected packages..."
  install_common_packages

  for pkg in "${!install_decisions[@]}"; do
    case "$pkg" in
    "ansible")
      add_ansiblerepo
      install_ansible
      ;;
    "git")
      add_gitrepo
      install_git
      ;;
    "tmux")
      install_tmux
      ;;
    "git-credential-manager")
      install_gitcredentialmanager
      ;;
    "gparted")
      install_gparted
      ;;
    "node")
      install_node
      ;;
    "neovim")
      install_neovim
      install_nerdfonts
      install_lazygit
      ;;
    "docker")
      add_dockerkeys
      install_docker
      ;;
    "sublime")
      add_sublimekeys
      install_sublime
      ;;
    "catppuccin")
      install_catppuccin_gnome_terminal
      ;;
    esac
  done

  prompt_for_stow
  prompt_for_gcmconfig

  echo "Installation process complete."
  echo "Run pass init <gpg-id> to finish the config"
}

main
