#!/bin/bash 

# Objective: Backup a single namespace on an OSD/ROSA cluster
# Version: 1
# Author: David Kumar

# this function ensures you have oc installed and are logged into the cluster of choice 
function checkPrerequisites(){
  
  oc_output=$(command -v oc)
  if [ ! -z $oc_output ] && [ -x $oc_output ]; then
    oc_location=$oc_output
    echo -e "oc found in \"$oc_location\"."
  else
    echo -e "Error! oc is needed to backup projects in a cluster."
    exit 1
  fi

  oc whoami
  if [[ $? != 0 ]]; then
    echo "Error! You are not logged in."
    exit 1
  fi
}

# this function creates a backup of a single user-specified project in the cluster the user is currently logged into  
function createBackup(){

    read -p "Enter project namespace to backup: " project_name

    mkdir -p ${project_name}
    oc project ${project_name}
    oc get -o yaml --export all > ${project_name}/project.yaml
    
    # retrieving necessary namespaced resources that may not be included in project.yaml
    for object in $(oc api-resources --namespaced=true -o name)
    do
    oc get -o yaml --export $object > ${project_name}/$object.yaml
    if [ "$?" != "0" ]; then
        continue

    fi
    done
}

#this function removes the unnecessary placeholder YAML files extracted from the cluster 
function removePlaceholderFilesForSingleProject(){

    read -p "Enter project namespace to remove placeholder files for: " project_name
    cd ${project_name}
    if [[ $? != 0 ]]; then
      echo "Error! Failed to enter a working directory."
    exit 1
    fi

    file_list=( $(ls) ) 
    for file_name in "${file_list[@]}"
    do
      file_size=$(stat -f%z "$file_name")

      # removing every config file with default placeholder YAML
      if (( file_size < 84 )); then
        rm ${file_name}
      fi
    done

}

checkPrerequisites
createBackup

echo "Successfully terminating."