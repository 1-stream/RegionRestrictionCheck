#!/bin/bash
shopt -s expand_aliases
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

while getopts ":I:M:E:X:P:F:S:" optname; do
    case "$optname" in
        # "I")
        #     iface="$OPTARG"
        #     useNIC="--interface $iface"
        #     ;;
        # "M")
        #     if [[ "$OPTARG" == "4" ]]; then
        #         NetworkType=4
        #     elif [[ "$OPTARG" == "6" ]]; then
        #         NetworkType=6
        #     fi
        #     ;;
        # "E")
        #     language="e"
        #     ;;
        # "X")
        #     XIP="$OPTARG"
        #     xForward="--header X-Forwarded-For:$XIP"
        #     ;;
        # "P")
        #     proxy="$OPTARG"
        #     usePROXY="-x $proxy"
        # 	;;
        "F")
            func="$OPTARG"
        ;;
        # "S")
        #     Stype="$OPTARG"
        # 	;;
        ":")
            echo "Unknown error while processing options"
            exit 1
        ;;
    esac
    
done

curlArgs=""
UA="Mozilla"

checkCPU() {
    CPUArch=$(uname -m)
    if [[ "$CPUArch" == "aarch64" ]]; then
        arch=arm64
        elif [[ "$CPUArch" == "i686" ]]; then
        arch=i686
        elif [[ "$CPUArch" == "arm" ]]; then
        arch=arm
        elif [[ "$CPUArch" == "x86_64" ]] && [ -n "$ifMacOS" ]; then
        arch=darwin
        elif [[ "$CPUArch" == "x86_64" ]]; then
        arch=amd64
    fi
}
checkCPU

checkNet() {
    myip4=$(curl -SsL "ipv4.ip.sb")
    myip6=$(curl -SsL "ipv6.ip.sb")
}
checkNet

