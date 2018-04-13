#!/bin/bash

## Global variables
os="$( awk -F '=' '/^ID=/ {print $2}' /etc/os-release 2>&- )"

if [ "${os}" == "arch" ] \
|| [ "${os}" == "blackarch" ] \
|| [ "${os}" == "debian" ] \
|| [ "${os}" == "deepin" ] \
|| [ "${os}" == "elementary" ] \
|| [ "${os}" == "kali" ] \
|| [ "${os}" == "linuxmint" ] \
|| [ "${os}" == "ubuntu" ]; then
  trueuser="$( who | tr -d '\n' | cut -d' ' -f1 )"
else
  ## If this is blank, we're actually root
  trueuser="$( who am i | cut -d' ' -f1 )"
fi

## If this is blank, we're actually root
if [ "${trueuser}" == "" ]; then
  trueuser="root"
fi

if [ "${trueuser}" != "root" ]; then
  userhomedir="$( echo /home/${trueuser} )"
else
  userhomedir="${HOME}"
fi

arch="$( uname -m )"
nukewinedir=""
silent=false
force=false
osversion="$( awk -F '=' '/^VERSION_ID=/ {print $2}' /etc/os-release 2>&- )"
arg=""
errors=""
veildir="/opt/veil"
outputdir="${veildir}/output"
dependenciesdir="${veildir}/setup-dependencies"
runuser="$( whoami )"
userprimarygroup="$( id -Gn "${trueuser}" | cut -d' ' -f1 )"
rootdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )
winedir="${veildir}/wine/veil"
winedrive="${winedir}/drive_c"
gempath="${winedir}\drive_c\Ruby187\bin\gem"
replace="\\"
prefix="Z:"
gempath=${gempath////$replace}
gempath=${prefix}${gempath}

BOLD="\033[01;01m"     # Highlight
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RESET="\033[00m"       # Normal


########################################################################


## Title function
func_title(){
  ## Echo title
  echo " =========================================================================="
  echo "                  Veil (Setup Script) | [Updated]: 2018-04-02"
  echo " =========================================================================="
  echo "  [Web]: https://www.veil-framework.com/ | [Twitter]: @VeilFramework"
  echo " =========================================================================="
  echo ""
  #echo "Debug:          winedir = ${winedir}"
  #echo "Debug:        winedrive = ${winedrive}"
  #echo "Debug:      userhomedir = ${HOME}"
  #echo "Debug:          rootdir = ${rootdir}"
  #echo "Debug:          veildir = ${veildir}"
  #echo "Debug:  dependenciesdir = ${dependenciesdir}"
  #echo "Debug:         trueuser = ${trueuser}"
  #echo "Debug: userprimarygroup = ${userprimarygroup}"
  #echo "Debug:               os = ${os}"
  #echo "Debug:        osversion = ${osversion}"
  #echo ""
}


## Trap CTRl-C
function ctrl_c(){
  echo -e "\n\n${RED}Quitting...${RESET}\n"
  exit 2
}


## Environment checks
func_check_env(){
  ## Check sudo dependency
  which sudo >/dev/null 2>&-
  if [ "$?" -ne "0" ]; then
    echo ""
    echo -e " ${RED}[ERROR]: This setup script requires sudo!${RESET}"
    echo -e " ${YELLOW}         Please install and configure sudo then run this setup again.${RESET}"
    echo -e " ${YELLOW}         Example: For Debian/Ubuntu: apt-get -y install sudo${RESET}"
    echo -e " ${YELLOW}                  For Fedora 22+: dnf -y install sudo${RESET}"
    exit 1
  fi


  ## Feedback to user
  [ "${silent}" == "true" ] && echo -e " [I] ${YELLOW}Silent Mode${RESET}: ${GREEN}Enabled${RESET}"
  [ "${force}" == "true" ] &&  echo -e " [I]  ${YELLOW}Force Mode${RESET}: ${GREEN}Enabled${RESET}"


  ## Double check install (if not silent)
  echo -e "\n\n [?] ${BOLD}Are you sure you wish to install Veil?${RESET}\n"
  echo -en "     Continue with installation? ([${BOLD}y${RESET}]es/[${BOLD}s${RESET}]ilent/[${BOLD}N${RESET}]o): "
  if [ "${silent}" == "true" ]; then
    echo -e "${GREEN}S${RESET}\n"
  else
    read -p '' install
    install=$(echo "${install}" | tr '[:upper:]' '[:lower:]')
    echo

    if [ "${install}" == 's' ] \
    || [ "${install}" == 'silent' ]; then
      silent=true
    elif [ "${install}" != 'y' ] \
    && [ "${install}" != 'yes' ]; then
      echo -e "\n\n ${RED}[ERROR]: Installation aborted by user${RESET}\n"
      exit 1
    fi
  fi


  ## Make sure Metasploit framework is already installed
  if [ "${os}" != "kali" ] \
  || [ "${os}" == "parrot" ] \
  && [ "${silent}" == false ]; then
    echo -e "\n\n ${BOLD}[!] NON-KALI Users: Before you begin the install, make sure that you have"
    echo -e "     the Metasploit-Framework installed before you proceed!${RESET}\n"
    echo -en "     Continue with installation? ([${BOLD}Y${RESET}]es/[${BOLD}n${RESET}]o): "

    read -p '' install
    install=$(echo "${install}" | tr '[:upper:]' '[:lower:]')
    echo

    if [ "${install}" == 'n' ] \
    || [ "${install}" == 'no' ]; then
      echo -e "\n\n ${RED}[ERROR]: Installation aborted by user${RESET}\n"
      exit 1
    fi
  fi


  ## Install architecture dependent dependencies
  func_package_deps


  ## Check if (Wine) Python is already installed
  if [ "${force}" == "false" ] \
  && [ -f "${winedrive}/Python34/python.exe" ] \
  && [ -f "${winedrive}/Python34/DLLs/python3.dll" ] \
  && [ -f "${winedrive}/Python34/Lib/site-packages/win32/win32api.pyd" ]; then
    echo -e "\n\n [*] ${YELLOW}(Wine) Python is already installed... Skipping...${RESET}\n"
  else
    func_python_deps
  fi


  ## Check if (Wine) Ruby is already installed
  if [ "${force}" == "false" ] \
  && [ -f "${winedrive}/Ruby187/bin/ruby.exe" ] \
  && [ -d "${winedrive}/Ruby187/lib/ruby/gems/1.8/gems/win32-api-1.4.8-x86-mingw32/lib/win32/" ]; then
    echo -e "\n\n [*] ${YELLOW}(Wine) Ruby is already installed... Skipping...${RESET}\n"
  else
    func_ruby_deps
  fi


  ## Check if go is installed
  if [ "${force}" == "false" ] \
  && [ -f "/usr/src/go/bin/windows_386/go.exe" ]; then
    echo -e "\n\n [*] ${YELLOW}Go is already installed... Skipping...${RESET}\n"
  else
    func_go_deps
  fi


  ## Check if autoit is installed
  if [ "${force}" == "false" ] \
  && [ -f "${winedrive}/Program Files/AutoIt3/AutoIt3.exe" ]; then
    echo -e "\n\n [*] ${YELLOW}AutoIt is already installed... Skipping...${RESET}\n"
  else
    func_autoit_deps
  fi


  ## Finally, update the config
  if [ "${force}" == "false" ] \
  && [ -f "/etc/veil/settings.py" ] \
  && [ -d "${outputdir}" ]; then
    echo -e "\n\n [*] ${YELLOW}Setttings already detected... Skipping...${RESET}\n"
  else
    func_update_config
  fi


  ## Function done
  echo -e "\n\n [*] ${YELLOW}Finished environment checks${RESET}\n"
}


## Install architecture dependent dependencies
func_package_deps(){
  echo -e "\n\n [*] ${YELLOW}Initializing package installation${RESET}\n"


  ## Clone down the required install files
  echo -e "\n\n [*] ${YELLOW}Pulling down binary dependencies${RESET}\n"
  ## Pulling down from github, if it fails, pull local folder
  if [ -d "${dependenciesdir}" ]; then
    echo -e " [*] ${YELLOW}Already detected folder: ${BOLD}${dependenciesdir}${RESET}\n"
    echo -e " [*] ${YELLOW}Trying to git pull${RESET}\n"
    pushd "${dependenciesdir}" >/dev/null
    sudo git reset --hard HEAD >/dev/null
    sudo git clean -fd >/dev/null
    sudo git pull \
      || echo -e "${RED}[ERROR]: Failed with git pull (1)\n${RESET}\n"
    popd >/dev/null
  else
    echo -e " [*] ${YELLOW}Empty folder... git cloning${RESET}\n"
    sudo mkdir -p "${dependenciesdir}"
    sudo rm -rf "${dependenciesdir}"
    sudo git clone https://github.com/Veil-Framework/VeilDependencies.git "${dependenciesdir}" \
      || echo -e "${RED}[ERROR]: Failed with git clone (1)\n${RESET}\n"
  fi


  ## Begin Wine install for multiple architectures
  ## Always install 32-bit support for 64-bit architectures
  ## <wine>
  echo -e "\n\n [*] ${YELLOW}Installing Wine${RESET}\n"


  ## Debian based distributions
  if [ "${os}" == "ubuntu" ] \
  || [ "${os}" == "debian" ] \
  || [ "${os}" == "kali" ] \
  || [ "${os}" == "parrot" ] \
  || [ "${os}" == "deepin" ] \
  || [ "${os}" == "linuxmint" ]; then
    [ "${silent}" == "true" ] \
      && arg=" DEBIAN_FRONTEND=noninteractive" \
      || arg=""

    if [ "${arch}" == "x86_64" ]; then
      echo -e "\n\n [*] ${YELLOW}Adding x86 architecture to x86_64 system for Wine${RESET}\n"
      sudo dpkg --add-architecture i386
      sudo apt-get -qq update \
        || echo -e "${RED}[ERROR]: Failed with apt-get update (1)\n${RESET}\n"

      echo -e "\n\n [*] ${YELLOW}Installing Wine 32-bit and 64-bit binaries (via APT)${RESET}\n"
      if [ "${os}" == "ubuntu" ] \
      || [ "${os}" == "linuxmint" ]; then
        ## Special urghbuntu derivative snowflakes
        sudo ${arg} apt-get -y -qq install wine-stable \
          || echo -e "${RED}[ERROR]: Failed with apt-get install wine (1)\n${RESET}\n"
      else
        ## anything that isn't ubuntu or ubuntu-derived
        sudo ${arg} apt-get -y -qq install wine wine64 wine32 \
          || echo -e "${RED}[ERROR]: Failed with apt-get install wine (2)\n${RESET}\n"
      fi
      tmp="$?"
      if [ "${tmp}" -ne "0" ]; then
        msg="Failed to install Wine... Exit code: ${tmp}"
        errors="${errors}\n${msg}"
        echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
      fi
    elif [ "${arch}" == "x86" ] \
    || [ "${arch}" == "i686" ]; then
      sudo apt-get -qq update \
        || echo -e "${RED}[ERROR]: Failed with apt-get update (2)\n${RESET}\n"
      sudo ${arg} apt-get -y -qq install wine32 \
        || echo -e "${RED}[ERROR]: Failed with apt-get install wine (3)\n${RESET}\n"
      tmp="$?"
      if [ "${tmp}" -ne "0" ]; then
        msg="Failed to install Wine... Exit code: ${tmp}"
        errors="${errors}\n${msg}"
        echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
      fi
    else
      ## Dead code. We really shouldn't end up here, but, you never know...
      echo -e "${RED}[ERROR]: Architecture ${arch} is not supported!\n${RESET}\n"
      exit 1
    fi

  ## Elementary OS x86_64
  elif [ "${os}" == '"elementary"' ]; then
    echo -e "\n\n [*] ${YELLOW}Installing Wine on Elementary OS (via APT)${RESET}\n"
    sudo ${arg} apt-get -y -qq install wine wine1.6 wine1.6-amd64 \
      || echo -e "${RED}[ERROR]: Failed with apt-get install wine (4)\n${RESET}\n"
    tmp="$?"
    if [ "${tmp}" -ne "0" ]; then
      msg="Failed to install Wine in Elementary OS... Exit code: ${tmp}"
      errors="${errors}\n${msg}"
      echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
    fi

  ## Red Hat based distributions
  elif [ "${os}" == "fedora" ] \
  || [ "${os}" == "rhel" ] \
  || [ "${os}" == "centos" ]; then
    echo -e "\n\n [*] ${YELLOW}Installing Wine 32-bit on x86_64 System (via DNF)${RESET}\n"
    sudo dnf install -y wine.i686 wine
    tmp="$?"
    if [ "${tmp}" -ne "0" ]; then
      msg="Failed to install Wine x86_64... Exit code: ${tmp}"
      errors="${errors}\n${msg}"
      echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
    fi
  elif [ "${os}" == "arch" ] \
  || [ "${os}" == "blackarch" ]; then
    echo -e "\n\n [*] ${YELLOW}Installing Wine 32-bit on x86_64 System (via PACMAN)${RESET}\n"
    if grep -Fxq "#[multilib]" /etc/pacman.conf; then
      echo "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
    fi

    sudo pacman -Syu ${args} --needed --noconfirm wine wine-mono wine_gecko git
    tmp="$?"
    if [ "${tmp}" -ne "0" ]; then
      msg="Failed to install Wine x86_64... Exit code: ${tmp}"
      errors="${errors}\n${msg}"
      echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
    fi
  fi
  ## </wine>


  ## Setup Wine prefices
  ## Because Veil currently only supports Win32 binaries, we have to set the WINEARCH PREFIX
  ## to use Win32. This is a potential issue for the future when Veil has windows 64-bit
  ## binary support. To get around this in setup and somewhat future proof for that eventuality,
  ## we're already going to look for an existing veil wine setup (~/.config/veil/) and nuke it
  ## making it easy for a user to rerun the setup and have a new wine environment.
  if [ -d "${winedir}" ]; then
    echo -e "\n\n [*] ${RED}[ALERT]: Existing Veil Wine environment detected at: ${BOLD}${winedir}${RESET}\n"
    echo -en "     Do you want to nuke it? ([${BOLD}y${RESET}]es/[${BOLD}N${RESET}]o): "
    if [ "${silent}" == "true" ]; then
      echo -e "${GREEN}Y${RESET}\n"
    else
      read -p '' nukewinedir
      nukewinedir=$(echo "${nukewinedir}" | tr '[:upper:]' '[:lower:]')
      echo
    fi

    if [ "${nukewinedir}" == 'y' ] \
    || [ "${nukewinedir}" == 'yes' ] \
    || [ "${silent}" == 'true' ]; then
      echo -e " [*] ${YELLOW}Deleting existing Veil Wine environment...${RESET}\n"
      sudo rm -rf "${winedir}"
    else
      echo -e " [*] ${YELLOW}Maintaining current Veil Wine environment...${RESET}\n"
    fi
  fi


  ## For creating wine environment on newer distros
  if [ -f "/usr/bin/wineboot" ]; then
    winebootexists=true
    sudo mkdir -p "${winedrive}/"
    sudo chown -R "${trueuser}:" "${winedir}"
  else
    winebootexists=false
  fi


  if [ ! -d "${winedir}" ] \
  || [ "${nukewinedir}" == 'y' ] \
  || [ "${nukewinedir}" == 'yes' ] \
  || [ "${silent}" == 'true' ]; then
    echo -e " [*] ${YELLOW}Creating new Veil Wine environment in: ${BOLD}${winedir}${RESET}\n"

    echo -e " [*] ${YELLOW}Initializing Veil's Wine environment...${RESET}\n"
    ## x64
    if [ "${arch}" == "x86_64" ]; then
      ## First time running wine, need to run a dummy file to create files
      [ "${winebootexists}" == "true" ] \
        && sudo -u "${trueuser}" WINEARCH=win32 WINEPREFIX="${winedir}" wineboot -u \
        || sudo -u "${trueuser}" WINEARCH=win32 WINEPREFIX="${winedir}" wine cmd.exe /c ipconfig >/dev/null
    ## x86
    elif [ "${arch}" == "x86" ] \
    || [ "${arch}" == "i686" ]; then
      sudo -u "${trueuser}" WINEPREFIX="${winedir}" wineboot -u
    fi

    if [ -d "${winedrive}" ]; then
      echo -e " [*] ${GREEN}Veil Wine environment successfully created!${RESET}\n"
    else
      msg="Veil Wine environment could not be found!"
      errors="${errors}\n${msg}"
      echo -e " ${RED}[ERROR] ${msg}${RESET}\n"

      msg="Check for existence of ${winedrive}"
      errors="${errors}\n${msg}"
      echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
    fi
  fi


  ## Start dependency install
  echo -e "\n\n [*] ${YELLOW}Installing dependencies${RESET}\n"
  if [ "${os}" == "debian" ] \
  || [ "${os}" == "kali" ] \
  || [ "${os}" == "parrot" ] \
  || [ "${os}" == "deepin" ] \
  || [ "${os}" == "linuxmint" ]; then
    #ttf-mscorefonts-installer
    sudo ${arg} apt-get -y install mingw-w64 monodevelop mono-mcs wine unzip ruby golang wget git \
      python python-crypto python-pefile python-pip ca-certificates python3-pip winbind \
        || echo -e "${RED}[ERROR]: Failed with apt-get install dependencies (1)\n${RESET}\n"

  elif [ "${os}" == "ubuntu" ]; then
    sudo ${arg} apt-get -y install mingw-w64 monodevelop mono-mcs wine-stable unzip ruby golang wget git \
      python python-crypto python-pefile python-pip ca-certificates python3-pip winbind \
        || echo -e "${RED}[ERROR]: Failed with apt-get install dependencies (1)\n${RESET}\n"

  elif [ "${os}" == '"elementary"' ]; then
    sudo ${arg} apt-get -y install mingw-w64 monodevelop mono-mcs wine unzip ruby golang wget git \
      python python-crypto python-pefile python-pip ca-certificates python3-pip winbind python3-crypto \
        || echo -e "${RED}[ERROR]: Failed with apt-get install dependencies (2)\n${RESET}\n"

  elif [ "${os}" == "fedora" ] \
  || [ "${os}" == "rhel" ] \
  || [ "${os}" == "centos" ]; then
    sudo ${arg} dnf -y install mingw64-binutils mingw64-cpp mingw64-gcc mingw64-gcc-c++ mono-tools-monodoc monodoc \
      monodevelop mono-tools mono-core wine unzip ruby golang wget git python python-crypto python-pefile \
      python-pip ca-certificates msttcore-fonts-installer python3-pip winbind \
        || echo -e "${RED}[ERROR]: Failed with apt-get install dependencies (3)\n${RESET}\n"

  elif [ "${os}" ==  "arch" ] \
  || [ "${os}" == "blackarch" ]; then
    sudo pacman -Sy ${arg} --needed mingw-w64-binutils mingw-w64-crt mingw-w64-gcc mingw-w64-headers mingw-w64-winpthreads \
      mono mono-tools mono-addins python2-pip wget unzip ruby python python2 python-crypto gcc-go ca-certificates base-devel python-pip krb5 samba \
        || echo -e "${RED}[ERROR]: Failed with apt-get install dependencies (4)\n${RESET}\n"
    ## Install pefile for python2 using pip, rather than via AUR as the package is currently broken.
    sudo pip2 install pefile \
        || echo -e "${RED}[ERROR]: Failed with pip2 install (1)\n${RESET}\n"
  fi
  tmp="$?"
  if [ "${tmp}" -ne "0" ]; then
    msg="Failed to install dependencies... Exit code: ${tmp}"
    errors="${errors}\n${msg}"
    echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
  fi


  if [ "${os}" == "kali" ] \
  || [ "${os}" == "parrot" ]; then
    sudo ${arg} apt-get -y install metasploit-framework python2.7 python3 python3-pycryptodome \
        || echo -e "${RED}[ERROR]: Failed with apt-get install dependencies (5)\n${RESET}\n"
    tmp="$?"
    if [ "${tmp}" -ne "0" ]; then
      msg="Failed to install dependencies (Metasploit-Framework/python2.7/python3/python3-pycryptodome)... Exit code: ${tmp}"
      errors="${errors}\n${msg}"
      echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
    fi
  fi

  ## Function done
  echo -e "\n\n [*] ${YELLOW}Finished package installation${RESET}\n"
}


## Install Python dependencies
func_python_deps(){
  ## Banner
  echo -e "\n\n [*] ${YELLOW}Initializing Python dependencies installation...${RESET}\n"

  ## Python (OS) - install-addons.sh
  ## In-case its 'First time run' for Wine (More information - http://wiki.winehq.org/Mono)
  #[[ "${silent}" == "true" ]] && bash "${dependenciesdir}/install-addons.sh"   #wget -qO - "http://winezeug.googlecode.com/svn/trunk/install-addons.sh"

  ## Install (Wine) Python main setup file
  echo -e "\n\n [*] ${YELLOW}Installing (Wine) Python...${RESET}\n"
  echo -e " [*] ${BOLD} Next -> Next -> Next -> Finished! ...Overwrite if prompt (use default values)${RESET}\n"
  sleep 1s

  [ "${silent}" == "true" ] \
    && arg=" TARGETDIR=C:\Python34 ALLUSERS=1 /q /norestart" \
    || arg=""
  sudo -u "${trueuser}" WINEPREFIX="${winedir}" wine msiexec /i "${dependenciesdir}/python-3.4.4.msi" ${arg}
  tmp="$?"
  if [ "${tmp}" -ne "0" ]; then
    msg="Failed to install (Wine) Python 3.4.4... Exit code: ${tmp}"
    errors="${errors}\n${msg}"
    echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
  fi

  ## If not kali or parrot, use pip to install
  if [ "${os}" != "kali" ] \
  && [ "${os}" != "parrot" ]; then
    echo -e "\n\n [*] ${YELLOW}Installing Python's pycrypto (via PIP3)...${RESET}\n"
    pip3 install pycrypto
  fi

  ## Cool down
  sleep 3s

  ## Banner
  echo -e "\n\n [*] ${YELLOW}Installing (Wine) Python dependencies...${RESET}\n"
  pushd "${dependenciesdir}/" >/dev/null

  ## Install (Wine) Python extra setup files (PyWin32 & PyCrypto)
  for FILE in pywin32-220.win32-py3.4.exe pycrypto-2.6.1.win32-py3.4.exe; do
    echo -e "\n\n [*] ${YELLOW}Installing (Wine) Python's ${FILE}...${RESET}\n"
    echo -e " [*] ${BOLD} Next -> Next -> Next -> Finished! ...Overwrite if prompt (use default values)${RESET}\n"
    sleep 1s

    if [ "${silent}" == "true" ]; then
      ## Start fresh
      sudo rm -rf "PLATLIB/" "SCRIPTS/"
      ## Extract
      sudo unzip -q -o "${FILE}"
      ## Copy files to right location
      [ -e "PLATLIB" ] && sudo -u "${trueuser}" cp -rf PLATLIB/* "${winedrive}/Python34/Lib/site-packages/"
      [ -e "SCRIPTS" ] && sudo -u "${trueuser}" cp -rf SCRIPTS/* "${winedrive}/Python34/Scripts/"
      ## Run post install file
      [ -e "SCRIPTS/pywin32_postinstall.py" ] && sudo -u "${trueuser}" WINEPREFIX="${winedir}" wine "${winedir}/drive_c/Python34/python.exe" "${winedrive}/Python34/Scripts/pywin32_postinstall.py" "-silent" "-quiet" "-install" >/dev/null
      ## Clean up
      sudo rm -rf "PLATLIB/" "SCRIPTS/"
    else
      sudo -u "${trueuser}" WINEPREFIX="${winedir}" wine "${FILE}"
      tmp="$?"
      if [ "${tmp}" -ne "0" ]; then
        msg="Failed to install ${FILE}... Exit code: ${tmp}"
        errors="${errors}\n${msg}"
        echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
      fi
    fi
  done

  popd >/dev/null

  ## Install Python (OS) extra setup files (PyInstaller)
  echo -e "\n\n [*] ${YELLOW}Installing Python's PyInstaller (via TAR)${RESET}\n"
  if [ "${force}" == "false" ] \
  && [ -f "${veildir}/PyInstaller-3.2.1/pyinstaller.py" ]; then
    echo -e "\n\n [*] ${YELLOW}PyInstaller v3.2 is already installed... Skipping...${RESET}\n"
  else
    ## Install PyInstaller now
    file="${dependenciesdir}/PyInstaller-3.2.1.tar"
    shasum="$( openssl dgst -sha256 "${file}" | cut -d' ' -f2 )"
    if [ "${shasum}" == "4727314ddf95bfe4aed28b3b98e0175d469a36aff5eb7e2af3c3d2fffd662d2d" ]; then
      sudo rm -rf "${veildir}/PyInstaller-*"
      sudo mkdir -p "${veildir}"
      sudo tar -C "${veildir}" -xf "${file}"
    else
      msg="Bad hash for PyInstaller.tar.gz!"
      errors="${errors}\n${msg}"
      echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
    fi
  fi

  ## Use wine based pip to install dependencies
  echo -e "\n\n [*] ${YELLOW}Installing (Wine) Python's PIP pefile${RESET}\n"
  sudo -u "${trueuser}" WINEPREFIX="${winedir}" wine "${winedir}/drive_c/Python34/python.exe" "-m" "pip" "install" "--upgrade" "pip"
  sudo -u "${trueuser}" WINEPREFIX="${winedir}" wine "${winedir}/drive_c/Python34/python.exe" "-m" "pip" "install" "future"
  sudo -u "${trueuser}" WINEPREFIX="${winedir}" wine "${winedir}/drive_c/Python34/python.exe" "-m" "pip" "install" "pefile"


  ## Function done
  echo -e "\n\n [*] ${YELLOW}Finished Python dependencies installation${RESET}\n"
}


## Install Go dependencies (Requires v1.2 or higher)
func_go_deps(){
  ## Download Go from source, cd into it, build it, and prep it for making windows payloads help for this setup came from:
  ## http://www.limitlessfx.com/cross-compile-golang-app-for-windows-from-linux.html

  echo -e "\n\n [*] ${YELLOW}Initializing Go installation...${RESET}\n"
  pushd "/tmp/" >/dev/null

  sudo mkdir -p /usr/src/go/

  if [ ! -f "/usr/src/go/bin/windows_386/go.exe" ]; then
    if [ "${arch}" == "x86_64" ]; then
      echo -e "\n\n [*] ${YELLOW}Installing Go x86_64 (via TAR)${RESET}\n"

      file="${dependenciesdir}/go1.7.5.linux-amd64.tar.gz"
      shasum="$( openssl dgst -sha256 "${file}" | cut -d' ' -f2 )"
      if [ "${shasum}" == "2e4dd6c44f0693bef4e7b46cc701513d74c3cc44f2419bf519d7868b12931ac3" ]; then
        sudo tar -C /usr/local -xf "${file}"
      else
        if [ "${tmp}" -ne "0" ]; then
          msg="Bad hash for go153x64.tar.gz!"
          errors="${errors}\n${msg}"
          echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
        fi
      fi
    elif [ "${arch}" == "x86" ] \
    || [ "${arch}" == "i686" ]; then
      echo -e "\n\n [*] ${YELLOW}Installing Go x86 (via TAR)${RESET}\n"

      file="${dependenciesdir}/go1.7.5.linux-386.tar.gz"
      shasum="$( openssl dgst -sha256 "${file}" | cut -d' ' -f2 )"
      if [ "${shasum}" == "432cb92ae656f6fe1fa96a981782ef5948438b6da6691423aae900918b1eb955" ]; then
        sudo tar -C /usr/local -xf "${file}"
      else
        if [ "${tmp}" -ne "0" ]; then
          msg="Bad hash for go153x86.tar.gz!"
          errors="${errors}\n${msg}"
          echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
        fi
      fi
    fi

    export GOROOT=/usr/local/go
    sudo rm -f /usr/bin/go
    sudo ln -s /usr/local/go/bin/go /usr/bin/go
  fi

  ## Done
  popd >/dev/null


  ## Function done
  echo -e "\n\n [*] ${YELLOW}Finished Go installation${RESET}\n"
}


func_autoit_deps(){
  echo -e "\n\n [*] ${YELLOW}Initializing AutoIT installation...${RESET}\n"

  echo -e "\n\n [*] ${YELLOW}Installing (Wine) AutoIT${RESET}\n"
  echo -e " [*] ${BOLD} Next -> Next -> Next -> Finished! ...Overwrite if prompt (use default values)${RESET}\n"
  sleep 1s

  [ "${silent}" == "true" ] \
    && arg=" /S" \
    || arg=""
  sudo -u "${trueuser}" WINEPREFIX="${winedir}" wine "${dependenciesdir}/autoit-v3-setup.exe" ${arg}


  ## Function done
  echo -e "\n\n [*] ${YELLOW}Finished AutoIT installation${RESET}\n"
}


## Install (Wine) Ruby dependencies
func_ruby_deps(){
  echo -e "\n\n [*] ${YELLOW}Initializing (Wine) Ruby installation...${RESET}\n"

  pushd "${dependenciesdir}/" >/dev/null

  ## Install Ruby under Wine
  echo -e "\n\n [*] ${YELLOW}Installing (Wine) Ruby & dependencies${RESET}\n"
  echo -e " [*] ${BOLD} Next -> Next -> Next -> Finished! ...Overwrite if prompt (use default values)${RESET}\n"
  sleep 1s

  sudo -u "${trueuser}" mkdir -p "${winedrive}/Ruby187/lib/ruby/gems/1.8/"

  [ "${silent}" == "true" ] \
    && arg=" /silent" \
    || arg=""
  sudo -u "${trueuser}" WINEPREFIX="${winedir}" wine "${dependenciesdir}/rubyinstaller-1.8.7-p371.exe" ${arg}
  tmp="$?"
  if [ "${tmp}" -ne "0" ]; then
    msg="Failed to install (Wine) Ruby.exe... Exit code: ${tmp}"
    errors="${errors}\n${msg}"
    echo -e " ${RED}[ERROR] ${msg}${RESET}\n"
  fi

  ## Install the OCRA Gem under Wine
  echo -e "\n\n [*] ${YELLOW}Installing (Wine) Ruby OCRA gem...${RESET}\n"
  ## Write batch script to disk
  echo "${gempath} install --force --local ocra-1.3.6.gem" > /tmp/ocrainstall.bat
  sudo -u "${trueuser}" WINEPREFIX="${winedir}" wine cmd /c /tmp/ocrainstall.bat

  ## Unzip the Ruby dependencies
  echo -e "\n\n [*] ${YELLOW}Extracting (Wine) Ruby dependencies...${RESET}\n"
  sudo -u "${trueuser}" unzip -q -o -d "${winedrive}/Ruby187/lib/ruby/gems/1.8/" "${dependenciesdir}/ruby_gems-1.8.zip"

  popd >/dev/null


  ## Function done
  echo -e "\n\n [*] ${YELLOW}Finished Ruby installation${RESET}\n"
}


## Update Veil config
func_update_config(){
  echo -e "\n\n [*] ${YELLOW}Updating Veil configuration...${RESET}\n"
  cd "${rootdir}/config/"

  ## SUDOINCEPTION! (There is method behind the, at first glance, madness)
  ## The SUDO_USER environment variable of the actual user doesn't get passed on to the python interpreter properly,
  ## so when we call "sudo python update-config.py", it thinks the user calling it, it's interpretation of SUDO_USER is root,
  ## and that's not what we want. Look at this fake process tree with what the env variables would be...
  ##    - |_ sudo setup.sh (${USER}=root ${SUDO_USER}=yourname)
  ##      - | sudo -u yourname sudo python update-config.py (${USER}=root ${SUDO_USER}=yourname)
  ## snip 8<-  -  -  -  -  -  -  -  -  -  -  -  -  - The alternative below without "sudo -u username"...
  ##      - | sudo python update-config.py (${USER}=root ${SUDO_USER}=root)
  ## snip 8<-  -  -  -  -  -  -  -  -  -  -  -  -  - And thus it would have screwed up the ${winedir} dir for the user.
  if [ -f /etc/veil/settings.py ]; then
    echo -e "\n\n [*] ${YELLOW}Detected current Veil settings file. Removing...${RESET}\n"
    sudo rm -f /etc/veil/settings.py
  fi
  sudo -u "${trueuser}" sudo python2 update-config.py

  sudo mkdir -p "${outputdir}"

  ## Chown output directory
  if [ -d "${outputdir}" ]; then
    echo -e "\n\n [*] ${YELLOW}Ensuring this account (${trueuser}) owns veil output directory (${outputdir})...${RESET}\n"
    sudo chown -R "${trueuser}" "${outputdir}"
  else
    echo -e " ${RED}[ERROR] Internal Issue. Couldn't create output folder...${RESET}\n"
  fi

  ## Ensure that user completely owns the wine directory
  echo -e " [*] ${YELLOW}Ensuring this account (${trueuser}) has correct ownership of ${winedir}${RESET}\n"
  sudo chown -R "${trueuser}":"${userprimarygroup}" "${winedir}"


  ## Function done
  echo -e "\n\n [*] ${YELLOW}Finished Veil configuration...${RESET}\n"
}

########################################################################


## Print banner
func_title


## Check architecture
if [ "${arch}" != "x86" ] \
&& [ "${arch}" != "i686" ] \
&& [ "${arch}" != "x86_64" ]; then
  echo -e " ${RED}[ERROR] Your architecture ${arch} is not supported!${RESET}\n\n"
  exit 1
fi


## Check OS
if [ "${os}" == "kali" ]; then
  echo -e " [I] ${YELLOW}Kali Linux ${osversion} ${arch} detected...${RESET}\n"
elif [ "${os}" == "parrot" ]; then
  echo -e " [I] ${YELLOW}Parrot Security ${osversion} ${arch} detected...${RESET}\n"
elif [ "${os}" == "ubuntu" ]; then
  version="$( awk -F '["=]' '/^VERSION_ID=/ {print $3}' /etc/os-release 2>&- | cut -d'.' -f1 )"
  echo -e " [I] ${YELLOW}Ubuntu ${osversion} ${arch} detected...${RESET}\n"
  if [[ "${osversion}" -lt "15" ]]; then
    echo -e " ${RED}[ERROR]: Veil is only supported On Ubuntu 15.10 or higher!${RESET}\n"
    exit 1
  fi
elif [ "${os}" == "linuxmint" ]; then
  version="$( awk -F '["=]' '/^VERSION_ID=/ {print $3}' /etc/os-release 2>&- | cut -d'.' -f1 )"
  echo -e " [I] ${YELLOW}Linux Mint ${osversion} ${arch} detected...${RESET}\n"
elif [ "${os}" == "deepin" ]; then
  version="$( awk -F '["=]' '/^VERSION_ID=/ {print $3}' /etc/os-release 2>&- | cut -d'.' -f1 )"
  echo -e " [I] ${YELLOW}Deepin ${osversion} ${arch} detected...${RESET}\n"
  if [[ "${osversion}" -lt "15" ]]; then
    echo -e " ${RED}[ERROR]: Veil is only supported On Deepin 15 or higher!${RESET}\n"
    exit 1
  fi
elif [ "${os}" == '"elementary"' ]; then
  echo -e " [I] ${YELLOW}Elementary OS ${osversion} ${arch} detected...${RESET}\n"
elif [ "${os}" == "debian" ]; then
  version="$( awk -F '["=]' '/^VERSION_ID=/ {print $3}' /etc/os-release 2>&- | cut -d'.' -f1 )"
  if [[ "${osversion}" -lt "8" ]]; then
    echo -e " ${RED}[ERROR]: Veil is only supported on Debian 8 (Jessie) or higher!${RESET}\n"
    exit 1
  fi
elif [ "${os}" == "fedora" ]; then
  echo -e " [I] ${YELLOW}Fedora ${osversion} ${arch} detected...${RESET}\n"
  if [[ "${osversion}" -lt "22" ]]; then
    echo -e " ${RED}[ERROR]: Veil is only supported on Fedora 22 or higher!${RESET}\n"
    exit 1
  fi
else
  os="$( awk -F '["=]' '/^ID=/ {print $2}' /etc/os-release 2>&- | cut -d'.' -f1 )"
  if [ "${os}" == "arch" ]; then
    echo -e " [I] ${YELLOW}Arch Linux ${arch} detected...${RESET}\n"
  elif [ "${os}" == "blackarch" ]; then
    echo -e " [I] ${RED}BlackArch Linux ${arch} detected...${RESET}\n"
  elif [ "${os}" == "debian" ]; then
    echo -e " [!] ${RED}Debian Linux sid/TESTING ${arch} *possibly* detected..."
    echo -e "     If you are not currently running Debian Testing, you should exit this installer!${RESET}\n"
  else
    echo -e " ${RED}[ERROR] Unable to determine OS information. Exiting...${RESET}\n"
    exit 1
  fi
fi


## Trap ctrl-c
trap ctrl_c INT


## Menu case statement
while [[ "${#}" -gt 0 && ."${1}" == .-* ]]; do
  opt="${1}";
  shift;
  case "$(echo ${opt} | tr '[:upper:]' '[:lower:]')" in
    ## Make sure not to nag the user
    -s|--silent)
    silent=true
    ;;

    ## Force clean install of (Wine) Python dependencies
    ## Bypass environment checks (func_check_env) to force install dependencies
    -f|--force)
    force=true
    ;;

    ## Print help menu
    -h|--help)
    echo ""
    echo "  [Usage]....: ${0} [OPTIONAL]"
    echo "  [Optional].:"
    echo "               -f|--force    = Force install of any dependencies"
    echo "               -s|--silent   = Automates the installation"
    echo "               -h|--help     = Show this help menu"
    echo ""
    exit 0
    ;;

    ## Run standard setup
    "")
    ;;

    *)
    echo -e "\n\n ${RED}[ERROR] Unknown option: ${BOLD}$1${RESET}\n"
    exit 1
    ;;
   esac
done


## Run setup, maybe with -f and/or -s
func_check_env


if [ "${errors}" != "" ]; then
  echo -e " ${RED}[ERROR] There was issues installing the following:${RESET}\n"
  echo -e " ${BOLD}${errors}${RESET}\n"
fi


file="./Veil.py --setup"
echo -e "\n\n [I] ${BOLD}If you have any errors${RESET} running Veil, run: '${BOLD}${file}' and select the nuke the wine folder option${RESET}\n"


echo -e "\n\n [I] ${GREEN}Done!${RESET}\n"
exit 0
