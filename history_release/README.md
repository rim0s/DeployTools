# DeployTools

A toolset for making changes to your Linux PC/Server.  
It's a mess, but it works well.

---

## ⚠️ You Have to Finish It Yourself

This project provides some basic functions, and you can add your own.  
Functions prefixed with `PJ_` are predefined — you can also add your own `PJ_` functions and reuse existing ones to achieve what you need.

### Example

There is a function like this:

```bash
PJ_set_new_fedora_workstation()
{
    #project_set_user_never_expiration
    project_set_record_his_with_datetime
    # ~/.bashrc or ~/.bash_profile

    # Source custom function file
    if [ -f "/path/to/your/custom_functions.sh" ]; then
        source "/path/to/your/custom_functions.sh"
    fi

    # Reload configurations
    source ~/.bashrc
    # or
    source ~/.bash_profile

    # For opening old server BMC JVM-generated JNLP files
    sudo dnf -y install icedtea-web
    sudo dnf -y install openjdk
    sudo dnf -y install java

    # Development tools group
    sudo dnf -y groupinstall develop-tools

    # Other common and required packages
    local ltmp_pakage_list_of_fedora="aircrack aisleriot amule anjuta ardour ark at audacity autodesk-dwgtrueview aview basemarkgpu bavarder biglybt brasero builder bz bz2 bzip bzip2-devel cambalache cavestory ccat chromium clonezilla clutter-devel clutter-doc cluttermm-devel cmake cmospwd cobbler cockpit codeblock codeblocks collision cowpatty cpeditor Cutter czkawka dbeaver detwinner development-libs development-tools devhelp dialog dnf drawio dwg-viewer edb etherape ettercap exploitdb fgdump figlet filezila filezilla firmware flatseal freecad g++ g3l g4l gcc gcc-c++ gdb gdm gdmsetting gdmsettings geany gear ghex gimp gimp-data-extras gimp-dds-plugin gimp-devel gimp-devel-tools gimp-elsamuko gimpfx-foundry gimp-help gimp-help-zh_CN gimp-high-pass-filter gimp-layer-via-copy-cut gimp-libs gimp-luminosity-masks gimp-paint-studio gimp-resynthesizer gimp-save-for-web gimp-separate+ gimp-wavelet-decompose git gitg glade glade3 glibc glibc-devel gmp-devel gnome-software-development gnome-tweaks gobject-introspection-devel godot google-chrome gparted gpuviewer group groupinstall gstreamer1-plugins gstreamer-devel gstreamer-devel-docs gstreamermm-doc gtk3-devel gtk3-devel-docs gtkmm gtkmm30-devel gtkmm30-doc gtkmm4.0-devel hashcat heaptrack helvum httpd hydra hydra-gtk imhex Inkscape insomnia inspector install jad jadx java java-21-openjdk-devel jdk john jp2a kernel-devel kernel-headers l0phtcrack libappindicator libappindicator-gtk3-12.10.1-4.fc40.i686 libappindicator-gtk3-12.10.1-4.fc40.x86_64 libavcodec libcl libde265 liberation-fonts libfreeaptx libgda-devel libgdamm-devel libgl libgtkmm libpcap-devel libQt5Help librecad libredwg librtmp libvncserver libwacom libxml libxml2 libxml3 libXScrnSaver lightzone live-build lm_sensors lsblk make mandelbulber man-pages-zh man-pages-zh-CN Manuals medusa Multimedia muon natron ncat nessus netbeans newelle nfs-utils ngrep nikto nmap nping nvdtools obs-studio ocrfeeder octave opencv openjdk openmpi openssl openssl-devel opera ophcrack ophrack partclone perl photoflare pk-gtk-module prometheus-jmx-exporter-openjdk8 putty pwgen python python3 qgis quadrapassel reaper redhat-lsb rpcbind samba shim sigil Simple-Fuzzer simulide skipfish snowflake speedtest sqlmap sqlninja ssh_mitm streamermm-devel sublime-text sudo tabby thunderbird tmux uefitool ueiftool vlc vncpwd w3af warp weasis webkitgtk3-devel wfuzz wireshark workbench xhydra xmllint xmlstarlet xsltproc yasm zenmap dhcp-server"
    dnf_install_packages  $ltmp_pakage_list_of_fedora
}
```

