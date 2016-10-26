#sed -i "$line d" tmpimage.json
#sed -i "$line i$newimagelist," tmpimage.json

orchestration_name=`cat $2 | grep name | head -n 1 | awk -F ":" '{print $2}'|sed 's/\"//g'|sed 's/\,//g'`

#If the orchestration is already there, stop and delete it.
image_exist=`napi list orchestration $orchestration_name`
if [ -n $image_exist ]; then
   echo " $orchestration_name is not found "
else
   image_status=`napi list orchestration $orchestration_name -F status | tail -n 1`
   if [ $image_status != "stopped" ]; then
      napi stop orchestration $orchestration_name --force
   fi
   stop_status="stopping"
   while [[ $stop_status != "stopped" ]]
   do
      stop_status=`napi list orchestration $orchestration_name -F status | tail -n 1`
   done
   napi delete orchestration $orchestration_name
fi

#Add orchestration and start it.
napi add orchestration $2 -F name

napi start orchestration $orchestration_name -F name,status

sleep 30

new_image_status=`napi list orchestration $orchestration_name -F status | tail -n 1`
while [[ $new_image_status != "ready" ]]
do
      new_image_status=`napi list orchestration $orchestration_name -F status | tail -n 1`
done


instance=`napi list orchestration $orchestration_name -f json | grep name |head -n 1 | awk -F : '{print $2}'|sed 's/\"//g'|sed 's/\,//g'`

echo $instance

vcableid=`napi list vcable /imagepipeline -F id,instance | grep $instance |awk '{print $1}'`

ipassociation=`napi add ipassociation $vcableid ippool:/oracle/public/ippool1 -F name,ip`

napi list ipassociation / -F name,vcable,ip | grep $vcableid

echo "The instance status is ready now, you can login it by NAT ip"
