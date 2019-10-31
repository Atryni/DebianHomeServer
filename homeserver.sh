#!/usr/bin/env bash
# shellcheck disable=SC1090

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

if [ -z "${USER}" ]; then
  USER="$(id -un)"
fi

# This is a file used for the colorized output
coltable=/opt/homeServer/COL_TABLE

# This is an important file as it contains information specific to the machine it's being installed on
setupVars=/etc/homeServer/setupVars.conf
utilsListFile=/etc/homeServer/utilsListFile.list

# Find the rows and columns will default to 80x24 if it can not be detected
screen_size=$(stty size || printf '%d %d' 24 80)
# Set rows variable to contain first number
printf -v rows '%d' "${screen_size%% *}"
# Set columns variable to contain second number
printf -v columns '%d' "${screen_size##* }"

# Divide by two so the dialogs take up half of the screen, which looks nice.
r=$(( rows / 2 ))
c=$(( columns / 2 ))
# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
c=$(( c < 70 ? 70 : c ))

# If the color table file exists,
if [[ -f "${coltable}" ]]; then
    # source it
    source ${coltable}
# Otherwise,
else
    # Set these values so the installer can still run in color
    COL_NC='\e[0m' # No Color
    COL_LIGHT_GREEN='\e[1;32m'
    COL_LIGHT_RED='\e[1;31m'
    TICK="[${COL_LIGHT_GREEN}✓${COL_NC}]"
    CROSS="[${COL_LIGHT_RED}✗${COL_NC}]"
    INFO="[i]"
    # shellcheck disable=SC2034
    DONE="${COL_LIGHT_GREEN} done!${COL_NC}"
    OVER="\\r\\033[K"
fi


# A simple function that just echoes out our logo in ASCII format
show_ascii_logo() {
  echo -e "                                
${COL_LIGHT_GREEN}  _    _                         ${COL_LIGHT_RED}  _____                               ${COL_NC}
${COL_LIGHT_GREEN} | |  | |                        ${COL_LIGHT_RED} / ____|                              ${COL_NC}
${COL_LIGHT_GREEN} | |__| |  ___   _ __ ___    ___ ${COL_LIGHT_RED}| (___    ___  _ __ __   __ ___  _ __ ${COL_NC}
${COL_LIGHT_GREEN} |  __  | / _ \ | '_ \` _ \ /  _ \ ${COL_LIGHT_RED}\___ \  / _ \| '__|\ \ / // _ \| '__|${COL_NC}
${COL_LIGHT_GREEN} | |  | || (_) || | | | | ||  __/${COL_LIGHT_RED} ____) ||  __/| |    \ V /|  __/| |   ${COL_NC}
${COL_LIGHT_GREEN} |_|  |_| \___/ |_| |_| |_| \___|${COL_LIGHT_RED}|_____/  \___||_|     \_/  \___||_|   ${COL_NC}
"
}

is_command() {
    # Checks for existence of string passed in as only function argument.
    # Exit value of 0 when exists, 1 if not exists. Value is the result
    # of the `command` shell built-in call.
    local check_command="$1"

    command -v "${check_command}" >/dev/null 2>&1
}

# A function for displaying the dialogs the user sees when first running the installer
welcomeDialogs() {
    # Display the welcome dialog using an appropriately sized window via the calculation conducted earlier in the script
    whiptail --msgbox --title "HomeServer automated installer" "\\n\\nThis installer will transform your device into a local multi-util server!" ${r} ${c}

    # Request that users donate if they enjoy the software since we all work on it in our free time
    whiptail --msgbox --title "Free and open source" "\\n\\nThe HomeServer is free, but powered by your actions" ${r} ${c}
}


# Select, what util you want to install
chooseUtilsToInstall() {
    # Back up any existing adlist file, on the off chance that it exists. Useful in case of a reconfigure.
    if [[ -f "${utilsListFile}" ]]; then
        mv "${utilsListFile}" "${utilsListFile}.old"
    fi
    # Let user select (or not) utils to install via a checklist
    cmd=(whiptail --separate-output --checklist "Install third party libraries and touch that utils\\n" "${r}" "${c}" 7)
    # In an array, show the options available (all off by default):
    options=(
        Gogs        "Gogs [Private repository server]" off
        ownCloud    "ownCloud [Private NAS server]" off
        PiHole      "PiHole [DNS Ad's filter]" on
        WebMin      "WebMin [Administrative system panel]" on
    )

    # In a variable, show the choices available; exit if Cancel is selected
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty) || { printf "  %bCancel was selected, exiting installer%b\\n" "${COL_LIGHT_RED}" "${COL_NC}"; rm "${utilsListFile}" ;exit 1; }
    # For each choice available,
    for choice in ${choices}
    do
        appendToListsFile "${choice}"
    done
}

