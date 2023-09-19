# BREW-PHP-SWITCHER
> Only for MacOS(zsh).

A simple script to switch PHP versions(brew installed). <br>
Suitable for environments with <b>PHP(shivammathur/php/php) + APACHE(httpd)</b> configured.
## Supports
PHP in shivammathur/php/php, include:
* PHP@5.6
* PHP@7.0
* PHP@7.1
* PHP@7.2
* PHP@7.3
* PHP@7.4
* PHP@8.0
* PHP@8.1
* PHP@8.3
* PHP@8.4

## Installation
Move the .sh to your $PATH.
Or use it like:
`zsh bps.sh` 
## USAGE
```
Usage: ./bps.sh -a <action> -t <target_php>

Available Actions:
-       switch_php_version       Switch PHP version in your shell.
-       change_httpd_setting     Change httpd setting for PHP version.
-       clean_brew_links         Clean brew links for PHP version.
-       swith_php_change_httpd   Switch PHP version and change httpd setting for PHP version.

Example:
> zsh bps.sh -a swith_php_change_httpd -t PHP@7.4
```

## LICENSE
MIT
