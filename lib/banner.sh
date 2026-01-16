#!/bin/bash
#################################################################################################
# Banner显示模块
#################################################################################################

# 加载依赖
source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/constants.sh" 2>/dev/null || source "./lib/constants.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"

# Banner base64内容（从constants.sh获取，如果未加载则使用默认值）
if [ -z "$SAINT_LOGO_BASE64" ]; then
    # 如果constants.sh未加载，直接使用base64内容
    this_saintlogo="ICAgICAgICAgICAgICAgIOKWiOKWiOKWiOKWiOKWiOKWiCAg4paE4paE4paEICAgICAgIOKWiOKWiOKWkyDilojilojilojiloQgICAg4paIIOKWhOKWhOKWhOKWiOKWiOKWiOKWiOKWiOKWkwogICAgICAgICAgICAgIOKWkuKWiOKWiCAgICDilpIg4paS4paI4paI4paI4paI4paEICAgIOKWk+KWiOKWiOKWkiDilojilogg4paA4paIICAg4paIIOKWkyAg4paI4paI4paSIOKWk+KWkgogICAgICAgICAgICAgIOKWkSDilpPilojilojiloQgICDilpLilojiloggIOKWgOKWiOKWhCAg4paS4paI4paI4paS4paT4paI4paIICDiloDilogg4paI4paI4paS4paSIOKWk+KWiOKWiOKWkSDilpLilpEKICAgICAgICAgICAgICAgIOKWkiAgIOKWiOKWiOKWkuKWkeKWiOKWiOKWhOKWhOKWhOKWhOKWiOKWiCDilpHilojilojilpHilpPilojilojilpIgIOKWkOKWjOKWiOKWiOKWkuKWkSDilpPilojilojilpMg4paRIAogICAgICAgICAgICAgIOKWkuKWiOKWiOKWiOKWiOKWiOKWiOKWkuKWkiDilpPiloggICDilpPilojilojilpLilpHilojilojilpHilpLilojilojilpEgICDilpPilojilojilpEgIOKWkuKWiOKWiOKWkiDilpEgCiAgICAgICAgICAgICAg4paSIOKWkuKWk+KWkiDilpIg4paRIOKWkuKWkiAgIOKWk+KWkuKWiOKWkeKWkeKWkyAg4paRIOKWkuKWkSAgIOKWkiDilpIgICDilpIg4paR4paRICAgCiAgICAgICAgICAgICAg4paRIOKWkeKWkiAg4paRIOKWkSAg4paSICAg4paS4paSIOKWkSDilpIg4paR4paRIOKWkeKWkSAgIOKWkSDilpLilpEgICAg4paRICAgIAogICAgICAgICAgICAgIOKWkSAg4paRICDilpEgICAg4paRICAg4paSICAgIOKWkiDilpEgICDilpEgICDilpEg4paRICAg4paRICAgICAgCiAgICAgICAgICAgICAgICAgICAg4paRICAgICAgICDilpEgIOKWkSDilpEgICAgICAgICAgIOKWkSAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAK"
    this_developer="ICBBIExpbnV4IGVudGh1c2lhc3Qgd2hvIGhhcyBiZWVuIGFyb3VuZCBzaW5jZSAyMDA3LiBNYWlsIDogd2RpbHlAcXEuY29tCj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0K"
    this_tailline="PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0909PT09PT09PT09"
else
    this_saintlogo="${SAINT_LOGO_BASE64}"
    this_developer="${DEVELOPER_BASE64}"
    this_tailline="${TAIL_LINE_BASE64}"
fi

#################################################################################################
# 显示Banner
#################################################################################################
show_banner(){
    base64 --version  >/dev/null 2>&1
    local ltmp_RET=$?
    case "$ltmp_RET" in
        0)
            this_b_base64support=true
            show_banner_base64
            ;;
        *)
            this_b_base64support=false
            show_banner_ascii
            ;;
    esac
}

#################################################################################################
# 使用base64显示Banner
#################################################################################################
show_banner_base64(){
    local ltmp_tempfilename=$(date +"%Y%m%d%H%M%S")
    LOG_message "Creating tempfile ${this_TMP_DIR}/${ltmp_tempfilename}.logotmp" "TRACE"
    echo "${this_saintlogo}" >${this_TMP_DIR}/${ltmp_tempfilename}.logotmp

    echo -e "${GREEN}
    "

    cat ${this_TMP_DIR}/${ltmp_tempfilename}.logotmp | base64 -d   
    delete_file  ${this_TMP_DIR}/${ltmp_tempfilename}.logotmp

    local ltmp_tempfilename2=$(date +"%Y%m%d%H%M%S")
    LOG_message "Creating tempfile ${this_TMP_DIR}/${ltmp_tempfilename2}.mailtmp" "TRACE"
    echo "${this_developer}">${this_TMP_DIR}/${ltmp_tempfilename2}.mailtmp

    echo -e "${WHITE}

    "

    cat ${this_TMP_DIR}/${ltmp_tempfilename2}.mailtmp | base64 -d   
    delete_file  ${this_TMP_DIR}/${ltmp_tempfilename2}.mailtmp

    this_b_banner_shown=true
}

#################################################################################################
# 使用ASCII显示Banner
#################################################################################################
show_banner_ascii(){
    echo -e "${RED}
               ██████  ▄▄▄       ██▓ ███▄    █ ▄▄▄█████▓
             ▒██    ▒ ▒████▄    ▓██▒ ██ ▀█   █ ▓  ██▒ ▓▒
             ░ ▓██▄   ▒██  ▀█▄  ▒██▒▓██  ▀█ ██▒▒ ▓██░ ▒░
               ▒   ██▒░██▄▄▄▄██ ░██░▓██▒  ▐▌██▒░ ▓██▓ ░ 
             ▒██████▒▒ ▓█   ▓██▒░██░▒██░   ▓██░  ▒██▒ ░ 
             ▒ ▒▓▒ ▒ ░ ▒▒   ▓▒█░░▓  ░ ▒░   ▒ ▒   ▒ ░░   
             ░ ░▒  ░ ░  ▒   ▒▒ ░ ▒ ░░ ░░   ░ ▒░    ░    
             ░  ░  ░    ░   ▒    ▒ ░   ░   ░ ░   ░      
                   ░        ░  ░ ░           ░          
                                                    
    ${NC}\r\n"
    echo -ne "${WHITE}\r\n【A Linux enthusiast who has been around since 2007. Mail : wdily@qq.com】 \r\n"
    echo -ne "==========================================================================${NC}\r\n"
    
    this_b_banner_shown=true
}

#################################################################################################
# 显示结束Banner
#################################################################################################
show_tail_base64(){
    local ltmp_tempfilename3=$(date +"%Y%m%d%H%M%S")
    LOG_message "Creating tempfile ${this_TMP_DIR}/${ltmp_tempfilename3}.taillinetmp" "TRACE"
    echo "${this_tailline}" >${this_TMP_DIR}/${ltmp_tempfilename3}.taillinetmp

    cat ${this_TMP_DIR}/${ltmp_tempfilename3}.taillinetmp | base64 -d   
    delete_file  ${this_TMP_DIR}/${ltmp_tempfilename3}.taillinetmp

    echo -e "${NC}"
}

show_tail_ascii(){
    echo -ne "${WHITE}==========================================================================${NC}\r\n"
    echo 
}

show_tail(){
    if [ "$this_b_base64support" == "true" ];then
        show_tail_base64
    else
        show_tail_ascii
    fi
}
