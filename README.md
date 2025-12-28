# DeployTools
A Tools set which can make some changes of your Linux PC/Server. 
It's a mess, but it works well.

# You have to finish it yourself.
There is some basic functions,and you can add yours.Thers is some functions Prefixed with  Pr_ . You can  add a function   Prefixed with  Pr_ too ,and  use some functions it has , to do something you want. 
eg.
There a function like this:

PJ_set_new_fedora_workstation()
{
    #project_set_user_never_expiration
    project_set_record_his_with_datetime
    # ~/.bashrc 或 ~/.bash_profile

    # 引用自定义函数文件
    if [ -f "/path/to/your/custom_functions.sh" ]; then
        source "/path/to/your/custom_functions.sh"
    fi

    # 加载新的配置
    source ~/.bashrc
    # 或者
    source ~/.bash_profile

    # 用以打开老式服务器 BMC 内置的 JVM 生成的 Jnlp文件.
    sudo dnf -y install icedtea-web
    sudo dnf -y install openjdk
    sudo dnf -y install java

    # 开发包组
    sudo dnf -y groupinstall develop-tools

    # 其他常用的和需要的包
    local ltmp_pakage_list_of_fedora="aircrack aisleriot amule anjuta ardour ark at audacity autodesk-dwgtrueview aview basemarkgpu bavarder biglybt brasero builder bz bz2 bzip bzip2-devel cambalache cavestory ccat chromium clonezilla clutter-devel clutter-doc cluttermm-devel cmake cmospwd cobbler cockpit codeblock codeblocks collision cowpatty cpeditor Cutter czkawka dbeaver detwinner development-libs development-tools devhelp dialog dnf drawio dwg-viewer edb etherape ettercap exploitdb fgdump figlet filezila filezilla firmware flatseal freecad g++ g3l g4l gcc gcc-c++ gdb gdm gdmsetting gdmsettings geany gear ghex gimp gimp-data-extras gimp-dds-plugin gimp-devel gimp-devel-tools gimp-elsamuko gimpfx-foundry gimp-help gimp-help-zh_CN gimp-high-pass-filter gimp-layer-via-copy-cut gimp-libs gimp-luminosity-masks gimp-paint-studio gimp-resynthesizer gimp-save-for-web gimp-separate+ gimp-wavelet-decompose git gitg glade glade3 glibc glibc-devel gmp-devel gnome-software-development gnome-tweaks gobject-introspection-devel godot google-chrome gparted gpuviewer group groupinstall gstreamer1-plugins gstreamer-devel gstreamer-devel-docs gstreamermm-doc gtk3-devel gtk3-devel-docs gtkmm gtkmm30-devel gtkmm30-doc gtkmm4.0-devel hashcat heaptrack helvum httpd hydra hydra-gtk imhex Inkscape insomnia inspector install jad jadx java java-21-openjdk-devel jdk john jp2a kernel-devel kernel-headers l0phtcrack libappindicator libappindicator-gtk3-12.10.1-4.fc40.i686 libappindicator-gtk3-12.10.1-4.fc40.x86_64 libavcodec libcl libde265 liberation-fonts libfreeaptx libgda-devel libgdamm-devel libgl libgtkmm libpcap-devel libQt5Help librecad libredwg librtmp libvncserver libwacom libxml libxml2 libxml3 libXScrnSaver lightzone live-build lm_sensors lsblk make mandelbulber man-pages-zh man-pages-zh-CN Manuals medusa Multimedia muon natron ncat nessus netbeans newelle nfs-utils ngrep nikto nmap nping nvdtools obs-studio ocrfeeder octave opencv openjdk openmpi openssl openssl-devel opera ophcrack ophrack partclone perl photoflare pk-gtk-module prometheus-jmx-exporter-openjdk8 putty pwgen python python3 qgis quadrapassel reaper redhat-lsb rpcbind samba shim sigil Simple-Fuzzer simulide skipfish snowflake speedtest sqlmap sqlninja ssh_mitm streamermm-devel sublime-text sudo tabby thunderbird tmux uefitool ueiftool vlc vncpwd w3af warp weasis webkitgtk3-devel wfuzz wireshark workbench xhydra xmllint xmlstarlet xsltproc yasm zenmap dhcp-server"
    dnf_install_packages  $ltmp_pakage_list_of_fedora

}


We can execute it use : 
./ProjectManage_current.sh --project PJ_set_new_fedora_workstation

Make usage yourself :
When you add a new function and give a entry to user. You can add a useage show without break the usage-function you had finished before.
You can add a function with a Suffix with _usage. I suggest that you andd the same function name with the main-function and the usage-function.