You can execute it with:

```bash
./ProjectManage_current.sh --project PJ_set_new_fedora_workstation
```

---

## 🧩 Make Your Own Usage

When you add a new function and provide an entry for the user, you can also add a usage message without breaking the existing `usage` function.  
It is suggested to create a function with the same name as the main function but suffixed with `_usage`.

Example of a usage function:

```bash
setup_x11vnc_server_usage(){
    echo -ne "${GREEN}
    --set_x11vnc ${BLUE}vncpassword  ${NC}Install and set up x11vnc with password ${BLUE}vncpassword${NC}
                        When vncpassword is 'default', VNC password will be set to Tongyi@123.
                        Example: ${GREEN}$0 --set_x11vnc ${BLUE}myVNCPassword${NC}"
    echo
}
```

The main function’s name is `setup_x11vnc_server`.

---

## 🛠️ Usage Overview

```
Usage: ./ProjectManage_V42.sh [OPTIONS] [ARGUMENTS]...

Options:

    --add_fw_port "port_list" --type [tcp/udp] [--zone public] [-p] [--permanent]
        Add ports listed in port_list to firewall.
        Examples:
            ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone public -p
            ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone trusted -p
            ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone home
            ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp -p
            ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp
            ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300" --icmp_reply add
            ./ProjectManage_V42.sh --add_fw_port "9060 8088" --icmp_reply remove
            ./ProjectManage_V42.sh --add_fw_port "" --icmp_reply remove

    --debug
        Debug mode. Insert 'bp' or 'breakpoint' in code, then run with --debug.
        Commands available when paused:
            q / quit               : Quit script
            show_all               : Show all local and global variables
            show_this_all          : Show all global variables
            show_ltmp_all          : Show all local variables
            who_call / who call    : Show call stack
            trace_run / trace run  : Enable trace mode and continue
            run                    : Continue (trace mode off)
            ex [command]           : Execute arbitrary command (e.g., "ex ls -lh")
            (More to be added...)

    --init_new_disk mount_point [--dev device] [--fs fstype]
        Mount device to mount_point, format as fstype (default: ext4).
        Examples:
            ./ProjectManage_V42.sh --init_new_disk /Ddata --dev /dev/sdc --fs ext4
            ./ProjectManage_V42.sh --init_new_disk /Ddata --dev /dev/sdc
            ./ProjectManage_V42.sh --init_new_disk /Ddata --dev sdc
            ./ProjectManage_V42.sh --init_new_disk /Ddata --fs ext4
            ./ProjectManage_V42.sh --init_new_disk /Ddata --fs btrfs
            ./ProjectManage_V42.sh --init_new_disk /Ddata

    --project PJ_project_code
        Execute the function named PJ_project_code.
        Example:
            ./ProjectManage_V42.sh --project PJ_1234

    --remove_fw_port "port_list" --type [tcp/udp] [--zone public] [-p] [--permanent]
        Remove ports listed in port_list from firewall.
        Examples:
            ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone trusted -p
            ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone work -p
            ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone home
            ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp -p
            ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp
            ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300" --icmp_reply add
            ./ProjectManage_V42.sh --remove_fw_port "9060 8088" --icmp_reply remove
            ./ProjectManage_V42.sh --remove_fw_port "" --icmp_reply remove

    --set_x11vnc vncpassword
        Install and set up x11vnc with the given password.
        If vncpassword is 'default', password will be set to Tongyi@123.
        Example:
            ./ProjectManage_V42.sh --set_x11vnc myVNCPassword

    --start
        Start HTTP service.

    --stop
        Stop HTTP service.

    --help, -h
        Show this help message.

    --version, -v
        Show version information.

    --test, -t
        Run test function (for development and testing).

    --trace
        Enable trace mode (verbose logs, keep temporary files).
```

---

> **My AI Note:** This README is compatible with both GitHub and Gitea markdown rendering.