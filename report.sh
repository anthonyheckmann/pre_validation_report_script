#!/usr/bin/env bash


#Sould return just version of OS . (Note \K in grep suppressed 1st group)
OS(){

    local name_and_version_regex="((?:^NAME=\")\K.*(\"))|((^VERSION=\")\K.*(\"))"
    grep -oP  "$name_and_version_regex" /etc/os-release | tr -d \"
}

DOCKER_ACCESS() {
    #normal
    local -a dock_req=()
    
    if sudo docker version > /dev/null 2>&1; then
        dock_req+=("root")
    fi
    if docker version > /dev/null 2>&1; then
        dock_req+=("$(whoami)")
    fi
    if [[ ${#dock_req[@]} -gt 0 ]]; then
        echo -n "Users checked: ${dock_req[*]}"
    fi

}


#Sould return just version of Docker client. (Note \K in grep suppressed 1st group)
DOCKER_V(){
    docker version \
    | grep -ozP  "(?s)(Client:.*?Version:\W+)\K\N*" \
    | tr -d '\0'
    }

#prints out storage found, excluding loop and temp devices
STORAGE_SPACE(){
    
    df -h | grep -vE "(loop)|(tmpfs)"

} 

#Looks for uid=0 via id command
ROOT_ACCESS_INSTALL() {
    # local id_dump="$( sudo id || id )"
    if  { sudo id || id; } |  grep -q "uid=0"; then
        echo "Available";
    else
        echo "No Root";
    fi
    
}

CURRENT_UID() {
    echo "Current UID: $(id | grep -oP '(uid=)\K\d*')"
}

#Check for existence of sestatus command; then try running it and look if enabled
SELINUX() {
    local access_local=""
    local grep_filter="(SELinux\Wstatus:\W+)\K\w*"
    if hash sestatus 2>/dev/null; then
    
        if sestatus > /dev/null 2>&1; then
            echo -n "$(sestatus | grep -oP "$grep_filter")"
        elif sestatus > /dev/null 2>&1; then
            echo -n "$(sudo sestatus | grep -oP "$grep_filter")"
        else
            echo "Nothing Found"
        fi
    fi
}

bold="\e[1m"
reseto="\e[0m"
dim="\e[2m"
red="\e[31m"
blink="\e[5m"

boldo(){

    echo -e "$bold$1$reseto"
}

dimmo(){
    echo -e "$dim$1$reseto"
}

blinky() {
    echo -e "$blink$1$reseto"
}

dim_line(){
    dimmo "======================================="
}

red_red() {
    echo -e "$red$1$reseto"
}

cat <<EOF
$(dim_line)
Linux Distribution & Version:
$( boldo  "$(OS)")
$(dim_line)
Root Status:
$( boldo "$(ROOT_ACCESS_INSTALL)")
$( dimmo "$(CURRENT_UID)")
$(dim_line)
Docker Version:
$( boldo "$(DOCKER_V)")
$( dimmo "$(DOCKER_ACCESS)")
$(dim_line)
Space Report:
$( boldo "$(STORAGE_SPACE)")
$(dim_line)
SELinux Status:
$( boldo "$(SELINUX)")
$(dim_line)
EOF


