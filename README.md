# OpenBSD Mailserver

A full mailserver with an admin GUI and a domain admin GUI.
This works on OpenBSD 5.9.

Includes:

- postfix
- dovecot
- spamassasin
- clamav with automatic updates
- packet filter
- roundcube webmail

*The admin and account apps forked from the free [mailserv project](https://github.com/mailserv/mailserv).

## Installation

#### Get git

    export PKG_PATH=http://ftp2.fr.openbsd.org/pub/OpenBSD/5.9/packages/amd64/
    pkg_add git

#### Update the box

    cd /usr/local/sbin
    ftp https://stable.mtier.org/openup
    chmod +x openup
    openup && reboot
    
#### Fetch the project

    cd /var
    git clone https://github.com/wesley974/mailserver
    
#### Install the GUI

Don't forget to tune your hosts file and verify your hostname!

    cd /var/mailserver/install
    ./install_gui.sh
    ./build_db.sh

#### INSTALL THE MAIL SYSTEM

    cd /var/mailserver/install
    ./install_system.sh 
    ./enable_admin_rc.sh
    ./sysmail.sh

## USAGE

### Execute the apps

    ./run_gui.sh

#### Set the mailserver administrator

Just browse https://ip_address:4200/getting_started

#### The mailserver app

https://ip_address:4200

#### Your webmail

https://ip_address  
 
*Enjoy!*
