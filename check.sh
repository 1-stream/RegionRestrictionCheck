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

while getopts ":I:M:EX:P:F:S:R:C:D:" optname; do
    case "$optname" in
        "I")
            iface="$OPTARG"
            useNIC="--interface $iface"
        ;;
        "M")
            if [[ "$OPTARG" == "4" ]]; then
                NetworkType=4
                elif [[ "$OPTARG" == "6" ]]; then
                NetworkType=6
            fi
        ;;
        "E")
            language="e"
        ;;
        "X")
            XIP="$OPTARG"
            xForward="--header X-Forwarded-For:$XIP"
        ;;
        "P")
            proxy="$OPTARG"
            usePROXY="-x $proxy"
        ;;
        "F")
            func="$OPTARG"
        ;;
        "S")
            Stype="$OPTARG"
        ;;
        "R")
            Resolve="$OPTARG"
            resolve="--resolve *:443:$Resolve"
        ;;
        "C")
            Curl="$OPTARG"
            alias curl=$Curl
        ;;
        "D")
            Dns="$OPTARG"
            dns="--dns-servers $Dns"
        ;;
        ":")
            echo "Unknown error while processing options"
            exit 1
        ;;
    esac
    
done

if [ -z "$iface" ]; then
    useNIC=""
fi

if [ -z "$XIP" ]; then
    xForward=""
fi

if [ -z "$proxy" ]; then
    usePROXY=""
fi

if [ -z "$Resolve" ]; then
    resolve=""
fi

if [ -z "$Dns" ]; then
    dns=""
fi

if ! mktemp -u --suffix=RRC &>/dev/null; then
    is_busybox=1
fi
curlArgs="$useNIC $usePROXY $xForward $resolve $dns --max-time 10"
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.64"
UA_Dalvik="Dalvik/2.1.0 (Linux; U; Android 9; ALP-AL00 Build/HUAWEIALP-AL00)"
Media_Cookie=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/1-stream/RegionRestrictionCheck/main/cookies" &)
IATACode=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/1-stream/RegionRestrictionCheck/main/reference/IATACode.txt" &)

checkOS() {
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
}
checkOS

checkCPU() {
    CPUArch=$(uname -m)
    if [[ "$CPUArch" == "aarch64" ]]; then
        arch=_arm64
        elif [[ "$CPUArch" == "i686" ]]; then
        arch=_i686
        elif [[ "$CPUArch" == "arm" ]]; then
        arch=_arm
        elif [[ "$CPUArch" == "x86_64" ]] && [ -n "$ifMacOS" ]; then
        arch=_darwin
    fi
}
checkCPU

checkDependencies() {
    
    # os_detail=$(cat /etc/os-release 2> /dev/null)
    
    if ! command -v python &>/dev/null; then
        if command -v python3 &>/dev/null; then
            alias python="python3"
        else
            if [ "$is_debian" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                $InstallMethod update >/dev/null 2>&1
                $InstallMethod install python3 -y >/dev/null 2>&1
                alias python="python3"
                elif [ "$is_redhat" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                if [[ "$os_version" -gt 7 ]]; then
                    $InstallMethod makecache >/dev/null 2>&1
                    $InstallMethod install python3 -y >/dev/null 2>&1
                    alias python="python3"
                else
                    $InstallMethod makecache >/dev/null 2>&1
                    $InstallMethod install python3 -y >/dev/null 2>&1
                fi
                
                elif [ "$is_termux" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                $InstallMethod update -y >/dev/null 2>&1
                $InstallMethod install python3 -y >/dev/null 2>&1
                alias python="python3"
                
                elif [ "$is_macos" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                $InstallMethod install python3
                alias python="python3"
            fi
        fi
    fi
    
    if ! command -v jq &>/dev/null; then
        if [ "$is_debian" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod update >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_redhat" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod makecache >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_termux" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod update -y >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_macos" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod install jq
        fi
    fi
    
    if [ "$is_macos" == 1 ]; then
        if ! command -v md5sum &>/dev/null; then
            echo -e "${Font_Green}Installing md5sha1sum${Font_Suffix}"
            $InstallMethod install md5sha1sum
        fi
    fi
    
}
checkDependencies
if [ -z "$func" ]; then
    local_ipv4=$(curl $curlArgs -4 -s --max-time 10 cloudflare.com/cdn-cgi/trace | grep ip | awk -F= '{print $2}' &)
    local_ipv6=$(curl $curlArgs -6 -s --max-time 20 cloudflare.com/cdn-cgi/trace | grep ip | awk -F= '{print $2}' &)
    wait
    # bgptools_v4=$(curl $curlArgs -s -4 --max-time 10 --user-agent "${UA_Browser}" "https://v4.bgp.tools/whoami-not-for-robots" &)
    # bgptools_v6=$(curl $curlArgs -s -6 --max-time 10 --user-agent "${UA_Browser}" "https://v6.bgp.tools/whoami-not-for-robots" &)
    ripe_stat_v4=$(curl $curlArgs -s --max-time 10 "https://stat.ripe.net/data/prefix-overview/data.json?resource=$local_ipv4" &)
    ripe_stat_v6=$(curl $curlArgs -s --max-time 10 "https://stat.ripe.net/data/prefix-overview/data.json?resource=$local_ipv6" &)
    wait
    local_isp4=$(echo $ripe_stat_v4 | jq .data.asns[0].holder | tr -d '"')
    local_as4=$(echo $ripe_stat_v4 | jq .data.asns[0].asn | tr -d '"')
    local_ipv4_asterisk=$(echo $ripe_stat_v4 | jq .data.resource | tr -d '"')
    local_isp6=$(echo $ripe_stat_v6 | jq .data.asns[0].holder | tr -d '"')
    local_as6=$(echo $ripe_stat_v6 | jq .data.asns[0].asn | tr -d '"')
    local_ipv6_asterisk=$(echo $ripe_stat_v6 | jq .data.resource | tr -d '"')
    wait
fi


ShowRegion() {
    echo -e "${Font_Yellow} ---${1}---${Font_Suffix}"
}

function detect_isp() {
    local lan_ip=$(echo "$1" | grep -Eo "^(10\.[0-9]{1,3}\.[0-9]{1,3}\.((0\/([89]|1[0-9]|2[0-9]|3[012]))|([0-9]{1,3})))|(172\.(1[6789]|2\[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}(\/(1[6789]|2[0-9]|3[012]))?)|(192\.168\.[0-9]{1,3}\.[0-9]{1,3}(\/(1[6789]|2[0-9]|3[012]))?)$")
    if [ -n "$lan_ip" ]; then
        echo "LAN"
        return
    else
        local res=$(curl $curlArgs --user-agent "${UA_Browser}" -s --max-time 20 "https://api.ip.sb/geoip/$1" | jq ".isp" | tr -d '"' )
        echo "$res"
        return
    fi
}

function GameTest_Steam() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://store.steampowered.com/app/761830" 2>&1 | grep priceCurrency | cut -d '"' -f4)

    if [ ! -n "$result" ]; then
        echo -n -e "\r Steam Currency:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    else
        echo -n -e "\r Steam Currency:\t\t\t${Font_Green}${result}${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_HBONow() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 --write-out "%{url_effective}\n" --output /dev/null "https://play.hbonow.com/" 2>&1)
    if [[ "$result" != "curl"* ]]; then
        if [ "${result}" = "https://play.hbonow.com" ] || [ "${result}" = "https://play.hbonow.com/" ]; then
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        elif [ "${result}" = "http://hbogeo.cust.footprint.net/hbonow/geo.html" ] || [ "${result}" = "http://geocust.hbonow.com/hbonow/geo.html" ]; then
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        fi
    else
        echo -e "\r HBO Now:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_BahamutAnime() {
    local tmpdeviceid=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" --max-time 10 -fsSL "https://ani.gamer.com.tw/ajax/getdeviceid.php" --cookie-jar bahamut_cookie.txt 2>&1)
    if [[ "$tmpdeviceid" == "curl"* ]]; then
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        rm -f bahamut_cookie.txt
        return
    fi
    local tempdeviceid=$(echo $tmpdeviceid | python -m json.tool 2>/dev/null | grep 'deviceid' | awk '{print $2}' | tr -d '"' )
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" --max-time 10 -fsSL "https://ani.gamer.com.tw/ajax/token.php?adID=89422&sn=38832&device=${tempdeviceid}" -b bahamut_cookie.txt 2>&1)
    local tmpresult2=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" --max-time 10 -fsSL "https://ani.gamer.com.tw/ajax/token.php?adID=89422&sn=37783&device=${tempdeviceid}" -b bahamut_cookie.txt 2>&1)
    if [[ "$tmpresult" == "curl"* ]] || [[ "$tmpresult2" == "curl"* ]]; then
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    rm -f bahamut_cookie.txt
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'animeSn')
    local result2=$(echo $tmpresult2 | python -m json.tool 2>/dev/null | grep 'animeSn')
    if [ -n "$result" ] && [ -n "$result2" ]; then
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Green}Yes (Region: TW)${Font_Suffix}\n"
    elif [ -n "$result2" ]; then
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Green}Yes (Region: HK/MO)${Font_Suffix}\n"
    else
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_BilibiliHKMCTW() {
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)"
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.com/pgc/player/web/playurl?avid=18281381&cid=29892777&qn=0&type=&otype=json&ep_id=183799&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1)
    if [[ "$result" != "curl"* ]]; then
        local result="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
        if [ "${result}" = "0" ]; then
            echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Green}Yes${Font_Suffix}\n"
        elif [ "${result}" = "-10403" ]; then
            echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}No${Font_Suffix}\n"
        else
            echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
        fi
    else
        echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    fi
}

# 流媒体解锁测试-哔哩哔哩台湾限定
function MediaUnlockTest_BilibiliTW() {
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)"
    # 尝试获取成功的结果
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.com/pgc/player/web/playurl?avid=50762638&cid=100279344&qn=0&type=&otype=json&ep_id=268176&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1)
    if [[ "$result" != "curl"* ]]; then
        local result="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
        if [ "${result}" = "0" ]; then
            echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        elif [ "${result}" = "-10403" ]; then
            echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}No${Font_Suffix}\n"
        else
            echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}Failed${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
        fi
    else
        echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    fi
}

# 流媒体解锁测试-Abema.TV
#
function MediaUnlockTest_AbemaTV_IPTest() {
    local tempresult=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --max-time 10 "https://api.abema.io/v1/ip/check?device=android" 2>&1)
    if [[ "$tempresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tempresult" == "curl"* ]]; then
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    result=$(echo "$tempresult" | python -m json.tool 2>/dev/null | grep isoCountryCode | awk '{print $2}' | cut -f2 -d'"')
    if [ -n "$result" ]; then
        if [[ "$result" == "JP" ]]; then
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        else
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Yellow}Oversea Only (Region: ${result})${Font_Suffix}\n"
        fi
    else
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_PCRJP() {
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api-priconne-redive.cygames.jp/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "404" ]; then
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_UMAJP() {
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api-umamusume.cygames.jp/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Pretty Derby Japan:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "404" ]; then
        echo -n -e "\r Pretty Derby Japan:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Pretty Derby Japan:\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Pretty Derby Japan:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Kancolle() {
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "http://w00g.kancolle-server.com/kcscontents/news/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Kancolle Japan:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Kancolle Japan:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Kancolle Japan:\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Kancolle Japan:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_BBCiPLAYER() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsL --max-time 10 "https://open.live.bbc.co.uk/mediaselector/6/select/version/2.0/mediaset/pc/vpid/bbc_one_london/format/json/jsfunc/JS_callbacks0" 2>&1)
    if [ "${tmpresult}" = "000" ]; then
        echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    if [ -n "$tmpresult" ]; then
        result=$(echo $tmpresult | grep 'geolocation')
        if [ -n "$result" ]; then
            echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        else
            echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        fi
    else
        echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Netflix() {
    local tmpresult1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 --tlsv1.3 "https://www.netflix.com/title/81280792" 2>&1)
    local tmpresult2=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 --tlsv1.3 "https://www.netflix.com/title/70143836" 2>&1)
    if [[ "$tmpresult1" == "curl"* ]] || [[ "$tmpresult2" == "curl"* ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$( echo "$tmpresult1" | grep "og:video" )
    local result2=$( echo "$tmpresult2" | grep "og:video" )
    local region1=$( echo -e $(echo "$tmpresult1" | grep 'netflix.reactContext' | awk -F= '{print $2}' | awk -F\; '{print $1}') | tr -d '[:cntrl:]' | sed 's/\^[^$]*\$//g' | jq '.models.geo.data.requestCountry.id' | tr -d '"' )

    if [ -n "$result1" ] || [ -n "$result2" ]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Netflix:\t\t\t\t${Font_Yellow}Originals Only (Region: ${region1})${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_DisneyPlus() {
    local PreAssertion=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/devices" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -H "content-type: application/json; charset=UTF-8" -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' 2>&1)
    if [[ "$PreAssertion" == "curl"* ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed (Network Connection[1])${Font_Suffix}\n"
        return
    fi

    local assertion=$(echo $PreAssertion | python -m json.tool 2>/dev/null | grep assertion | cut -f4 -d'"')
    local PreDisneyCookie=$(echo "$Media_Cookie" | sed -n '1p')
    local disneycookie=$(echo $PreDisneyCookie | sed "s/DISNEYASSERTION/${assertion}/g")
    local TokenContent=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/token" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycookie" 2>&1)
    if [[ "$TokenContent" == "curl"* ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed (Network Connection[2])${Font_Suffix}\n"
        return
    fi
    local isBanned=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'forbidden-location')
    local is403=$(echo $TokenContent | grep '403 ERROR')

    if [ -n "$isBanned" ] || [ -n "$is403" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No (Banned)${Font_Suffix}\n"
        return
    fi

    local fakecontent=$(echo "$Media_Cookie" | sed -n '8p')
    local refreshToken=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'refresh_token' | awk '{print $2}' | cut -f2 -d'"')
    local disneycontent=$(echo $fakecontent | sed "s/ILOVEDISNEY/${refreshToken}/g")
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycontent" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed (Network Connection[3])${Font_Suffix}\n"
        return
    fi
    local previewchecktmp=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.disneyplus.com")
    if [[ "$previewchecktmp" == "curl"* ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed (Network Connection[4])${Font_Suffix}\n"
        return
    fi
    local previewcheck=$(echo $previewchecktmp | grep preview)
    local isUnavailable=$(echo $previewcheck | grep 'unavailable')
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | cut -f4 -d'"')
    local inSupportedLocation=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'inSupportedLocation' | awk '{print $2}' | cut -f1 -d',')

    if [[ "$region" == "JP" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Green}Yes (Region: JP)${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "false" ]] && [ -z "$isUnavailable" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Yellow}Available For [Disney+ $region] Soon${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [ -n "$isUnavailable" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No (Unavailable)${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "true" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    elif [ -z "$region" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No (Unknown)${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Dazn() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 -X POST -H "Content-Type: application/json" -d '{"LandingPageKey":"generic","Languages":"zh-CN,zh,en","Platform":"web","PlatformAttributes":{},"Manufacturer":"","PromoCode":"","Version":"2"}' "https://startup.core.indazn.com/misl/v5/Startup" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$tmpresult" == *"Security policy has been breached"* ]]; then
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}No  (Banned)${Font_Suffix}\n"
        return
    fi
    local isAllowed=$(echo $tmpresult | jq .Region.isAllowed)
    local region=$(echo $tmpresult | jq .Region.GeolocatedCountry | tr -d '"')

    if [[ "$isAllowed" == "true" ]]; then
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
        return
    elif [[ "$isAllowed" == "false" ]]; then
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}Unsupport${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_HuluJP() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s -o /dev/null -L --max-time 10 -w '%{url_effective}%{http_code}\n' "https://id.hulu.jp" 2>&1 | grep -E 'restrict|403')

    if [ -n "$result" ]; then
        echo -n -e "\r Hulu Japan:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Hulu Japan:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Hulu Japan:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_MyTVSuper() {
    local result=$(curl $curlArgs -s -${1} --max-time 10 "https://www.mytvsuper.com/api/auth/getSession/self/" 2>&1 | python -m json.tool 2>/dev/null | grep 'region' | awk '{print $2}' | tr -d ",")

    if [[ "$result" == "1" ]]; then
        echo -n -e "\r MyTVSuper:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MyTVSuper:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r MyTVSuper:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_NowE() {

    local result=$(curl $curlArgs -${1} -s --max-time 10 -X POST -H "Content-Type: application/json" -d '{"contentId":"202105121370235","contentType":"Vod","pin":"","deviceId":"W-60b8d30a-9294-d251-617b-6oagagn3","deviceType":"WEB"}' "https://webtvapi.nowe.com/16/1/getVodURL" | python -m json.tool 2>/dev/null | grep 'responseCode' | awk '{print $2}' | cut -f2 -d'"' 2>&1)

    if [[ "$result" == "NOT_LOGIN" ]]; then
        echo -n -e "\r Now E:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "SUCCESS" ]]; then
        echo -n -e "\r Now E:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "PRODUCT_INFORMATION_INCOMPLETE" ]]; then
        echo -n -e "\r Now E:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "GEO_CHECK_FAIL" ]]; then
        echo -n -e "\r Now E:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Now E:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Now E:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_ViuTV() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 -X POST -H "Content-Type: application/json" -d '{"callerReferenceNo":"20210726112323","contentId":"099","contentType":"Channel","channelno":"099","mode":"prod","deviceId":"29b3cb117a635d5b56","deviceType":"ANDROID_WEB"}' "https://api.viu.now.com/p8/3/getLiveURL" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Viu.TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'responseCode' | awk '{print $2}' | cut -f2 -d'"')
    if [[ "$result" == "SUCCESS" ]]; then
        echo -n -e "\r Viu.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "GEO_CHECK_FAIL" ]]; then
        echo -n -e "\r Viu.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Viu.TV:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_unext() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://cc.unext.jp/" -X POST -d '{"operationName":"cosmo_getPlaylistUrl","variables":{"code":"ED00467205","playMode":"caption","bitrateLow":192,"bitrateHigh":null,"validationOnly":false},"query":"query cosmo_getPlaylistUrl($code: String, $playMode: String, $bitrateLow: Int, $bitrateHigh: Int, $validationOnly: Boolean) {\n  webfront_playlistUrl(\n    code: $code\n    playMode: $playMode\n    bitrateLow: $bitrateLow\n    bitrateHigh: $bitrateHigh\n    validationOnly: $validationOnly\n  ) {\n    subTitle\n    playToken\n    playTokenHash\n    beaconSpan\n    result {\n      errorCode\n      errorMessage\n      __typename\n    }\n    resultStatus\n    licenseExpireDate\n    urlInfo {\n      code\n      startPoint\n      resumePoint\n      endPoint\n      endrollStartPosition\n      holderId\n      saleTypeCode\n      sceneSearchList {\n        IMS_AD1\n        IMS_L\n        IMS_M\n        IMS_S\n        __typename\n      }\n      movieProfile {\n        cdnId\n        type\n        playlistUrl\n        movieAudioList {\n          audioType\n          __typename\n        }\n        licenseUrlList {\n          type\n          licenseUrl\n          __typename\n        }\n        __typename\n      }\n      umcContentId\n      movieSecurityLevelCode\n      captionFlg\n      dubFlg\n      commodityCode\n      movieAudioList {\n        audioType\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n"}' -H "Content-Type: application/json" )
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r U-NEXT:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'resultStatus' | awk '{print $2}' | cut -d ',' -f1 2>&1)
    if [ -n "$result" ]; then
        if [[ "$result" == "475" ]]; then
            echo -n -e "\r U-NEXT:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        elif [[ "$result" == "200" ]]; then
            echo -n -e "\r U-NEXT:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        elif [[ "$result" == "467" ]]; then
            echo -n -e "\r U-NEXT:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        else
            echo -n -e "\r U-NEXT:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r U-NEXT:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Paravi() {
    local tmpresult=$(curl $curlArgs -${1} -Ss --max-time 10 -H "Content-Type: application/json" -d '{"meta_id":17414,"vuid":"3b64a775a4e38d90cc43ea4c7214702b","device_code":1,"app_id":1}' "https://api.paravi.jp/api/v1/playback/auth" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Paravi:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep type | awk '{print $2}' | cut -f2 -d'"')
    if [[ "$result" == "Forbidden" ]]; then
        echo -n -e "\r Paravi:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "Unauthorized" ]]; then
        echo -n -e "\r Paravi:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_wowow() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sS --max-time 10 "https://mapi.wowow.co.jp/api/v1/playback/auth" -X POST -d '{"meta_id":81174}' -H "Content-Type: application/json" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r WOWOW:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    checkfailed=$(echo $tmpresult | jq '.error.code')
    if [[ "$checkfailed" == "2055" ]]; then
        echo -n -e "\r WOWOW:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$checkfailed" == "2041" ]] || [[ "$checkfailed" == "2003" ]]; then
        echo -n -e "\r WOWOW:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r WOWOW:\t\t\t\t\t${Font_Red}Unknown (Code: $checkfailed)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_TVer() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL "https://playback.api.streaks.jp/v1/projects/tver-simul-ntv/medias/ref:simul-ntv" -H 'x-streaks-api-key: ntv'  2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r TVer:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$tmpresult" == *"project_id"* ]]; then
        echo -n -e "\r TVer:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == *"403"* ]]; then
        echo -n -e "\r TVer:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r TVer:\t\t\t\t\t${Font_Red}Unknown${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_HamiVideo() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -Ss --max-time 10 "https://hamivideo.hinet.net/api/play.do?id=OTT_VOD_0000249064&freeProduct=1" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Hami Video:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    checkfailed=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'code' | cut -f4 -d'"')
    if [[ "$checkfailed" == "06001-106" ]]; then
        echo -n -e "\r Hami Video:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$checkfailed" == "06001-107" ]]; then
        echo -n -e "\r Hami Video:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Hami Video:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_4GTV() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sS --max-time 10 -X POST -d 'value=D33jXJ0JVFkBqV%2BZSi1mhPltbejAbPYbDnyI9hmfqjKaQwRQdj7ZKZRAdb16%2FRUrE8vGXLFfNKBLKJv%2BfDSiD%2BZJlUa5Msps2P4IWuTrUP1%2BCnS255YfRadf%2BKLUhIPj' "https://api2.4gtv.tv//Vod/GetVodUrl3" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r 4GTV.TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    checkfailed=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'Success' | awk '{print $2}' | cut -f1 -d',')
    if [[ "$checkfailed" == "false" ]]; then
        echo -n -e "\r 4GTV.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$checkfailed" == "true" ]]; then
        echo -n -e "\r 4GTV.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r 4GTV.TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_SlingTV() {
    local tmpresult=$(curl $curlArgs -${1} -sSL --max-time 10 'https://p-geo.movetv.com/geo' 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r Rakuten TV JP:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local is_restricted=$(echo $tmpresult | jq .ip_restricted | tr -d '"')
    local region=$(echo $tmpresult | jq .country | tr -d '"')
    if [[ "$is_restricted" == "true" ]]; then
        echo -n -e "\r Sling TV:\t\t\t\t${Font_Red}No  (Region: ${region^^})${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Sling TV:\t\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_PlutoTV() {
    local tmpresult=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://pluto.tv/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Pluto TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'thanks-for-watching')
    if [ -n "$result" ]; then
        echo -n -e "\r Pluto TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Pluto TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Pluto TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_HBOMax() {
    local GetToken=$(curl $curlArgs -${1} -sS "https://default.any-any.prd.api.hbomax.com/token?realm=bolt&deviceId=afbb5daa-c327-461d-9460-d8e4b3ee4a1f"   -H 'x-device-info: beam/5.0.0 (desktop/desktop; Windows/10; afbb5daa-c327-461d-9460-d8e4b3ee4a1f/da0cdd94-5a39-42ef-aa68-54cbc1b852c3)' -H 'x-disco-client: WEB:10:beam:5.2.1' 2>&1)
    if [[ "$GetToken" == "curl"* ]]; then
        echo -n -e "\r HBO Max:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local Token=$(echo $GetToken | jq .data.attributes.token | tr -d '"' )
    local APITemp=$(curl $curlArgs -${1} -sS "https://default.any-any.prd.api.hbomax.com/session-context/headwaiter/v1/bootstrap" -X POST -b "st=${Token}")
    local domain=$(echo $APITemp | jq .routing.domain | tr -d '"')
    local tenant=$(echo $APITemp | jq .routing.tenant | tr -d '"')
    local env=$(echo $APITemp | jq .routing.env | tr -d '"')
    local homeMarket=$(echo $APITemp | jq .routing.homeMarket | tr -d '"')
    local tmpresult=$(curl $curlArgs -${1} -sS "https://default.$tenant-$homeMarket.$env.$domain/users/me" -b "st=${Token}" 2>&1)
    local result=$(echo $tmpresult | jq .data.attributes.currentLocationTerritory | tr -d '"')
    local availableRegion=$(curl $curlArgs -${1} -sSL "https://www.hbomax.com/" 2>&1 | grep -woP '"url":"/[a-z]{2}/[a-z]{2}"' | cut -f4 -d'"' | cut -f2 -d'/' | sort -n | uniq | xargs | tr a-z A-Z)
    local isVPN=$(curl $curlArgs -${1} -sS 'https://default.any-any.prd.api.hbomax.com/any/playback/v1/playbackInfo' -b 'st=eyJhbGciOiJSUzI1NiJ9.eyJqdGkiOiJ0b2tlbi0wOWQxOTg4Yy1mZmUzLTQxMDEtOWI5My0yNDU1ZTkyNGQ1YjYiLCJpc3MiOiJmcGEtaXNzdWVyIiwic3ViIjoiVVNFUklEOmJvbHQ6YjYzOTgxZWQtNzA2MC00ZGYwLThkZGItZjA2YjFkNWRjZWVkIiwiaWF0IjoxNzQzODQwMzgwLCJleHAiOjIwNTkyMDAzODAsInR5cGUiOiJBQ0NFU1NfVE9LRU4iLCJzdWJkaXZpc2lvbiI6ImJlYW1fYW1lciIsInNjb3BlIjoiZGVmYXVsdCIsImlpZCI6IjQwYTgzZjNlLTY4OTktNDE3Mi1hMWY2LWJjZDVjN2ZkNjA4NSIsInZlcnNpb24iOiJ2MyIsImFub255bW91cyI6ZmFsc2UsImRldmljZUlkIjoiNWY3YzViZjQtYjc4Ny00NDRjLWJhYTYtMzU5MzgwYWFiM2RmIn0.f5HTgIV2v0nQQDp5LQG0xqLrxyACdvnMDiWO_viX_CUGqtc5ncSjp_LgM30QFkkMnINFhzKEGRpsZvb-o3Pj_Z39uRBr5LCeiCPR7ssV-_SXyRFVRRDEB2lpxyz7jmdD1SxvA06HnEwTbZQzlbZ7g9GXq02yNdEfHlqYEh_4WF88UbXfeieYTd4TH7kwN1RE50NfQUS6f0WmzpAbpiULyd87mpTeynchFNMMz-YHVzZ_-nDW6geihXc3tS0FKVSR8fdOSPQFzEYOLCfhInufiPahiXI-OKF89aShAqM-y4Hx_eukGnsq3mO5wa3unnqVr9Kzc61BIhHh1Hs2bqYiYg;'  2>&1 )
    # Token may expire.
    if [[ "$availableRegion" == *"$result"* ]] && [ -n "$result" ]; then
        if [[ "$isVPN" == *"VPN"* ]]; then 
            echo -n -e "\r HBO Max:\t\t\t\t${Font_Red}No  (VPN Detected;Region: $result)${Font_Suffix}\n"
            return
        fi
        echo -n -e "\r HBO Max:\t\t\t\t${Font_Green}Yes (Region: $result)${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HBO Max:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r HBO Max:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Channel4() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.channel4.com/simulcast/channels/C4" 2>&1)

    if [[ "$result" == "403" ]]; then
        echo -n -e "\r Channel 4:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "200" ]]; then
        echo -n -e "\r Channel 4:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Channel 4:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_ITVHUB() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://simulcast.itv.com/playlist/itvonline/ITV" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r ITV Hub:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "404" ]; then
        echo -n -e "\r ITV Hub:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r ITV Hub:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r ITV Hub:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_iQYI_Region() {
    local tmpresult=$(curl $curlArgs -${1} -s -I --max-time 10 "https://www.iq.com/")

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -z "$tmpresult" ]; then
        echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
    result=$(echo "$tmpresult" | grep 'mod=' | awk '{print $2}' | cut -f2 -d'=' | cut -f1 -d';')
    region=$(echo "$tmpresult" | grep 'x-custom-client-ip:' | cut -f3 -d':' | sed 's/.$//')
    if [[ "$region" == "cn" ]]; then
            echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Yellow}Mainland (Region: ${region^^})${Font_Suffix}\n"
            return
    fi
    if [ -n "$result" ]; then
        if [[ "$result" == "intl" ]]; then
            echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Red}No  (Region: ${region^^})${Font_Suffix}\n"
            return
        else
            echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}


