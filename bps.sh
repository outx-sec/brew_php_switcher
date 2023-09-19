#!/bin/zsh

# Setting colors
readonly COLOR_DEFAULT='\e[0m'  # 默认颜色
readonly COLOR_INFO='\e[36m'  # Info: 青色
readonly COLOR_WARNING='\e[33m'  # Warning: 黄色
readonly COLOR_ERROR='\e[31m'  # Error: 红色
readonly COLOR_TRIVAL="\e[90m"  # 灰色

# Setting Path and 
httpd_conf_file="/opt/homebrew/etc/httpd/httpd.conf"
backup_httpd_conf_file="/opt/homebrew/etc/httpd/httpd.conf.bak"
brew_php_support_version=("PHP@5.6" "PHP@7.0" "PHP@7.1" "PHP@7.2" "PHP@7.3" "PHP@7.4" "PHP@8.0" "PHP@8.1" "PHP@8.3" "PHP@8.4")

# Define delimiter
window_width=$(tput cols)
DELIMITER() {
    printf '\e[32m%*s\n\e[0m' "${COLUMNS:-$window_width}" '' | tr ' ' -
}


# Clean up Brew links related to PHP versions
clean_brew_links() {
    for version in "${local_php_versions[@]}"; do
        echo -e "${COLOR_INFO}[+] Unlinking:${COLOR_TRIVAL}"
        brew unlink -q "$version"
    done
    
    echo -e "${COLOR_INFO}[+] Linking to: $1${COLOR_TRIVAL}"
    brew link -q --force --overwrite $1
    
    DELIMITER
}

# Check and back up the httpd configuration file
check_and_backup_httpd_conf() {    
    if [[ -f "$httpd_conf_file" ]]; then
        if [[ -f "$backup_httpd_conf_file" ]]; then
            echo -e "${COLOR_WARNING}[~] Found $backup_httpd_conf_file, Skipping...${COLOR_DEFAULT}"
        else
            echo -e "${COLOR_INFO}[+] Cannot found $httpd_conf_file , backup to: $backup_httpd_conf_file${COLOR_DEFAULT}"
            cp "$httpd_conf_file" "$backup_httpd_conf_file"
        fi
    else
        echo -e "${COLOR_WARNING}[~] The httpd configuration file does not exists, plz input:${COLOR_DEFAULT}"
        read -r httpd_conf_file
        if [[ ! -f "$httpd_conf_file" ]]; then
            echo -e "${COLOR_ERROR}[-] Cannot set your input, plz check it again...${COLOR_DEFAULT}"
            exit 1
        fi
    fi
   
    DELIMITER
}

# Get all local PHP versions
check_local_php_path() {
    IFS=$'\n' local php_paths=($(find /opt/homebrew/Cellar -type f | grep -i "PHP@[578].*/bin/php$"))
    
    echo -e "${COLOR_INFO}[+] Local PHP Version:"
    local_php_versions=()
    for php_path in $php_paths; do
        if [[ $php_path =~ php\@(5\.[0-9]+|7\.[0-9]+|8\.[0-9]+) ]]; then
            local_php_versions+="PHP@${match[1]}"
            echo -e "\t-\tPHP@${match[1]}"
        fi
    done
    
    echo -e "${COLOR_DEFAULT}"
    DELIMITER
}

# Switch the php version
switch_php_version() {
    local changing_php_version=$1
    local current_php_version="PHP@$(php -v | grep -oE '[0-9]+\.[0-9]+' | head -n1)"
    
    echo -e "${COLOR_INFO}[+] Unlinking $current_php_version${COLOR_TRIVAL}"
    brew unlink -q "$current_php_version" 
    
    echo -e "${COLOR_INFO}[+] Linking to: $changing_php_version${COLOR_TRIVAL}"
    brew link -q --force --overwrite "$changing_php_version"
    
    echo -e "${COLOR_INFO}[+] PHP has changed to:$changing_php_version${COLOR_DEFAULT}"
    
    DELIMITER
}

# Get the php_module for the php version
get_php_module_name() {
    local php_version=$1
    local php_module_name=""
    
    case $php_version in
        PHP@5*)
            php_module_name="php5_module"
        ;;
        PHP@7*)
            php_module_name="php7_module"
        ;;
        PHP@8*)
            php_module_name="php_module"
        ;;
    esac
    
    echo "$php_module_name"
}

