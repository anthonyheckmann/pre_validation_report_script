#!/usr/bin/env bash


#Sould return just version of OS . (Note \K in grep suppressed 1st group)
OS(){

    local name_and_version_regex="((?:^NAME=\")\K.*(\"))|((^VERSION=\")\K.*(\"))"
    grep -oP  "$name_and_version_regex" /etc/os-release | tr -d \"
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
    if  { sudo id || id; } |  grep -q "uid=0"; then
        echo "Available";
    else
        echo "No Root";
    fi 
}

#Check for existence of sestatus command; then try running it and look if enabled
SELINUX() { 
    if hash sestatus 2>/dev/null; then

        { sestatus || sudo sestatus; } | grep -oP "(SELinux\Wstatus:\W+)\K\w*";
    else
        echo -e "Nothing Found"
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
Docker Version:
$( boldo "$(DOCKER_V)")
$(dim_line)
Space Report:
$( boldo "$(STORAGE_SPACE)")
$(dim_line)
Root Status:
$( boldo "$(ROOT_ACCESS_INSTALL)")
$(dim_line)
SELinux:
$( boldo "$(SELINUX)")
$(dim_line)
EOF


