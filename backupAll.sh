#!/bin/bash 

# Objective: Backup all namespaces on a OSD/ROSA cluster 
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

# this function creates a backup of every project in the cluster the user is currently logged into  
function createBackup(){

  array=( $(oc projects -q) ) 

  #storing the name of every project into this array 
  array_length=${#my_array[@]}

  if ($array_length==0); then
    echo -e "Error! There are no projects to backup."
    exit 1
  fi

  for i in "${array[@]}"
  do
    # ignoring the projects named "openshift" automatically created by oc
    if [[ $i != *"openshift"* ]]; then
      mkdir -p "${i}"
      mkdir -p "uww-db-pg13-pc"
      oc project ${i}
      oc project uww-db-pg13-pc
      oc get -o yaml --export all > ${i}/project.yaml
      oc get -o yaml --export all > uww-db-pg13-pc/project.yaml
      # retrieving necessary namespaced resources that may not be included in project.yaml
      for object in $(oc api-resources --namespaced=true -o name)
      do
        oc get -o yaml --export $object > uww-db-pg13-pc/$object.yaml
        if [ "$?" != "0" ]; then
          continue

        fi
      done
    fi
  done
}

#this function removes the unnecessary placeholder files extracted from the cluster 
function removePlaceholderFiles(){

    project_list=( $(ls) ) 
    for project_name in "${project_list[@]}"
    do
      if [[ ${project_name} != "backupAutomation.sh" ]]; then

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
        cd ..
      fi 
    done 

}

checkPrerequisites
createBackup

echo "Successfully terminating."