# Modify the httpd configuration according to the php version that needs to be changed
change_httpd_setting() {
    local changing_php_version=$1
    local changing_php_module_name=$(get_php_module_name "$changing_php_version")
    
    local changing_php_module_file_path=$(find /opt/homebrew/Cellar/$changing_php_version -type f -name "libphp*.so")
    local changing_httpd_libphp="LoadModule $changing_php_module_name $changing_php_module_file_path"
    
    echo -e "${COLOR_INFO}[+] Changed HTTP Setting: $changing_httpd_libphp${COLOR_DEFAULT}"   
    if grep -q -E "^#?.*LoadModule php[578]?_module.*" "$httpd_conf_file"; then
        sed -i ".add_bak" -E "s|^LoadModule php[578]?_module.*|$changing_httpd_libphp|" "$httpd_conf_file"
    else
        sed -i '.org_bak' "1s|^|$changing_httpd_libphp\n|" "$httpd_conf_file"
    fi
    
    DELIMITER
}

# The main function
main() {
    local action=""
    local target_php=""
      
    # parse args
    while getopts "a:t:h" opt; do
        case $opt in
            a)
                action=$OPTARG
            ;;
            t)
                target_php=$OPTARG
            ;;
            h)
                help
                exit 1
            ;;
            \?)
                echo -e "${COLOR_ERROR}[-] Invalid action: -$OPTARG${COLOR_DEFAULT}" >&2
                exit 1
                ;;
            :)
                echo -e "${COLOR_ERROR}[-] Action -$OPTARG need a arg${COLOR_DEFAULT}" >&2
                exit 1
            ;;
        esac
    done
    if [[ -z $target_php ]]; then
        echo -e "${COLOR_ERROR}[-] Missing required \`-t\` parameter value${COLOR_DEFAULT}" >&2
        exit 1
    fi
    
    check_local_php_path
    case $action in
        switch_php_version)
            if contains_element "$target_php" "${local_php_versions[@]}"; then
                switch_php_version "$target_php"
            else
                echo -e "${COLOR_ERROR}[-] Invalid PHP Version: $target_php${COLOR_DEFAULT}"
                available_php_versions
                exit 1
            fi
        ;;
        change_httpd_setting)
            if contains_element "$target_php" "${local_php_versions[@]}"; then
                check_and_backup_httpd_conf
                change_httpd_setting "$target_php"
            else
                echo -e "${COLOR_ERROR}[-] Invalid PHP Version: $target_php${COLOR_DEFAULT}"
                available_php_versions
                exit 1
            fi
        ;;
        clean_brew_links)
            if contains_element "$target_php" "${local_php_versions[@]}"; then
                clean_brew_links "$target_php"
            else
                echo -e "${COLOR_ERROR}[-] Invalid PHP Version: $target_php${COLOR_DEFAULT}"
                available_php_versions
                exit 1
            fi
        ;;
        swith_php_change_httpd)
            if contains_element "$target_php" "${local_php_versions[@]}"; then
                switch_php_version "$target_php"
                check_and_backup_httpd_conf
                change_httpd_setting "$target_php"
            else
                echo -e "${COLOR_ERROR}[-] Invalid PHP Version: $target_php${COLOR_DEFAULT}"
                available_php_versions
                exit 1
            fi
        ;;
        *)
            echo -e "${COLOR_ERROR}[-] Invalid Action: $action${COLOR_DEFAULT}"
            available_actions
            exit 1
        ;;
    esac
}

# Check whether the element exists in the array
contains_element() {
    local element=$1
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    
    return 1
}

# List of available actions
available_actions() {
    echo -e "${COLOR_WARNING}[~] Available Actions:"
    echo -e "\t-\tswitch_php_version\t Switch PHP version in your shell."
    echo -e "\t-\tchange_httpd_setting\t Change httpd setting for PHP version."
    echo -e "\t-\tclean_brew_links\t Clean brew links for PHP version."
    echo -e "\t-\tswith_php_change_httpd\t Switch PHP version and change httpd setting for PHP version."  
    
    echo -e "${COLOR_DEFAULT}"
    DELIMITER
}

# List of available PHP versions
available_php_versions() {
    echo -e "${COLOR_WARNING}[~] Available PHP Versions:"
    for version in "${brew_php_support_version[@]}"; do
        echo -e "\t-\t$version"
    done
    
    echo -e "${COLOR_DEFAULT}"
    DELIMITER
}

# Help information
help() {
    echo -e "${COLOR_WARNING}[~] Usage: zsh bps.sh -a <action> -t <target_php>${COLOR_DEFAULT}"
    
    DELIMITER
    
    available_actions
    available_php_versions
    echo ""
}

# Start
if [[ $# -eq 0 ]]; then
    help
    exit 0
else
    DELIMITER
    main "$@"
fi