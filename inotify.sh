#!/bin/bash
#para
host01=192.168.10.96  #inotify-slave的ip地址
srcarr=("/home/public" "/home/harbor")
dstarr=("backup" "harborbak")
user=rsync_backup      #inotify-slave的rsync服务的虚拟用户
rsync_passfile=/etc/rsync.password   #本地调用rsync服务的密码文件
inotify_home=/usr/local/inotify-3.14    #inotify的安装目录
callRsync(){
inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format '%T %w%f' -e close_write,create,attrib $1 \
| while read file
    do
     cd $1 && rsync -aruz -R  ./  --timeout=300 $user@$host01::$2 --password-file=${rsync_passfile} >/dev/null 2>&1
    done
}
 
#judge
if [ ! -e "${rsync_passfile}" ]
then
echo "Check File and Folder"
exit 9
fi
i=0
count=2
while [ $i -lt $count ]
do
 callRsync ${srcarr[$i]} ${dstarr[$i]} &
 let i++
done