function MediaUnlockTest_HuluUS() {
    local tmpresult=$(curl $curlArgs -${1}  --user-agent "${UA_Browser}" -SsL 'https://auth.hulu.com/v4/web/password/authenticate' -H 'cookie: _h_csrf_id=b0b3da20eccdc796dd61d9145a095be4927a2ff56821ad4d3f91804fd6f918ea' --data-raw 'csrf=fdc1427eccde53326e27d7575c436595e28299dc420232ff26075ca06bbb28ed&password=Jam0.5cm~&scenario=web_password_login&user_email=me%40jamchoi.cc' 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Hulu:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo "$tmpresult" | jq .error.name | tr -d '"')
    case "$result" in
        'LOGIN_FORBIDDEN') echo -n -e "\r Hulu:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n" ;;
        'GEO_BLOCKED') echo -n -e "\r Hulu:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n" ;;
        '' ) echo -n -e "\r Hulu:\t\t\t\t\t${Font_Red}Failed (Error: PAGE ERROR)${Font_Suffix}\n" ;;
        *) echo -n -e "\r Hulu:\t\t\t\t\t${Font_Red}Failed (Error: ${result})${Font_Suffix}\n" ;;
    esac
}

function MediaUnlockTest_encoreTVB() {
    tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 -H "Accept: application/json;pk=BCpkADawqM2Gpjj8SlY2mj4FgJJMfUpxTNtHWXOItY1PvamzxGstJbsgc-zFOHkCVcKeeOhPUd9MNHEGJoVy1By1Hrlh9rOXArC5M5MTcChJGU6maC8qhQ4Y8W-QYtvi8Nq34bUb9IOvoKBLeNF4D9Avskfe9rtMoEjj6ImXu_i4oIhYS0dx7x1AgHvtAaZFFhq3LBGtR-ZcsSqxNzVg-4PRUI9zcytQkk_YJXndNSfhVdmYmnxkgx1XXisGv1FG5GOmEK4jZ_Ih0riX5icFnHrgniADr4bA2G7TYh4OeGBrYLyFN_BDOvq3nFGrXVWrTLhaYyjxOr4rZqJPKK2ybmMsq466Ke1ZtE-wNQ" -H "Origin: https://www.encoretvb.com" "https://edge.api.brightcove.com/playback/v1/accounts/5324042807001/videos/6005570109001" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r encoreTVB:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'error_subcode' | cut -f4 -d'"')
    if [[ "$result" == "CLIENT_GEO" ]]; then
        echo -n -e "\r encoreTVB:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo $tmpresult | python -m json.tool 2>/dev/null | grep 'account_id' >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -n -e "\r encoreTVB:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r encoreTVB:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Molotov() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 "https://fapi.molotov.tv/v1/open-europe/is-france" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Molotov:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    echo $tmpresult | python -m json.tool 2>/dev/null | grep 'false' >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -n -e "\r Molotov:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo $tmpresult | python -m json.tool 2>/dev/null | grep 'true' >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -n -e "\r Molotov:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Molotov:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Salto() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 "https://geo.salto.fr/v1/geoInfo/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Salto:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local CountryCode=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'country_code' | cut -f4 -d'"')
    local AllowedCode="FR,GP,MQ,GF,RE,YT,PM,BL,MF,WF,PF,NC"
    echo ${AllowedCode} | grep ${CountryCode} >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -n -e "\r Salto:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Salto:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_LineTV.TW() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://www.linetv.tw/api/part/11829/eps/1/part?chocomemberId=&appId=062097f1b1f34e11e7f82aag22000aee" 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r LineTV.TW:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | awk '{print $2}' | cut -f1 -d',')
    if [ -n "$result" ]; then
        if [ "$result" = "228" ]; then
            echo -n -e "\r LineTV.TW:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        else
            echo -n -e "\r LineTV.TW:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r LineTV.TW:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Viu.com() {
    local tmpresult=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.viu.com/" 2>&1)
    local banresult=$(curl $curlArgs -${1} -SsL --max-time 10 "https://d3o7oi00quuwqu.cloudfront.net" 2>&1)
    if [ "$tmpresult" = "000" ] || [ "$banresult" == "curl"* ]; then
        echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    result=$(echo $tmpresult | cut -f5 -d"/")
    if [ -n "$result" ]; then
        if [[ "$result" == "no-service" ]]; then
            echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        else
            result=$(echo $result | tr [:lower:] [:upper:])
            if [[ "$banresult" == *"block access"* ]]; then
                echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}No  (Region: ${result})${Font_Suffix}\n"
                return
            else
                echo -n -e "\r Viu.com:\t\t\t\t${Font_Green}Yes (Region: ${result})${Font_Suffix}\n"
                return
            fi
        fi

    else
        echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_Niconico() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSI -X GET "https://www.nicovideo.jp/watch/so23017073" --write-out %{http_code} --output /dev/null 2>&1)
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Niconico:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "400" ]]; then
        echo -n -e "\r Niconico:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "200" ]]; then
        echo -n -e "\r Niconico:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Niconico:\t\t\t\t${Font_Red}Failed ($result)${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_MGStage() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSI -X GET "https://www.mgstage.com/" --write-out %{http_code} --output /dev/null 2>&1)
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r MGStage:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "403" ]]; then
        echo -n -e "\r MGStage:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "200" ]]; then
        echo -n -e "\r MGStage:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MGStage:\t\t\t\t${Font_Red}Failed ($result)${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_ParamountPlus() {
    local result=$(curl $curlArgs -${1} -Ss -o /dev/null -L --max-time 10 -w '%{http_code}_%{url_effective}\n' "https://www.paramountplus.com/" --tlsv1.3 2>&1)
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Paramount+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    if [[ "$result" == *"intl"* ]] || [[ "$result" == "403"* ]]; then
        echo -n -e "\r Paramount+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "200"* ]]; then
        local region=$(echo $result | cut -f4 -d '/')
        if [[ -z "$region" ]]; then
            echo -n -e "\r Paramount+:\t\t\t\t${Font_Green}Yes (Region: US)${Font_Suffix}\n"
            return
        else
            echo -n -e "\r Paramount+:\t\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r Paramount+:\t\t\t\t${Font_Red}Failed (Unknown Resp)${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Paramount+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    return

}

function MediaUnlockTest_KKTV() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api.kktv.me/v3/ipcheck" 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r KKTV:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'country' | cut -f4 -d'"')
    if [[ "$result" == "TW" ]]; then
        echo -n -e "\r KKTV:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r KKTV:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_PeacockTV() {
    local tmpresult=$(curl $curlArgs -${1} -fsL -w "%{http_code}\n%{url_effective}\n" -o /dev/null "https://www.peacocktv.com/" 2>&1)
    if [[ "$tmpresult" == "000"* ]]; then
        echo -n -e "\r Peacock TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'unavailable')
    if [ -n "$result" ]; then
        echo -n -e "\r Peacock TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Peacock TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_FOD() {

    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://geocontrol1.stream.ne.jp/fod-geo/check.xml?time=1624504256" 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r FOD(Fuji TV):\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    echo $tmpresult | grep 'true' >/dev/null 2>&1
    if [[ "$?" -eq 0 ]]; then
        echo -n -e "\r FOD(Fuji TV):\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r FOD(Fuji TV):\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_YouTube_Premium() {
    local tmpresult1=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} --max-time 10 -sSL -H "Accept-Language: en" -b "YSC=BiCUU3-5Gdk; CONSENT=YES+cb.20220301-11-p0.en+FX+700; GPS=1; VISITOR_INFO1_LIVE=4VwPMkB7W5A; PREF=tz=Asia.Shanghai; _gcl_au=1.1.1809531354.1646633279" "https://www.youtube.com/premium" 2>&1)
    local tmpresult2=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} --max-time 10 -sSL -H "Accept-Language: en" "https://www.youtube.com/premium" 2>&1)
    local tmpresult="$tmpresult1:$tmpresult2"

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local isCN=$(echo $tmpresult | grep 'www.google.cn')
    if [ -n "$isCN" ]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No${Font_Suffix} ${Font_Green} (Region: CN)${Font_Suffix} \n"
        return
    fi

    local region=$(echo $tmpresult | grep "countryCode" | sed 's/.*"countryCode"//' | cut -f2 -d'"')
    local isAvailable=$(echo $tmpresult | grep 'purchaseButtonOverride')
    local isAvailable2=$(echo $tmpresult | grep "Start trial")

    if [ -n "$isAvailable" ] || [ -n "$isAvailable2" ] || [ -n "$region" ]; then
        if [ -n "$region" ]; then
            echo -n -e "\r YouTube Premium:\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
            return
        else
            echo -n -e "\r YouTube Premium:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        fi
    else
        if [ -n "$region" ]; then
            echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No  (Region: $region)${Font_Suffix} \n"
            return
        else
            echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No${Font_Suffix} \n"
            return
        fi
    fi
    echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}Failed${Font_Suffix}\n"

}

function MediaUnlockTest_YouTube_CDN() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 "https://redirector.googlevideo.com/report_mapping?di=no" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r YouTube Region:\t\t\t${Font_Red}Check Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local cdn_node=$(echo $tmpresult | awk '{print $3}')
    if [[ "$cdn_node" == *"-"* ]]; then
        local CDN_ISP=$(echo $cdn_node | cut -f1 -d"-" | tr [:lower:] [:upper:])
        local CDN_LOC=$(echo $cdn_node | cut -f2 -d"-" | sed 's/[^a-z]//g')
        local lineNo=$(echo "${IATACode}" | cut -f3 -d"|" | sed -n "/${CDN_LOC^^}/=")
        local location=$(echo "${IATACode}" | awk "NR==${lineNo}" | cut -f1 -d"|" | sed -e 's/^[[:space:]]*//' | sed 's/\s*$//')
        echo -n -e "\r YouTube CDN:\t\t\t\t${Font_Yellow}$CDN_ISP in $location ($cdn_node)${Font_Suffix}\n"
        return
    fi
    if [[ "$cdn_node" == *"s"* ]]; then
        local CDN_LOC=$(echo $cdn_node | cut -f2 -d"-" | cut -c1-3)
        local lineNo=$(echo "${IATACode}" | cut -f3 -d"|" | sed -n "/${CDN_LOC^^}/=")
        local location=$(echo "${IATACode}" | awk "NR==${lineNo}" | cut -f1 -d"|" | sed -e 's/^[[:space:]]*//' | sed 's/\s*$//')
        echo -n -e "\r YouTube CDN:\t\t\t\t${Font_Green}$location ($cdn_node)${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r YouTube CDN:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    return
    
}

