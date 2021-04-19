#!/bin/bash

# Record when we started to make it easier to look for logs.
date

for ((i=0;i<100;i++)); do
    idx=$(printf %03d $i)
    echo $idx
    yaml=pod-corral/pod-${idx}.yaml
    sed "s/%%/${idx}/g" < pod-tmpl.yaml > $yaml
    kubectl apply -f $yaml
done
  
