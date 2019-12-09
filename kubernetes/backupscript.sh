#!/bin/bash

# Input: file with a namespace per line
# Output: the backup of the tokens of the service accounts of each namespace in the file, in json format
# Requirements: kubectl, jq, bash

auxjson='{ "namespaces": {} }'

while read namespace; do
  if [ -z $(kubectl get namespace $namespace -ojsonpath=\"{.metadata.name}\" 2>/dev/null) ]; then
    echo "Namespace ${namespace} not found"
  else
    serviceaccounts=$(kubectl get serviceaccounts -n ${namespace} -ojsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
    while IFS= read -r sa_from_namespace ; do 
      auxsecret=$(kubectl get sa ${sa_from_namespace} -n ${namespace} -ojsonpath='{.secrets[0].name}{"\n"}')
      auxtoken=$(kubectl get secret ${auxsecret} -n ${namespace} -ojsonpath='{.data.token}' )
      auxjson=$(echo $auxjson | jq ".namespaces.\"${namespace}\".serviceaccounts += {\"${sa_from_namespace}\": \"${auxtoken}\"}")
    done <<< "$serviceaccounts"
  fi
done < $1
echo ${auxjson} > result.json
