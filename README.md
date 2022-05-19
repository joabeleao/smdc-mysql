# smdc-mysql
Simple Mail Database Cleanner

## Description:
Script to clean the recurrent email databases that come with thousands of invalid records.
This is a generalist script, take care. The most common case is dabases with id, email and document id.


### Requirements for a valid email
- Emails must contain letters ( or letters and numbers) with or without special chars followd by /
letters or numbers, then followed by @ char and a domain (or domain + subdomain) plus a TLD.
- Emails must always start with letters.
- Emails can only contain the following special charachters: - _ . (dash, underline and dot).
- Emails can not have two special chars in sequence.
- Emais can only have one @ char.

### Abstraction for general validation:

occurrencies that not start with letters:
```select email FROM emails WHERE email NOT REGEXP '^[a-z]';```

occurrencies without any @:
```select email FROM emails WHERE email NOT REGEXP '.*@.*';"```

occurrencies with double @:
```select email FROM emails WHERE email REGEXP '.*@.*@';```

occurrencies with two punctuations at sequence:
```select email FROM emails WHERE email REGEXP '.*[[:punct:]]{2,}.*';```

punctuation before \@ char:
```select email FROM emails WHERE email REGEXP '[[:punct:]]@';```

invalid characters:
```select email FROM emails WHERE email NOT REGEXP '[a-z0-9\._-_@]+';```

at domain, optional subdomain and TLD:
```select email FROM emails WHERE email NOT REGEXP '@[a-z0-9]+\.[a-z]+(\.[a-z]+)?';```

Regex for general validation:
``` ^[a-z]+((([0-9]+)?(([\.\_\-]+)?[a-z0-9]+)+)+)?@[a-z0-9]+\.[a-z]+(\.[a-z]+)? ```

## Usage:

smdc-mysql --action dbparams

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

Examples:

    smdc-mysql --select duplicates john password 192.168.0.1 maildb mails\n
    smdc-mysql --delete invalid john password 192.168.0.1 maildb mails\n"
