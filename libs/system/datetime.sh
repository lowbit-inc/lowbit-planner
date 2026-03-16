#!/bin/bash

function datetime_get_current_day() {
  date '+%Y-%m-%d'
}

function datetime_get_current_week() {
  date '+%YW%W'
}

function datetime_get_current_month() {
  date '+%Y-%m'
}

function datetime_get_current_quarter() {
  this_month=$(date +%m)
  case $this_month in
    "01"|"02"|"03")
      this_quarter="1"
      ;;
    "04"|"05"|"06")
      this_quarter="2"
      ;;
    "07"|"08"|"09")
      this_quarter="3"
      ;;
    "10"|"11"|"12")
      this_quarter="4"
      ;;
  esac
  date "+%YQ${this_quarter}"
}

function datetime_get_current_semester() {
  this_month=$(date +%m)
  case $this_month in
    "01"|"02"|"03"|"04"|"05"|"06")
      this_semester="1"
      ;;
    "07"|"08"|"09"|"10"|"11"|"12")
      this_semester="2"
      ;;
  esac
  date "+%YS${this_semester}"
}

function datetime_get_current_year() {
  date '+%Y'
}

function datetime_get_week_from_date() {
  this_date="$1"

  this_year=$(datetime_get_year_from_date $this_date)
  this_week_number=$(date -j -f %Y-%m-%d ${this_date} +%W)

  echo "${this_year}W${this_week_number}"
}

function datetime_get_month_from_date() {
  this_date="$1"

  echo $this_date | cut -d- -f1-2
}

function datetime_get_quarter_from_date() {
  this_date="$1"

  this_year=$(datetime_get_year_from_date $this_date)
  this_month_number=$(echo $this_date | cut -d- -f2)

  case $this_month_number in
    "01"|"02"|"03")
      this_quarter="1"
      ;;
    "04"|"05"|"06")
      this_quarter="2"
      ;;
    "07"|"08"|"09")
      this_quarter="3"
      ;;
    "10"|"11"|"12")
      this_quarter="4"
      ;;
  esac

  echo "${this_year}Q${this_quarter}"
}

function datetime_get_semester_from_date() {
  this_date="$1"

  this_year=$(datetime_get_year_from_date $this_date)
  this_month_number=$(echo $this_date | cut -d- -f2)

  case $this_month_number in
    "01"|"02"|"03"|"04"|"05"|"06")
      this_semester="1"
      ;;
    "07"|"08"|"09"|"10"|"11"|"12")
      this_semester="2"
      ;;
  esac

  echo "${this_year}S${this_semester}"
}

function datetime_get_year_from_date() {
  this_date="$1"

  echo $this_date | cut -d- -f1
}