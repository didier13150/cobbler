#!/bin/bash

DEFAULT_ROOT_PASSWD=${DEFAULT_ROOT_PASSWD:-cobbler}
HOST_IP_ADDR=${HOST_IP_ADDR:-192.168.122.1}
HOST_HTTP_PORT=${HOST_HTTP_PORT:-8080}
COBBLER_WEB_USER=${COBBLER_WEB_USER:-cobbler}
COBBLER_WEB_PASSWD=${COBBLER_WEB_PASSWD:-cobbler}
COBBLER_WEB_REALM=${COBBLER_WEB_REALM:-Cobbler}
COBBLER_LANG=${COBBLER_LANG:-fr_FR}
COBBLER_KEYBOARD=${COBBLER_KEYBOARD:-fr-latin9}
COBBLER_TZ=${COBBLER_TZ:-Europe/Paris}
COBBLER_WEB_CERT=${COBBLER_WEB_CERT:-/etc/pki/tls/certs/localhost.crt}
COBBLER_WEB_KEY=${COBBLER_WEB_KEY:-/etc/pki/tls/private/localhost.key}
COBBLER_WEB_KEYSIZE=${COBBLER_WEB_KEYSIZE:-2048}
COBBLER_CERT_COUNTRY=${COBBLER_CERT_COUNTRY:-FR}
COBBLER_CERT_STATE=${COBBLER_CERT_STATE:-Occitanie}
COBBLER_CERT_CITY=${COBBLER_CERT_CITY:-Beaucaire}
COBBLER_CERT_ORGNAME=${COBBLER_CERT_ORGNAME:-Home}
COBBLER_CERT_ORGUNIT=${COBBLER_CERT_ORGUNIT:-SysAdmin}
COBBLER_CERT_HOSTNAME=${COBBLER_CERT_HOSTNAME:-cobbler.tartarefr.eu}
COBBLER_CERT_EMAIL=${COBBLER_CERT_EMAIL:-root@cobbler.tartarefr.eu}

if [ ! -z "${COBBLER_WEB_KEY}" ] && [ ! -f ${COBBLER_WEB_KEY} ]
then
    openssl genrsa ${COBBLER_WEB_KEYSIZE} > ${COBBLER_WEB_KEY}
fi
if [ ! -z "${COBBLER_WEB_CERT}" ] && [ ! -f ${COBBLER_WEB_CERT} ]
then
    cat << EOF | openssl req -new -key ${COBBLER_WEB_KEY} -x509 -days 365 -out ${COBBLER_WEB_CERT} 2>/dev/null
${COBBLER_CERT_COUNTRY}
${COBBLER_CERT_STATE}
${COBBLER_CERT_CITY}
${COBBLER_CERT_ORGNAME}
${COBBLER_CERT_ORGUNIT}
${COBBLER_CERT_HOSTNAME}
${COBBLER_CERT_EMAIL}
EOF
fi

sed -i \
    -e "/^SSLCertificateFile/ s;^.*$;SSLCertificateFile ${COBBLER_WEB_CERT};" \
    -e "/^SSLCertificateKeyFile/ s;^.*$;SSLCertificateKeyFile ${COBBLER_WEB_KEY};" \
    /etc/httpd/conf.d/ssl.conf
    
echo "ServerName $(hostname -i)" > /etc/httpd/conf.d/_my_hostname.conf

#htdigest -c /etc/cobbler/users.digest "Cobbler Web Access" cobbler
printf "%s:%s:%s\n" "${COBBLER_WEB_USER}" "${COBBLER_WEB_REALM}" "$( printf "%s:%s:%s" "${COBBLER_WEB_USER}" "${COBBLER_WEB_REALM}" "${COBBLER_WEB_PASSWD}" | md5sum | awk '{print $1}' )" > "/etc/cobbler/users.digest"
if [ "${COBBLER_WEB_USER}" != "cobbler" ] && [ "${COBBLER_WEB_USER}" != "admin" ]
then
    echo "${COBBLER_WEB_USER} = \"\"" >> /etc/cobbler/users.conf
fi

cobbler_root_passwd=$(echo -e "${DEFAULT_ROOT_PASSWD}" | openssl passwd -1 -stdin)
sed -i \
    -e "/^default_password_crypted/ s|:.*$|: \"${cobbler_root_passwd}\"|" \
    -e "/^next_server/ s/:.*$/: ${HOST_IP_ADDR}/" \
    -e "/^server/ s/:.*$/: ${HOST_IP_ADDR}/" \
    -e "/^http_port:/ s/:.*$/: ${HOST_HTTP_PORT}/" \
    /etc/cobbler/settings

for ks in sample.ks sample_legacy.ks pxerescue.ks
do
  sed -i \
      -e "/^lang/ s/en_US/${COBBLER_LANG}/" \
      -e "/^keyboard/ s/us/${COBBLER_KEYBOARD}/" \
      /var/lib/cobbler/templates/${ks}
done
for ks in sample.ks sample_legacy.ks
do
  sed -i \
      -e "/^timezone/ s|America/New_York|${COBBLER_TZ}|" \
      /var/lib/cobbler/templates/${ks}
done
for snippet in sample.seed sample_old.seed
do
  sed -i \
      -e "s|US/Eastern|${COBBLER_TZ}|" \
      -e "s|us$|fr-latin9|" \
      -e "s|en_US$|${COBBLER_LANG}|" \
      /var/lib/cobbler/templates/${snippet}
done
for dir in distros.d files.d images.d mgmtclasses.d packages.d profiles.d repos.d systems.d
do
  [ ! -d "/var/lib/cobbler/config/${dir}" ] && mkdir -p /var/lib/cobbler/config/${dir}
done

touch /usr/share/cobbler/web/cobbler.wsgi

# Already fixed on cobbler master branch in github
grep redhat_list /usr/lib/python3.6/site-packages/cobbler/utils.py | grep rocky
retval=$?
[ ${retval} -eq 0 ] || sed -i -e '/redhat_list/ s/)/, "almalinux", "rocky linux")/' /usr/lib/python3.6/site-packages/cobbler/utils.py

# Sad hack: because digest auth is not working
sed -i -e '/module = authentication/ s/configfile/testing/' /etc/cobbler/modules.conf

/usr/local/bin/first-sync.sh &
echo "Running supervisord"
/usr/bin/supervisord -c /etc/supervisord.conf
