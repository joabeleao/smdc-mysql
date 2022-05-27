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
# list of valid top level domain by iana.org
VALIDTLD=("$(curl -s https://data.iana.org/TLD/tlds-alpha-by-domain.txt)")

# connection settings
MYSQL_USER=''
MYSQL_PASS=''
MYSQL_HOST=''
MYSQL_DB=''
MYSQL_PORT=''
MYSQL_TABLE=''
MYSQL_FIELD=''

function _help() {

  echo -e "
Usage: $0 --type -parameter -criteria

type:
    --list       \t analyse emails in list and log results.
    --database   \t query emails in database and log results.

Parameteres:
    filepath     \t path of the email list.
    action       \t Select or delete action to query database.

criteria:
    rfc          \t filter and log invalid/valid emails according to rfc 3639.
    modern       \t filter and log invalid/valid emails according to modern email providers.

Examples:

    $0 --list /var/emailist rfc\n
    $0 --database select modern \n"

}

function _test_list() {
    #
    # Find invalid and valid emails according to selected criteria.
    # Arguments:
    #    $1: path to emails list.
    #    $2: criteria

    # locals
    local list="${1}"
    local criteria="${2}"

    # queries
    for line in $(cat "${list}"); do # the while command was not elegible due to work different with continue comand
        # missing @ character. - any provider
        # double @ character. - any provider
        # invalid top level domain according to iana's tld official list. - any provider
        echo "${line}" | grep -Eiv '.*@.*' >> /var/log/smdc-mysql_invalid && continue
        echo "${line}" | grep -Ei '.*@.*@.' >> /var/log/smdc-mysql_invalid && continue
        [[ "${VALIDTLD[@]}" =~ "$(echo $line | grep -Eio "\.[^\.]*$" | grep -Eio "[^\.]*" | tr "a-z" "A-Z")" ]] && echo "${line}" >> /var/log/smdc-mysql_invalid && continue

        if [ "${criteria}" == 'rfc' ]; then
            # not a valid ( ! # $ % & ' * + - / = ?  ^ _ ` . { | } ~ ) characters. - rfc 3639
            # period at beginning; double period; before or after @ character. - rfc 3639
            echo "${line}" | grep -Eiv '^[a-z0-9!#$%&\*+-/=?^_`.{|}~]+@[a-z0-9!#$%&\*+-/=?^_`.{|}~]+$' >> /var/log/smdc-mysql_invalid-rfc3639 && continue
            echo "${line}" | grep -E '((^\.)|(\.\.)|(\.@)|(@[[:punct:]]))' >> /var/log/smdc-mysql_invalid-rfc3639 && continue
            echo "${line}" >> /var/log/smdc-mysql_valid-rfc3639
        elif [ "${criteria}" == 'modern' ]; then
            # double punct before @ char (not necessary after due to following regex) - modern providers
            # general validation:
            #   followed by @ and domains
            #   starting with alfanum chars divided or not by . - _ chars
            #   no punctuation before or after @ character.
            #   optional subdomain followed by domain and top level domain
            echo "${line}" | grep -Ei "^.*[[:punct:]]{2,}.*@.*$" >> /var/log/smdc-mysql_invalid-modern && continue 
            echo "${line}" | grep -Eiv "^[a-z0-9]+((([\.\_\-]+)?[a-z0-9]+)+)?@[a-z0-9-]+((\.[a-z0-9-]+)+)?\.[a-z0-9-]+$" >> /var/log/smdc-mysql_invalid-modern && continue
            echo "${line}" >> /var/log/smdc-mysql_valid-modern
        else
            _help
        fi

    done

}

function _test_database() {
    #
    # Execute queries to query invalid emails according to selected criteria.
    # Arguments:
    #     $1: select or delete.
    #     $2: criteria

    # locals
    local action="${1}"
    local criteria="${2}"

    # queries
    QUERY[0]="${action} FROM ${MYSQL_TABLE} WHERE ${MYSQL_FIELD} NOT REGEXP '@';" # occurrencies without @ char;
    QUERY[1]="${action} FROM ${MYSQL_TABLE} WHERE ${MYSQL_FIELD} REGEXP '@.+@';" # occurrencies containing two @ char;

    if [ "${criteria}" == 'rfc' ]; then
        QUERY[2]="${action} FROM ${MYSQL_TABLE} WHERE ${MYSQL_FIELD} REGEXP '((^\.)|(\.\.)|(\.@)|(@[[:punct:]]))';" # occurrencies containing wrong punctuation sequence;
        QUERY[3]="${action} FROM ${MYSQL_TABLE} WHERE ${MYSQL_FIELD} NOT REGEXP '^[a-z0-9!#$%&\*+-/=?^_\`.{|}~]+@[a-z0-9!#$%&\*+-/=?^_\`.{|}~]+$';" # general validation;
    elif [ "${criteria}" == 'modern' ]; then
        QUERY[2]="${action} FROM ${MYSQL_TABLE} WHERE ${MYSQL_FIELD} REGEXP '^.*[[:punct:]]{2,}.*@.*$';" # double punct before @ char (not necessary after due to regex bellow);
        QUERY[3]="${action} FROM ${MYSQL_TABLE} WHERE ${MYSQL_FIELD} NOT REGEXP '^[a-z0-9]+((([\.\_\-]+)?[a-z0-9]+)+)?@[a-z0-9-]+((\.[a-z0-9-]+)+)?\.[a-z0-9-]+$';" # general validation;
    else
        _help
    fi

    # iterate, execute and log
    for query in "${QUERY[@]}"; do
    	"${MYSQL}" -u"${MYSQL_USER}" -p"${MYSQL_PASS}" -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" -D"${MYSQL_DB}" -vv -e "${query}" >> /var/log/smdc_invalid.log
    done

}

# action type
ACTION=''

# argument validation
[ "${#ARGUMENTS[*]}" -ne 3 ] && _help && exit
[ "${ARGUMENTS[2]}" != "rfc" ] && [ "${ARGUMENTS[2]}" != "modern" ] && _help && exit

# execution
if [ "${ARGUMENTS[0]}" == "--list" ]; then
    _test_list "${ARGUMENTS[1]}" "${ARGUMENTS[2]}"
elif [ "${ARGUMENTS[0]}" == "--database" ] && [ "${ARGUMENTS[1]}" == "select" ]; then
    _test_database 'SELECT *' "${ARGUMENTS[2]}"
elif [ "${ARGUMENTS[0]}" == "--database" ] && [ "${ARGUMENTS[1]}" == "delete" ]; then
    _test_database 'DELETE' "${ARGUMENTS[2]}"
else
    _help; exit;
fi