function MediaUnlockTest_BritBox() {
    local tmpresult=$(curl $curlArgs -${1} -sS -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.britbox.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r BritBox:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'locationnotvalidated')
    if [ -n "$result" ]; then
        local region=$(echo $tmpresult | cut -d '/' -f4)
        echo -n -e "\r BritBox:\t\t\t\t${Font_Red}No  (Region: ${region^^})${Font_Suffix}\n"
        return
    else
        echo -n -e "\r BritBox:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r BritBox:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_PrimeVideo_Region() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sL --max-time 10 "https://www.primevideo.com" 2>&1)

    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local tmpresult1=$(curl $curlArgs -${1} --user-agent "PrimeVideo/10.68 (iPad; iOS 18.3.2; Scale/2.00)" -sL --max-time 10 "https://ab9f7h23rcdn.eu.api.amazonvideo.com/cdp/appleedge/getDataByTransform/v1/apple/detail/vod/v1.kt?itemId=amzn1.dv.gti.e6b39984-2bb6-f7d0-33e4-08ec574947f0&deviceId=6F97F9CCFA2243F1A3C44BD3C7F7908E&deviceTypeId=A3JTVZS31ZJ340&density=2x&firmware=10.6800.16104.3&format=json&enabledFeatures=denarius.location.gen4.daric.siglos.siglosPartnerBilling.contentDescriptors.contentDescriptorsV2.productPlacement.zeno.seriesSearch.tapsV2.dateTimeLocalization.multiSourcedEvents.mseEventLevelOffers.liveWatchModal.lbv.daapi.maturityRatingDecoration.seasonTrailer.cleanSlate.xbdModalV2.xbdModalVdp.playbackPinV2.exploreTab.reactions.progBadging.atfEpTimeVis.prereleaseCx.vppaConsent.episodicRelease.movieVam.movieVamCatalog&journeyIngressContext=8%7CEgRzdm9k&osLocale=zh_Hans_CN&timeZoneId=Asia%2FShanghai&uxLocale=zh_CN" 2>&1)
    if [[ "$tmpresult1" = "curl"* ]]; then
        echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local VPNDetected=$(echo $tmpresult1 | grep "您的设备使用了 VPN 或代理服务连接互联网请禁用并重试")

    local result=$(echo $tmpresult | grep '"currentTerritory":' | sed 's/.*currentTerritory//' | cut -f3 -d'"' | head -n 1)
    if [ -n "$result" ]; then
        if [ -n "$VPNDetected" ]; then
            echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Red}No  (VPN Detected;Region: $result)${Font_Suffix}\n"
            return
        else
            echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Green}Yes (Region: $result)${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Red}Unsupported${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Radiko() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 "https://radiko.jp/area?_=1625406539531" 2>&1)

    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r Radiko:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local checkfailed=$(echo $tmpresult | grep 'class="OUT"')
    if [ -n "$checkfailed" ]; then
        echo -n -e "\r Radiko:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local checksuccess=$(echo $tmpresult | grep 'JAPAN')
    if [ -n "$checksuccess" ]; then
        area=$(echo $tmpresult | awk '{print $2}' | sed 's/.*>//')
        echo -n -e "\r Radiko:\t\t\t\t${Font_Green}Yes (City: $area)${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Radiko:\t\t\t\t${Font_Red}Unsupported${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_DMM() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 "https://api-p.videomarket.jp/v3/api/play/keyauth?playKey=4c9e93baa7ca1fc0b63ccf418275afc2&deviceType=3&bitRate=0&loginFlag=0&connType=" -H "X-Authorization: 2bCf81eLJWOnHuqg6nNaPZJWfnuniPTKz9GXv5IS" 2>&1)

    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r DMM:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local checkfailed=$(echo $tmpresult | grep 'Access is denied')
    if [ -n "$checkfailed" ]; then
        echo -n -e "\r DMM:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local checksuccess=$(echo $tmpresult | grep 'PlayKey has expired')
    if [ -n "$checksuccess" ]; then
        echo -n -e "\r DMM:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r DMM:\t\t\t\t\t${Font_Red}Unsupported${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_DMMTV() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST -d '{"player_name":"dmmtv_browser","player_version":"0.0.0","content_type_detail":"VOD_SVOD","content_id":"11uvjcm4fw2wdu7drtd1epnvz","purchase_product_id":null}' "https://api.beacon.dmm.com/v1/streaming/start" 2>&1)

    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r DMM TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local checkfailed=$(echo $tmpresult | grep 'FOREIGN')
    if [ -n "$checkfailed" ]; then
        echo -n -e "\r DMM TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local checksuccess=$(echo $tmpresult | grep 'UNAUTHORIZED')
    if [ -n "$checksuccess" ]; then
        echo -n -e "\r DMM TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r DMM TV:\t\t\t\t${Font_Red}Unsupported${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Catchplay() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://sunapi.catchplay.com/geo" -H "authorization: Basic NTQ3MzM0NDgtYTU3Yi00MjU2LWE4MTEtMzdlYzNkNjJmM2E0Ok90QzR3elJRR2hLQ01sSDc2VEoy" 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'code' | awk '{print $2}' | cut -f2 -d'"')
    region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'isoCode' | awk '{print $2}' | cut -f2 -d'"')
    if [ -n "$result" ]; then
        if [ "$result" = "0" ]; then
            echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
            return
        elif [ "$result" = "100016" ]; then
            echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        else
            echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_HotStar() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api.hotstar.com/o/v1/page/1557?offset=0&size=20&tao=0&tas=20" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r HotStar:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "401" ]; then
        local region=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sI "https://www.hotstar.com" | grep 'geo=' | sed 's/.*geo=//' | cut -f1 -d",")
        local site_region=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.hotstar.com" | sed 's@.*com/@@' | tr [:lower:] [:upper:])
        if [ -n "$region" ] && [ "$region" = "$site_region" ]; then
            echo -n -e "\r HotStar:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
            return
        else
            echo -n -e "\r HotStar:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        fi
    elif [ "$result" = "475" ]; then
        echo -n -e "\r HotStar:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HotStar:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_LiTV() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 -X POST 'https://www.litv.tv/api/get-urls-no-auth' -H 'content-type: application/json' -d '{"AssetId":"iNEWS","MediaType":"channel","puid":"b0b59472-72eb-4e06-b0b1-591716e4f9a4"}'  2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r LiTV:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | jq .error.code)
    if [[ "$result" != "null" ]]; then
        if [ "$result" = "42000087" ]; then
            echo -n -e "\r LiTV:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        elif [ "$result" = "42000075" ]; then
            echo -n -e "\r LiTV:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        else
            echo -n -e "\r LiTV:\t\t\t\t\t${Font_Red}Unknown (Code: $result)${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r LiTV:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_FridayVideo() {
    local tmpresult=$(curl $curlArgs -${1} -sSL --max-time 10 --user-agent "${UA_Browser}" 'https://video.friday.tw/api2/streaming/get?streamingId=122581&streamingType=2&contentType=4&contentId=1&clientId=' 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r Friday Video:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | jq .code | tr -d '"')
    if [[ "$result" != "null" ]]; then
        if [ "$result" = "1006" ]; then
            echo -n -e "\r Friday Video:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        elif [ "$result" = "0000" ]; then
            echo -n -e "\r Friday Video:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        else
            echo -n -e "\r Friday Video:\t\t\t\t${Font_Red}Unknown (Code: $result)${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r Friday Video:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_FuboTV() {
    local radom_num=${RANDOM:0-1}
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://api.fubo.tv/appconfig/v1/homepage?platform=web&client_version=R20230310.${radom_num}&nav=v0"2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Fubo TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Fubo TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'Forbidden IP')
    if [ -n "$result" ]; then
        echo -n -e "\r Fubo TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Fubo TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Fox() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://x-live-fox-stgec.uplynk.com/ausw/slices/8d1/d8e6eec26bf544f084bad49a7fa2eac5/8d1de292bcc943a6b886d029e6c0dc87/G00000000.ts?pbs=c61e60ee63ce43359679fb9f65d21564&cloud=aws&si=0" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r FOX:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r FOX:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r FOX:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r FOX:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Joyn() {
    local tmpauth=$(curl $curlArgs -${1} -s --max-time 10 -X POST "https://auth.joyn.de/auth/anonymous" -H "Content-Type: application/json" -d '{"client_id":"b74b9f27-a994-4c45-b7eb-5b81b1c856e7","client_name":"web","anon_device_id":"b74b9f27-a994-4c45-b7eb-5b81b1c856e7"}' 2>&1)
    if [ -z "$tmpauth" ]; then
        echo -n -e "\r Joyn:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    auth=$(echo $tmpauth | python -m json.tool 2>/dev/null | grep access_token | awk '{print $2}' | cut -f2 -d'"')
    local result=$(curl $curlArgs -s "https://api.joyn.de/content/entitlement-token" -H "x-api-key: 36lp1t4wto5uu2i2nk57ywy9on1ns5yg" -H "content-type: application/json" -d '{"content_id":"daserste-de-hd","content_type":"LIVE"}' -H "authorization: Bearer $auth" 2>&1)
    if [ -n "$result" ]; then
        isBlock=$(echo $result | python -m json.tool 2>/dev/null | grep 'code' | awk '{print $2}' | cut -f2 -d'"')
        if [[ "$isBlock" == "ENT_AssetNotAvailableInCountry" ]]; then
            echo -n -e "\r Joyn:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        else
            echo -n -e "\r Joyn:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r Joyn:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_SKY_DE() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://edge.api.brightcove.com/playback/v1/accounts/1050888051001/videos/6247131490001" -H "Accept: application/json;pk=BCpkADawqM0OXCLe4eIkpyuir8Ssf3kIQAM62a1KMa4-1_vTOWQIxoHHD4-oL-dPmlp-rLoS-WIAcaAMKuZVMR57QY4uLAmP4Ov3V416hHbqr0GNNtzVXamJ6d4-rA3Xi98W-8wtypdEyjGEZNepUCt3D7UdMthbsG-Ean3V4cafT4nZX03st5HlyK1chp51SfA-vKcAOhHZ4_Oa9TTN61tEH6YqML9PWGyKrbuN5myICcGsFzP3R2aOF8c5rPCHT2ZAiG7MoavHx8WMjhfB0QdBr2fphX24CSpUKlcjEnQJnBiA1AdLg9iyReWrAdQylX4Eyhw5OwKiCGJznfgY6BDtbUmeq1I9r9RfmhP5bfxVGjILSEFZgXbMqGOvYdrdare0aW2fTCxeHdHt0vyKOWTC6CS1lrGJF2sFPKn1T1csjVR8s4MODqCBY1PTbHY4A9aZ-2MDJUVJDkOK52hGej6aXE5b9N9_xOT2B9wbXL1B1ZB4JLjeAdBuVtaUOJ44N0aCd8Ns0o02E1APxucQqrjnEociLFNB0Bobe1nkGt3PS74IQcs-eBvWYSpolldMH6TKLu8JqgdnM4WIp3FZtTWJRADgAmvF9tVDUG9pcJoRx_CZ4im-rn-AzN3FeOQrM4rTlU3Q8YhSmyEIoxYYqsFDwbFlhsAcvqQkgaElYtuciCL5i3U8N4W9rIhPhQJzsPafmLdWxBP_FXicyek25GHFdQzCiT8nf1o860Jv2cHQ4xUNcnP-9blIkLy9JmuB2RgUXOHzWsrLGGW6hq9wLUtqwEoxcEAAcNJgmoC0k8HE-Ga-NHXng6EFWnqiOg_mZ_MDd7gmHrrKLkQV" -H "Origin: https://www.sky.de" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Sky DE:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep error_subcode | cut -f4 -d'"')
    if [[ "$result" == "CLIENT_GEO" ]]; then
        echo -n -e "\r Sky DE:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$result" ] && [ -n "$tmpresult" ]; then
        echo -n -e "\r Sky DE:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Sky DE:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_ZDF() {
    # 测试，连续请求两次 (单独请求一次可能会返回35, 第二次开始变成0)
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://ssl.zdf.de/geo/de/geo.txt/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r ZDF: \t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "404" ]; then
        echo -n -e "\r ZDF: \t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r ZDF: \t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r ZDF: \t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_HBOGO_ASIA() {

    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api2.hbogoasia.com/v1/geog?lang=undefined&version=0&bundleId=www.hbogoasia.com" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r HBO GO Asia:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep territory)
    if [ -z "$result" ]; then
        echo -n -e "\r HBO GO Asia:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -n "$result" ]; then
        local CountryCode=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep country | cut -f4 -d'"')
        echo -n -e "\r HBO GO Asia:\t\t\t\t${Font_Green}Yes (Region: $CountryCode)${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HBO GO Asia:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_EPIX() {
    tmpToken=$(curl $curlArgs -${1} -s -X POST --max-time 10 "https://api.epix.com/v2/sessions" -H "Content-Type: application/json" -d '{"device":{"guid":"e2add88e-2d92-4392-9724-326c2336013b","format":"console","os":"web","app_version":"1.0.2","model":"browser","manufacturer":"google"},"apikey":"53e208a9bbaee479903f43b39d7301f7","oauth":{"token":null}}' 2>&1)
    if [ -z "$tmpToken" ]; then
        echo -n -e "\r Epix:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [[ "$tmpToken" == "error code"* ]]; then
        echo -n -e "\r Epix:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    EpixToken=$(echo $tmpToken | python -m json.tool 2>/dev/null | grep 'session_token' | cut -f4 -d'"')
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 -X POST -H 'content-type: application/json' -H "x-session-token: ${EpixToken}" -d $'{"operationName":"PlayFlow","variables":{"id":"bW92aWU7MjExNDc=","supportedActions":["open_url","show_notice","start_billing","play_content","log_in","noop","confirm_provider","unlinked_provider"],"streamTypes":[{"encryptionScheme":"CBCS","packagingSystem":"DASH"},{"encryptionScheme":"CENC","packagingSystem":"DASH"},{"encryptionScheme":"NONE","packagingSystem":"HLS"},{"encryptionScheme":"SAMPLE_AES","packagingSystem":"HLS"}]},"query":"fragment ShowNotice on ShowNotice {\\n  type\\n  actions {\\n    continuationContext\\n    text\\n    __typename\\n  }\\n  description\\n  title\\n  __typename\\n}\\n\\nfragment OpenUrl on OpenUrl {\\n  type\\n  url\\n  __typename\\n}\\n\\nfragment Content on Content {\\n  title\\n  __typename\\n}\\n\\nfragment Movie on Movie {\\n  id\\n  shortName\\n  __typename\\n}\\n\\nfragment Episode on Episode {\\n  id\\n  series {\\n    shortName\\n    __typename\\n  }\\n  seasonNumber\\n  number\\n  __typename\\n}\\n\\nfragment Preroll on Preroll {\\n  id\\n  __typename\\n}\\n\\nfragment ContentUnion on ContentUnion {\\n  ...Content\\n  ...Movie\\n  ...Episode\\n  ...Preroll\\n  __typename\\n}\\n\\nfragment PlayContent on PlayContent {\\n  type\\n  continuationContext\\n  heartbeatToken\\n  currentItem {\\n    content {\\n      ...ContentUnion\\n      __typename\\n    }\\n    __typename\\n  }\\n  nextItem {\\n    content {\\n      ...ContentUnion\\n      __typename\\n    }\\n    showNotice {\\n      ...ShowNotice\\n      __typename\\n    }\\n    showNoticeAt\\n    __typename\\n  }\\n  amazonPlaybackData {\\n    pid\\n    playbackToken\\n    materialType\\n    __typename\\n  }\\n  playheadPosition\\n  vizbeeStreamInfo {\\n    customStreamInfo\\n    __typename\\n  }\\n  closedCaptions {\\n    ttml {\\n      location\\n      __typename\\n    }\\n    vtt {\\n      location\\n      __typename\\n    }\\n    xml {\\n      location\\n      __typename\\n    }\\n    __typename\\n  }\\n  hints {\\n    duration\\n    seekAllowed\\n    trackingEnabled\\n    trackingId\\n    __typename\\n  }\\n  streams(types: $streamTypes) {\\n    playlistUrl\\n    closedCaptionsEmbedded\\n    packagingSystem\\n    encryptionScheme\\n    videoQuality {\\n      height\\n      width\\n      __typename\\n    }\\n    widevine {\\n      authenticationToken\\n      licenseServerUrl\\n      __typename\\n    }\\n    playready {\\n      authenticationToken\\n      licenseServerUrl\\n      __typename\\n    }\\n    fairplay {\\n      authenticationToken\\n      certificateUrl\\n      licenseServerUrl\\n      __typename\\n    }\\n    __typename\\n  }\\n  __typename\\n}\\n\\nfragment StartBilling on StartBilling {\\n  type\\n  __typename\\n}\\n\\nfragment LogIn on LogIn {\\n  type\\n  __typename\\n}\\n\\nfragment Noop on Noop {\\n  type\\n  __typename\\n}\\n\\nfragment PreviewContent on PreviewContent {\\n  type\\n  title\\n  description\\n  stream {\\n    sources {\\n      hls {\\n        location\\n        __typename\\n      }\\n      __typename\\n    }\\n    __typename\\n  }\\n  __typename\\n}\\n\\nfragment ConfirmProvider on ConfirmProvider {\\n  type\\n  __typename\\n}\\n\\nfragment UnlinkedProvider on UnlinkedProvider {\\n  type\\n  __typename\\n}\\n\\nquery PlayFlow($id: String\u0021, $supportedActions: [PlayFlowActionEnum\u0021]\u0021, $context: String, $behavior: BehaviorEnum = DEFAULT, $streamTypes: [StreamDefinition\u0021]) {\\n  playFlow(\\n    id: $id\\n    supportedActions: $supportedActions\\n    context: $context\\n    behavior: $behavior\\n  ) {\\n    ...ShowNotice\\n    ...OpenUrl\\n    ...PlayContent\\n    ...StartBilling\\n    ...LogIn\\n    ...Noop\\n    ...PreviewContent\\n    ...ConfirmProvider\\n    ...UnlinkedProvider\\n    __typename\\n  }\\n}"}' 'https://api.epix.com/graphql'  2>&1)

    local isBlocked=$(echo $tmpresult | grep 'MGM+ is only available in the United States')
    local isOK=$(echo $tmpresult | grep StartBilling)
    if [ -n "$isBlocked" ]; then
        echo -n -e "\r MGM+:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -n "$isOK" ]; then
        echo -n -e "\r MGM+:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MGM+:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NLZIET() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 'https://api.nlziet.nl/v7/stream/handshake/Widevine/Dash/VOD/rzIL9rb-TkSn-ek_wBmvaw?playerName=BitmovinWeb'   -H 'accept: application/json, text/plain, */*'   -H 'accept-language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6'   -H 'authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkM4M0YzQUFGOTRCOTM0ODA2NkQwRjZDRTNEODhGQkREIiwidHlwIjoiYXQrand0In0.eyJuYmYiOjE3MTIxMjY0NTMsImV4cCI6MTcxMjE1NTI0OCwiaXNzIjoiaHR0cHM6Ly9pZC5ubHppZXQubmwiLCJhdWQiOiJhcGkiLCJjbGllbnRfaWQiOiJ0cmlwbGUtd2ViIiwic3ViIjoiMDAzMTZiNGEtMDAwMC0wMDAwLWNhZmUtZjFkZTA1ZGVlZmVlIiwiYXV0aF90aW1lIjoxNzEyMTI2NDUzLCJpZHAiOiJsb2NhbCIsImVtYWlsIjoibXVsdGkuZG5zMUBvdXRsb29rLmNvbSIsInVzZXJJZCI6IjMyMzg3MzAiLCJjdXN0b21lcklkIjoiMCIsImRldmljZUlkZW50aWZpZXIiOiJJZGVudGl6aWV0LTI0NWJiNmYzLWM2ZjktNDNjZS05ODhmLTgxNDc2OTcwM2E5OCIsImV4dGVybmFsVXNlcklkIjoiZTM1ZjdkMzktMjQ0ZC00ZTkzLWFkOTItNGFjYzVjNGY0NGNlIiwicHJvZmlsZUlkIjoiMjdDMzM3RjktOTRDRS00NjBDLTlBNjktMTlDNjlCRTYwQUIzIiwicHJvZmlsZUNvbG9yIjoiRkY0MjdDIiwicHJvZmlsZVR5cGUiOiJBZHVsdCIsIm5hbWUiOiJTdHJlYW1pbmciLCJqdGkiOiI4Q0M1QzYzNkJGRjg3MEE2REJBOERBNUMwQTk0RUZDRiIsImlhdCI6MTcxMjEyNjQ1Mywic2NvcGUiOlsiYXBpIiwib3BlbmlkIl0sImFtciI6WyJwcm9maWxlIiwicHdkIl19.bk-ziFPJM00bpE7TcgPmIYFFx-2Q5N3BkUzEvQ_dDMK9O1F9f7DEe-Qzmnb5ym7ChlnXwrCV3QyOOA24hu_gCrlNlD7-vI3XGZR-54zFD-F7cRDOoL-1-iO_10tmgwb5Io-svY0bn0EDYKeRxYYBi0w_3bFVFDM2CxxA6tWeBYIfN5rCSzBHd3RPPjYtqX-sogyh_5W_7KJ83GK5kpsywT3mz8q7Cs1mtKs9QA1-o01N0RvTxZAcfzsHg3-qGgLnvaAuZ_XqRK9kLWqJWeJTWKWtUI6OlPex22sY3keKFpfZnUtFv-BvkCM6tvbIlMZAClk3lhI8rMFAWDpUcbcS3w'   -H 'nlziet-appname: WebApp'   -H 'nlziet-appversion: 5.43.24'   -H 'origin: https://app.nlziet.nl'   -H 'referer: https://app.nlziet.nl/'  2>&1)
    local isBlocked=$(echo $tmpresult | grep 'CountryNotAllowed')
    local isOK=$(echo $tmpresult | grep 'streamSessionId')
    if [ -n "$isBlocked" ]; then
        echo -n -e "\r NLZIET:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -n "$isOK" ]; then
        echo -n -e "\r NLZIET:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r NLZIET:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_videoland() {
    local tmpresult=$(curl $curlArgs -${1} -sS --user-agent "${UA_Browser}" --max-time 10  -X POST -H 'content-type: application/json' -d '{"operationName":"IsOnboardingGeoBlocked","variables":{},"query":"query IsOnboardingGeoBlocked {\n isOnboardingGeoBlocked\n}\n"}' 'https://api.videoland.com/subscribe/videoland-account/graphql' 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r videoland:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | jq .data.isOnboardingGeoBlocked)
    if [[ "$result" == "false" ]]; then
        echo -n -e "\r videoland:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r videoland:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NPO_Start_Plus() {
    local tmptoken=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sS  --max-time 10 "https://npo.nl/start/api/domain/player-token?productId=BV_101410466")
    if [[ "$tmptoken" == "curl"* ]]; then
        echo -n -e "\r NPO Start Plus:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local token=$(echo $tmptoken | jq .token | tr -d '"')
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sS --max-time 10 "https://prod.npoplayer.nl/stream-link" -X POST -H "Authorization:$token" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r NPO Start Plus:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | jq .status)
    if [[ "$result" == "451" ]]; then
        echo -n -e "\r NPO Start Plus:\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r NPO Start Plus:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_RakutenTV() {
    local tmpresult=$(curl $curlArgs -${1} -sS -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://rakuten.tv" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Rakuten TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'waitforit')
    if [ -n "$result" ]; then
        echo -n -e "\r Rakuten TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Rakuten TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Rakuten TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_HBO_Spain() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api-discovery.hbo.eu/v1/discover/hbo?language=null&product=hboe" -H "X-Client-Name: web" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r HBO Spain:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep signupAllowed | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r HBO Spain:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r HBO Spain:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HBO Spain:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_MoviStarPlus() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSI -X GET "https://contratar.movistarplus.es/" --write-out %{http_code} --output /dev/null 2>&1)
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Movistar+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "200" ]]; then
        echo -n -e "\r Movistar+:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "403" ]]; then
        echo -n -e "\r Movistar+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "000" ]]; then
        echo -n -e "\r Movistar+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Movistar+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_Sky_CH() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sS -o /dev/null -IL -X GET --max-time 10 -w '%{url_effective}\n' "https://sky.ch/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r SKY CH:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'out-of-country')
    if [ -n "$result" ]; then
        echo -n -e "\r SKY CH:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r SKY CH:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r SKY CH:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Starz() {
    local authorization=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 "https://www.starz.com/sapi/header/v1/starz/us/09b397fc9eb64d5080687fc8a218775b" -H "Referer: https://www.starz.com/us/en/" 2>&1)
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://auth.starz.com/api/v4/User/geolocation" -H "AuthTokenAuthorization: $authorization")
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local isAllowedAccess=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isAllowedAccess | awk '{print $2}' | cut -f1 -d",")
    local isAllowedCountry=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isAllowedCountry | awk '{print $2}' | cut -f1 -d",")
    local isKnownProxy=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isKnownProxy | awk '{print $2}' | cut -f1 -d",")
    if [[ "$isAllowedAccess" == "true" ]] && [[ "$isAllowedCountry" == "true" ]] && [[ "$isKnownProxy" == "false" ]]; then
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$isAllowedAccess" == "false" ]]; then
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$isKnownProxy" == "false" ]]; then
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_CanalPlus() {
    local tmpresult=$(curl $curlArgs -${1}  --user-agent "${UA_Browser}" -sS -o /dev/null -IL -X GET --max-time 10 -w '%{url_effective}\n' "https://boutique-tunnel.canalplus.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Canal+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'other-country-blocking')
    if [ -n "$result" ]; then
        echo -n -e "\r Canal+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Canal+:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Canal+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}


function MediaUnlockTest_FranceTV() {
    local tmpresult=$(curl $curlArgs -${1}  --user-agent "${UA_Browser}" -fsS -L -X GET --max-time 10  "https://geo-info.ftven.fr/ws/edgescape.json" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r France.tv:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo $tmpresult | jq '.reponse.geo_info.country_code' | tr -d '"')
    if [[ "$region" == "FR" ]]; then
        echo -n -e "\r France.tv:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    else
        echo -n -e "\r France.tv:\t\t\t\t${Font_Red}No   (Region: $region)${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r France.tv:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_CBCGem() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://www.cbc.ca/g/stats/js/cbc-stats-top.js" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r CBC Gem:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | sed 's/.*country":"//' | cut -f1 -d"}" | cut -f1 -d'"')
    if [[ "$result" == "CA" ]]; then
        echo -n -e "\r CBC Gem:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r CBC Gem:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_AcornTV() {
    local tmpresult=$(curl $curlArgs -${1} -s -L --max-time 10 "https://acorn.tv/")
    local isblocked=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://acorn.tv/" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Acorn TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [[ "$isblocked" == "403" ]]; then
        echo -n -e "\r Acorn TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'Not yet available in your country')
    if [ -n "$result" ]; then
        echo -n -e "\r Acorn TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Acorn TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Crave() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://capi.9c9media.com/destinations/crave_atexace/platforms/desktop/playback/contents/2189628/contentPackages/4178863/manifest.pmpd" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Crave:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'Geo Constraint Restrictions')
    if [ -n "$result" ]; then
        echo -n -e "\r Crave:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Crave:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Amediateka() {
    local tmpresult=$(curl $curlArgs -${1} -sSL -I -X GET -w "%{url_effective}" --max-time 10 --output /dev/null "https://www.amediateka.ru/" 2>&1)
    if [[ "$tmpresult" == *"curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Amediateka:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == *"curl"* ]]; then
        echo -n -e "\r Amediateka:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'unavailable')
    if [ -n "$result" ]; then
        echo -n -e "\r Amediateka:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Amediateka:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_MegogoTV() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://ctx.playfamily.ru/screenapi/v4/preparepurchase/web/1?elementId=0b974dc3-d4c5-4291-9df5-81a8132f67c5&elementAlias=51459024&elementType=GAME&withUpgradeSubscriptionReturnAmount=true&forceSvod=true&includeProductsForUpsale=false&sid=mDRnXOffdh_l2sBCyUIlbA" -H "X-SCRAPI-CLIENT-TS: 1627391624026" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Megogo TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep status | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "0" ]]; then
        echo -n -e "\r Megogo TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "502" ]]; then
        echo -n -e "\r Megogo TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Megogo TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_RaiPlay() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -s --max-time 10  "https://mediapolisvod.rai.it/relinker/relinkerServlet.htm?cont=VxXwi7UcqjApssSlashbjsAghviAeeqqEEqualeeqqEEqual&output=64" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Rai Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'no_available')
    if [ -n "$result" ]; then
        echo -n -e "\r Rai Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Rai Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_TVBAnywhere() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://uapisfm.tvbanywhere.com.sg/geoip/check/platform/android" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_21Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo $tmpresult | jq .country | tr -d '"' )
    local result=$(echo $tmpresult | jq .allow_in_this_country )
    if [[ "$region" == "HK" ]]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Yellow}Serviced by MyTvSuper (Region: ${region})${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Red}No  (Region: ${region})${Font_Suffix}\n"
        return
    else
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_ProjectSekai() {
    local result=$(curl $curlArgs --user-agent "User-Agent: pjsekai/48 CFNetwork/1240.0.4 Darwin/20.6.0" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://game-version.sekai.colorfulpalette.org/1.8.1/3ed70b6a-8352-4532-b819-108837926ff5" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Project Sekai: Colorful Stage:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Project Sekai: Colorful Stage:\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Project Sekai: Colorful Stage:\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Project Sekai: Colorful Stage:\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_KonosubaFD() {
    local result=$(curl $curlArgs -X POST --user-agent "User-Agent: pj0007/212 CFNetwork/1240.0.4 Darwin/20.6.0" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api.konosubafd.jp/api/masterlist" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Konosuba Fantastic Days:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Konosuba Fantastic Days:\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Konosuba Fantastic Days:\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Konosuba Fantastic Days:\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_SHOWTIME() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.showtime.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r SHOWTIME:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r SHOWTIME:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r SHOWTIME:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r SHOWTIME:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NBATV() {
    local tmpresult=$(curl $curlArgs -${1} -sSL --max-time 10 "https://www.nba.com/watch/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r NBA TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'Service is not available in your region')
    if [ -n "$result" ]; then
        echo -n -e "\r NBA TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r NBA TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_ATTNOW() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.atttvnow.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Directv Stream:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Directv Stream:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Directv Stream:\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_CineMax() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://play.maxgo.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r CineMax Go:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r CineMax Go:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r CineMax Go:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NetflixCDN() {
    #Detect Hijack
    if [[ "$1" == "6" ]]; then
        local nf_web_ip=$(getent ahostsv6 www.netflix.com | head -1 | awk '{print $1}')
    else
        local nf_web_ip=$(getent ahostsv4 www.netflix.com | head -1 | awk '{print $1}')
    fi
    if [ ! -n "$nf_web_ip" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Null${Font_Suffix}\n"
        return
    else
        local nf_web_isp=$(detect_isp $nf_web_ip)
        if [[ ! "$nf_web_isp" == *"Amazon"* ]] && [[ ! "$nf_web_isp" == *"Netflix"* ]]; then
            echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Yellow}Hijacked with [$nf_web_isp]${Font_Suffix}\n"
            return
        fi
    fi
    #Detect ISP's OCAs 
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 "https://api.fast.com/netflix/speedtest/v2?https=true&token=YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm&urlCount=1" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local isp=$(echo $tmpresult | jq .client.isp)
    local target_city=$(echo $tmpresult | jq .targets[0].location.city | tr -d '"')
    local target_country=$(echo $tmpresult | jq .targets[0].location.country | tr -d '"')
    local isp=$(echo $tmpresult | jq .client.isp | tr -d '"')
    local target_url=$(echo $tmpresult | jq .targets[0].url | tr -d '"')
    local target_fqdn=$(echo $target_url |awk -F"/" '{print $3}'| awk -F"." '{print $1}')
    if [ -n "$isp" ] && [[ "${isp}" != "null" ]] && [[ $target_url == *"isp.1.oca"*  ]]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Yellow}${isp}'s OCAs in ${target_city},${target_country} ($target_fqdn)${Font_Suffix}\n"
        return
    fi
    if [[ $target_url == *"isp.1.oca"* ]]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Yellow}ISP's OCAs in ${target_city},${target_country} ($target_fqdn)${Font_Suffix}\n"
        return
    fi
    #Detect Offical OCAs
    if [ -n "$target_city" ] && [ -n "$target_city" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Green}${target_city},${target_country} ($target_fqdn)${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    return

        
}

function MediaUnlockTest_HBO_Nordic() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api-discovery.hbo.eu/v1/discover/hbo?language=null&product=hbon" -H "X-Client-Name: web" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r HBO Nordic:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep signupAllowed | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r HBO Nordic:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r HBO Nordic:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HBO Nordic:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_HBO_Portugal() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api.ugw.hbogo.eu/v3.0/GeoCheck/json/PRT" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r HBO Portugal:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep allow | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "1" ]]; then
        echo -n -e "\r HBO Portugal:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "0" ]]; then
        echo -n -e "\r HBO Portugal:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HBO Portugal:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_SkyGo() {
    local tmpresult=$(curl $curlArgs -${1} -sL --max-time 10 "https://skyid.sky.com/authorise/skygo?response_type=token&client_id=sky&appearance=compact&redirect_uri=skygo://auth" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Sky Go:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep "You don't have permission to access")
    if [ -z "$result" ]; then
        echo -n -e "\r Sky Go:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Sky Go:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_DirecTVGO() {
    local tmpresult=$(curl $curlArgs -${1} -Ss -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.directvgo.com/registrarse" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r DirecTV Go:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local isForbidden=$(echo $tmpresult | grep 'proximamente')
    local region=$(echo $tmpresult | cut -f4 -d"/" | tr [:lower:] [:upper:])
    if [ -n "$isForbidden" ]; then
        echo -n -e "\r DirecTV Go:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$isForbidden" ] && [ -n "$region" ]; then
        echo -n -e "\r DirecTV Go:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r DirecTV Go:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_DAM() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "http://cds1.clubdam.com/vhls-cds1/site/xbox/sample_1.mp4.m3u8" 2>&1)
    if [[ "$result" == "000" ]]; then
        echo -n -e "\r Karaoke@DAM:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Karaoke@DAM:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Karaoke@DAM:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Karaoke@DAM:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_DiscoveryPlus() {
    local GetToken=$(curl $curlArgs -${1} -sS "https://us1-prod-direct.discoveryplus.com/token?deviceId=d1a4a5d25212400d1e6985984604d740&realm=go&shortlived=true" 2>&1)
    if [[ "$GetToken" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Discovery+:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$GetToken" == "curl"* ]]; then
        echo -n -e "\r Discovery+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local Token=$(echo $GetToken | python -m json.tool 2>/dev/null | grep '"token":' | cut -f4 -d'"')
    local tmpresult=$(curl $curlArgs -${1} -sS "https://us1-prod-direct.discoveryplus.com/users/me" -b "_gcl_au=1.1.858579665.1632206782; _rdt_uuid=1632206782474.6a9ad4f2-8ef7-4a49-9d60-e071bce45e88; _scid=d154b864-8b7e-4f46-90e0-8b56cff67d05; _pin_unauth=dWlkPU1qWTRNR1ZoTlRBdE1tSXdNaTAwTW1Nd0xUbGxORFV0WWpZMU0yVXdPV1l6WldFeQ; _sctr=1|1632153600000; aam_fw=aam%3D9354365%3Baam%3D9040990; aam_uuid=24382050115125439381416006538140778858; st=${Token}; gi_ls=0; _uetvid=a25161a01aa711ec92d47775379d5e4d; AMCV_BC501253513148ED0A490D45%40AdobeOrg=-1124106680%7CMCIDTS%7C18894%7CMCMID%7C24223296309793747161435877577673078228%7CMCAAMLH-1633011393%7C9%7CMCAAMB-1633011393%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1632413793s%7CNONE%7CvVersion%7C5.2.0; ass=19ef15da-95d6-4b1d-8fa2-e9e099c9cc38.1632408400.1632406594" 2>&1)
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep currentLocationTerritory | cut -f4 -d'"')
    if [[ "$result" == "us" ]]; then
        echo -n -e "\r Discovery+:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Discovery+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Discovery+:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_ESPNPlus() {
    local espncookie=$(echo "$Media_Cookie" | sed -n '11p')
    local TokenContent=$(curl -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://espn.api.edge.bamgrid.com/token" -H "authorization: Bearer ZXNwbiZicm93c2VyJjEuMC4w.ptUt7QxsteaRruuPmGZFaJByOoqKvDP2a5YkInHrc7c" -d "$espncookie" 2>&1)
    local isBanned=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'forbidden-location')
    local is403=$(echo $TokenContent | grep '403 ERROR')

    if [ -n "$isBanned" ] || [ -n "$is403" ]; then
        echo -n -e "\r ESPN+:${Font_SkyBlue}[Sponsored by Jam]${Font_Suffix}\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local fakecontent=$(echo "$Media_Cookie" | sed -n '10p')
    local refreshToken=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'refresh_token' | awk '{print $2}' | cut -f2 -d'"')
    local espncontent=$(echo $fakecontent | sed "s/ILOVESTAR/${refreshToken}/g")
    local tmpresult=$(curl -${1} --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://espn.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZXNwbiZicm93c2VyJjEuMC4w.ptUt7QxsteaRruuPmGZFaJByOoqKvDP2a5YkInHrc7c" -d "$espncontent" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r ESPN+:${Font_SkyBlue}[Sponsored by Jam]${Font_Suffix}\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | cut -f4 -d'"')
    local inSupportedLocation=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'inSupportedLocation' | awk '{print $2}' | cut -f1 -d',')

    if [[ "$region" == "US" ]] && [[ "$inSupportedLocation" == "true" ]]; then
        echo -n -e "\r ESPN+:${Font_SkyBlue}[Sponsored by Jam]${Font_Suffix}\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r ESPN+:${Font_SkyBlue}[Sponsored by Jam]${Font_Suffix}\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Stan() {
    local tmpresult=$(curl $curlArgs -${1} -X POST -sS --max-time 10 "https://api.stan.com.au/login/v1/sessions/web/account" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Stan:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep VPNDetected)
    if [ -z "$result" ]; then
        echo -n -e "\r Stan:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Stan:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_Binge() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://auth.streamotion.com.au" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Binge:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ] || [ "$result" = "302" ]; then
        echo -n -e "\r Binge:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Binge:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Binge:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Docplay() {
    local result=$(curl $curlArgs -${1} -Ss -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.docplay.com/subscribe" 2>&1 | grep 'geoblocked')
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Docplay:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        isKayoSportsOK=2
        return
    elif [ -n "$result" ]; then
        echo -n -e "\r Docplay:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        isKayoSportsOK=0
        return
    else
        echo -n -e "\r Docplay:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        isKayoSportsOK=1
        return
    fi

    echo -n -e "\r Docplay:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    isKayoSportsOK=2
    return

}

