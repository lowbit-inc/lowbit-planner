#!/bin/bash

function decisionForget() {
  this_collection_id=$1

  database_silent "DELETE FROM collection_item_decision WHERE collection_id = ${this_collection_id}"
  database_silent "UPDATE collection_item SET position = 0 WHERE collection_id = ${this_collection_id}"
}

function decisionGenerateList() {
  this_collection_id=$1

  echo "Generating decisions list..."

  this_item_list=$(database_silent "SELECT id FROM collection_item WHERE collection_id = $this_collection_id;")
  
  # Nested loop for decision-matrix
  for item_id1 in $this_item_list ; do
    for item_id2 in $this_item_list ; do

      # Ignoring equal values
      if [[ $item_id1 -eq $item_id2 ]] ; then
        continue
      fi

      # The lesser number comes first
      if [[ $item_id1 -lt $item_id2 ]] ; then
        this_decision_matrix+="$item_id1,$item_id2 "
        # Debugging
        # echo "${this_decision_matrix}"
      else
        this_decision_matrix+="$item_id2,$item_id1 "
        # Debugging
        # echo "${this_decision_matrix}"
      fi

    done
  done

  # Deduplicating the matrix
  this_decision_matrix_dedup=$(echo $this_decision_matrix | tr ' ' '\n' | sort -u)

  for decision in $this_decision_matrix_dedup; do
    this_item_id1=$(echo $decision | cut -d, -f1)
    this_item_id2=$(echo $decision | cut -d, -f2)
    database_silent "INSERT INTO collection_item_decision (collection_id, collection_item_id1, collection_item_id2) VALUES (${this_collection_id},${this_item_id1},${this_item_id2});" 2>/dev/null
  done

  return 0

}

function decisionMakeChoice() {
  this_collection_id=$1

  # Counting...
  decisions_all=$(database_silent "SELECT COUNT(collection_id) FROM collection_item_decision WHERE collection_id = $this_collection_id;")
  decisions_made=$(database_silent "SELECT COUNT(collection_id) FROM collection_item_decision WHERE collection_id = $this_collection_id AND collection_item_id_choice IS NOT NULL;")
  decisions_pending=$(database_silent "SELECT COUNT(collection_id) FROM collection_item_decision WHERE collection_id = $this_collection_id AND collection_item_id_choice IS NULL;")

  if [[ $decisions_pending -eq 0 ]]; then
    echo "No decisions to be made :)"
    exit 0
  fi

  # Deciding...
  this_decisions=$(database_silent "SELECT collection_item_id1, collection_item_id2 FROM collection_item_decision WHERE collection_id = $this_collection_id AND collection_item_id_choice IS NULL ORDER BY RANDOM();")
  for decision in $this_decisions; do

    # Option IDs
    this_option_1=$(echo $decision | cut -d, -f1)
    this_option_2=$(echo $decision | cut -d, -f2)

    # Option Labels
    this_option_1_label=$(database_silent "SELECT name FROM collection_item WHERE id = $this_option_1" | tr -d \")
    this_option_2_label=$(database_silent "SELECT name FROM collection_item WHERE id = $this_option_2" | tr -d \")

    while [[ true ]] ; do
      clear
      echo "Decisions ( Total:$decisions_all | Made:$decisions_made | Pending:$decisions_pending )"
      echo
      echo "1) $this_option_1_label"
      echo "2) $this_option_2_label"
      echo
      echo "a) abort decision process"
      echo
      echo -n "> "
      read this_choice
      case $this_choice in
        "1")
          this_choice_id=$this_option_1
          break
          ;;
        "2")
          this_choice_id=$this_option_2
          break
          ;;
        "a")
          exit 0
          ;;
      esac
    done

    database_silent "UPDATE collection_item_decision SET collection_item_id_choice = ${this_choice_id} WHERE collection_id = ${this_collection_id} AND collection_item_id1 = ${this_option_1} AND collection_item_id2 = ${this_option_2};"
    database_silent "UPDATE collection_item SET position = position + 1 WHERE id = ${this_choice_id};"

    # Updating the counters
    ((decisions_made++))
    ((decisions_pending--))

  done
}