checkIfUserWantsDashboard(){
    # Similar to the logging function, ask what the user wants
    WebToggleCommand=(whiptail --separate-output --radiolist "Do you wish to install the Dashboard WWW interface?" ${r} ${c} 6)
    # with the default being enabled
    WebChooseOptions=("On (Recommended)" "" on
        "Off" "" off)
    WebChoices=$("${WebToggleCommand[@]}" "${WebChooseOptions[@]}" 2>&1 >/dev/tty) || (printf "  %bCancel was selected, exiting installer%b\\n" "${COL_LIGHT_RED}" "${COL_NC}" && exit 1)
    # Depending on their choice
    case ${WebChoices} in
        "On (Recommended)")
            printf "  %b Dashboard Interface On\\n" "${INFO}"
            appendToListsFile "Dashboard"
            # Set it to true
            INSTALL_DASHBOARD=true
            ;;
        "Off")
            printf "  %b Dashboard Interface Off\\n" "${INFO}"
            # or false
            INSTALL_DASHBOARD=false
            ;;
    esac
}

# Accept a string parameter, it must be one of the default lists
# This function allow to not duplicate code in chooseBlocklists and
# in installDefaultBlocklists
appendToListsFile() {
    case $1 in
        Gogs        )  echo "scripts/Gogs.sh" >> "${utilsListFile}";;
        ownCloud    )  echo "scripts/ownCloud.sh" >> "${utilsListFile}";;
        PiHole      )  echo "scripts/PiHole.sh" >> "${utilsListFile}";;
        WebMin      )  echo "scripts/WebMin.sh" >> "${utilsListFile}";;
        Dashboard   )  echo "scripts/Dashboard.sh" >> "${utilsListFile}";;
    esac
}

# Used only in unattended setup
# If there is already the utilsListFile, we keep it, else we create it using all default lists
installDefaultBlocklists() {
    # In unattended setup, could be useful to use userdefined blocklist.
    # If this file exists, we avoid overriding it.
    if [[ -f "${utilsListFile}" ]]; then
        return;
    fi
    appendToListsFile WebMin
}

distro_prepare_debian() {
    # Set some global variables here
    # We don't set them earlier since the family might be Red Hat, so these values would be different
    PKG_MANAGER="apt-get"
    # A variable to store the command used to update the package cache
    UPDATE_PKG_CACHE="${PKG_MANAGER} update"
    # An array for something...
    PKG_INSTALL=(${PKG_MANAGER} --yes --no-install-recommends install)
    # grep -c will return 1 retVal on 0 matches, block this throwing the set -e with an OR TRUE
    PKG_COUNT="${PKG_MANAGER} -s -o Debug::NoLocking=true upgrade | grep -c ^Inst || true"
    
    # Since our install script is so large, we need several other programs to successfully get a machine provisioned
    # These programs are stored in an array so they can be looped through later
    INSTALLER_DEPS=(apt-utils dialog debconf git whiptail)
    # HomeServer itself has several dependencies that also need to be installed
    HOMESERVER_DEPS=(curl sudo unzip wget dnsmasq apache2)
    # The Web server user,
    WEB_USER="www-data"
    # group,
    WEB_GROUP="www-data"

    # A function to check...
    test_dpkg_lock() {
        # An iterator used for counting loop iterations
        i=0
        # fuser is a program to show which processes use the named files, sockets, or filesystems
        # So while the command is true
        while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
            # Wait half a second
            sleep 0.5
            # and increase the iterator
            ((i=i+1))
        done
        # Always return success, since we only return if there is no
        # lock (anymore)
        return 0
    }
}

update_package_cache() {
    # Running apt-get update/upgrade with minimal output can cause some issues with
    # requiring user input (e.g password for phpmyadmin see #218)

    # Update package cache on apt based OSes. Do this every time since
    # it's quick and packages can be updated at any time.

    # Local, named variables
    local str="Update local cache of available packages"
    printf "  %b %s..." "${INFO}" "${str}"
    # Create a command from the package cache variable
    if eval "${UPDATE_PKG_CACHE}" &> /dev/null; then
        printf "%b  %b %s\\n" "${OVER}" "${TICK}" "${str}"
    # Otherwise,
    else
        # show an error and exit
        printf "%b  %b %s\\n" "${OVER}" "${CROSS}" "${str}"
        printf "  %bError: Unable to update package cache. Please try \"%s\"%b" "${COL_LIGHT_RED}" "${COL_LIGHT_RED}" "${COL_NC}"
        return 1
    fi
}

# Let user know if they have outdated packages on their system and
# advise them to run a package update at soonest possible.
notify_package_updates_available() {
    # Local, named variables
    local str="Checking ${PKG_MANAGER} for upgraded packages"
    printf "\\n  %b %s..." "${INFO}" "${str}"
    # Store the list of packages in a variable
    updatesToInstall=$(eval "${PKG_COUNT}")

    if [[ -d "/lib/modules/$(uname -r)" ]]; then
        if [[ "${updatesToInstall}" -eq 0 ]]; then
            printf "%b  %b %s... up to date!\\n\\n" "${OVER}" "${TICK}" "${str}"
        else
            printf "%b  %b %s... %s updates available\\n" "${OVER}" "${TICK}" "${str}" "${updatesToInstall}"
            printf "  %b %bIt is recommended to update your OS after installing the Pi-hole!%b\\n\\n" "${INFO}" "${COL_LIGHT_GREEN}" "${COL_NC}"
        fi
    else
        printf "%b  %b %s\\n" "${OVER}" "${CROSS}" "${str}"
        printf "      Kernel update detected. If the install fails, please reboot and try again\\n"
    fi
}

