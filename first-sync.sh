#!/bin/bash

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
echo "cobbler signature update"
cobbler signature update
[ $? -eq 0 ] || exit 1
#echo "cobbler get-loaders" #deprecated, bugged and strongly discouraged
#cobbler get-loaders
cp -f /usr/share/syslinux/{ldlinux.c32,libcom32.c32,libutil.c32,menu.c32,pxelinux.0} /var/lib/cobbler/loaders
echo "cobbler sync"
cobbler sync
[ $? -eq 0 ] || exit 1
echo "cobbler check"
cobbler check

cobbler image list | grep memtest 1>/dev/null 2>&1
retval=$?
if [ ${retval} -ne 0 ]
then
  image=$(ls /boot/memtest*)
  cobbler image add --name=memtest --file=${image} --image-type=direct
fi
supervisorctl start rsyncd
