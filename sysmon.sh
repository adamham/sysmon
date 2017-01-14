#!/bin/bash

# Menu driven bash script that manages:
#   - Install/uninstall of htop, iotop and dstat monitoring programs
#   - Start/kill a preconfigured tmux session
#   - Remove all files from server

# Requirements:
#   - apt/yum
#   - Passwordless sudo access

# Intended use:
#   Quickly deploy common monitoring tools to a server in need of debugging

# To copy files across, cd to where your sysmon directory is and run
#   tar -c sysmon | ssh <user@your_host> "tar -x"

# To run this script remotely
#   ssh -t <user@your_host> "~/sysmon/sysmon.sh"

export TERM=xterm

RED='\033[0;41;30m'
GREEN='\033[48;5;29m'
STD='\033[0;0;39m'

function set_pkg_mgr() {
  echo -n "Setting package manager... "
  if [ -n "$(which apt-get 2> /dev/null)" ]; then
    PKG_MGR='apt'
    echo -e "${GREEN}done!${STD}"
    return
  elif [ -n "$(which yum 2> /dev/null)" ]; then
    PKG_MGR='yum'
    echo -e "${GREEN}done!${STD}"
    return
  else
    echo -e "${RED}no suitable package manager found!${STD}"
    exit 1
  fi
}

function install_tools() {
  echo -n "Installing monitoring tools..."
  if [[ "${PKG_MGR}" == "apt" ]]; then
    sudo apt-get install -y tmux htop dstat iotop
  elif [[ "${PKG_MGR}" == "yum" ]]; then
    sudo yum install -y tmux htop dstat iotop
  fi
  echo -e "${GREEN}done!${STD}"
  sleep 1
}

function check_privilege() {
  sudo -n true && echo "success!"; return
  echo -e "\n${RED}This must be run with sudo access${STD}"
  exit 1
}

function tmux_session() {
  if [ $1 == "start" ]; then
    # Mouse mode changed in 2.1
    TMUX_VER=$(tmux -V | cut -d' ' -f2)
    [ ${TMUX_VER}'<'2.1 | bc -l ] && tmux set -g mode-mouse on \; set -f mouse-select-pane onf || tmux set -g mouse on

    tmux -f ~/sysmon/sysmon.conf a -t sysmon
  elif [ $1 == "destroy" ]; then
    tmux kill-session -t sysmon 2> /dev/null
    if [ $? -eq 0 ]; then
      echo -e "\n${GREEN}Session destroyed${STD}"
      sleep 1
    else
      echo -e "\n${RED}No session exists${STD}"
      sleep 1
    fi
  fi
}

function uninstall() {
  echo -n "Removing packages and files..."
  if [[ "${PKG_MGR}" == "apt" ]]; then
    sudo apt-get remove -y tmux htop dstat iotop && rm -rf ~/sysmon/
  elif [[ "${PKG_MGR}" == "yum" ]]; then
    sudo yum remove -y tmux htop dstat iotop && rm -rf ~/sysmon/
  fi
  echo "done!"

}
function show_menus() {
	clear
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo "   SYSMON"
	echo "~~~~~~~~~~~~~~~~~~~~"
	echo "1. Install tools and run session"
  echo "2. Run/reattach the tmux session"
  echo "3. Destroy the tmux session"
	echo "4. Remove everything"
  echo "5. Quit/logout"
  echo
}

function read_options(){
  local choice
  read -p "What to do? (1-5) " choice
  case $choice in
  	1) set_pkg_mgr && install_tools && tmux_session start;;
    2) tmux_session start;;
  	3) tmux_session destroy;;
    4) set_pkg_mgr && uninstall && exit;;
    5) exit;;
  	*) echo -e "\n${RED}Error...${STD}" && sleep 2
  esac
}

trap '' SIGINT SIGQUIT SIGTSTP

check_privilege

while true
do
  show_menus
  read_options
done
