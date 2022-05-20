# smdc-mysql
Simple Mail Database Cleanner

## Description:
Script to clean the recurrent email databases that come with thousands of invalid records.
This is a generalist script, take care. The most common case is dabases with id, email and document id.


### Requirements for a valid email

According to the rfc 3639 ```https://datatracker.ietf.org/doc/html/rfc3696#page-5```:

>Contemporary email addresses consist of a "local part" separated from
   a "domain part" (a fully-qualified domain name) by an at-sign ("@").
>
> ...
>
> Without quotes, local-parts may consist of any combination of
   alphabetic characters, digits, or any of the special characters
>
>      ! # $ % & ' * + - / = ?  ^ _ ` . { | } ~

Despite rfc, each email provider have its own restrictions while creating a new email username (local part).

After testing email creation on different providers like google, microsoft, proton, terra, bol and checking its documentation, 
the most common criteria found was:

- Emails must start with only letters or numbers.
- Emails must contain letters ( or letters and numbers) with or without special chars followd by
letters or numbers, then followed by @ char and a domain (or domain + subdomain) plus a TLD.
- Emails can only contain the following special charachters: - _ . (dash, underline and dot).
- Emails can only have two special chars in sequence if the next one is not a dot.
- Emais can only have one @ char.


### Abstraction for validation:

There will be always a tradeoff to be considered since a good portion of invalid emails are caused by misspelled punctuation. Which, depending on the precision level, could be fixed instead of purged if better analyzed.

Queries using regex to find:

**occurrencies that not start with letters or numbers:**

```select email FROM emails WHERE email NOT REGEXP '^[a-z-0-9]';```

**occurrencies without any @:**

```select email FROM emails WHERE email NOT REGEXP '@';"```

**occurrencies with double @:**

```select email FROM emails WHERE email REGEXP '@.+@';```

**occurrencies with two dots in sequence:**

```select email FROM emails WHERE email REGEXP '\\.\\.';```

**punctuation before \@ char:**

```select email FROM emails WHERE email REGEXP '[[:punct:]]@';```

**invalid characters:**

```select email FROM emails WHERE email NOT REGEXP '[a-z0-9\.-\_@]+';```

**at domain, optional subdomain and TLD:**

```select email FROM emails WHERE email NOT REGEXP '@[a-z0-9-]+((\.[a-z0-9-]+)+)?\.[a-z]+$';```

**Regex for general validation:**

``` ^[a-z0-9]+((([\.\_\-]+)?[a-z0-9]+)+)?@[a-z0-9-]+((\.[a-z0-9-]+)+)?\.[a-z]+$ ```

## Usage:

``` smdc-mysql --action dbparams ```

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

    smdc-mysql --select duplicates john password 192.168.0.1 maildb mails email\n
    smdc-mysql --delete invalid john password 192.168.0.1 maildb mails email\n"


## Caveats

Numbers and dash charachters are now allowed for Top level domains names, but with restriction of being a punycode.

As stated in ```https://tools.ietf.org/id/draft-liman-tld-names-01.html#rfc.section.3```:

> The precise syntax allowed in top-level domain (TLD) name labels has been the subject to some debate. RFC 1123 [RFC1123], for example, states that TLD names must be "alphabetic", which is interpreted as excluding the hyphen (or dash) character. This document updates the definition of allowable top-level domain names to support internationalized domain names that consist of Unicode letters, as encoded by the IDNA protocols [RFCXXX]. In particular, this document clarifies that ASCII TLDs beginning with the IDN A-label prefix (currently "xn--"), as encoded by IDNA, are permissible as DNS TLD names as long as they are made from Unicode letters. This document focuses narrowly on the issue of allowable ASCII labels encoded by the IDNA protocols and does not (and is not intended to) make any other changes or clarifications to existing domain name syntax rules.

- https://tools.ietf.org/id/draft-liman-tld-names-01.html#rfc.section.3
- https://data.iana.org/TLD/tlds-alpha-by-domain.txt
- https://www.swcs.com.au/tld.htm
- https://uasg.tech/wp-content/uploads/2018/02/UASG019B-Email-Address-Internationalization-A-technical-perspective.pdf

## RFC References:

- RFC 3696: https://tools.ietf.org/html/rfc3696
- RFC 5321: https://tools.ietf.org/html/rfc5321
- RFC 5322: https://tools.ietf.org/html/rfc5322
- RFC 6530: https://tools.ietf.org/html/rfc6530
- RFC 6854: https://tools.ietf.org/html/rfc6854
- RFC 1123: https://tools.ietf.org/html/rfc1123
- RFC 5322: https://tools.ietf.org/html/rfc5322
