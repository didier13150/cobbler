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

timeout=30
while ! netstat -laputen | grep -i listen | grep 25151 1>/dev/null 2>&1
do
  sleep 1
  timeout=$((${timeout} - 1))
  if [ ${timeout} -eq 0 ]
  then
    echo "ERROR: cobblerd is not running."
    exit 1
  fi
done
sleep 2
echo "cobbler get-loaders"
cobbler get-loaders
echo "cobbler sync"
cobbler sync
echo "cobbler check"
cobbler check
