#!/bin/bash
#
# Filename: scritp.py
# Version: 1.0
# Author: joabe leão - joabe.leao1@gmail.com
#
# Description:
#    Script to clean the recurrent email databases that come with thousands of invalid records.
#    This is a generalist script, take care. The most common case is dabases with id, email and document id.

# binary settings
WHICH="/usr/bin/which"
MYSQL="$(${WHICH} mysql)"

# script args
ARGUMENTS=("$@")

function _help() {

  echo -e "
Usage: $0 --action dbparams

Arguments:
  --select     \t SELECT emails and log results.
  --delete     \t DELETE emails and log results.
  --help       \t Always useful.

    duplicates \t Select or delete duplicated emails and log results.
    invalid    \t Select or delete invalid emails and log results.

    db user
    db password.
    db address.
    mail database name.
    mail table name.
    mail field name

Examples:

    $0 --select duplicates john password 192.168.0.1 maildb mails mail\n
    $0 --delete invalid john password 192.168.0.1 maildb mails mail\n"

}

function _clean_duplicate() {
    # Execute queries to clean duplicated emails based on the unique value of email and document id.
    # Arguments:
    #     Mysql connection variables.

    # locals
    local action="${1}"
    local mysql_user="${2}"
    local mysql_pass="${3}"
    local mysql_host="${4}"
    local mysql_db="${5}"
    local mysql_table="${6}"
    local mysql_field="${7}"

    # queries
    DQUERY[0]="${action} c1 FROM ${mysql_table} c1
INNER JOIN ${mysql_table} c2
WHERE
c1.id > c2.id AND
c1.${mysql_field} = c2.${mysql_field} AND
c1.doc = c2.doc;"

    i=0
    # iterate, execute and log.
    for query in "${DQUERY[@]}"; do
    	"${MYSQL}" -u"${mysql_user}" -p"${mysql_pass}" -h"${mysql_host}" -D"${mysql_db}" -e "${query}" >> /var/log/smdc_duplicate${i}.log
    	((i++))
    done

}

function _clean_invalid() {
    
    # Execute queries to clean invalid emails.
    # Arguments:
    #     Mysql connection variables.

    # locals
    local action="${1}"
    local mysql_user="${2}"
    local mysql_pass="${3}"
    local mysql_host="${4}"
    local mysql_db="${5}"
    local mysql_table="${6}"
    local mysql_field="${7}"
    
    # set * char for deletion

    # queries
    QUERY[0]="${action} FROM ${mysql_table} WHERE ${mysql_field} NOT REGEXP '@';" # occurrencies without @ char;
    QUERY[1]="${action} FROM ${mysql_table} WHERE ${mysql_field} REGEXP '@.+@';" # occurrencies containing two @ char;
    QUERY[3]="${action} FROM ${mysql_table} WHERE ${mysql_field} REGEXP '\\.\\.';" # occurrencies containing two punctuation chars at sequence;
    QUERY[4]="${action} FROM ${mysql_table} WHERE ${mysql_field} NOT REGEXP '^[a-z0-9]+((([\.\_\-]+)?[a-z0-9]+)+)?@[a-z0-9-]+((\.[a-z0-9-]+)+)?\.[a-z]+$'" # general validation;
    
    i=0
    # iterate, execute and log
    for query in "${QUERY[@]}"; do
    	"${MYSQL}" -u"${mysql_user}" -p"${mysql_pass}" -h"${mysql_host}" -D"${mysql_db}" -e "${query}" >> /var/log/smdc_invalid${i}.log
    	((i++))
    done

}

[ "${#ARGUMENTS[*]}" -ne 8 ] && _help && exit

# connection settings
MYSQL_USER="${ARGUMENTS[2]}"
MYSQL_PASS="${ARGUMENTS[3]}"
MYSQL_HOST="${ARGUMENTS[4]}"
MYSQL_DB="${ARGUMENTS[5]}"
MYSQL_TABLE="${ARGUMENTS[6]}"
MYSQL_FIELD="${ARGUMENTS[7]}"

# action type
ACTION=''

case "${ARGUMENTS[0]}" in
    "--select" ) ACTION='SELECT *' ;;
    "--delete" ) ACTION='DELETE' ;;
    "--help"      ) _help; exit  ;;
    *             ) _help; exit  ;;
esac

case "${ARGUMENTS[1]}" in
  "duplicate"   ) _clean_duplicate "${ACTION}"  "${MYSQL_USER}" "${MYSQL_PASS}" "${MYSQL_HOST}" "${MYSQL_DB}" "${MYSQL_TABLE}" "${MYSQL_FIELD}";;
  "invalid"     ) _clean_invalid "${ACTION}" "${MYSQL_USER}" "${MYSQL_PASS}" "${MYSQL_HOST}" "${MYSQL_DB}" "${MYSQL_TABLE}" "${MYSQL_FIELD}";;
  "--help"      ) _help; exit  ;;
  *             ) _help; exit  ;;
esac
