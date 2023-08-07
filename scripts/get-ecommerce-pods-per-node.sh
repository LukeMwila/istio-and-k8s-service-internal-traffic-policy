#!/bin/bash

FILE=pods-per-node.txt

# Check if pods-per-node file exists. If so, delete content.
if test -f "$FILE"; then
    echo "$FILE exists."
    > $FILE
    cat $FILE
fi

echo "NODE: <ec2-node-ip>; AZ: <ec2-az>" >> $FILE 
kubectl get pods -n ecommerce -o wide --field-selector spec.nodeName=ec2-node-ip >> $FILE 
echo "------------------------------------------------------------------------" >> $FILE 
echo "NODE: <ec2-node-ip>; AZ: <ec2-az>" >> $FILE 
kubectl get pods -n ecommerce -o wide --field-selector spec.nodeName=ec2-node-ip >> $FILE 
echo "------------------------------------------------------------------------" >> $FILE 
echo "NODE: <ec2-node-ip>; AZ: <ec2-az>" >> $FILE 
kubectl get pods -n ecommerce -o wide --field-selector spec.nodeName=ec2-node-ip >> $FILE 

cat $FILE