checkDependencies() {
    ifTermux=$(echo $PWD | grep termux)
    ifMacOS=$(uname -a | grep Darwin)
    if [ -n "$ifTermux" ]; then
        os_version=Termux
        is_termux=1
        elif [ -n "$ifMacOS" ]; then
        os_version=MacOS
        is_macos=1
    else
        os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
    fi
    
    if [[ "$os_version" == "2004" ]] || [[ "$os_version" == "10" ]] || [[ "$os_version" == "11" ]]; then
        is_windows=1
        ssll="-k --ciphers DEFAULT@SECLEVEL=1"
    fi
    
    if [ "$(which apt 2>/dev/null)" ]; then
        InstallMethod="apt"
        is_debian=1
        elif [ "$(which dnf 2>/dev/null)" ] || [ "$(which yum 2>/dev/null)" ]; then
        InstallMethod="yum"
        is_redhat=1
        elif [[ "$os_version" == "Termux" ]]; then
        InstallMethod="pkg"
        elif [[ "$os_version" == "MacOS" ]]; then
        InstallMethod="brew"
    fi
    
    if ! command -v jq &>/dev/null; then
        if [ "$is_debian" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod update >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_redhat" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            if [[ "$os_version" -gt 7 ]]; then
                $InstallMethod makecache >/dev/null 2>&1
                $InstallMethod install jq -y >/dev/null 2>&1
            else
                $InstallMethod makecache >/dev/null 2>&1
                $InstallMethod install jq -y >/dev/null 2>&1
            fi
            
            elif [ "$is_termux" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod update -y >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            
            elif [ "$is_macos" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod install jq
        fi
    fi
    
}
checkDependencies &

install_nali() {
    if [ -f "/tmp/nali" ];then
        chmod +x /tmp/nali
    else
        curl "https://github.com/nxtrace/nali/releases/latest/download/nali-nt_linux_${arch}" $curlArgs -SsL -o /tmp/nali
        chmod +x /tmp/nali
    fi
    
}
install_nali &

wait

echo "$myip4"
echo "$myip6"

function ip_check_ipipnet() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://myip.ipip.net" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipip.net:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | grep -Eo "来自于.*")
    echo -n -e "\r ipip.net:\t\t\t${Font_Yellow}${result##*：}${Font_Suffix}\n"
    return
}

function ip_check_ipinfo() {
    if [[ "${1}" == "6" ]];then
        local tmp=$(curl $curlArgs -m 10 -SsL "https://ipinfo.io/${myip6}" 2>&1)
    else
        local tmp=$(curl $curlArgs -${1} -m 10 -SsL "https://ipinfo.io" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipinfo:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".country" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".region" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r ipinfo:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r ipinfo:\t\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}

function ip_check_ipapico() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://ipapi.co/json" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipapi.co:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local error=$(echo "$tmp" | jq ".error" | tr -d '"')
    if [[ "$error" == "true" ]]; then
        local error_reason=$(echo "$tmp" | jq ".reason" | tr -d '"')
        echo -n -e "\r ipapi.co:\t\t\t${Font_Red}Failed ($error_reason)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".country" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".region" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r ipapi.co:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r ipapi.co:\t\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}

function ip_check_ip2location() {
    local api_key="0d4f60641cd9b95ff5ac9b4d866a0655"
    #TODO
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://api.ip2location.io/?key=${api_key}" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ip2location:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".country_code" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".city_name" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".region_name" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r ip2location:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r ip2location:\t\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}

function ip_check_ipsb() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://api.ip.sb/geoip" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Maxmind (ip.sb):\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".country_code" | tr -d '"')
    echo -n -e "\r Maxmind (ip.sb):\t\t${Font_Yellow}${result}${Font_Suffix}\n"
    return
}

function ip_check_cloudflare() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://speed.cloudflare.com/meta" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Maxmind (Cloudflare):\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".country" | tr -d '"')
    local result_colo=$(echo "$tmp" | jq ".colo" | tr -d '"')
    echo -n -e "\r Maxmind (Cloudflare):\t\t${Font_Yellow}${result} (Colo: $result_colo)${Font_Suffix}\n"
    return
}

function ip_check_google() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://www.google.com/async/lbsc" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Google:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$tmp" == *"websearch/answer/86640"* ]]; then
        echo -n -e "\r Google:\t\t\t${Font_Red}Failed (Unusual Traffic)${Font_Suffix}\n"
        return
    fi
    local result="$(echo "${tmp}" | grep "location_address" | jq ".BottomSheetParams.payload.bottom_sheet_params.location_address" | tr -d '"')"
    echo -n -e "\r Google:\t\t\t${Font_Yellow}$result${Font_Suffix}\n"
    return
}

function ip_check_ipapicom() {
    if [[ "${1}" == "6" ]];then
        local tmp=$(curl $curlArgs -A "$UA" -m  10 -SsL "http://ip-api.com/json/${myip6}" 2>&1)
    else
        local tmp=$(curl $curlArgs -A "$UA" -${1} -m 10 -SsL "http://ip-api.com/json" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ip-api.com:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".countryCode" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".regionName" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r ip-api.com:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r ip-api.com:\t\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}

function ip_check_ipregistry() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://api.ipregistry.co/?hostname=true&key=sb69ksjcajfs4c" -H "Origin: https://ipregistry.co" -H "Referer: https://ipregistry.co" -H "Content-Type: application/json" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipregistry:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".location.country.code" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".location.city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".location.region.name" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r ipregistry:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r ipregistry:\t\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}

function ip_check_tencentmap() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://apis.map.qq.com/ws/location/v1/ip?key=OB4BZ-D4W3U-B7VVO-4PJWW-6TKDJ-WPB77" -H "Referer: https://lbs.qq.com/" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Tencent Map:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local error=$(echo "$tmp" | jq ".status" | tr -d '"')
    if [[ ! "$error" == "0" ]]; then
        local error_reason=$(echo "$tmp" | jq ".message" | tr -d '"')
        echo -n -e "\r Tencent Map:\t\t\t${Font_Red}Failed ($error_reason)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".result.ad_info.nation" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".result.ad_info.province" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".result.ad_info.city" | tr -d '"')
    echo -n -e "\r Tencent Map:\t\t\t${Font_Yellow}${result} $result_city $result_region${Font_Suffix}\n"
    return
}

function ip_check_ripe() {
    if [[ ${1} == "4" ]];then
        local tmp_rir=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://stat.ripe.net/data/rir-stats-country/data.json?resource=$myip4" 2>&1)
        local tmp_whois=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://stat.ripe.net/data/whois/data.json?resource=$myip4" 2>&1)
        local tmp_maxmind=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://stat.ripe.net/data/maxmind-geo-lite/data.json?resource=$myip4" 2>&1)
    else
        local tmp_rir=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://stat.ripe.net/data/rir-stats-country/data.json?resource=$myip6" 2>&1)
        local tmp_whois=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://stat.ripe.net/data/whois/data.json?resource=$myip6" 2>&1)
        local tmp_maxmind=$(curl $curlArgs  -A "$UA" -m 10 -SsL "https://stat.ripe.net/data/maxmind-geo-lite/data.json?resource=$myip6" 2>&1)
    fi
    
    if [[ "$tmp_rir" == "curl"* ]] || [[ "$tmp_whois" == "curl"* ]] || [[ "$tmp_maxmind" == "curl"* ]]; then
        echo -n -e "\r RIPE:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result_rir=$(echo "$tmp_rir" | jq ".data.located_resources[0].location" | tr -d '"')
    local result_rir_inetnum=$(echo "$tmp_rir" | jq ".data.located_resources[0].resource" | tr -d '"')
    local result_whois=$(echo "$tmp_whois" | jq '.data.records[0][]' -c | grep "country" | head -1 | jq ".value" | tr -d '"')
    local result_whois_inetnum=$(echo "$tmp_whois" | jq '.data.records[0][]' -c | grep  -E "inetnum|inet6num" | jq ".value" | tr -d '"')
    local result_maxmind=$(echo "$tmp_maxmind" | jq ".data.located_resources[0].locations[0].country" | tr -d '"')
    if [[ "$result_maxmind" == "?" ]];then
        local result_maxmind_city="Anycast"
    else
        local result_maxmind_city=$(echo "$tmp_maxmind" | jq ".data.located_resources[0].locations[0].city" | tr -d '"')
    fi
    echo -n -e "\r RIR (RIPE):\t\t\t${Font_Yellow}${result_rir} ($result_rir_inetnum)${Font_Suffix}\n"
    if [[ -n "$result_whois" ]];then
        echo -n -e "\r Whois (RIPE):\t\t\t${Font_Yellow}${result_whois} ($result_whois_inetnum)${Font_Suffix}\n"
    else
        echo -n -e "\r Whois (RIPE):\t\t\t${Font_Red}No data (May be ARIN)${Font_Suffix}\n"
    fi
    if [[ -n "$result_maxmind_city" ]];then
        echo -n -e "\r Maxmind (RIPE):\t\t${Font_Yellow}${result_maxmind} ($result_maxmind_city)${Font_Suffix}\n"
    else
        echo -n -e "\r Maxmind (RIPE):\t\t${Font_Yellow}${result_maxmind}${Font_Suffix}\n"
    fi
    return
}

function ip_check_cz88() {
    if [[ "${1}" == "6" ]];then
        local tmp=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://cz88.net/api/cz88/ip/base?ip=${myip6}" 2>&1)
    else
        local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://cz88.net/api/cz88/ip/base?ip=" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r CZ88:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".data.countryCode" | tr -d '"')
    local result_full=$(echo "$tmp" | jq ".data.actionAddress[0]" | tr -d '"')
    echo -n -e "\r CZ88:\t\t\t\t${Font_Yellow}${result} ($result_full)${Font_Suffix}\n"
    return
}

function ip_check_zxnic() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://ip.zxinc.org/api.php?type=json" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ZXNIC:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".data.location" | tr -d '"')
    echo -n -e "\r ZXNIC:\t\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
    return
}

