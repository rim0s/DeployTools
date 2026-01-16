#!/bin/bash
#################################################################################################
# 常量定义模块
# 包含颜色、版本、Banner等常量
#################################################################################################

# 版本信息
readonly VERSION="48.0"

# 定义颜色变量（1是高亮）
readonly GREEN='\033[1;32m'
readonly green='\033[0;32m'
readonly WHITE='\e[1;37m'
readonly NC='\e[0m'
readonly NC='\033[0m'  # No Color
readonly RED='\033[1;31m'
readonly red='\033[0;31m'
readonly YELLOW='\E[1;33m'
readonly yellow='\E[0;33m'
readonly BLUE='\E[1;34m'
readonly blue='\E[0;34m'
readonly PINK='\E[1;35m'
readonly pink='\E[0;35m'
readonly purple='\e[0;35m'
readonly PURPLE='\e[1;35m'
readonly cyan='\e[0;36m'
readonly CYAN='\e[1;36m'

# Banner base64编码内容
readonly SAINT_LOGO_BASE64="ICAgICAgICAgICAgICAgIOKWiOKWiOKWiOKWiOKWiOKWiCAg4paE4paE4paEICAgICAgIOKWiOKWiOKWkyDilojilojilojiloQgICAg4paIIOKWhOKWhOKWhOKWiOKWiOKWiOKWiOKWiOKWkwogICAgICAgICAgICAgIOKWkuKWiOKWiCAgICDilpIg4paS4paI4paI4paI4paI4paEICAgIOKWk+KWiOKWiOKWkiDilojilogg4paA4paIICAg4paIIOKWkyAg4paI4paI4paSIOKWk+KWkgogICAgICAgICAgICAgIOKWkSDilpPilojilojiloQgICDilpLilojiloggIOKWgOKWiOKWhCAg4paS4paI4paI4paS4paT4paI4paIICDiloDilogg4paI4paI4paS4paSIOKWk+KWiOKWiOKWkSDilpLilpEKICAgICAgICAgICAgICAgIOKWkiAgIOKWiOKWiOKWkuKWkeKWiOKWiOKWhOKWhOKWhOKWhOKWiOKWiCDilpHilojilojilpHilpPilojilojilpIgIOKWkOKWjOKWiOKWiOKWkuKWkSDilpPilojilojilpMg4paRIAogICAgICAgICAgICAgIOKWkuKWiOKWiOKWiOKWiOKWiOKWiOKWkuKWkiDilpPiloggICDilpPilojilojilpLilpHilojilojilpHilpLilojilojilpEgICDilpPilojilojilpEgIOKWkuKWiOKWiOKWkiDilpEgCiAgICAgICAgICAgICAg4paSIOKWkuKWk+KWkiDilpIg4paRIOKWkuKWkiAgIOKWk+KWkuKWiOKWkeKWkeKWkyAg4paRIOKWkuKWkSAgIOKWkiDilpIgICDilpIg4paR4paRICAgCiAgICAgICAgICAgICAg4paRIOKWkeKWkiAg4paRIOKWkSAg4paSICAg4paS4paSIOKWkSDilpIg4paR4paRIOKWkeKWkSAgIOKWkSDilpLilpEgICAg4paRICAgIAogICAgICAgICAgICAgIOKWkSAg4paRICDilpEgICAg4paRICAg4paSICAgIOKWkiDilpEgICDilpEgICDilpEg4paRICAg4paRICAgICAgCiAgICAgICAgICAgICAgICAgICAg4paRICAgICAgICDilpEgIOKWkSDilpEgICAgICAgICAgIOKWkSAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAK"

readonly DEVELOPER_BASE64="ICBBIExpbnV4IGVudGh1c2lhc3Qgd2hvIGhhcyBiZWVuIGFyb3VuZCBzaW5jZSAyMDA3LiBNYWlsIDogd2RpbHlAcXEuY29tCj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0K"

readonly TAIL_LINE_BASE64="PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0K"

# 日志级别颜色映射
declare -A LOG_LEVEL_COLORS
LOG_LEVEL_COLORS=([ERROR]=${RED} [WARNING]=${YELLOW} [INFO]=${blue} [DEBUG]=${PINK} [TRACE]=${BLUE})