function MediaUnlockTest_OptusSports() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://sport.optus.com.au/api/userauth/validate/web/username/restriction.check@gmail.com" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Optus Sports:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Optus Sports:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Optus Sports:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Optus Sports:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_KayoSports() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://auth.streamotion.com.au" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Kayo Sports:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ] || [ "$result" = "302" ]; then
        echo -n -e "\r Kayo Sports:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Kayo Sports:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Kayo Sports:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NeonTV() {
    local NeonHeader=$(echo "$Media_Cookie" | sed -n '12p')
    local NeonContent=$(echo "$Media_Cookie" | sed -n '13p')
    local tmpresult=$(curl $curlArgs -${1} -sS -X POST "https://api.neontv.co.nz/api/client/gql?" -H "content-type: application/json" -H "$NeonHeader" -d "$NeonContent" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Neon TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'RESTRICTED_GEOLOCATION')
    if [ -z "$result" ]; then
        echo -n -e "\r Neon TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Neon TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_SkyGONZ() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSL --max-time 10  --output /dev/null -w %{http_code} "https://linear-s.stream.skyone.co.nz/sky-sport-1.mpd" 2>&1)
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r SkyGo NZ:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "200" ]]; then
        echo -n -e "\r SkyGo NZ:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r SkyGo NZ:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r SkyGo NZ:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_ThreeNow() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://bravo-livestream.fullscreen.nz/index.m3u8" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r ThreeNow:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r ThreeNow:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r ThreeNow:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r ThreeNow:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_MaoriTV() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://edge.api.brightcove.com/playback/v1/accounts/1614493167001/videos/6275380737001" -H "Accept: application/json;pk=BCpkADawqM2E9yW4lLgKIEIV5majz5djzZCIqJiYMkP5yYaYdF6AQYq4isPId1ZLtQdGnK1ErLYG0-r1N-3DzAEdbfvw9SFdDWz_i09pLp8Njx1ybslyIXid-X_Dx31b7-PLdQhJCws-vk6Y" -H "Origin: https://www.maoritelevision.com" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Maori TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep error_subcode | cut -f4 -d'"')
    if [[ "$result" == "CLIENT_GEO" ]]; then
        echo -n -e "\r Maori TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$result" ] && [ -n "$tmpresult" ]; then
        echo -n -e "\r Maori TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Maori TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_SBSonDemand() {

    local tmpresult=$(curl $curlArgs -${1} -sS "https://www.sbs.com.au/api/v3/network?context=odwebsite" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r SBS on Demand:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep country_code | cut -f4 -d'"')
    if [[ "$result" == "AU" ]]; then
        echo -n -e "\r SBS on Demand:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r SBS on Demand:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r SBS on Demand:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_ABCiView() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 "https://api.iview.abc.net.au/v2/show/abc-kids-live-stream/video/LS1604H001S00?embed=highlightVideo,selectedSeries" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r ABC iView:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'unavailable outside Australia')
    if [ -z "$result" ]; then
        echo -n -e "\r ABC iView:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r ABC iView:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_Channel9() {
    local result=$(curl $curlArgs -${1} -Ss -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://login.nine.com.au" 2>&1 | grep 'geoblock')
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Channel 9:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -n "$result" ]; then
        echo -n -e "\r Channel 9:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Channel 9:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Channel 9:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Telasa() {
    local tmpresult=$(curl $curlArgs -${1} -sS "https://api-videopass-anon.kddi-video.com/v1/playback/system_status" -H "X-Device-ID: d36f8e6b-e344-4f5e-9a55-90aeb3403799" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Telasa:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local isForbidden=$(echo $tmpresult | grep IPLocationNotAllowed)
    local isAllowed=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"type"' | cut -f4 -d'"')
    if [ -n "$isForbidden" ]; then
        echo -n -e "\r Telasa:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$isForbidden" ] && [[ "$isAllowed" == "OK" ]]; then
        echo -n -e "\r Telasa:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Telasa:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_SetantaSports() {
    local tmpresult=$(curl $curlArgs -${1} -sS "https://dce-frontoffice.imggaming.com/api/v2/consent-prompt" -H "Realm: dce.adjara" -H "x-api-key: 857a1e5d-e35e-4fdf-805b-a87b6f8364bf" 2>&1)
    local tmpresult1=$(curl $curlArgs -${1} -sS "https://dce-frontoffice.imggaming.com/api/v3/i18n/country-codes" -H "Realm: dce.adjara" -H "x-api-key: 857a1e5d-e35e-4fdf-805b-a87b6f8364bf" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Setanta Sports:\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Setanta Sports:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep outsideAllowedTerritories | awk '{print $2}' | cut -f1 -d",")
    local region=$(echo $tmpresult1 | python -m json.tool 2>/dev/null | grep callerCountryCode | awk '{print $2}' | cut -f2 -d'"')
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r Setanta Sports:\t\t\t${Font_Red}No  (Region: ${region})${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r Setanta Sports:\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Setanta Sports:\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_MolaTV() {
    local tmpresult=$(curl $curlArgs -${1} -sS "https://mola.tv/api/v2/videos/geoguard/check/vd30491025" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Mola TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Mola TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isAllowed | awk '{print $2}')
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r Mola TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r Mola TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Mola TV:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_BeinConnect() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://proxies.bein-mena-production.eu-west-2.tuc.red/proxy/availableOffers" 2>&1)
    if [ "$result" = "000" ] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [ "$result" = "000" ]; then
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "500" ]; then
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "451" ]; then
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_EurosportRO() {
    local tmpresult=$(curl $curlArgs -${1} -sS "https://eu3-prod-direct.eurosport.ro/playback/v2/videoPlaybackInfo/sourceSystemId/eurosport-vid1560178?usePreAuth=true" -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJVU0VSSUQ6ZXVyb3Nwb3J0OjlkMWU3MmYyLTdkYjItNDE2Yy1iNmIyLTAwZjQyMWRiN2M4NiIsImp0aSI6InRva2VuLTc0MDU0ZDE3LWFhNWUtNGI0ZS04MDM4LTM3NTE4YjBiMzE4OCIsImFub255bW91cyI6dHJ1ZSwiaWF0IjoxNjM0NjM0MzY0fQ.T7X_JOyvAr3-spU_6wh07re4W-fmbCxZdGaUSZiu1mw' 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep access.denied.geoblocked)
    if [ -n "$result" ]; then
        echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_DiscoveryPlusUK() {
    local GetToken=$(curl $curlArgs -${1} -sS "https://disco-api.discoveryplus.co.uk/token?realm=questuk&deviceId=61ee588b07c4df08c02861ecc1366a592c4ad02d08e8228ecfee67501d98bf47&shortlived=true" 2>&1)
    if [[ "$GetToken" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$GetToken" == "curl"* ]]; then
        echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local Token=$(echo $GetToken | python -m json.tool 2>/dev/null | grep '"token":' | cut -f4 -d'"')
    local tmpresult=$(curl $curlArgs -${1} -sS "https://disco-api.discoveryplus.co.uk/users/me" -b "st=${Token}" 2>&1)
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep currentLocationTerritory | cut -f4 -d'"')
    if [[ "$result" == "gb" ]]; then
        echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Channel5() {
    local Timestamp=$(date +%s)
    local tmpresult=$(curl $curlArgs -${1} -sL --max-time 10 "https://cassie.channel5.com/api/v2/live_media/my5desktopng/C5.json?timestamp=${Timestamp}&auth=0_rZDiY0hp_TNcDyk2uD-Kl40HqDbXs7hOawxyqPnbI" 2>&1)
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep code | cut -f4 -d'"')
    if [ -z "$result" ] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Channel 5:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
    elif [[ "$result" == "4003" ]]; then
        echo -n -e "\r Channel 5:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ -n "$result" ] && [[ "$result" != "4003" ]]; then
        echo -n -e "\r Channel 5:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Channel 5:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_MyVideo() {
    local tmpresult=$(curl $curlArgs -${1} -SsL -o /dev/null --max-time 10 -w '%{url_effective}\n' "https://www.myvideo.net.tw/login.do" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r MyVideo:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r MyVideo:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'serviceAreaBlock')
    if [ -n "$result" ]; then
        echo -n -e "\r MyVideo:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MyVideo:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r MyVideo:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_7plus() {
    local result1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://7plus-sevennetwork.akamaized.net/media/v1/dash/live/cenc/5303576322001/68dca38b-85d7-4dae-b1c5-c88acc58d51c/f4ea4711-514e-4cad-824f-e0c87db0a614/225ec0a0-ef18-4b7c-8fd6-8dcdd16cf03a/1x/segment0.m4f?akamai_token=exp=1672500385~acl=/media/v1/dash/live/cenc/5303576322001/68dca38b-85d7-4dae-b1c5-c88acc58d51c/f4ea4711-514e-4cad-824f-e0c87db0a614/*~hmac=800e1e1d1943addf12b71339277c637c7211582fe12d148e486ae40d6549dbde" 2>&1)
    if [[ "$GetPlayURL" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r 7plus:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$GetPlayURL" == "curl"* ]]; then
        echo -n -e "\r 7plus:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "200" ]]; then
        echo -n -e "\r 7plus:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r 7plus:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Channel10() {
    local tmpresult=$(curl $curlArgs -${1} -sL --max-time 10 "https://e410fasadvz.global.ssl.fastly.net/geo" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Channel 10:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Channel 10:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'allow' | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "false" ]]; then
        echo -n -e "\r Channel 10:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "true" ]]; then
        echo -n -e "\r Channel 10:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Channel 10:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Spotify() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 https://www.spotify.com/tw/signup 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Spotify Region:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local country=$(echo $tmpresult | grep -Eo 'geoCountry.*","geoCountryMarket"')

    if [ -n "$country" ]; then
        echo -n -e "\r Spotify Region:\t\t\t${Font_Green}${country:13:-20}${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r Spotify Region:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_VideoMarket() {
    local TokenSrc=$(curl $curlArgs  --user-agent "${UA_Browser}" -${1} -Ss --max-time 10 "https://www.videomarket.jp/player/17588S/A17588S001999H01"  2>&1)
    if [[ "$TokenSrc" == "curl"* ]]; then
        echo -n -e "\r VideoMarket:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local Token=$(echo $TokenSrc| grep -Eo 'notLoggedInTokenPc:(.|)*notLoggedInTokenSpAndroid')
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --max-time 10 "https://www.videomarket.jp/graphql" -X POST -d '{"operationName":"readStatus","variables":{},"query":"query readStatus {\n  readStatus {\n    isRead\n    __typename\n  }\n}\n"}' -H "Authorization:Bearer ${Token:20:-27}"   2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r VideoMarket:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep OverseasAccess)
    if [ -n "$result" ]; then
        echo -n -e "\r VideoMarket:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r VideoMarket:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_J:COM_ON_DEMAND() {
	local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://id.zaq.ne.jp" 2>&1)
	if [ "$result" = "000" ]; then
        echo -n -e "\r J:com On Demand:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "404" ]; then
        echo -n -e "\r J:com On Demand:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r J:com On Demand:\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r J:com On Demand:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_music.jp() {
	local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sL --max-time 10 "https://overseaauth.music-book.jp/globalIpcheck.js" 2>&1)
	if [ -n "$result" ]; then
        echo -n -e "\r music.jp:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r music.jp:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Instagram.Music() {
    local tmpresult=$(curl -sS --user-agent "${UA_Browser}" $curlArgs -${1}  'https://www.instagram.com/graphql/query'  -d 'av=0&__d=www&__user=0&__a=1&__req=3&__hs=19876.HYP%3Ainstagram_web_pkg.2.1..0.0&dpr=1&__ccg=UNKNOWN&__rev=1013915830&__s=e0krj4%3Ay7ob1k%3Arsdf9x&__hsi=7375722728458088454&__dyn=7xeUjG1mxu1syUbFp40NonwgU7SbzEdF8aUco2qwJw5ux609vCwjE1xoswaq0yE7i0n24oaEd86a3a1YwBgao6C0Mo2iyo7u3i4U2zxe2GewGwso88cobEaU2eUlwhEe87q7U1bobpEbUGdwtU662O0z8c86-3u2WE5B0bK1Iwqo5q1IQp1yUoxe4UrAwCAxW6Uf9EO6VU8U&__csr=gpgJOllNq9nP9ROd9bqTh-GEzh_jppaAGmAyGprFoBkVqmh2QHF28y-GBrgHV9aByaQ8XiyUCl7GX-bl12UHx2gxp8GUSuaBVAGCXK48zHKHUG2mi669G8KcjAgCEW8yax911u6V5yE01mJPw2mpU4yu1I8030e56OmawtxxkaDwkEGu0yQ0eYwdfw6NyGiG2Cae2S0Z80gvwsU2ACkE020ww3UU&__comet_req=7&lsd=AVpOeIV9Tzw&jazoest=2984&__spin_r=1013915830&__spin_b=trunk&__spin_t=1717294270&fb_api_caller_class=RelayModern&fb_api_req_friendly_name=PolarisPostActionLoadPostQueryQuery&variables=%7B%22shortcode%22%3A%22C2YEAdOh9AB%22%2C%22fetch_comment_count%22%3A0%2C%22parent_comment_count%22%3A0%2C%22child_comment_count%22%3A0%2C%22fetch_like_count%22%3A0%2C%22fetch_tagged_user_count%22%3Anull%2C%22fetch_preview_comment_count%22%3A0%2C%22has_threaded_comments%22%3Atrue%2C%22hoisted_comment_id%22%3Anull%2C%22hoisted_reply_id%22%3Anull%7D&server_timestamps=true&doc_id=25531498899829322' 2>&1 )
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Instagram Licensed Music:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | jq .data.xdt_shortcode_media.clips_music_attribution_info.should_mute_audio)
    if [[ "$result" == "false" ]]; then
        echo -n -e "\r Instagram Licensed Music:\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [[ "$result" == "true" ]]; then
        echo -n -e "\r Instagram Licensed Music:\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Instagram Licensed Music:\t\t${Font_Red}No  (Failed)${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_Popcornflix(){
    local result=$(curl $curlArgs -${1} -s --user-agent "${UA_Browser}" --write-out %{http_code} --output /dev/null --max-time 10 "https://popcornflix-prod.cloud.seachange.com/cms/popcornflix/clientconfiguration/versions/2" 2>&1)
    if [ "$result" = "000" ] && [ "$1" == "6" ]; then
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
    elif [ "$result" = "000" ] && [ "$1" == "4" ]; then
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_TubiTV(){
    local tmpresult=$(curl $curlArgs -${1} -sSL --user-agent "${UA_Browser}" -w "%{url_effective}\n" -o /dev/null  --max-time 10 "https://tubitv.com" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Tubi TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'gdpr.tubi.tv')
    if [ -n "$result" ]; then
        echo -n -e "\r Tubi TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Tubi TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Philo(){
    local tmpresult=$(curl $curlArgs -${1} -fsSL --user-agent "${UA_Browser}" --max-time 10 "https://content-us-east-2-fastly-b.www.philo.com/geo" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"status":' | cut -f1 -d',' | awk '{print $2}' | sed 's/"//g')
    if [[ "$result" == 'FAIL' ]]; then
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    elif [[ "$result" == 'SUCCESS' ]]; then
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Green}Failed${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_FXNOW(){
    local tmpresult=$(curl $curlArgs -${1} -fsSL --user-agent "${UA_Browser}" --max-time 10 "https://fxnow.fxnetworks.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r FXNOW:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r FXNOW:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'is not accessible')
    if [ -n "$result" ]; then
        echo -n -e "\r FXNOW:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r FXNOW:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Crunchyroll(){
    local tmpresult=$(curl $curlArgs -${1} -fsSL --user-agent "${UA_Browser}" --max-time 10 "https://c.evidon.com/geo/country.js" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Crunchyroll:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Crunchyroll:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep "'code':'us'")
    if [ -z "$result" ]; then
        echo -n -e "\r Crunchyroll:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Crunchyroll:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}


function MediaUnlockTest_CWTV(){
    local result=$(curl $curlArgs -${1} -fsL --user-agent "${UA_Browser}" --write-out %{http_code} --output /dev/null --max-time 10 --retry 3 "https://www.cwtv.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r CW TV:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r CW TV:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r CW TV:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r CW TV:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Shudder(){
    local tmpresult=$(curl $curlArgs -${1} -sS --user-agent "${UA_Browser}" --max-time 10 "https://www.shudder.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Shudder:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'not available')
    if [ -n "$result" ]; then
        echo -n -e "\r Shudder:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Shudder:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_TLCGO(){
    onetrustresult=$(curl $curlArgs -${1} -sS --user-agent "${UA_Browser}" --max-time 10 "https://geolocation.onetrust.com/cookieconsentpub/v1/geo/location/dnsfeed" 2>&1)
    if [ "$1" == "6" ]; then
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$onetrustresult" == "curl"* ]]; then
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -z "$onetrustresult" ]; then
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
    local result=$(echo $onetrustresult | grep '"country":"US"')
    if [ -z "$result" ]; then
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Wavve() {
    local result1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://apis.wavve.com/fz/streaming?device=pc&partner=pooq&apikey=E5F3E0D30947AA5440556471321BB6D9&credential=none&service=wavve&pooqzone=none&region=kor&drm=pr&targetage=all&contentid=MV_C3001_C300000012559&contenttype=movie&hdr=sdr&videocodec=avc&audiocodec=ac3&issurround=n&format=normal&withinsubtitle=n&action=dash&protocol=dash&quality=auto&deviceModelId=Windows%2010&guid=1a8e9c88-6a3b-11ed-8584-eed06ef80652&lastplayid=none&authtype=cookie&isabr=y&ishevc=n" 2>&1)
    if [[ "$result1" == "000" ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Wavve:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result1" == "000" ]]; then
        echo -n -e "\r Wavve:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "200" ]]; then
        echo -n -e "\r Wavve:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Wavve:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Tving() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL --max-time 10 "https://api.tving.com/v2a/media/stream/info?apiKey=1e7952d0917d6aab1f0293a063697610&mediaCode=RV60891248" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Tving:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Tving:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'play')
    if [ -z "$result1" ]; then
        echo -n -e "\r Tving:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Tving:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_CoupangPlay() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsI --max-time 10 "https://www.coupangplay.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Coupang Play:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Coupang Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep 'Location' -i | awk '{print $2}' )
    if [[ "$result1" == *"/not-available"* ]]; then
        echo -n -e "\r Coupang Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Coupang Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_NaverTV() {
    local ts=$(date +%s%3N)
    local base_url="https://apis.naver.com/"
    local key="nbxvs5nwNG9QKEWK0ADjYA4JZoujF4gHcIwvoCxFTPAeamq5eemvt5IWAYXxrbYM"
    local sign_text="https://apis.naver.com/now_web2/now_web_api/v1/clips/31030608/play-info${ts}"
    local signature=$(printf "%s" "${sign_text}" | openssl dgst -sha1 -hmac "${key}" -binary | openssl base64)
    local signature_encoded=$(printf "%s" "${signature}" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/\*/%2a/g;s/+/%2b/g;s/,/%2c/g;s/\//%2f/g;s/:/%3a/g;s/;/%3b/g;s/=/%3d/g;s/?/%3f/g;s/@/%40/g;s/\[/%5b/g;s/\]/%5d/g')
    local req_url="${base_url}now_web2/now_web_api/v1/clips/31030608/play-info?msgpad=${ts}&md=${signature_encoded}"
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "${req_url}" --user-agent "${UA_Browser}" -H 'host: apis.naver.com' -H 'connection: keep-alive' -H "sec-ch-ua: ${UA_SecCHUA}" -H 'accept: application/json, text/plain, */*' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'origin: https://tv.naver.com' -H 'sec-fetch-site: same-site' -H 'sec-fetch-mode: cors' -H 'sec-fetch-dest: empty' -H 'referer: https://tv.naver.com/v/31030608' -H 'accept-language: en,zh-CN;q=0.9,zh;q=0.8')
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Naver TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Naver TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local playable=$(echo "$tmpresult" | python -m json.tool 2>/dev/null | grep -o '"playable": *"[^"]*"' | cut -d'"' -f4)

    if [[ "$playable" == "NOT_COUNTRY_AVAILABLE" ]] && [ -n "$playable" ]; then
        echo -n -e "\r Naver TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Naver TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r Naver TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    return
    # local result=$(echo "$tmpresult" | python -m json.tool 2>/dev/null | grep ctry | cut -f4 -d'"')
    # if [[ "$result" == "KR" ]]; then
    #     echo -n -e "\r Naver TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    # else
    #     echo -n -e "\r Naver TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    # fi
}

function MediaUnlockTest_Afreeca() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL --max-time 10 "https://vod.afreecatv.com/player/97464151" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Afreeca TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Afreeca TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep "document.location.href='https://vod.afreecatv.com'" )
    if [ -z "$result1" ]; then
        echo -n -e "\r Afreeca TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Afreeca TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_KBSDomestic() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL --max-time 10 "https://vod.kbs.co.kr/index.html?source=episode&sname=vod&stype=vod&program_code=T2022-0690&program_id=PS-2022164275-01-000&broadcast_complete_yn=N&local_station_code=00&section_code=03" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r KBS Domestic:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r KBS Domestic:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep "ipck" | grep 'Domestic\\\":\ true' )
    if [ -z "$result1" ]; then
        echo -n -e "\r KBS Domestic:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r KBS Domestic:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_SpotvNow() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}"  -Ss --max-time 10 'https://edge.api.brightcove.com/playback/v1/accounts/5764318566001/videos/6349973203112'   -H 'accept: application/json;pk=BCpkADawqM0U3mi_PT566m5lvtapzMq3Uy7ICGGjGB6v4Ske7ZX_ynzj8ePedQJhH36nym_5mbvSYeyyHOOdUsZovyg2XlhV6rRspyYPw_USVNLaR0fB_AAL2HSQlfuetIPiEzbUs1tpNF9NtQxt3BAPvXdOAsvy1ltLPWMVzJHiw9slpLRgI2NUufc' 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r SPOTV NOW:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r SPOTV NOW:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | jq .[0].error_subcode 2>/dev/null | tr -d '"')
    local region=$(echo $tmpresult | jq .[0].client_geo 2>/dev/null | tr -d '"')
    if [[ "$result" == "CLIENT_GEO" ]]; then
        echo -n -e "\r SPOTV NOW:\t\t\t\t${Font_Red}No  (Region: ${region^^})${Font_Suffix}\n"
        return
    elif [ -z "$result" ] && [ -n "$tmpresult" ]; then
        echo -n -e "\r SPOTV NOW:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r SPOTV NOW:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_KBSAmerican() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL --max-time 10 "https://vod.kbs.co.kr/index.html?source=episode&sname=vod&stype=vod&program_code=T2022-0690&program_id=PS-2022164275-01-000&broadcast_complete_yn=N&local_station_code=00&section_code=03" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r KBS American:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r KBS American:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep "ipck" | grep 'American\\\":\ true' )
    if [ -z "$result1" ]; then
        echo -n -e "\r KBS American:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r KBS American:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_KOCOWA() {
    local result1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.kocowa.com/" 2>&1)
    if [[ "$result1" == "000" ]] && [ "$1" == "6" ]; then
        echo -n -e "\r KOCOWA:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result1" == "000" ]]; then
        echo -n -e "\r KOCOWA:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "200" ]]; then
        echo -n -e "\r KOCOWA:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r KOCOWA:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_PandaTV() {
    local result1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api.pandalive.co.kr/v1/live/play" 2>&1)
    if [[ "$result1" == "000" ]] && [ "$1" == "6" ]; then
        echo -n -e "\r PandaTV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result1" == "000" ]]; then
        echo -n -e "\r PandaTV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "400" ]]; then
        echo -n -e "\r PandaTV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [[ "$result1" == "403" ]]; then
        echo -n -e "\r PandaTV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r PandaTV:\t\t\t\t${Font_Red}Unknown (Code: $result1)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_NBCTV(){
    if [[ "$onetrustresult" == "curl"* ]]; then
        echo -n -e "\r NBC TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -z "$onetrustresult" ]; then
        echo -n -e "\r NBC TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
    local result=$(echo $onetrustresult | grep '"country":"US"')
    if [ -z "$result" ]; then
        echo -n -e "\r NBC TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r NBC TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Crackle(){
    local tmpresult=$(curl $curlArgs -${1} -sS -I --user-agent "${UA_Browser}" --max-time 10 "https://prod-api.crackle.com/appconfig" 2>&1 | grep -E 'x-crackle-region:|curl')
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Crackle:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -z "$tmpresult" ]; then
        echo -n -e "\r Crackle:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | awk '{print $2}' | sed 's/[[:space:]]//g')
    if [[ "$result" == "US" ]]; then
        echo -n -e "\r Crackle:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Crackle:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_AETV(){
    local tmpresult=$(curl $curlArgs -${1} -sS -X POST --user-agent "${UA_Browser}" --max-time 10 "https://ccpa-service.sp-prod.net/ccpa/consent/10265/display-dns" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"ccpaApplies":' | cut -f1 -d',' | awk '{print $2}')
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_NFLPlus() {
    local tmpresult=$(curl $curlArgs -${1} -fsL -w "%{http_code}\n%{url_effective}\n" -o /dev/null "https://www.nfl.com/plus/" 2>&1)
    if [[ "$tmpresult" == "000"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r NFL+:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "000"* ]]; then
        echo -n -e "\r NFL+:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'nflgamepass')
    if [ -n "$result" ]; then
        echo -n -e "\r NFL+:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r NFL+:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_SkyShowTime(){
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsi --max-time 10 "https://www.skyshowtime.com/" -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r SkyShowTime:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result1=$(echo "$tmpresult" | grep 'location' | head -1 | awk '{print $2}' )
    if [[ "$result1" == *"where-can-i-stream"* ]]; then
    	echo -n -e "\r SkyShowTime:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
    	local region1=$(echo -n "$result1" | sed 's#https://www.skyshowtime.com/\([0-9a-zA-Z][0-9a-zA-Z]\)?\r#\1#i' | tr [:lower:] [:upper:] )
        echo -n -e "\r SkyShowTime:\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_MathsSpot() {
    local tmpresult1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sS --max-time 10 "https://netv2.now.gg/v3/playtoken" 2>&1)
    if [[ "$tmpresult1" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult1" == "curl"* ]]; then
        echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local blocked=$(echo "$tmpresult1" | grep 'Request blocked')
    if [ -n "$blocked" ]; then
    	echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}No  (Proxy/VPN Detected)${Font_Suffix}\n"
        return
    fi
    local playtoken=$(echo "$tmpresult1" | python -m json.tool 2>/dev/null | grep '"playToken":' | awk '{print $2}' | cut -f2 -d'"')
    local region=$(echo "$tmpresult1" | python -m json.tool 2>/dev/null | grep '"countryCode":' | awk '{print $2}' | cut -f2 -d'"')
    local host=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sS --max-time 10 "https://mathsspot.com/2/api/play/v1/startSession?uaId=ua-KzV6fgcCBHQDU9DHCt2uG&uaSessionId=uasess-IdEux1e80EUstUlnnnHG0&appId=5349&initialOrientation=landscape&utmSource=NA&utmMedium=NA&utmCampaign=NA&deviceType=&playToken=${playtoken}&deepLinkUrl=&accessCode=" 2>&1)
    local tmpresult2=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sS --max-time 10 "https://mathsspot.com/2/api/play/v1/startSession?uaId=ua-KzV6fgcCBHQDU9DHCt2uG&uaSessionId=uasess-IdEux1e80EUstUlnnnHG0&appId=5349&initialOrientation=landscape&utmSource=NA&utmMedium=NA&utmCampaign=NA&deviceType=&playToken=${playtoken}&deepLinkUrl=&accessCode=" -H "x-ngg-fe-version: ${host}" 2>&1)
    if [[ "$host" == "curl"* ]] || [[ "$tmpresult2" == "curl"* ]]; then
        echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmpresult2" | python -m json.tool 2>/dev/null | grep '"status":' | awk '{print $2}' | cut -f2 -d'"')
    if [[ "$result" == "FailureServiceNotInRegion" ]]; then
    	echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    elif [[ "$result" == "Success" ]]; then
        echo -n -e "\r Maths Spot:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
    else
    	echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi
}

function MediaUnblockTest_BGlobalSEA() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.tv/intl/gateway/web/playurl?s_locale=en_US&platform=web&ep_id=347666" 2>&1)
    local result1="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "0" ]]; then
        echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnblockTest_BGlobalTH() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.tv/intl/gateway/web/playurl?s_locale=en_US&platform=web&ep_id=10077726" 2>&1)
    local result1="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r B-Global Thailand Only:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r B-Global Thailand Only:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "0" ]]; then
        echo -n -e "\r B-Global Thailand Only:\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r B-Global Thailand Only:\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r B-Global Thailand Only:\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnblockTest_BGlobalID() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.tv/intl/gateway/web/playurl?s_locale=en_US&platform=web&ep_id=11130043" 2>&1)
    local result1="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "0" ]]; then
        echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnblockTest_BGlobalVN() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.tv/intl/gateway/web/playurl?s_locale=en_US&platform=web&ep_id=11405745" 2>&1)
    local result1="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "0" ]]; then
        echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_AISPlay() {
    local result=$(curl $curlArgs -${1} -sSLI --max-time 10 "https://49-231-37-237-rewriter.ais-vidnt.com/ais/play/origin/VOD/playlist/ais-yMzNH1-bGUxc/index.m3u8" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r AIS Play:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r AIS Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1="$(echo "${result}" | grep 'X-Geo-Protection-System-Status' | awk '{print $2}' )"
    if [[ "$result1" == *"ALLOW"* ]]; then
        echo -n -e "\r AIS Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result1" == *"BLOCK"* ]]; then
        echo -n -e "\r AIS Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r AIS Play:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_TrueID() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://movie.trueid.net/apis/auth/checkedplay" -X POST -d '{"lang":"th","cmsId":"gROjxLzNBJb6","contentType":"movie"}' -H "Authorization: Basic YmJjNjI5Yzk3OTEzMDNhMmNjYzcyMWQzYTJlNGRkOGFiZWZkN2ZhNzoxMzAzYTJjY2M3MjFkM2EyZTRkZDhhYmVmZDdmYTc=" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r TrueID:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r TrueID:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1="$(echo "${result}" | python -m json.tool | grep 'billboardType' | awk '{print $2}' )"
    if [[ "$result1" == *"GEO_BLOCK"* ]]; then
        echo -n -e "\r TrueID:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r TrueID:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r TrueID:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_meWATCH() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://cdn.mewatch.sg/api/items/362414/videos?delivery=stream%2Cprogressive&ff=idp%2Cldp%2Crpt%2Ccd&lang=en&resolution=External&segments=all" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r meWATCH:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r meWATCH:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == *"location that is not permitted"* ]]; then
        echo -n -e "\r meWATCH:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r meWATCH:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r meWATCH:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_VTVcab() {
    #未完成。
    local token=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSLI --max-time 10 "https://www.vtvcab.vn/" 2>&1 | grep "token" | grep -Eo 'token=([^;]*)' | tr -d "token=")
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://apigwon.gviet.vn/sdp-vod/api/v1/source" -H "authorization: ${token}" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r VTVcab:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r VTVcab:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    echo $result > debug.logs
    if [[ "$result" == *"4006"* ]]; then
        echo -n -e "\r VTVcab:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r VTVcab:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r VTVcab:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Vidio() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://geo-id-media-001-vidio-com.akamaized.net/2x2.png" 2>&1)
    if [[ "$result" == "000" ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Vidio:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "000" ]]; then
        echo -n -e "\r Vidio:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "200" ]]; then
        echo -n -e "\r Vidio:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Vidio:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Vidio:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_TataPlay() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://watch.tataplay.com/" 2>&1)
    if [[ "$result" == "000" ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Tata Play:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "000" ]]; then
        echo -n -e "\r Tata Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "200" ]]; then
        echo -n -e "\r Tata Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Tata Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Tata Play:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_MXPlayer() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://www.mxplayer.in/" 2>&1)
    if [[ "$result" == *"curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r MXPlayer:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == *"curl"* ]]; then
        echo -n -e "\r MXPlayer:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == *"We are currently not available in your region"* ]]; then
        echo -n -e "\r MXPlayer:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MXPlayer:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r MXPlayer:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_ClipTV() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://cliptv.vn/the-forgiven-2022,lvDoN0JrP/Jx52YAKL2v" 2>&1)
    if [[ "$result" == *"curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Clip TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == *"curl"* ]]; then
        echo -n -e "\r Clip TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == *"Sorry, this video is not available in your country."* ]]; then
        echo -n -e "\r Clip TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Clip TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Clip TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_GalaxyPlay() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://api.glxplay.io/account/device/new" 2>&1)
    if [[ "$result" == *"curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == *"curl"* ]]; then
        echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == *"495"* ]]; then
        echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_MYTV() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://webapi.mytv.vn/api/v1/movie/138546/play?" -X POST -d "partition=1" 2>&1)
    if [[ "$result" == *"curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r MYTV:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == *"curl"* ]]; then
        echo -n -e "\r MYTV:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1="$(echo "${result}" | python -m json.tool | grep 'result' | awk '{print $2}'| tr -d "," )"
    if [[ "$result1" == "103" ]]; then
        echo -n -e "\r MYTV:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MYTV:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r MYTV:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Google() {
    local tmp=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 'https://bard.google.com/_/BardChatUi/data/batchexecute'   -H 'accept-language: en-US'   --data-raw 'f.req=[[["K4WWud","[[0],[\"en-US\"]]",null,"generic"]]]' 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Google Location:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo "$tmp" | grep K4WWud | jq .[0][2] | grep -Eo '\[\[\\"(.*)\\",\\"S' )
    echo -n -e "\r Google Location:\t\t\t${Font_Green}${region:4:-6}${Font_Suffix}\n"
}

function MediaUnlockTest_NHKPlus() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://location-plus.nhk.jp/geoip/area.json" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r NHK+:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r NHK+:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1="$(echo "${result}" | python -m json.tool | grep "country_code" | awk '{print $2}' | cut -d '"' -f 2)"
    if [[ "$result1" == "JP" ]]; then
        echo -n -e "\r NHK+:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r NHK+:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r NHK+:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Tiktok() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10  --output /dev/null -w %{url_effective} "https://www.tiktok.com/" 2>&1)
    local result1=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 -X POST "https://www.tiktok.com/passport/web/store_region/" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Tiktok:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Tiktok:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region="$(echo "${result1}" | jq ".data.store_region" | tr -d '"' )"
    if [[ "$result" == *"/about" ]] || [[ "$result" == *"/status"* ]] || [[ "$result" == *"landing"* ]]; then
        if [[ "$region" == "cn" ]]; then
            echo -n -e "\r Tiktok:\t\t\t\t${Font_Yellow}Provided by Douyin${Font_Suffix}\n"
            return
        else
            echo -n -e "\r Tiktok:\t\t\t\t${Font_Red}No  (Region: ${region^^})${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r Tiktok:\t\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Tiktok:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_StarhubTVPlus() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSL --max-time 10  --output /dev/null -w %{http_code} "https://ucdn.starhubgo.com/bpk-tv/HubSensasiHD/output/manifest.mpd" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "200" ]]; then
        echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_KPlus() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSL --max-time 10 -X POST -d '{"osVersion":"Windows 10","deviceModel":"Edge","deviceType":"PC","deviceSerial":"w7ab83550-c0aa-11ee-bf07-531681e47537","deviceOem":"Edge","devicePrettyName":"Edge 121.0.0.0","appVersion":"11.0","language":"en_US","brand":"vstv","featureLevel":5}' "https://tvapi-sgn.solocoo.tv/v1/provision" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r K+:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r K+:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo "${tmpresult}" | jq .session.geoCountryCode | tr -d '"')
    if [[ "$region" == "VN" ]]; then
        echo -n -e "\r K+:\t\t\t\t\t${Font_Green}Yes (Region:${region})${Font_Suffix}\n"
        return
    else
        echo -n -e "\r K+:\t\t\t\t\t${Font_Red}No  (Region:${region})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r K+:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_TV360() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSL --max-time 10 'https://tv360.vn/public/v1/composite/get-link?sq=CJSkRii71PAn41F9A2OlJSTxkOTDBl8uip04KFxqJc6iAmCPOt52q12a9hpwORZGjayWYrJSGjwYdG7Jy2NqPA%3D%3D&secured=true' 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r TV360:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r TV360:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local errcode=$(echo "${tmpresult}" | jq .errorCode)
    if [[ "$errcode" == "310" ]]; then
        echo -n -e "\r TV360:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r TV360:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r TV360:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_SonyLiv() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSL --max-time 10 'https://www.sonyliv.com/signin' 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r SonyLiv:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r SonyLiv:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local country=$(echo "${tmpresult}" | grep country_code | grep -Eo 'country_code:...')
    if [[ "$country" == *"IN" ]]; then
        echo -n -e "\r SonyLiv:\t\t\t\t${Font_Green}Yes (Region:${country#*\"})${Font_Suffix}\n"
        return
    else
        echo -n -e "\r SonyLiv:\t\t\t\t${Font_Red}No  (Region:${country#*\"})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r SonyLiv:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_JioCinema() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSL --max-time 10 'https://content-jiovoot.voot.com/psapi/' 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Jio Cinema:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Jio Cinema:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local code=$(echo "${tmpresult}" | jq .code)
    if [[ "$code" == "474" ]]; then
        echo -n -e "\r Jio Cinema:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Jio Cinema:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Jio Cinema:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Zee5() {
    local tmpresult=$(curl $curlArgs -sLi 'https://www.zee5.com/' -w "_TAG_%{http_code}_TAG_" -H 'Upgrade-Insecure-Requests: 1' --user-agent "${UA_BROWSER}")
    local httpCode=$(echo "$tmpresult" | grep '_TAG_' | awk -F'_TAG_' '{print $2}')
    if [ "$httpCode" == '000' ]; then
        echo -n -e "\r Zee5:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local region=$(echo "$tmpresult" | grep -woP 'country=\K[A-Z]{2}' | head -n 1)
    if [ -n "$region" ]; then
        echo -n -e "\r Zee5:\t\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Zee5:\t\t\t\t\t${Font_Red}Failed (Error: Unknown)${Font_Suffix}\n"
}