function ip_check_LeoMoeAPI() {
    if [[ ${1} == "6" ]];then
        local tmp=$(/tmp/nali ${myip6} 2>&1)
    else
        local tmp=$(/tmp/nali ${myip4} 2>&1)
    fi
    local result=$(echo "$tmp" | grep -Eo "\[.*\]")
    echo -n -e "\r LeoMoeAPI:\t\t\t${Font_Yellow}${result:1:-1}${Font_Suffix}\n"
    return
}

function ip_check_ipgeolocation() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://api.ipgeolocation.io/ipgeo?include=hostname" -H "Referer:https://ipgeolocation.io/" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipGeolocation:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".country_code2" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".state_prov" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r ipGeolocation:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r ipGeolocation:\t\t\t${Font_Yellow}${result} ($result_city $result_region)${Font_Suffix}\n"
    return
}

function ip_check_akamai() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://www.edgecompute.live/geolocation" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Akamai EdgeScape:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".geoInfo.country" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".geoInfo.city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".geoInfo.region" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r Akamai EdgeScape:\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r Akamai EdgeScape:\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}

function ip_check_ipstack() {
    if [[ "${1}" == "6" ]];then
        local tmp=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://api.ipstack.com/${myip6}?access_key=1064c5485963a2fe844a3d485b1b339a" 2>&1)
    else
        local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://api.ipstack.com/${myip4}?access_key=1064c5485963a2fe844a3d485b1b339a" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipstack:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".country_code" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".region_name" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r ipstack:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r ipstack:\t\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}

function ip_check_ipwhoisio() {
    if [[ "${1}" == "6" ]];then
        local tmp=$(curl $curlArgs -A "$UA" -m 10 -SsL "ipwho.is/${myip6}" 2>&1)
    else
        local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "ipwho.is" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipwhois.io:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".country_code" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".region" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r ipwhois.io:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r ipwhois.io:\t\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}

function ip_check_ipdata() {
    if [[ "${1}" == "6" ]];then
        local tmp=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://api.ipdata.co/${myip6}?api-key=eca677b284b3bac29eb72f5e496aa9047f26543605efe99ff2ce35c9" 2>&1)
    else
        local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://api.ipdata.co/?api-key=eca677b284b3bac29eb72f5e496aa9047f26543605efe99ff2ce35c9" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipdata.co:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".country_code" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".region" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r ipdata.co:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r ipdata.co:\t\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}

function ip_check_internetdata() {
    if [[ "${1}" == "6" ]];then
        local tmp=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://api.internetdata.io/${myip6}" 2>&1)
    else
        local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://api.internetdata.io/myip" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r InternetData:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local error=$(echo "$tmp" | jq ".error" | tr -d '"')
    if [ "$error" != "null" ]; then
        echo -n -e "\r InternetData:\t\t\t${Font_Red}Failed ($error)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".location.country" | tr -d '"')
    local result_city=$(echo "$tmp" | jq ".location.city" | tr -d '"')
    local result_region=$(echo "$tmp" | jq ".location.region" | tr -d '"')
    if [ "$result_city" == "null" ] && [ "$result_region" == "null" ]; then
        echo -n -e "\r InternetData:\t\t\t${Font_Yellow}${result}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r InternetData:\t\t\t${Font_Yellow}${result} ($result_city/$result_region)${Font_Suffix}\n"
    return
}


function isp_check_bgptools() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://bgp.tools/whoami" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r AS (bgp.tools):\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp" | jq ".ASS" | tr -d '"')
    local result_asn=$(echo "$tmp" | jq ".ASN" | tr -d '"')
    echo -n -e "\r AS (bgp.tools):\t\t${Font_Yellow}${result} (AS$result_asn)${Font_Suffix}\n"
    return
}

function isp_check_ipinfo() {
    if [[ "${1}" == "6" ]];then
        local tmp=$(curl $curlArgs -m 10 -SsL "https://ipinfo.io/widget/demo/${myip6}" -H "Referer:https://ipinfo.io/" 2>&1)
    else
        local tmp=$(curl $curlArgs -m 10 -SsL "https://ipinfo.io/widget/demo/${myip4}" -H "Referer:https://ipinfo.io/" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Ipinfo:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$tmp" == *"Too Many Requests"* ]]; then
        echo -n -e "\r Ipinfo:\t\t\t${Font_Red}Failed (429)${Font_Suffix}\n"
        return
    fi
    local result_asn=$(echo "$tmp" | jq ".data.asn.asn" | tr -d '"')
    local result_asn_name=$(echo "$tmp" | jq ".data.asn.name" | tr -d '"')
    local result_asn_type=$(echo "$tmp" | jq ".data.asn.type" | tr -d '"')
    local result_company=$(echo "$tmp" | jq ".data.company.name" | tr -d '"')
    local result_company_type=$(echo "$tmp" | jq ".data.company.type" | tr -d '"')
    echo -n -e "\r AS (Ipinfo):\t\t\t${Font_Yellow}${result_asn_name} ($result_asn;$result_asn_type)${Font_Suffix}\n"
    echo -n -e "\r Company (Ipinfo):\t\t${Font_Yellow}${result_company} ($result_company_type)${Font_Suffix}\n"
    return
}

function isp_check_ipregistry() {
    local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://api.ipregistry.co/?hostname=true&key=sb69ksjcajfs4c" -H "Origin: https://ipregistry.co" -H "Referer: https://ipregistry.co" -H "Content-Type: application/json" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipregistry:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result_asn=$(echo "$tmp" | jq ".connection.asn" | tr -d '"')
    local result_asn_name=$(echo "$tmp" | jq ".connection.organization" | tr -d '"')
    local result_asn_type=$(echo "$tmp" | jq ".connection.type" | tr -d '"')
    local result_company=$(echo "$tmp" | jq ".company.name" | tr -d '"')
    local result_company_type=$(echo "$tmp" | jq ".company.type" | tr -d '"')
    echo -n -e "\r AS (ipregistry):\t\t${Font_Yellow}${result_asn_name} (AS$result_asn;$result_asn_type)${Font_Suffix}\n"
    echo -n -e "\r Company (ipregistry):\t\t${Font_Yellow}${result_company} ($result_company_type)${Font_Suffix}\n"
    return
}
function isp_check_ipdata() {
    if [[ "${1}" == "6" ]];then
        local tmp=$(curl $curlArgs -A "$UA" -m 10 -SsL "https://api.ipdata.co/${myip6}?api-key=eca677b284b3bac29eb72f5e496aa9047f26543605efe99ff2ce35c9" 2>&1)
    else
        local tmp=$(curl $curlArgs -${1} -A "$UA" -m 10 -SsL "https://api.ipdata.co/?api-key=eca677b284b3bac29eb72f5e496aa9047f26543605efe99ff2ce35c9" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r ipdata.co:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result_asn=$(echo "$tmp" | jq ".asn.asn" | tr -d '"')
    local result_asn_name=$(echo "$tmp" | jq ".asn.name" | tr -d '"')
    local result_asn_type=$(echo "$tmp" | jq ".asn.type" | tr -d '"')
    local result_company=$(echo "$tmp" | jq ".company.name" | tr -d '"')
    local result_company_type=$(echo "$tmp" | jq ".company.type" | tr -d '"')
    echo -n -e "\r AS (ipdata.co):\t\t${Font_Yellow}${result_asn_name} ($result_asn;$result_asn_type)${Font_Suffix}\n"
    echo -n -e "\r Company (ipdata.co):\t\t${Font_Yellow}${result_company} ($result_company_type)${Font_Suffix}\n"
    return
}

# echo -e "${Font_Green}IPv4:${Font_Suffix}"
# ip_check_ipipnet 4
# ip_check_ipinfo 4
# ip_check_ipapico 4
# ip_check_ip2location 4
# ip_check_ipsb 4
# ip_check_cloudflare 4
# ip_check_google 4
# ip_check_ipapicom 4
# ip_check_ipregistry 4
# ip_check_tencentmap 4
# ip_check_ripe 4
# ip_check_cz88 4
# ip_check_zxnic 4
# ip_check_LeoMoeAPI 4
# ip_check_ipgeolocation 4
# ip_check_akamai 4
# ip_check_ipstack 4
# ip_check_ipwhoisio 4
# ip_check_ipdata 4
# ip_check_internetdata 4
# isp_check_bgptools 4
# isp_check_ipinfo 4
# isp_check_ipregistry 4
# isp_check_ipdata 4
# if [[ -z "$myip6" ]]; then
#     exit
# fi
# echo -e "${Font_Green}IPv6:${Font_Suffix}"
# # ip_check_ipipnet 6
# ip_check_ipinfo 6
# ip_check_ipapico 6
# ip_check_ip2location 6
# ip_check_ipsb 6
# ip_check_cloudflare 6
# ip_check_google 6
# ip_check_ipregistry 6
# ip_check_tencentmap 6
# ip_check_ripe 6
# ip_check_cz88 6
# ip_check_zxnic 6
# ip_check_LeoMoeAPI 6
# ip_check_ipgeolocation 6
# ip_check_akamai 6
# ip_check_ipstack 6
# ip_check_ipwhoisio 6
# ip_check_ipdata 6
# ip_check_internetdata 6
# isp_check_bgptools 6
# isp_check_ipinfo 6
# isp_check_ipregistry 6
# isp_check_ipdata 6


function echo_Result() {
    for((i=0;i<${#array[@]};i++))
    do
        echo "$result" | grep "${array[i]}"
        # sleep 0.03
    done;
}

function geoiptest() {
    local result=$(
        ip_check_ipipnet ${1} &
        ip_check_ipinfo ${1} &
        ip_check_ipapico ${1} &
        ip_check_ip2location ${1} &
        ip_check_ipsb ${1} &
        ip_check_cloudflare ${1} &
        ip_check_google ${1} &
        ip_check_ipapicom ${1} &
        ip_check_ipregistry ${1} &
        ip_check_tencentmap ${1} &
        ip_check_ripe ${1} &
        ip_check_cz88 ${1} &
        ip_check_zxnic ${1} &
        ip_check_LeoMoeAPI ${1} &
        ip_check_ipgeolocation ${1} &
        ip_check_akamai ${1} &
        ip_check_ipstack ${1} &
        ip_check_ipwhoisio ${1} &
        ip_check_ipdata ${1} &
        ip_check_internetdata ${1} &
    )
    wait
    local array=("ipip.net:" "ipinfo:" "ipapi.co:" "ip2location:" "Maxmind (ip.sb):" "Maxmind (Cloudflare):" "Google:" "ip-api.com:" "ipregistry:" "Tencent Map:" "RIR (RIPE):" "Whois (RIPE):" "Maxmind (RIPE):" "RIPE:" "CZ88:" "ZXNIC:" "LeoMoeAPI:" "ipGeolocation:" "Akamai EdgeScape:" "ipstack:" "ipwhois.io:" "ipdata.co:" "InternetData:")
    echo_Result ${result} ${array}
}

function ispiptest() {
    local result=$(
        isp_check_bgptools ${1} &
        isp_check_ipinfo ${1} &
        isp_check_ipregistry ${1} &
        isp_check_ipdata ${1} &
    )
    wait
    local array=("(bgp.tools)" "(Ipinfo)" "Ipinfo:" "(ipregistry)" "ipdata.co")
    echo_Result ${result} ${array}
}

if [ -n "$func" ]; then
    echo -e "${Font_Green}IPv4:${Font_Suffix}"
    $func 4
    echo -e "${Font_Green}IPv6:${Font_Suffix}"
    $func 6
    exit
fi

function ScriptTitle() {
    echo -e " [IP地理位置测试脚本]"
    echo ""
    echo -e "${Font_Green}项目地址${Font_Suffix} ${Font_Yellow}https://github.com/1-stream/RegionRestrictionCheck ${Font_Suffix}"
    echo -e "${Font_Green}[商家]TG群组${Font_Suffix} ${Font_Yellow}https://t.me/streamunblock1 ${Font_Suffix}"
    # echo -e "${Font_Purple}脚本适配OS: IDK${Font_Suffix}"
    echo ""
    echo -e " ** 测试时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo ""
}
ScriptTitle

function Start() {
    
    echo -e "${Font_Blue}请选择检测项目，直接按回车将进行全部检测${Font_Suffix}"
    echo -e "${Font_SkyBlue}输入数字  [1]: [ IP地理位置 ]检测${Font_Suffix}"
    echo -e "${Font_SkyBlue}输入数字  [2]: [   IP ISP   ]检测${Font_Suffix}"
    read -p "请输入正确数字或直接按回车:" num
}
Start

function Goodbye() {
    echo -e "${Font_Green}本次测试已结束，感谢使用此脚本 ${Font_Suffix}"
    echo -e ""
    # echo -e "${Font_Yellow}检测脚本当天运行次数: ${TodayRunTimes}; 共计运行次数: ${TotalRunTimes} ${Font_Suffix}"
}

function RunScript() {
    if [[ -n "${num}" ]]; then
        if [[ "$num" -eq 1 ]]; then
            clear
            ScriptTitle
            if [ -n "$myip4" ]; then
                echo -e "${Font_Green}IPv4:${Font_Suffix}"
                geoiptest 4
            fi
            if [ -n "$myip6" ]; then
                echo -e "${Font_Green}IPv6:${Font_Suffix}"
                geoiptest 6
            fi
            Goodbye
            
            elif [[ "$num" -eq 2 ]]; then
            clear
            ScriptTitle
            if [ -n "$myip4" ]; then
                echo -e "${Font_Green}IPv4:${Font_Suffix}"
                ispiptest 4
            fi
            if [ -n "$myip6" ]; then
                echo -e "${Font_Green}IPv6:${Font_Suffix}"
                ispiptest 6
            fi
            Goodbye
        else
            echo -e "${Font_Red}请重新执行脚本并输入正确号码${Font_Suffix}"
            echo -e "${Font_Red}Please Re-run the Script with Correct Number Input${Font_Suffix}"
            return
        fi
    else
        clear
        ScriptTitle
        if [ -n "$myip4" ]; then
            echo -e "${Font_Green}IPv4:${Font_Suffix}"
            geoiptest 4
            ispiptest 4
        fi
        if [ -n "$myip6" ]; then
            echo -e "${Font_Green}IPv6:${Font_Suffix}"
            geoiptest 6
            ispiptest 6
        fi
        Goodbye
    fi
}
wait
RunScript
