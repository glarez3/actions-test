#!/usr/bin/bash

COMMAND_OUPUT=`aws deploy get-deployment --deployment-id $deployment_id --query "deploymentInfo.[status]" --output text`
echo "You deployment status is: $COMMAND_OUPUT"
if grep -q Skipped | Failed "$COMMAND_OUPUT"; then
    echo "Muelte!"
    exit 1
elif grep -q Inprogress | Pending "$COMMAND_OUPUT"; then
    echo "Calmaooo!"
else
    grep -q Sucedeed "$COMMAND_OUPUT"
    exit 0
fi


        COMMAND_OUPUT=`aws deploy get-deployment --deployment-id $deployment_id --query "deploymentInfo.[status]" --output text`
        
        echo "You deployment status is: $COMMAND_OUPUT"
        
        while $COMMAND_OUPUT" == Inprogress | Pending; do
          echo "Calmaooo que falta poco!"
          if $COMMAND_OUPUT" == Skipped | Failed; then
            echo "Muelte!"
            exit 1
          else
            echo "Exito!"
            exit 0
          fi
        break