function MediaUnlockTest_HoyTV() {
    local result=$(curl $curlArgs -${1} -SsL --write-out %{http_code} --output /dev/null --max-time 10 "https://hoytv-live-stream.hoy.tv/ch78/index-fhd.m3u8" 2>&1)

    if [[ "$result" == "403" ]]; then
        echo -n -e "\r HOY TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "200" ]]; then
        echo -n -e "\r HOY TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r HOY TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Eurosport() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSI --max-time 10 "https://www.eurosport.com/" 2>&1)
    # echo ${result: -2}
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Eurosports Region:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo $result | grep eurosport_country_code | grep -Eo "eurosport_country_code=..")
    # if [[ "$result" == "200" ]]; then
    echo -n -e "\r Eurosports Region:\t\t\t${Font_Green}${region: -2}${Font_Suffix}\n"
    #     return
    # else
    #     echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    #     return
    # fi

    # echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Viaplay() {
    local result1=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSL --max-time 10 --write-out "%{url_effective}" --output /dev/null "https://viaplay.pl/package?recommended=viaplay" 2>&1)
    local result2=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sS --max-time 10 --write-out %{redirect_url} --output /dev/null https://viaplay.com/ 2>&1)
    if [[ "$result1" == "curl"* ]] || [[ "$result2" == "curl"* ]]; then
        echo -n -e "\r Viaplay:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == *"region-blocked"* ]]; then
        echo -n -e "\r Viaplay:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        local region=$(echo $result2 | awk -F"/" '{print $4}')
        echo -n -e "\r Viaplay:\t\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Viaplay:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Sooka() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsL --max-time 10 --write-out %{http_code} --output /dev/null --max-time 10 "https://app-expmanager-proxy.sooka.my/prod/api/v1/enveu_prod/screen?screenId=0" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Sooka:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Sooka:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Sooka:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Sooka:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_BilibiliAnimeNew() {
    if [[ "$1" == "6" ]];then
        local bili_ip6=$(getent ahostsv6 api.bilibili.com | head -1 | awk '{print $1}')
        if [ -z "$bili_ip6" ];then
            local bili_ip6="2409:8c54:1841:2002::22"
            return
        fi
        local tmp=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.com/x/web-interface/zone" --resolve api.bilibili.com:443:[$bili_ip6] 2>&1)
    else
        local tmp=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.com/x/web-interface/zone" 2>&1)
    fi
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local country_code=$(echo $tmp | jq '.data.country_code')
    if [ "$country_code" == "86" ]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Green}Yes (Region: CN)${Font_Suffix}\n"
        return
    elif [ "$country_code" == "886" ]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Green}Yes (Region: TW)${Font_Suffix}\n"
        return
    elif [ "$country_code" == "852" ]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Green}Yes (Region: HK)${Font_Suffix}\n"
        return
    elif [ "$country_code" == "853" ]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Green}Yes (Region: MO)${Font_Suffix}\n"
        return
    else
        local country=$(echo $tmp | jq '.data.country' | tr -d '"' )
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Red}No${Font_Suffix}  ${Font_Green}(Country: $country)${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_ChatGPT() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://chatgpt.com" 2>&1)
    local tmpresult1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 "https://ios.chat.openai.com" 2>&1)
    local cf_details=$(echo "$tmpresult1" | jq .cf_details)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result1=$(echo "$tmpresult" | grep 'location' )
    if [ ! -n "$result1" ]; then
        if [[ "$tmpresult1" == *"blocked_why_headline"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No (Blocked)${Font_Suffix}\n"
            return
        fi
        if [[ "$tmpresult1" == *"unsupported_country_region_territory"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No (Unsupported Region)${Font_Suffix}\n"
            return
        fi
        if [[ "$cf_details" == *"(1)"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No (Disallowed ISP[1])${Font_Suffix}\n"
            return
        fi
        if [[ "$cf_details" == *"(2)"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No (Disallowed ISP[2])${Font_Suffix}\n"
            return
        fi
    	echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
    	local region1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 "https://chatgpt.com/cdn-cgi/trace" 2>&1 | grep "loc=" | awk -F= '{print $2}')
        if [[ "$cf_details" == *"(1)"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Yellow}Web Only (Disallowed ISP[1])${Font_Suffix}\n"
            return
        fi
        if [[ "$cf_details" == *"(2)"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Yellow}Web Only (Disallowed ISP[2])${Font_Suffix}\n"
            return
        fi
        echo -n -e "\r ChatGPT:\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Sora() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://sora.com" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Sora:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep 'location'  )
    if [ ! -n "$result1" ]; then
    	echo -n -e "\r Sora:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
    	local region1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 "https://sora.com/cdn-cgi/trace" 2>&1 | grep "loc=" | awk -F= '{print $2}')
        echo -n -e "\r Sora:\t\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
    fi
}

function AIUnlockTest_Gemini_location() {
    local tmp=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 'https://gemini.google.com/_/BardChatUi/data/batchexecute'   -H 'accept-language: en-US'   --data-raw 'f.req=[[["K4WWud","[[0],[\"en-US\"]]",null,"generic"]]]' 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Google Gemini Location:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo "$tmp" | grep K4WWud | jq .[0][2] | grep -Eo '\[\[\\"(.*)\\",\\"S' )
    echo -n -e "\r Google Gemini Location:\t\t${Font_Yellow}${region:4:-6}${Font_Suffix}\n"
}

function AIUnlockTest_Copilot() {
    local tmp=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 "https://copilot.microsoft.com/" 2>&1)
    local tmp2=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 "https://copilot.microsoft.com/turing/conversation/chats?bundleVersion=1.1342.3-cplt.12"  2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Microsoft Copilot:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmp2" | jq .result.value  2>&1 | tr -d '"' 2>&1) 
    local region=$(echo "$tmp" | sed -n 's/.*RevIpCC:"\([^"]*\)".*/\1/p' )
    if [[ "$result" == "Success" ]];then
        echo -n -e "\r Microsoft Copilot:\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
    else 
        echo -n -e "\r Microsoft Copilot:\t\t\t${Font_Red}No  (Region: ${region^^})${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_RakutenMagazine() {
    local result=$(curl $curlArgs -${1} -sL --write-out %{http_code} --output /dev/null --max-time 10 "https://data-cloudauthoring.magazine.rakuten.co.jp/rem_repository/////////.key" 2>&1)

    if [[ "$result" == "403" ]]; then
        echo -n -e "\r Rakuten MAGAZINE:\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "404" ]]; then
        echo -n -e "\r Rakuten MAGAZINE:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Rakuten MAGAZINE:\t\t\t${Font_Red}Failed ($result)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_AnimeFesta() {
    local result1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsLI -X GET --write-out %{http_code} --output /dev/null --max-time 10 "https://api-animefesta.iowl.jp/v1/titles/1" -H 'x-requested-with: XMLHttpRequest'  2>&1)
    if [[ "$result1" == "curl"* ]]; then
        echo -n -e "\r AnimeFesta:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "200" ]]; then
        echo -n -e "\r AnimeFesta:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result1" == "403" ]]; then
        echo -n -e "\r AnimeFesta:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r AnimeFesta:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Lemino() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 -X POST 'https://if.lemino.docomo.ne.jp/v1/user/delivery/watch/ready'  2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r Lemino:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$tmpresult" == *"CloudFront"* ]]; then
        echo -n -e "\r Lemino:\t\t\t\t${Font_Red}No  (Blocked)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | jq .result_code | tr -d '"')
    if [[ "$result" != "null" ]]; then
        if [[ "$result" == "WEBW100100" ]]; then
            echo -n -e "\r Lemino:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        elif [[ "$result" == "WEBW300100" ]]; then
            echo -n -e "\r Lemino:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        else
            echo -n -e "\r Lemino:\t\t\t\t${Font_Red}Unknown (Code: $result)${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r Lemino:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_mora() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 'https://mora.jp/buy?__requestToken=1713764407153&returnUrl=https%3A%2F%2Fmora.jp%2Fpackage%2F43000087%2FTFDS01006B00Z%2F%3Ffmid%3DTOPRNKS%26trackMaterialNo%3D31168909&fromMoraUx=false&deleteMaterial=' -H 'host: mora.jp' 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Mora:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Mora:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "500" ]; then
        echo -n -e "\r Mora:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Mora:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_DAnimeStore(){
    local tmpresult=$(curl $curlArgs -${1} -sSL --max-time 10 -sL 'https://animestore.docomo.ne.jp/animestore/reg_pc' 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r D Anime Store:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local isBlocked=$(echo $tmpresult | grep '海外')
    if [ -n "$isBlocked" ];then
        echo -n -e "\r D Anime Store:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r D Anime Store:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_EroGameSpace(){
    local result=$(curl $usePROXY $xForward -${1} -sSL --max-time 3  "https://erogamescape.org" 2>/dev/null | grep '18歳')
    if [ -n "$result" ]; then
      echo -n -e "\r EroGameSpace:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ -z "$countrycode" ]; then
        echo -n -e "\r EroGameSpace:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_RakutenTVJP(){
    local tmpresult=$(curl $curlArgs -${1} -sSL --max-time 10 'https://api.tv.rakuten.co.jp/content/playinfo.json?content_id=1&device_id=1' 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r Rakuten TV JP:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | jq .result.code | tr -d '"')
    if [[ "$result" == "40404030802" ]]; then
        echo -n -e "\r Rakuten TV JP:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "40301720109" ]]; then
        echo -n -e "\r Rakuten TV JP:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Rakuten TV JP:\t\t\t\t${Font_Red}Unknown (Code: $result)${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_ofiii() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://cdi.ofiii.com/ofiii_cdi/video/urls?device_type=pc&device_id=450b705c-7a08-49e9-9297-10ec0c8624b0&media_type=comic&asset_id=vod68157-020015M001&project_num=OFWEB00&puid=7a9c18b9-eecc-499b-afd2-e905bf04f5a4" 2>&1)
    if [[ "$result" == "000" ]]; then
        echo -n -e "\r ofiii:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "200" ]]; then
        echo -n -e "\r ofiii:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r ofiii:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r ofiii:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_DStv() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://now.dstv.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r DStv:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r DStv:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "451" ]; then
        echo -n -e "\r DStv:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r DStv:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_beIN_Sports() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://d6m3sfa7e58z5.cloudfront.net/out/v1/3b0660e05eed4d769521eb0275aab3ab/index.mpd")
    if [ "$result" = "000" ]; then
        echo -n -e "\r beIN Sports:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r beIN Sports:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r beIN Sports:\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r beIN Sports:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}