install_dependent_packages() {
    # Local, named variables should be used here, especially for an iterator
    # Add one to the counter
    counter=$((counter+1))
    # If it equals 1,
    if [[ "${counter}" == 1 ]]; then
        #
        printf "  %b Installer Dependency checks...\\n" "${INFO}"
    else
        #
        printf "  %b Main Dependency checks...\\n" "${INFO}"
    fi

    # Install packages passed in via argument array
    # No spinner - conflicts with set -e
    declare -a argArray1=("${!1}")
    declare -a installArray

    # Debian based package install - debconf will download the entire package list
    # so we just create an array of packages not currently installed to cut down on the
    # amount of download traffic.
    # NOTE: We may be able to use this installArray in the future to create a list of package that were
    # installed by us, and remove only the installed packages, and not the entire list.
    if is_command debconf-apt-progress ; then
        # For each package,
        for i in "${argArray1[@]}"; do
            printf "  %b Checking for %s..." "${INFO}" "${i}"
            if dpkg-query -W -f='${Status}' "${i}" 2>/dev/null | grep "ok installed" &> /dev/null; then
                printf "%b  %b Checking for %s\\n" "${OVER}" "${TICK}" "${i}"
            else
                echo -e "${OVER}  ${INFO} Checking for $i (will be installed)"
                installArray+=("${i}")
            fi
        done
        if [[ "${#installArray[@]}" -gt 0 ]]; then
            test_dpkg_lock
            debconf-apt-progress -- "${PKG_INSTALL[@]}" "${installArray[@]}"
            return
        fi
        printf "\\n"
        return 0
    fi

    # Install Fedora/CentOS packages
    for i in "${argArray1[@]}"; do
        printf "  %b Checking for %s..." "${INFO}" "${i}"
        if ${PKG_MANAGER} -q list installed "${i}" &> /dev/null; then
            printf "%b  %b Checking for %s" "${OVER}" "${TICK}" "${i}"
        else
            printf "%b  %b Checking for %s (will be installed)" "${OVER}" "${INFO}" "${i}"
            installArray+=("${i}")
        fi
    done
    if [[ "${#installArray[@]}" -gt 0 ]]; then
        "${PKG_INSTALL[@]}" "${installArray[@]}" &> /dev/null
        return
    fi
    printf "\\n"
    return 0
}

main() {
    ######## FIRST CHECK ########
    # Must be root to install
    local str="Root user check"
    printf "\\n"

    # If the user's id is zero,
    if [[ "${EUID}" -eq 0 ]]; then
        # they are root and all is good
        printf "  %b %s\\n" "${TICK}" "${str}"
        show_ascii_logo
    # Otherwise,
    else
        # They do not have enough privileges, so let the user know
        printf "  %b %s\\n" "${CROSS}" "${str}"
        printf "  %b %bScript called with non-root privileges%b\\n" "${INFO}" "${COL_LIGHT_RED}" "${COL_NC}"
        printf "      The HomeServer requires elevated privileges to install and run\\n"
        printf "      Please check the installer for any concerns regarding this requirement\\n"
        printf "      Make sure to download this script from a trusted source\\n\\n"
        printf "  %b Sudo utility check" "${INFO}"

        # If the sudo command exists,
        if is_command sudo ; then
            printf "%b  %b Sudo utility check\\n" "${OVER}"  "${TICK}"
            # Get the install script and run it with admin rights
            SCRIPT=`realpath $0`
            exec cat ${SCRIPT} | sudo bash "$@"
            exit $?
        # Otherwise,
        else
            # Let them know they need to run it as root
            printf "%b  %b Sudo utility check\\n" "${OVER}" "${CROSS}"
            printf "  %b Sudo is needed for the Web Interface to run pihole commands\\n\\n" "${INFO}"
            printf "  %b %bPlease re-run this installer as root${COL_NC}\\n" "${INFO}" "${COL_LIGHT_RED}"
            exit 1
        fi
    fi

    # Prepare for debian supported distribution
    distro_prepare_debian

    # Update package cache
    update_package_cache || exit 1

    # Notify user of package availability
    notify_package_updates_available

    # Install packages used by this installation script
    install_dependent_packages INSTALLER_DEPS[@]

    # Display welcome dialogs
    welcomeDialogs
    # Create directory for HomeServer storage
    mkdir -p /etc/homeServer/
    # Determine available interfaces
    # Give the user a choice of blocklists to include in their install. Or not.
    chooseUtilsToInstall

    # Check if user wants to install dashboard
    checkIfUserWantsDashboard

    # Install the Core dependencies
    local dep_install_list=("${HOMESERVER_DEPS[@]}")

    install_dependent_packages dep_install_list[@]
    unset dep_install_list

    printf "%b%s Complete! %b\\n" "${COL_LIGHT_GREEN}" "${INSTALL_TYPE}" "${COL_NC}"
}

if [[ "${PH_TEST}" != true ]] ; then
    main "$@"
fi