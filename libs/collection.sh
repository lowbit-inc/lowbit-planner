#!/bin/bash

function collectionAdd() {
  this_collection_name="$@"

  if [[ $this_collection_name ]] ; then
    database_run "INSERT INTO collection (name) VALUES ('$this_collection_name');"
  else
    echo "Error: missing collection name."
    exit 1
  fi
}

function collectionDelete() {
  this_collection_name="$1"

  if [[ $this_collection_name ]] ; then
    database_run "DELETE FROM collection WHERE name = '$this_collection_name';"
  else
    echo "Error: missing collection name."
    exit 1
  fi
}

function collectionHelp() {
  echo "${help_banner} - Collections"
  echo
  echo "Collections:"
  echo "  $(basename $0) add COLLECTION_NAME"
  echo "  $(basename $0) decide COLLECTION_NAME"
  echo "  $(basename $0) delete COLLECTION_NAME"
  echo "  $(basename $0) help (this message)"
  echo "  $(basename $0) list"
  echo "  $(basename $0) rename OLD_COLLECTION_NAME NEW_COLLECTION_NAME"
  echo
  echo "Items:"
  echo "  $(basename $0) add-item COLLECTION_NAME ITEM_NAME"
  echo "  $(basename $0) complete COLLECTION_NAME ITEM_NAME"
  echo "  $(basename $0) delete-item COLLECTION_NAME ITEM_NAME"
  echo "  $(basename $0) list-item COLLECTION_NAME"
  echo "  $(basename $0) rename-item COLLECTION_NAME OLD_ITEM_NAME NEW_ITEM_NAME"
  echo "  $(basename $0) start COLLECTION_NAME ITEM_NAME"
  echo "  $(basename $0) stop COLLECTION_NAME ITEM_NAME"
  echo
}

function collectionList() {
  database_run "SELECT name FROM collection ORDER BY name"
}

function collectionListItem() {

  if [[ "${1}" ]] ; then
    this_collection_name="${1}"
  else
    echo "Error: missing collection name."
    exit 1
  fi

  this_collection_id=$(database_silent "SELECT id FROM collection WHERE name='${this_collection_name}'")
  if [[ ! $this_collection_id ]] ; then
    echo "Error: invalid collection name."
    exit 1
  fi

  database_run "SELECT id, name, state, position FROM collection_item WHERE collection_id=$this_collection_id ORDER BY position"
}

function collectionMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "add")
      shift
      collectionAdd "$@"
      ;;
    "delete")
      shift
      collectionDelete "$1"
      ;;
    "help")
      collectionHelp
      ;;
    "list")
      collectionList
      ;;
    "list-item")
      shift
      collectionListItem "$1"
      ;;
    "rename")
      shift
      collectionRename "$@"
      ;;
    *)
      collectionHelp
      ;;
  esac
}

function collectionRename() {
  this_old_collection_name="$1"
  this_new_collection_name="$2"

  if [[ $this_new_collection_name ]] ; then
    database_run "UPDATE collection SET name='$this_new_collection_name' WHERE name='$this_old_collection_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}