function echo_Result() {
    for((i=0;i<${#array[@]};i++))
    do
        echo "$result" | grep "${array[i]}"
        # sleep 0.03
    done;
}

if [ -n "$func" ]; then
    echo -e "${Font_Green}IPv4:${Font_Suffix}"
    $func 4
    echo -e "${Font_Green}IPv6:${Font_Suffix}"
    $func 6
    exit
fi

function NA_UnlockTest() {
    echo "===========[ North America ]==========="
    local result=$(
    MediaUnlockTest_Fox ${1} &
    MediaUnlockTest_HuluUS ${1} &
    MediaUnlockTest_NFLPlus ${1} &
    MediaUnlockTest_ESPNPlus ${1} &
    MediaUnlockTest_EPIX ${1} &
    MediaUnlockTest_Starz ${1} &
    MediaUnlockTest_Philo ${1} &
    MediaUnlockTest_FXNOW ${1} &
    MediaUnlockTest_HBOMax ${1} &
    # MediaUnlockTest_TLCGO ${1} & # Wait to fix.
    )
    wait
    local array=("FOX:" "Hulu:" "NFL+" "ESPN+:" "MGM+:" "Starz:" "Philo:" "FXNOW:" "HBO Max")
    echo_Result ${result} ${array}
    local result=$(
    MediaUnlockTest_Shudder ${1} &
    MediaUnlockTest_BritBox ${1} &
    MediaUnlockTest_Crackle ${1} &
    MediaUnlockTest_CWTV ${1} &
    MediaUnlockTest_AETV ${1} &
    MediaUnlockTest_NBATV ${1} &
    MediaUnlockTest_FuboTV ${1} &
    MediaUnlockTest_TubiTV ${1} &
    )
    wait
    local array=("Shudder:" "BritBox:" "Crackle:" "CW TV:" "A&E TV:" "NBA TV:")
    echo_Result ${result} ${array}
    MediaUnlockTest_NBCTV ${1}
    echo "$result" | grep "Fubo TV:"
    echo "$result" | grep "Tubi TV:"
    local result=$(
    MediaUnlockTest_SlingTV ${1} &
    MediaUnlockTest_PlutoTV ${1} &
    MediaUnlockTest_AcornTV ${1} &
    MediaUnlockTest_SHOWTIME ${1} &
    MediaUnlockTest_encoreTVB ${1} &
    MediaUnlockTest_DiscoveryPlus ${1} &
    MediaUnlockTest_ParamountPlus ${1} &
    MediaUnlockTest_PeacockTV ${1} &
    MediaUnlockTest_Popcornflix ${1} &
    MediaUnlockTest_Crunchyroll ${1} &
    MediaUnlockTest_ATTNOW ${1} &
    # MediaUnlockTest_KBSAmerican ${1} &
    MediaUnlockTest_KOCOWA ${1} &
    # MediaUnlockTest_MathsSpot ${1} &
    )
    wait
    local array=("Sling TV:" "Pluto TV:" "Acorn TV:" "SHOWTIME:" "encoreTVB:" "Discovery" "Paramount+:" "Peacock TV:" "Popcornflix:" "Crunchyroll:" "Directv Stream:" "KBS American:" "KOCOWA:" "Maths Spot:")
    echo_Result ${result} ${array}
    ShowRegion CA
    local result=$(
    MediaUnlockTest_CBCGem ${1} &
    MediaUnlockTest_Crave ${1} &
    )
    wait
    echo "$result" | grep "CBC Gem:"
    echo "$result" | grep "Crave:"
    echo "======================================="
}

function EU_UnlockTest() {
    echo "===============[ Europe ]=============="
    local result=$(
    MediaUnlockTest_RakutenTV ${1} &
    MediaUnlockTest_SkyShowTime ${1} &
    # MediaUnlockTest_MathsSpot ${1} &
    MediaUnlockTest_Eurosport ${1} &
    MediaUnlockTest_Viaplay ${1} &
    MediaUnlockTest_SetantaSports ${1} &
    # MediaUnlockTest_HBO_Nordic ${1}
    # MediaUnlockTest_HBOGO_EUROPE ${1}
    )
    wait
    local array=("Rakuten TV:" "SkyShowTime:" "HBO Max:" "Maths Spot:" "Viaplay" "Eurosport" "Setanta Sports:")
    echo_Result ${result} ${array}
    ShowRegion GB
    local result=$(
    MediaUnlockTest_SkyGo ${1} &
    MediaUnlockTest_BritBox ${1} &
    MediaUnlockTest_ITVHUB ${1} &
    MediaUnlockTest_Channel4 ${1} &
    MediaUnlockTest_Channel5 ${1} &
    MediaUnlockTest_BBCiPLAYER ${1} &
    MediaUnlockTest_DiscoveryPlusUK ${1} &
    )
    wait
    local array=("Sky Go:" "BritBox:" "ITV Hub:" "Channel 4:" "Channel 5" "BBC iPLAYER:" "Discovery+ UK:")
    echo_Result ${result} ${array}
    ShowRegion FR
    local result=$(
    #MediaUnlockTest_Salto ${1} &
    MediaUnlockTest_CanalPlus ${1} &
    MediaUnlockTest_Molotov ${1} &
    MediaUnlockTest_FranceTV ${1} &
    MediaUnlockTest_Joyn ${1} &
    MediaUnlockTest_SKY_DE ${1} &
    MediaUnlockTest_ZDF ${1} &
    )
    wait
    local array=("Canal+:" "Molotov:" "France.tv")
    echo_Result ${result} ${array}
    ShowRegion DE
    local array=("Joyn:" "Sky DE:" "ZDF:")
    echo_Result ${result} ${array}
    ShowRegion NL
    local result=$(
    MediaUnlockTest_NLZIET ${1} &
    MediaUnlockTest_videoland ${1} &
    MediaUnlockTest_NPO_Start_Plus ${1} &
    # MediaUnlockTest_HBO_Spain ${1}
    MediaUnlockTest_MoviStarPlus ${1} &
    MediaUnlockTest_RaiPlay ${1} &
    MediaUnlockTest_Sky_CH ${1} &
    #MediaUnlockTest_MegogoTV ${1}
    MediaUnlockTest_Amediateka ${1} &
    )
    wait
    local array=("NLZIET:" "videoland:" "NPO Start Plus:")
    echo_Result ${result} ${array}
    ShowRegion ES
    echo "$result" | grep "Movistar+:"
    ShowRegion IT
    echo "$result" | grep "Rai Play:"
    ShowRegion CH
    echo "$result" | grep "SKY CH:"
    ShowRegion RU
    echo "$result" | grep "Amediateka:"
    echo "======================================="
}

function HK_UnlockTest() {
    echo "=============[ Hong Kong ]============="
       if [[ "$1" == 4 ]] || [[ "$Stype" == "force6" ]];then
	local result=$(
	    MediaUnlockTest_NowE ${1} &
	    MediaUnlockTest_ViuTV ${1} &
	    MediaUnlockTest_MyTVSuper ${1} &
	    # MediaUnlockTest_HBOGO_ASIA ${1} &
        MediaUnlockTest_HBOMax ${1} &
        MediaUnlockTest_HoyTV ${1} &
        MediaUnlockTest_BahamutAnime ${1} &
        MediaUnlockTest_NBATV ${1} &
	    # MediaUnlockTest_BilibiliHKMCTW ${1} &
	)
    else
	local result=$(
	    # MediaUnlockTest_NowE ${1} &
	    # MediaUnlockTest_ViuTV ${1} &
	    # MediaUnlockTest_MyTVSuper ${1} &
	    # MediaUnlockTest_HBOGO_ASIA ${1} &
        MediaUnlockTest_HoyTV ${1} &
        MediaUnlockTest_HBOMax ${1} &
	    # MediaUnlockTest_BilibiliHKMCTW ${1} &
	)
    fi
    wait
    local array=("Now E:" "Viu.TV:" "MyTVSuper:" "HBO Max:" "HOY TV" "BiliBili Hongkong/Macau/Taiwan:" "Bahamut Anime:" "NBA TV:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function TW_UnlockTest() {
    echo "==============[ Taiwan ]==============="
    local result=$(
    MediaUnlockTest_KKTV ${1} &
    MediaUnlockTest_LiTV ${1} &
    MediaUnlockTest_MyVideo ${1} &
    #MediaUnlockTest_4GTV ${1} &
    MediaUnlockTest_LineTV.TW ${1} &
    MediaUnlockTest_HamiVideo ${1} &
    MediaUnlockTest_Catchplay ${1} &
    # MediaUnlockTest_HBOGO_ASIA ${1} &
    MediaUnlockTest_HBOMax ${1} &
    MediaUnlockTest_BahamutAnime ${1} &
    MediaUnlockTest_FridayVideo ${1} &
    MediaUnlockTest_ofiii ${1} &
    #MediaUnlockTest_ElevenSportsTW ${1}
    # MediaUnlockTest_BilibiliTW ${1} &
    )
    wait
    local array=("KKTV:" "LiTV:" "ofiii:" "MyVideo:" "4GTV.TV:" "LineTV.TW:" "Hami Video:" "CatchPlay+:" "HBO Max" "Bahamut Anime:" "Friday Video:" "Bilibili Taiwan Only:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function JP_UnlockTest() {
    echo "===============[ Japan ]==============="
    local result=$(
    MediaUnlockTest_NHKPlus ${1} &
    MediaUnlockTest_DMMTV ${1} &
    MediaUnlockTest_AbemaTV_IPTest ${1} &
    MediaUnlockTest_Niconico ${1} &
    MediaUnlockTest_Telasa ${1} &
    MediaUnlockTest_Paravi ${1} &
    MediaUnlockTest_unext ${1} &
    MediaUnlockTest_HuluJP ${1} &
    )
    wait
    local array=("NHK+" "DMM TV:" "Abema.TV:" "Niconico:" "Telasa:" "Paravi:" "U-NEXT:" "Hulu Japan:")
    echo_Result ${result} ${array}
    local result=$(
    MediaUnlockTest_TVer ${1} &
    MediaUnlockTest_wowow ${1} &
    MediaUnlockTest_VideoMarket ${1} &
    MediaUnlockTest_DAnimeStore ${1} &
    MediaUnlockTest_FOD ${1} &
    MediaUnlockTest_Radiko ${1} &
    MediaUnlockTest_DAM ${1} &
    MediaUnlockTest_AnimeFesta ${1} &
    MediaUnlockTest_Lemino ${1} &
    MediaUnlockTest_J:COM_ON_DEMAND ${1} &
    MediaUnlockTest_RakutenTVJP ${1} &
    MediaUnlockTest_MGStage ${1} &
    )
    wait
    local array=("TVer:" "WOWOW:" "VideoMarket:" "D Anime Store:" "FOD(Fuji TV):" "Radiko:" "Karaoke@DAM:" "J:com On Demand:" "AnimeFesta:" "Lemino:" "MGStage:" "Rakuten TV JP:")
    echo_Result ${result} ${array}
    ShowRegion Game
    local result=$(
    MediaUnlockTest_Kancolle ${1} &
    MediaUnlockTest_UMAJP ${1} &
    MediaUnlockTest_KonosubaFD ${1} &
    MediaUnlockTest_PCRJP ${1} &
    MediaUnlockTest_ProjectSekai ${1} &
    )
    wait
    local array=("Kancolle Japan:" "Pretty Derby Japan:" "Konosuba Fantastic Days:" "Princess Connect Re:Dive Japan:" "World Flipper Japan:" "Project Sekai: Colorful Stage:")
    echo_Result ${result} ${array}
    ShowRegion Read
    local result=$(
    MediaUnlockTest_RakutenMagazine ${1} &
    )
    wait
    local array=("Rakuten MAGAZINE")
    echo_Result ${result} ${array}
    ShowRegion Music
    local result=$(
    MediaUnlockTest_mora ${1} &
    MediaUnlockTest_music.jp ${1} &
    )
    wait
    local array=("Mora:" "music.jp:") 
    echo_Result ${result} ${array}
    ShowRegion Forum
    MediaUnlockTest_EroGameSpace ${1}
    echo "======================================="

}

function Global_UnlockTest() {
    echo ""
    echo "============[ Multination ]============"
    if [[ "$1" == 4 ]] || [[ "$Stype" == "force6" ]];then
        local result=$(
        MediaUnlockTest_Dazn ${1} &
        MediaUnlockTest_HotStar ${1} &
        MediaUnlockTest_DisneyPlus ${1} &
        MediaUnlockTest_Netflix ${1} &
        MediaUnlockTest_YouTube_Premium ${1} &
        MediaUnlockTest_PrimeVideo_Region ${1} &
        MediaUnlockTest_TVBAnywhere ${1} &
        MediaUnlockTest_iQYI_Region ${1} &
        MediaUnlockTest_Viu.com ${1} &
        MediaUnlockTest_YouTube_CDN ${1} &
        MediaUnlockTest_NetflixCDN ${1} &
        MediaUnlockTest_Spotify ${1} &
        # MediaUnlockTest_Instagram.Music ${1}
        GameTest_Steam ${1} &
        MediaUnlockTest_Google ${1} &
        MediaUnlockTest_Tiktok ${1} &
        MediaUnlockTest_BilibiliAnimeNew ${1} &
        )
    else
        local result=$(
        # MediaUnlockTest_Dazn ${1} &
        MediaUnlockTest_HotStar ${1} &
        MediaUnlockTest_DisneyPlus ${1} &
        MediaUnlockTest_Netflix ${1} &
        MediaUnlockTest_YouTube_Premium ${1} &
        # MediaUnlockTest_PrimeVideo_Region ${1} &
        # MediaUnlockTest_TVBAnywhere ${1} &
        # MediaUnlockTest_iQYI_Region ${1} &
        # MediaUnlockTest_Viu.com ${1} &
        MediaUnlockTest_YouTube_CDN ${1} &
        MediaUnlockTest_NetflixCDN ${1} &
        MediaUnlockTest_Spotify ${1} &
        # MediaUnlockTest_Instagram.Music ${1}
        # GameTes t_Steam ${1} &
        MediaUnlockTest_Google ${1} &
        MediaUnlockTest_BilibiliAnimeNew ${1} &
        )
    fi
    wait
    local array=("Dazn:" "HotStar:" "Disney+:" "Netflix:" "YouTube Premium:" "Amazon Prime Video:" "TVBAnywhere+:" "iQyi Oversea:" "Bilibili Anime:" "Viu.com:" "Tiktok" "YouTube CDN:" "Google" "YouTube Region:" "Netflix Preferred CDN:" "Spotify" "Steam Currency:" "Instagram")
    echo_Result ${result} ${array}
    echo "======================================="
}

function SA_UnlockTest() {
    echo "===========[ South America ]==========="
    local result=$(
    MediaUnlockTest_DirecTVGO ${1} &
    )
    wait
    local array=("Star+:" "HBO Max:" "DirecTV Go:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function OA_UnlockTest() {
    echo "==============[ Oceania ]=============="
    local result=$(
    MediaUnlockTest_NBATV ${1} &
    MediaUnlockTest_AcornTV ${1} &
    MediaUnlockTest_SHOWTIME ${1} &
    MediaUnlockTest_BritBox ${1} &
    MediaUnlockTest_ParamountPlus ${1} &
    )
    wait
    local array=("NBA TV:" "Acorn TV:" "SHOWTIME:" "BritBox:" "Paramount+:")
    echo_Result ${result} ${array}
    ShowRegion AU
    local result=$(
    MediaUnlockTest_Stan ${1} &
    MediaUnlockTest_Binge ${1} &
    MediaUnlockTest_7plus ${1} &
    MediaUnlockTest_Channel9 ${1} &
    MediaUnlockTest_Channel10 ${1} &
    MediaUnlockTest_ABCiView ${1} &
    MediaUnlockTest_OptusSports ${1} &
    MediaUnlockTest_SBSonDemand ${1} &
    MediaUnlockTest_Docplay ${1}
    MediaUnlockTest_KayoSports ${1}
    )
    wait
    local array=("Stan:" "Binge:" "7plus:" "Channel 9:" "Channel 10:" "ABC iView:" "Docplay:" "Optus Sports:" "SBS on Demand:" "Kayo Sports:")
    echo_Result ${result} ${array}
    ShowRegion NZ
    local result=$(
    MediaUnlockTest_NeonTV ${1} &
    MediaUnlockTest_SkyGONZ ${1} &
    MediaUnlockTest_ThreeNow ${1} &
    MediaUnlockTest_MaoriTV ${1} &
    )
    wait
    local array=("Neon TV:" "SkyGo NZ:" "ThreeNow:" "Maori TV:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function KR_UnlockTest() {
    echo "==============[ Korean ]==============="
    local result=$(
    MediaUnlockTest_Wavve ${1} &
    MediaUnlockTest_Tving ${1} &
    MediaUnlockTest_CoupangPlay ${1} &
    MediaUnlockTest_NaverTV ${1} &
    MediaUnlockTest_Afreeca ${1} &
    # MediaUnlockTest_SpotvNow ${1} &
    MediaUnlockTest_KBSDomestic ${1} &
    MediaUnlockTest_PandaTV ${1} &
    MediaUnlockTest_KOCOWA ${1} &
    )
    wait
    local array=("Wavve:" "Tving:" "Coupang Play:" "Naver TV:" "Afreeca TV:" "SPOTV NOW:" "KBS Domestic:" "PandaTV:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function SEA_UnlockTest(){
    echo "==========[ SouthEastAsia ]============"
    local result=$(
    # MediaUnlockTest_HBOGO_ASIA ${1} &
    MediaUnlockTest_HBOMax ${1} &
    MediaUnblockTest_BGlobalSEA ${1} &
    )
    wait
    local array=("HBO Max:" "B-Global SouthEastAsia:")
    echo_Result ${result} ${array}
    ShowRegion SG
    local result=$(
        MediaUnlockTest_Catchplay ${1} &
        MediaUnlockTest_meWATCH ${1} &
        MediaUnlockTest_StarhubTVPlus ${1} &
    )
    wait
    local array=("meWATCH" "Starhub" "CatchPlay+:")
    echo_Result ${result} ${array}
    ShowRegion TH
    local result=$(
    #MediaUnlockTest_TrueID ${1} &
    MediaUnlockTest_AISPlay ${1} &
    MediaUnblockTest_BGlobalTH ${1} &
    )
    wait
    local array=("TrueID" "AIS Play" "B-Global Thailand Only")
    echo_Result ${result} ${array}
    ShowRegion ID
    local result=$(
    MediaUnlockTest_Vidio ${1} &
    MediaUnlockTest_beIN_Sports ${1} &
    MediaUnblockTest_BGlobalID ${1} &
    )
    wait
    local array=("Vidio" "beIN Sports" "B-Global Indonesia Only")
    echo_Result ${result} ${array}
    ShowRegion VN
    local result=$(
    # MediaUnlockTest_VTVcab ${1} &
    MediaUnlockTest_MYTV ${1} &
    MediaUnlockTest_ClipTV ${1} &
    MediaUnlockTest_GalaxyPlay ${1} &
    MediaUnlockTest_KPlus ${1} &
    #MediaUnlockTest_TV360 ${1} &
    MediaUnblockTest_BGlobalVN ${1} &
    )
    wait
    local array=("MYTV" "Clip TV" "Galaxy Play" "K+" "TV360" "B-Global Việt Nam Only" )
    echo_Result ${result} ${array}
    ShowRegion MY
    local result=$(
    MediaUnlockTest_Sooka ${1} &
    )
    wait
    local array=("Sooka")
    echo_Result ${result} ${array}
    ShowRegion IN
    local result=$(
    MediaUnlockTest_MXPlayer ${1} &
    MediaUnlockTest_TataPlay ${1} &
    MediaUnlockTest_SonyLiv ${1} &
    MediaUnlockTest_JioCinema ${1} &
    MediaUnlockTest_Zee5 ${1} &
    MediaUnlockTest_NBATV ${1} &
    )
    wait
    local array=("Zee5:" "NBA TV:" "MXPlayer" "Tata Play" "SonyLiv" "Jio Cinema")
    echo_Result ${result} ${array}
    echo "======================================="
}

function AF_UnlockTest() {
    echo "==============[ Africa ]=============="
    local result=$(
        MediaUnlockTest_DStv &
        # MediaUnlockTest_Showmax &
        MediaUnlockTest_Viu.com &
        # MediaUnlockTest_ParamountPlus &
    )
    wait
    local array=("DSTV:" "Showmax:" "Viu.com:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function Sport_UnlockTest() {
    echo "===============[ Sport ]==============="
    local result=$(
    MediaUnlockTest_Dazn ${1} &
    MediaUnlockTest_ESPNPlus ${1} &
    MediaUnlockTest_NBATV ${1} &
    MediaUnlockTest_FuboTV ${1} &
    MediaUnlockTest_MolaTV ${1} &
    MediaUnlockTest_SetantaSports ${1} &
    MediaUnlockTest_OptusSports ${1} &
    MediaUnlockTest_BeinConnect ${1} &
    MediaUnlockTest_EurosportRO ${1} &
    )
    wait
    local array=("Dazn:" "Star+:" "ESPN+:" "NBA TV:" "Fubo TV:" "Mola TV:" "Setanta Sports:" "Optus Sports:" "Bein Sports Connect:" "Eurosport RO:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function AI_UnlockTest() {
    echo "============[ AI Platform ]============"
    local result=$(
    MediaUnlockTest_ChatGPT ${1} &
    MediaUnlockTest_Sora ${1} &
    AIUnlockTest_Gemini_location ${1} &
    AIUnlockTest_Copilot ${1} &
    )
    wait
    local array=("ChatGPT" "Copilot" "Gemini" "Sora:" )
    echo_Result ${result} ${array}

    echo "======================================="
}

function CheckV4() {
    if [[ "$language" == "e" ]]; then
        if [[ "$NetworkType" == "6" ]]; then
            isv4=0
            echo -e "${Font_SkyBlue}User Choose to Test Only IPv6 Results, Skipping IPv4 Testing...${Font_Suffix}"
        else
            echo -e " ${Font_SkyBlue}** Checking Results Under IPv4${Font_Suffix} "
            echo "--------------------------------"
            echo -e " ${Font_SkyBlue}** Your Network Provider: AS${local_as4} ${local_isp4} (${local_ipv4_asterisk})${Font_Suffix} "
            if [ -n  "$local_ipv4"  ]; then
                isv4=1
            else
                echo -e "${Font_SkyBlue}No IPv4 Connectivity Found, Abort IPv4 Testing...${Font_Suffix}"
                isv4=0
            fi

            echo ""
        fi
    else
        if [[ "$NetworkType" == "6" ]]; then
            isv4=0
            echo -e "${Font_SkyBlue}用户选择只检测IPv6结果，跳过IPv4检测...${Font_Suffix}"
        else
            echo -e " ${Font_SkyBlue}** 正在测试IPv4解锁情况${Font_Suffix} "
            echo "--------------------------------"
            echo -e " ${Font_SkyBlue}** 您的网络为: AS${local_as4} ${local_isp4} (${local_ipv4_asterisk})${Font_Suffix} "
            if [ -n  "$local_ipv4"  ]; then
                isv4=1
            else
                echo -e "${Font_SkyBlue}当前网络不支持IPv4,跳过...${Font_Suffix}"
                isv4=0
            fi

            echo ""
        fi
    fi
}

function CheckV6() {
    if [[ "$language" == "e" ]]; then
        if [[ "$NetworkType" == "4" ]]; then
            isv6=0
            if [ -z "$usePROXY" ]; then
                echo -e "${Font_SkyBlue}User Choose to Test Only IPv4 Results, Skipping IPv6 Testing...${Font_Suffix}"
            fi
        else
            if [ -n  "$local_ipv6"  ]; then
                echo ""
                echo ""
                echo -e " ${Font_SkyBlue}** Checking Results Under IPv6${Font_Suffix} "
                echo "--------------------------------"
                echo -e " ${Font_SkyBlue}** Your Network Provider:  AS${local_as6} ${local_isp6} (${local_ipv6_asterisk})${Font_Suffix} "
                isv6=1
            else
                echo -e "${Font_SkyBlue}No IPv6 Connectivity Found, Abort IPv6 Testing...${Font_Suffix}"
                isv6=0
            fi
            echo -e ""
        fi

    else
        if [[ "$NetworkType" == "4" ]]; then
            isv6=0
            if [ -z "$usePROXY" ]; then
                echo -e "${Font_SkyBlue}用户选择只检测IPv4结果，跳过IPv6检测...${Font_Suffix}"
            fi
        else
            if [ -n  "$local_ipv6"  ]; then
                echo ""
                echo ""
                echo -e " ${Font_SkyBlue}** 正在测试IPv6解锁情况${Font_Suffix} "
                echo "--------------------------------"
                echo -e " ${Font_SkyBlue}** 您的网络为: AS${local_as6} ${local_isp6} (${local_ipv6_asterisk})${Font_Suffix} "
                isv6=1
            else
                echo -e "${Font_SkyBlue}当前主机不支持IPv6,跳过...${Font_Suffix}"
                isv6=0
            fi
            echo -e ""
        fi
    fi
}


function Goodbye() {
    if [[ "$language" == "e" ]]; then
        echo -e "${Font_Green}Testing Done! Thanks for Using This Script! ${Font_Suffix}"
    else
        echo -e "${Font_Green}本次测试已结束，感谢使用此脚本 ${Font_Suffix}"
    fi
}

clear

function ScriptTitle() {
    if [[ "$language" == "e" ]]; then
        echo -e " [Stream Platform & Game Region Restriction Test]"
        echo ""
        echo -e "${Font_Green}Github Repository:${Font_Suffix} ${Font_Yellow} https://github.com/1-stream/RegionRestrictionCheck ${Font_Suffix}"
        echo -e "${Font_Purple}Supporting OS: CentOS 6+, Ubuntu 14.04+, Debian 8+, MacOS, Android (Termux), iOS (iSH)${Font_Suffix}"
        echo ""
        echo -e " ** Test Starts At: $(date)"
        echo ""
    else
        echo -e " [流媒体平台及游戏区域限制测试]"
        echo ""
        echo -e "${Font_Green}项目地址${Font_Suffix} ${Font_Yellow}https://github.com/1-stream/RegionRestrictionCheck ${Font_Suffix}"
        echo -e "${Font_Green}[商家]TG群组${Font_Suffix} ${Font_Yellow}https://t.me/streamunblock1 ${Font_Suffix}"
        # echo -e "${Font_Purple}脚本适配OS: IDK${Font_Suffix}"
        echo ""
        echo -e " ** 测试时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo ""
    fi
}
ScriptTitle

function Start() {
    if [[ "$language" == "e" ]]; then
        echo -e "${Font_Blue}Please Select Test Region or Press ENTER to Test All Regions${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [1]: [ Multination + Taiwan ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [2]: [ Multination + Hong Kong ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [3]: [ Multination + Japan ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [4]: [ Multination + North America ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [5]: [ Multination + South America ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [6]: [ Multination + Europe ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [7]: [ Multination + Oceania ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [8]: [ Multination + Korean ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [9]: [ Multination + SouthEastAsia ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number [10]: [ AI Platform ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number [11]: [ Multination + Africa ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [0]: [ Multination Only ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number [99]: [ Sport Platforms ]${Font_Suffix}"
        read -p "Please Input the Correct Number or Press ENTER:" num
    else
        echo -e "${Font_Blue}请选择检测项目，直接按回车将进行全区域检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [1]: [ 跨国平台+台湾平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [2]: [ 跨国平台+香港平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [3]: [ 跨国平台+日本平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [4]: [ 跨国平台+北美平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [5]: [ 跨国平台+南美平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [6]: [ 跨国平台+欧洲平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [7]: [跨国平台+大洋洲平台]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [8]: [ 跨国平台+韩国平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [9]: [跨国平台+东南亚平台]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字 [10]: [      AI 平台     ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字 [11]: [ 跨国平台+非洲平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [0]: [   只进行跨国平台  ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字 [99]: [   体育直播平台    ]检测${Font_Suffix}"
        read -p "请输入正确数字或直接按回车:" num
    fi
}
Start

function RunScript() {

    if [[ -n "${num}" ]]; then
        if [[ "$num" -eq 1 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                TW_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                TW_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 2 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                HK_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                HK_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 3 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                JP_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                JP_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 4 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                NA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                NA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 5 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                SA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                SA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 6 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                EU_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                EU_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 7 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                OA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                OA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 8 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                KR_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                KR_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 9 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                SEA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                SEA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 10 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                AI_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                AI_UnlockTest 6
            fi
            Goodbye
            
        elif [[ "$num" -eq 11 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                AF_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                AF_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 99 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Sport_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Sport_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 0 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
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
        CheckV4
        if [[ "$isv4" -eq 1 ]]; then
            Global_UnlockTest 4
            TW_UnlockTest 4
            HK_UnlockTest 4
            JP_UnlockTest 4
            NA_UnlockTest 4
            SA_UnlockTest 4
            EU_UnlockTest 4
            OA_UnlockTest 4
            KR_UnlockTest 4
            SEA_UnlockTest 4
            AI_UnlockTest 4
            AF_UnlockTest 4
        fi
        CheckV6
        if [[ "$isv6" -eq 1 ]]; then
            Global_UnlockTest 6
            TW_UnlockTest 6
            HK_UnlockTest 6
            JP_UnlockTest 6
            NA_UnlockTest 6
            SA_UnlockTest 6
            EU_UnlockTest 6
            OA_UnlockTest 6
            KR_UnlockTest 6
            SEA_UnlockTest 6
            AI_UnlockTest 6
            AF_UnlockTest 6
        fi
        Goodbye
    fi
}
wait
RunScript
