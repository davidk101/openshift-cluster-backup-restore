#!/bin/bash 

# Objective: Restore the resources for a single namespace in an OSD/ROSA cluster 
# Input: Namespace directory with OpenShift resource YAMLs	
# Version: 1	
# Author: David Kumar

function checkPrerequisites(){
  
  oc_output=$(command -v oc)
  if [ ! -z $oc_output ] && [ -x $oc_output ]; then
    oc_location=$oc_output
    echo -e "oc found in \"$oc_location\"."
  else
    echo -e "Error! oc is needed to backup projets in a cluster."
    exit 1
  fi

  oc whoami
  if [[ $? != 0 ]]; then
    echo "Error! You are not logged in."
    exit 1
  fi
}

function restore(){

    read -p "Enter project namespace to restore: " project_name

    oc new-project ${project_name}
    if [[ $? != 0 ]]; then
      echo "Error! Project already exists."
      exit 1
    fi

    find ${project_name}
    if [[ $? != 0 ]]; then
      echo "Error! Project not found."
      exit 1
    fi

    cd project_name

    for file_name in *; 
    do 
        oc create -f ${file_name}
    done 
    
}

function restoreSpecificFile(){

  read -p "Enter project namespace to restore: " project_name
  read -p "Enter file name to restore: " file_name

  find ${project_name}
  if [[ $? != 0 ]]; then
    echo "Error! Project not found."
    exit 1
  fi

  cd ${project_name}
  oc create -f ${file_name}
}

checkPrerequisites
restoreSpecificFile
#restore

echo "Successfully terminating."
