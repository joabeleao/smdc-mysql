# smdc-mysql
Simple Mail Database Cleanner

## Description:
Script to clean the recurrent email databases that come with thousands of invalid records.
This is a generalist script, take care. The most common case is dabases with id, email and document id.


### Requirements for a valid email

According to the rfc 3696 ``https://datatracker.ietf.org/doc/html/rfc3696#page-5```:

>Contemporary email addresses consist of a "local part" separated from
   a "domain part" (a fully-qualified domain name) by an at-sign ("@").
>
> ...
>
> Without quotes, local-parts may consist of any combination of
>   alphabetic characters, digits, or any of the special characters
>
>      ! # $ % & ' * + - / = ?  ^ _ ` . { | } ~
>
>   period (".") may also appear, but may not be used to start or end the
>   local part, nor may two or more consecutive periods appear.  Stated
>   differently, any ASCII graphic (printing) character other than the
>   at-sign ("@"), backslash, double quote, comma, or square brackets may
>   appear without quoting.  If any of that list of excluded characters
>   are to appear, they must be quoted.
>
> ...
>
> In addition to restrictions on syntax, there is a length limit on
>   email addresses.  That limit is a maximum of 64 characters (octets)
>   in the "local part" (before the "@") and a maximum of 255 characters
>   (octets) in the domain part (after the "@") for a total length of 320
>   characters.  Systems that handle email should be prepared to process
>   addresses which are that long, even though they are rarely
>   encountered.


Despite rfc, each email provider have its own restrictions while creating a new email username (local part).
By this, the validation will be divided between rcf (3696) and modern (mail providers).

After testing email creation on different providers like google, microsoft, proton, terra, bol and checking its documentation, 
the most common criteria found was:

- Emails must start with only letters or numbers.
- Emails must contain letters ( or letters and numbers) with or without special chars followd by
letters or numbers, then followed by @ char and a domain (or domain + subdomain) plus a TLD.
- Emails can only contain the following special charachters: - _ . (dash, underline and dot).
- Emails can only have two special chars in sequence if the next one is not a dot.
- Emais can only have one @ char.


## Abstraction for script validation:

There will be always a tradeoff to be considered since a good portion of invalid emails are caused by misspelled punctuation. Which, depending on the precision level, could be fixed instead of purged if better analyzed.
Another consideration is the ratio of valid/invalid emails depending on each email provider.
Since each provider have its own policies and the validation here are based on the least restrictive police tested,
some emails categorized as valid could not work for some providers.
Also, not all providers were included on the tests.

Bellow, the queries used to find invalid emails on database:

### General validation:

occurrencies without any @:

```select email FROM emails WHERE email NOT REGEXP '@';"```

occurrencies with double @:

```select email FROM emails WHERE email REGEXP '@.+@';```

### RFC 3696:

occurrencies with wrong punctuation sequence:

```select email FROM emails WHERE email REGEXP '((^\.)|(\.\.)|(\.@)|(@[[:punct:]]))';```

general validation:

```select email FROM emails WHERE email NOT REGEXP ''^[a-z0-9!#$%&\*+-/=?^_\`.{|}~]+@[a-z0-9!#$%&\*+-/=?^_\`.{|}~]+$';```

### Modern providers:

occurrencies that not start with letters or numbers:

```select email FROM emails WHERE email NOT REGEXP '^[a-z-0-9]';```

occurrencies with double punct befor @ char:

```select email FROM emails WHERE email REGEXP '^.*[[:punct:]]{2,}.*@.*$';```

at domain, optional subdomain and TLD:

```select email FROM emails WHERE email NOT REGEXP '@[a-z0-9-]+((\.[a-z0-9-]+)+)?\.[a-z0-9-]+$';```

Complete regex for modern validation:

``` ^[a-z0-9]+((([\.\_\-]+)?[a-z0-9]+)+)?@[a-z0-9-]+((\.[a-z0-9-]+)+)?\.[a-z0-9-]+$ ```

## Usage:

``` smdc-mysql --type parameter criteria ```

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

    smdc-mysql --list /var/emailist rfc\n
    smdc-mysql --database select modern \n"

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
