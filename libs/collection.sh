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

function collectionAddItem() {

  if [[ $2 ]] ; then
    this_collection_name="$1"
    this_collection_item_name="$2"
  else
    echo "Error: missing required argument."
    exit 1
  fi

  # Validating collection name
  if [[ ${this_collection_name} ]]; then
    this_collection_id=$(database_silent "SELECT id FROM collection WHERE name='${this_collection_name}'")
    if [[ ! $this_collection_id ]] ; then
      echo "Error: invalid collection name."
      exit 1
    fi
  fi

  database_run "INSERT INTO collection_item (name, collection_id) VALUES ('$this_collection_item_name', '$this_collection_id');"

}

function collectionComplete() {
  if [[ "$1" ]] ; then
    this_collection_item_id="$1"
  else
    echo "Error: missing collection item ID."
    exit 1
  fi

  database_run "UPDATE collection_item SET state = 'Done', completion_date = DATE('now', 'localtime') WHERE id = $this_collection_item_id;"
}

function collectionDecide() {

  # Parsing args
  if [[ $1 ]] ; then
    this_collection_name="$1"
  else
    echo "Error: missing collection name."
    exit 1
  fi

  # Validating collection name
  this_collection_id=$(database_silent "SELECT id FROM collection WHERE name = '${this_collection_name}'")
  if [[ ! "${this_collection_id}" ]] ; then
    echo "Error: invalid collection name."
    exit 1
  fi

  decisionGenerateList $this_collection_id
  decisionMakeChoice $this_collection_id

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

function collectionDeleteItem() {

  if [[ $1 ]] ; then
    this_collection_item_id="$1"
  else
    echo "Error: missing collection item ID."
    exit 1
  fi

  database_run "DELETE FROM collection_item WHERE id = '$this_collection_item_id';"

}

function collectionHelp() {
  echo "${help_banner} - Collections"
  echo
  echo "Collections:"
  echo "  ${help_basename} add COLLECTION_NAME"
  echo "  ${help_basename} decide COLLECTION_NAME"
  echo "  ${help_basename} delete COLLECTION_NAME"
  echo "  ${help_basename} help (this message)"
  echo "  ${help_basename} list"
  echo "  ${help_basename} rename OLD_COLLECTION_NAME NEW_COLLECTION_NAME"
  echo
  echo "Items:"
  echo "  ${help_basename} add-item COLLECTION_NAME ITEM_NAME"
  echo "  ${help_basename} complete ITEM_ID"
  echo "  ${help_basename} delete-item ITEM_ID"
  echo "  ${help_basename} list-item COLLECTION_NAME"
  echo "  ${help_basename} rename-item OLD_ITEM_NAME NEW_ITEM_NAME"
  echo "  ${help_basename} start ITEM_ID"
  echo "  ${help_basename} stop ITEM_ID"
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

  database_run "SELECT id, name, position, completion_date, state FROM collection_item WHERE collection_id=$this_collection_id ORDER BY position DESC;"
}

function collectionMain() {
  usr_command="$1"
  
  case "${usr_command}" in
    "add")
      shift
      collectionAdd "$@"
      ;;
    "add-item")
      shift
      collectionAddItem "$@"
      ;;
    "complete")
      shift
      collectionComplete "$1"
      ;;
    "decide")
      shift
      collectionDecide "$1"
      ;;
    "delete")
      shift
      collectionDelete "$1"
      ;;
    "delete-item")
      shift
      collectionDeleteItem "$1"
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
    "rename-item")
      shift
      collectionRenameItem "$@"
      ;;
    "start")
      shift
      collectionItemStart "$1"
      ;;
    "stop")
      shift
      collectionItemStop "$1"
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

function collectionRenameItem() {
  this_old_collection_item_name="$1"
  this_new_collection_item_name="$2"

  if [[ $this_new_collection_item_name ]] ; then
    database_run "UPDATE collection_item SET name='$this_new_collection_item_name' WHERE name='$this_old_collection_item_name';"
  else
    echo "Error: missing required args."
    exit 1
  fi
}

function collectionItemStart() {
  if [[ "$1" ]] ; then
    this_collection_item_id="$1"
  else
    echo "Error: missing collection item ID."
    exit 1
  fi

  database_run "UPDATE collection_item SET state = 'Started' WHERE id = $this_collection_item_id;"
}

function collectionItemStop() {
  if [[ "$1" ]] ; then
    this_collection_item_id="$1"
  else
    echo "Error: missing collection item ID."
    exit 1
  fi

  database_run "UPDATE collection_item SET state = 'Pending' WHERE id = $this_collection_item_id;"
}
