#!/bin/bash

# Input: file with a namespace per line, file with the backup
# Requirements: kubectl, jq, bash

auxjson='{ "namespaces": {} }'

while read namespace; do
  if [ -z $(kubectl get namespace $namespace -ojsonpath=\"{.metadata.name}\" 2>/dev/null) ]; then
    echo "Namespace ${namespace} not found"
  else
    serviceaccounts=$(cat $2 | jq -r ".namespaces.\"${namespace}\".serviceaccounts | keys[]")
    #echo $serviceaccounts
    while IFS= read -r sa_from_namespace ; do 
      auxsecret=$(kubectl get sa ${sa_from_namespace} -n ${namespace} -ojsonpath='{.secrets[0].name}{"\n"}')
      echo $auxsecret
      #auxpatch2=$(cat $2 | jq ".namespaces.\"${namespace}\".serviceaccounts.\"${sa_from_namespace}\"")
      auxpatch="{\"data\": {\"token\": $(cat $2 | jq ".namespaces.\"${namespace}\".serviceaccounts.\"${sa_from_namespace}\"")}}"
      #echo $auxpatch
      #echo $auxpatch2
      kubectl patch secret ${auxsecret} -n ${namespace} --patch "${auxpatch}"
    done <<< "$serviceaccounts"
  fi
done < $1
echo "Done"
