#!/bin/sh

function test_pkg {
if [ "$?" == 1 ]; then
    echo "Error"
    exit 1
fi
}

if [ $(uname -r) != "5.9" ]; then
        echo "This only works on OpenBSD 5.9"
        exit 1
fi

DEFAULT=/var/mailserver
PLUGINS=/var/www/roundcubemail/plugins

mkdir -p /var/db/spamassassin

pkg_add roundcubemail clamav postfix-3.0.3p0-mysql p5-Mail-SpamAssassin \
    dovecot-mysql dovecot-pigeonhole
test_pkg

echo " -- Stop and disable unwanted services"
/usr/sbin/rcctl stop smtpd
/usr/sbin/rcctl disable smtpd
/usr/sbin/rcctl stop sndiod
/usr/sbin/rcctl disable sndiod

echo " -- Set Ntpd"
/usr/sbin/rcctl set ntpd flags -s
/usr/sbin/rcctl restart ntpd

echo " -- Set Postfix"
/usr/local/sbin/postfix-enable
mkdir -p /etc/postfix/sql
install -m 644 $DEFAULT/install/system/postfix/* /etc/postfix
install -m 644 $DEFAULT/install/system/postfix-sql/* /etc/postfix/sql
/usr/sbin/rcctl enable postfix
/usr/sbin/rcctl start postfix

echo " -- Set Spamassassin"
install -m 644 $DEFAULT/install/system/spamassassin/* /etc/mail/spamassassin/local.cf
/usr/sbin/rcctl enable spamassassin
/usr/sbin/rcctl start spamassassin
/usr/local/bin/sa-update -v

echo " -- Set ClamAV"
install -m 644 $DEFAULT/install/system/clamav/*clam* /etc 2> /dev/null
if [ ! -f /var/db/clamav/main.cld ]; then
touch /var/log/clamd.log 2> /dev/null
chown _clamav:_clamav /var/log/clamd.log
touch /var/log/clam-update.log 2> /dev/null
chown _clamav:_clamav /var/log/clam-update.log
touch /var/log/freshclam.log 2> /dev/null
chown _clamav:_clamav /var/log/freshclam.log
mkdir -p /var/db/clamav
chown -R _clamav:_clamav /var/db/clamav
/usr/local/bin/freshclam --no-warnings
fi
/usr/sbin/rcctl enable freshclam
/usr/sbin/rcctl enable clamd
/usr/sbin/rcctl enable clamav_milter
/usr/sbin/rcctl start freshclam
/usr/sbin/rcctl start clamd
/usr/sbin/rcctl start clamav_milter

echo " -- Set Dovecot"
install -m 644 $DEFAULT/install/system/dovecot/* /etc/dovecot
touch /var/log/imap 2> /dev/null
chgrp _dovecot /usr/local/libexec/dovecot/dovecot-lda
chmod 4750 /usr/local/libexec/dovecot/dovecot-lda
/usr/sbin/rcctl enable dovecot

cat <<EOF>>/etc/login.conf
dovecot:\\
          :openfiles-cur=512:\\
          :openfiles-max=2048:\\
          :tc=daemon:

EOF

/usr/sbin/rcctl start dovecot

echo " -- Set newsyslog"
cp /etc/newsyslog.conf /etc/examples
head -n 16 /etc/examples/newsyslog.conf > /etc/newsyslog.conf

cat <<EOF>>/etc/newsyslog.conf
/var/www/logs/access.log                644  4     *    $W0   Z /var/run/nginx.pid SIGUSR1
/var/www/logs/error.log                 644  7     250  *     Z /var/run/nginx.pid SIGUSR1

EOF

echo " -- Set Roundcube"
/usr/local/bin/mysqladmin create webmail
/usr/local/bin/mysql webmail < /var/www/roundcubemail/SQL/mysql.initial.sql
/usr/local/bin/mysql webmail -e "grant all privileges on webmail.* to 'webmail'@'localhost' identified by 'webmail'"
(cd /var/www/roundcubemail;ftp http://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types && chown www.www mime.types)
cp $DEFAULT/install/system/roundcube/*.php /var/www/roundcubemail/config

echo " -- Set Roundcube sa plugin"
(cd $PLUGINS && git clone https://github.com/JohnDoh/Roundcube-Plugin-SpamAssassin-User-Prefs-SQL.git sauserprefs)
(cd $PLUGINS/sauserprefs && cp config.inc.php.dist config.inc.php)
(cd $PLUGINS/sauserprefs && cp $DEFAULT/install/system/roundcube/plugins/sausersprefs/* .)

echo " -- Set Roundcube password plugin"
(cd $PLUGINS/password && cp $DEFAULT/install/system/roundcube/plugins/password/* .)

echo " -- Set Roundcube markasjunk plugin"
(cd $PLUGINS && git clone https://github.com/JohnDoh/Roundcube-Plugin-Mark-as-Junk-2.git markasjunk2)
(cd $PLUGINS/markasjunk2 && cp $DEFAULT/install/system/plugins/markasjunk2/config.inc.php .)

echo " -- Set Roundcube sieverules plugin"
(cd $PLUGINS && git clone https://github.com/JohnDoh/Roundcube-Plugin-SieveRules-Managesieve.git sieverules)
(cd $PLUGINS/sieverules && cp $DEFAULT/install/system/plugins/sieverules/config.inc.php .)

echo " -- Set Roundcube contextmenu plugin"
(cd $PLUGINS && git clone https://github.com/JohnDoh/Roundcube-Plugin-Context-Menu.git contextmenu)
