#! /usr/bin/zsh
WS=ws://127.0.0.1:17211
TOKEN=getQQLoginQRcode
time=50
work=/tmp/onebot
mkdir -p $work
mkfifo $work/fifo $work/onebot.log $work/onebot.json $work/onebotjson
while (true)  {
#heart
(curl $ws -H "Authorization: Bearer $TOKEN" -N >$work/fifo ) &
heart=$!
while ( kill -0 $heart ) {
timeout 1 cat $work/fifo > $work/onebot.log
echo >> $work/onebot.log
sleep 1
} &
LOG=$!
while ( kill -0 $LOG ) {
cat $work/onebot.log|jq -c >$work/onebot.json
sleep 1
} &
json=$!
while ( kill -0 $json ) {
cat $work/onebot.json|jq '{time:.time,self_id:.self_id,user_id:.user_id,message_id:.message_id,message_seq:.message_seq,real_id:.real_id,message_type:.message_type,sender:.sender,raw_message:.raw_message,font:.font,sub_type:.sub_type,message:.message,message_format:.message_format,post_type:.post_type,group_id:.group_id}' -c  >$work/onebotjson
} &
onebotjson=$!
while ( kill -0 $onebotjson ) {
cat $work/onebotjson
sleep 1
}
sleep $time
}
