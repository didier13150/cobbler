#!/bin/bash
##############################################################################
#       ____              ____    _       _   _                              #
#      /# /_\_           |  _ \  (_)   __| | (_)   ___   _ __                #
#     |  |/o\o\          | | | | | |  / _` | | |  / _ \ | '__|               #
#     |  \\_/_/          | |_| | | | | (_| | | | |  __/ | |                  #
#    / |_   |            |____/  |_|  \__,_| |_|  \___| |_|                  #
#   |  ||\_ ~|                                                               #
#   |  ||| \/                                                                #
#   |  |||                                                                   #
#   \//  |                                                                   #
#    ||  |       Developper : Didier FABERT <didier@tartarefr.eu>            #
#    ||_  \      Date : 2018, May                                            #
#    \_|  o|                                             ,__,                #
#     \___/      Copyright (C) 2018 by Didier FABERT     (oo)____            #
#      ||||__                                            (__)    )\          #
#      (___)_)                                             ||--||  *         #
#                                                                            #
#    This program is free software; you can redistribute it and/or modify    #
#    it under the terms of the GNU General Public License as published by    #
#    the Free Software Foundation; either version 3 of the License, or       #
#    (at your option) any later version.                                     #
#                                                                            #
#    This program is distributed in the hope that it will be useful,         #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of          #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           #
#    GNU General Public License for more details.                            #
#                                                                            #
#    You should have received a copy of the GNU General Public License       #
#    along with this program; if not, see                                    #
#    <http://www.gnu.org/licenses/>                                          #
##############################################################################

DEFAULT_ROOT_PASSWD=${DEFAULT_ROOT_PASSWD:-cobbler}
HOST_IP_ADDR=${HOST_IP_ADDR:-}
HOST_HTTP_PORT=${HOST_HTTP_PORT:-80}
COBBLER_WEB_USER=${COBBLER_WEB_USER:-cobbler}
COBBLER_WEB_PASSWD=${COBBLER_WEB_PASSWD:-cobbler}
COBBLER_WEB_REALM=${COBBLER_WEB_REALM:-cobbler}
COBBLER_LANG=${COBBLER_LANG:-fr_FR}
COBBLER_KEYBOARD=${COBBLER_KEYBOARD:-fr-latin9}
COBBLER_TZ=${COBBLER_TZ:-Europe/Paris}

if [ -z "${HOST_IP_ADDR}" ]
then
  echo "ERROR: HOST_IP_ADDR env cannot be empty. Set this variable value with the IP address of host which run docker"
  exit 1
fi

#htdigest -c /etc/cobbler/users.digest "cobbler" cobbler
printf "%s:%s:%s\n" "${COBBLER_WEB_USER}" "${COBBLER_WEB_REALM}" "$( printf "%s:%s:%s" "${COBBLER_WEB_USER}" "${COBBLER_WEB_REALM}" "${COBBLER_WEB_PASSWD}" | md5sum | awk '{print $1}' )" > "/etc/cobbler/users.digest"

cobbler_root_passwd=$(echo -e "${DEFAULT_ROOT_PASSWD}" | openssl passwd -1 -stdin)
sed -i \
    -e "/^default_password_crypted/ s|:.*$|: \"${cobbler_root_passwd}\"|" \
    -e "/^next_server/ s/:.*$/: ${HOST_IP_ADDR}/" \
    -e "/^server/ s/:.*$/: ${HOST_IP_ADDR}/" \
    -e "/^http_port:/ s/:.*$/: ${HOST_HTTP_PORT}/" \
    /etc/cobbler/settings

for ks in sample.ks sample_end.ks legacy.ks pxerescue.ks
do
  sed -i \
      -e "/^lang/ s/en_US/${COBBLER_LANG}/" \
      -e "/^keyboard/ s/us/${COBBLER_KEYBOARD}/" \
      /var/lib/cobbler/kickstarts/${ks}
done
for ks in sample.ks sample_end.ks legacy.ks
do
  sed -i \
      -e "/^timezone/ s|America/New_York|${COBBLER_TZ}|" \
      /var/lib/cobbler/kickstarts/${ks}
done
for snippet in sample.seed sample_old.seed
do
  sed -i \
      -e "s|America\/New_York|${COBBLER_TZ}|" \
      -e "s|us$|fr-latin9|" \
      -e "s|en_US$|${COBBLER_LANG}|" \
      /var/lib/cobbler/kickstarts/${snippet}
done
for dir in distros.d files.d images.d mgmtclasses.d packages.d profiles.d repos.d systems.d
do
  mkdir -p /var/lib/cobbler/config/${dir}
done

touch /usr/share/cobbler/web/cobbler.wsgi
/usr/local/bin/first-sync.sh &
echo "Running supervisord"
/usr/bin/supervisord -c /etc/supervisord.conf