There is a usage-funciton like this:
setup_x11vnc_server_usage(){
    
    echo -ne "${GREEN}
    --set_x11vnc ${BLUE}vncpassword  ${NC}安装并设置x11vnc,连接密码设置为${BLUE}vncpassword${NC}
                        当提供的 vncpassword 为default时,VNC密码会被设置为 Tongyi@123 
                        例:     ${GREEN}$0 --set_x11vnc ${BLUE}myVNCPassword${NC}"
    echo 
}
The main-function's names is  'setup_x11vnc_server'. The final shows below:
==========================================================================

使用方法: 

    ./ProjectManage_V42.sh   [选项]  参数...
    

    --add_fw_port "port_list"  --type [tcp/udp] [--zone public] -p [--permanent]  
                    添加端口清单 port_list 类型tcp或udp端口至防火墙 
                        例:     ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone public -p
                        例:     ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone trusted -p
                        例:     ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone work -p
                        例:     ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone home 
                        例:     ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp -p
                        例:     ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300 6200 6379 8083" --type tcp 
                        例:     ./ProjectManage_V42.sh --add_fw_port "9060 8088 6300" --icmp_reply add 
                        例:     ./ProjectManage_V42.sh --add_fw_port "9060 8088" --icmp_reply remove 
                        例:     ./ProjectManage_V42.sh --add_fw_port "" --icmp_reply remove 

    --debug         调试模式,此模式用以调试和测试.支持断点等调试常用功能.具体方法如下:
                    代码内插入 bp 或 breakpoint,然后附加 --debug参数来执行程序.
                    程序会在 bp 或 breakpoint 处停止执行等待用户输入,此时可输入各种命令以继续调试.
                    此模式下:
                    o q 或 quit : 退出脚本程序
                    o show_all  : 查看目前所有 局部 和 全局 变量
                    o show_this_all : 查看目前所有 全局 变量
                    o show_ltmp_all : 查看目前所有 局部 变量
                    o who_call 或 who call : 查看调用链(脚本目前的推展中函数调用关系)
                    o trace_run 或 trace run : 开启追踪模式(最大化输出,且保留临时文件)并继续执行脚本
                    o run : 继续执行脚本,且追踪模式会被关闭.即 --trace 选项被关闭
                    o ex 【 任意命令 命令的参数 】: ex 后跟命令可执行命令. 如 "ex ls -lh"
                    待编辑...
                        
    --init_new_disk mount_point --dev devicename --fs fstype  
                        挂载devicename 至 mount_point 新分区格式化为{BLUE}fstype{NC}.
                        mount_point      挂载点,必选参数,不可省略.需指定具体的挂载点,形式如 /data 或 /DB 等.
                        --dev devicename 指定设备名称,可以为 /dev/sdb 或 sdb.该参数不指定则会由程序搜索已识别但
                                         未分区的disk类型设备,
                                         以列表形式展现,并提示用户选择要分区并挂载的disk对应列表中的编号.选择后对
                                         其进行操作.
                        --fs  fstype     指定新分区文件系统类型,即要格式化为哪种格式.该参数不指定则为 ext4
    
                        例:     ./ProjectManage_V42.sh --init_new_disk /Ddata --dev /dev/sdc --fs ext4
                        例:     ./ProjectManage_V42.sh --init_new_disk /Ddata --dev /dev/sdc
                        例:     ./ProjectManage_V42.sh --init_new_disk /Ddata --dev sdc
                        例:     ./ProjectManage_V42.sh --init_new_disk /Ddata --fs ext4
                        例:     ./ProjectManage_V42.sh --init_new_disk /Ddata --fs btrfs
                        例:     ./ProjectManage_V42.sh --init_new_disk /Ddata 

    --project PJ_project_code    执行项目代码PJ_project_code对应的函数
                        例:     ./ProjectManage_V42.sh --project  PJ_1234 

    

    --remove_fw_port "port_list"  --type [tcp/udp] [--zone public] -p [--permanent]  
                    从防火墙移除清单 port_list 中类型tcp或udp的所有端口 
                        例:     ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone trusted -p
                        例:     ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone work -p
                        例:     ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp --zone home 
                        例:     ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp -p
                        例:     ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300 6200 6379 8083" --type tcp 
                        例:     ./ProjectManage_V42.sh --remove_fw_port "9060 8088 6300" --icmp_reply add 
                        例:     ./ProjectManage_V42.sh --remove_fw_port "9060 8088" --icmp_reply remove 
                        例:     ./ProjectManage_V42.sh --remove_fw_port "" --icmp_reply remove 

    --set_x11vnc vncpassword  安装并设置x11vnc,连接密码设置为vncpassword
                        当提供的 vncpassword 为default时,VNC密码会被设置为 Tongyi@123 
                        例:     ./ProjectManage_V42.sh --set_x11vnc myVNCPassword

    --start         开启 http 服务

    --stop          关闭 http 服务

    --help 或 -h    显示帮助信息
    --version 或 -v 显示版本信息
    --test 或 -t    程序启动后执行test函数的功能,用以开发和测试特定功能. 
    --trace         追踪模式.临时文件一律保留,日志输出最为详尽.用以排查问题. 
    
==========================================================================


