#! /usr/bin/zsh
trap "pkill -TERM -P $$; return -1"  TERM HUP INT
WS=ws://127.0.0.1:17211
TOKEN=getQQLoginQRcode
time=50
work=/tmp/onebot
function send(){
SEND={"action":"send_message","params":{"detail_type":"group","group_id":"$group_id","message":[{"type":"text","data":{"text":"$text"}}]}}
curl  -H "Authorization: Bearer $TOKEN" -N -d $SEND > $work/logs
}
mkdir -p $work
mkfifo $work/fifo $work/onebot.log $work/main
while (true)  {
#heart
(curl  -H "Authorization: Bearer $TOKEN" -N  $WS >$work/fifo ) &

while ( true ) {
timeout 1 cat $work/fifo > $work/onebot.log
echo >> $work/onebot.log
} &
LOG=$!
while ( true ) {
ERROR=0
LOG=$(cat $work/onebot.log)
if [[ ! $LOG ]] { ERROR=1 }
if (echo $LOG | jq ".meta_event_type"|grep \"lifecycle\"  > /dev/null  ){ ERROR=1 }
if (echo $LOG | jq ".meta_event_type"|grep  \"heartbeat\" > /dev/null  ){ ERROR=1 }
if (echo $LOG | jq ".status"|grep  \"ok\" > /dev/null  ){ ERROR=1 }
if (echo $LOG | jq ".sub_type"|grep  \"connect\" > /dev/null  ){ ERROR=1 }
if  [[ $ERROR != 1 ]] {
LOG=$(echo $LOG |jq -c)
echo $LOG >> $work/onebot.json
echo $LOG >> $work/main
}
} &
while ( true ) {
main=$( cat $work/main)
group_id= $(echo $main\ jq ".group_id")
user_id=$(echo $main\ jq ".user_id")
event="$(echo $main\ jq ".post_type") $(echo $main\ jq ".message_type") $(echo $main\ jq ".notice_type") $(echo $main\ jq ".sub_type") "
case $event in
"friend_recall" )
NOW=friend_recall

;;
"group_recall" )
NOW=group_recall

;;
"friend_add" )
NOW=friend_add

;;
"group_ban" )
NOW=group_ban

;;
"group_increase" )
NOW=group_increase

;;
"group_decrease" )
NOW=group_decrease

;;
"group_admin" )
NOW=group_admin

;;
"group_upload" )
NOW=group_upload

;;
"group" )
NOW=group

;;
"private" )
NOW=private

;;
"notify" )
NOW=notify

;;
"poke" )
NOW=poke

;;
"friend" )
NOW=friend

;;
"honor" )
NOW=honor

;;
"lucky_king" )
NOW=lucky_king

;;

"message")
NOW=message
time=$(echo $main\ jq ".time")
nickname=$(echo $main\ jq ".sender.nickname")
message_type=$(echo $main\ jq ".message_type")
message_id=$(echo $main\ jq ".message_id")
real_id=$(echo $main\ jq ".real_id")
message=$(echo $main\ jq ".message" -c )
sender=$(echo $main\ jq ".sender" -c )
raw_message=$(echo $main\ jq ".raw_message" -c )
font=$(echo $main\ jq ".font")
;;
esac
}
sleep $time
}
