#!/usr/bin/env bash

NOTES=( )

SPACE_NEEDED="65GB"
DOCKER_NEEDED="1.13"



######################################################
### FORMATTING VARS AND FUNCTIONS
bold="\e[1m"
reseto="\e[0m"
dim="\e[2m"
red="\e[31m"
blink="\e[5m"

boldo(){
    echo -en "$bold$1$reseto"
}
dimmo(){
    echo -en "$dim$1$reseto"
}
blinky() {
    echo -en "$blink$1$reseto"
}
dim_line(){
    dimmo "======================================="
}
red_red() {
    echo -en "$red$1$reseto"
}
################ END FORMATTING VARS AND FUNCTIONS

################ Utility Functions 

#Size less than or equals
size_lte(){
    [  "$1" = "$(echo -e "$1\n$2" | sort -h | head -n1)" ]
}

#Version less than or equals
version_lte(){
    [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

version_gte(){
    [  "$1" = "$(echo -e "$1\n$2" | sort -Vr | head -n1)" ]
}

version_lt(){
    [ "$1" = "$2" ] && return 1 || version_lte "$1" "$2"
}
    

################ END Utility Functions

#Sould return just version of OS . (Note \K in grep suppressed 1st group)
OS_INFO(){

    #Regex finds lines starting with NAME or VERSION plus following text, then
    #excludes first match with \K
    local name_and_version_regex="((?:^NAME=\")\K.*(\"))|((^VERSION=\")\K.*(\"))"
    

    #Check for release files like os-release, redhat-release, lsb-release
    for release_file in /etc/*release; do

        #However we only parse os-release, which should always exist
        if [[ $release_file == "/etc/os-release" ]]; then

            grep -oP  "$name_and_version_regex" "$release_file" | tr -d \"

        else
            NOTES+=( "Found $release_file but it was not parsed" )
        fi
       
    done
}




DOCKER_VALID_USERS() {
    #normal
    local -a dock_req=()
    
    if sudo docker version > /dev/null 2>&1; then
        dock_req+=("$(sudo whoami)")
    fi
    if docker version > /dev/null 2>&1; then
        dock_req+=("$(whoami)")
    fi
    if [[ ${#dock_req[@]} -gt 0 ]]; then
        echo -en "tested users: ${dock_req[*]}"
    fi

}


#Sould return just version of Docker client. (Note \K in grep suppressed 1st group)
DOCKER_VERSION(){
    local docker_ver
    if hash docker 2>/dev/null; then
        docker_ver="$(docker version \
        | grep -ozP  "(?s)(Client:.*?Version:\W+)\K\N*" \
        | tr -d '\0')"
        boldo "$docker_ver\n"
        if version_lt "$docker_ver" "$DOCKER_NEEDED"; then
            red_red "This version $docker_ver is incompatible since we require at least version $DOCKER_NEEDED\n"
        fi
    else
        red_red "DOCKER NOT FOUND"
    fi
}

#prints out storage found, excluding loop and temp devices
STORAGE_SPACE(){
    
    local dh_out formatted_dh
    #Raw df output saved for reuse
    dh_out="$(df -h)"

    #Create alias for stdout "5" in this case
    exec 5>&1

    #remove header, then print out remaining space, percentage left and mount
    #follow by some redirect magic, using alias "5"
    formatted_dh="$(echo "$dh_out" | grep -vE "(loop)|(tmpfs)|(Filesystem)" \
    | awk '{ print $4,"\t",$5,"\t",$6}' | sort -hr | tee >(cat >&5))"

    #from formatted space report, get largest free space
    largest_free_space="$(echo "$formatted_dh" | head -n1 | awk '{print $1}')"

    if size_lte "$SPACE_NEEDED" "$largest_free_space"; then
        dimmo "$largest_free_space found on largest drive"  
    else
        red_red "$largest_free_space found, but $SPACE_NEEDED is required"
    fi
} 

#Looks for uid=0 via id command
ROOT_ACCESS_PRESENT() {

    # local id_dump="$( sudo id || id )"
    if  { sudo id || id; } |  grep -q "uid=0"; then
        boldo "Available";
    else
        red_red "No Root";
        red_red " THIS MAY BE AN ISSUE"
    fi
    
}

CURRENT_UID() {
    echo -n "$(id | grep -oP '(uid=)\K\d*')"
}

CURRENT_USER() {
    echo -n "$(whoami)"
}

#Check for existence of sestatus command; then try running it and look if enabled
SELINUX_STATUS() {

    local grep_filter="(SELinux\Wstatus:\W+)\K\w*"
    if hash sestatus 2>/dev/null; then

        #Since sestatus exists, we'll print out it's status
        if sestatus > /dev/null 2>&1; then
            boldo "Running as:$(whoami) with Status: $(sestatus | grep -oP "$grep_filter")"
        elif sudo sestatus > /dev/null 2>&1; then
            boldo "Running as:$(sudo whoami) with Status: $(sudo sestatus | grep -oP "$grep_filter")"
        else
            boldo "Odd Finding: sestatus command exists, but cannot be run"
        fi
        red_red " You may need to run: \"chcon -t container_file_t <mount_point\" to ensure access"
    else
        boldo "Nothing Found"
    fi
}

AFTER_NOTES(){
    echo
}



cat <<EOF
$(dim_line)
Linux Distribution & Version:
$( boldo  "$(OS_INFO)")
$(dim_line)
Root Status:
$( ROOT_ACCESS_PRESENT; dimmo " current id/name:$(CURRENT_UID)/$(CURRENT_USER)" )
$(dim_line)
Docker Version:
$( boldo "$(DOCKER_VERSION)")$(dimmo "$(DOCKER_VALID_USERS)")
$(dim_line)
Space Report:
$( STORAGE_SPACE )
$(dim_line)
SELinux Status:
$( SELINUX_STATUS)
$(dim_line)
EOF


