# Search Result Extension for Request Tracker

#### Table of Contents

1. [About](#about)
2. [License](#license)
3. [Support](#support)
4. [Requirements](#requirements)
5. [Installation](#installation)
6. [Configuration](#configuration)

## About

Allows to highlight search result rows matching defined conditions:

* CF name matches value

The rows can be highlighted with

* Transparent background color
* Icon as an additional column from the extended search editor.

![Screenshot](doc/images/rt_searchresult_highlight_on_cf_condition_icon_bgcolor.png)

## License

This project is licensed under the terms of the GNU General Public License Version 2.

This software is Copyright (c) 2018 by NETWAYS GmbH <[support@netways.de](mailto:support@netways.de)>.

## Support

For bugs and feature requests please head over to our [issue tracker](https://github.com/NETWAYS/rt-extension-searchresult/issues).
You may also send us an email to [support@netways.de](mailto:support@netways.de) for general questions or to get technical support.

## Requirements

- RT 4.4.3

## Installation

Extract this extension to a temporary location.

Git clone:

```
cd /usr/local/src
git clone https://github.com/NETWAYS/rt-extension-searchresult
```

Tarball download (latest [release](https://github.com/NETWAYS/rt-extension-searchresult/releases/latest)):

```
cd /usr/local/src
wget https://github.com/NETWAYS/rt-extension-searchresult/archive/master.zip
unzip master.zip
```

Navigate into the source directory and install the extension.

```
perl Makefile.PL
make
make install
```

Clear your mason cache.

```
rm -rf /opt/rt4/var/mason_data/obj
```

Restart your web server.

```
systemctl restart httpd

systemctl restart apache2
```

## Configuration

### Highlight on CF Condition

You can define multiple highlights at once. Each configuration entry
requires

Key           | Description
--------------|----------------
`conditions`  | **Required.** One or multiple key-value pairs in the format `CF_name => CF_expected_value`.
`color`       | **Optional.** Background color for the highlighted search result line. Supported colors are: `red`, `green`, `blue`, `yellow`, `purple`, `grey`.
`icon`        | **Optional.** FontAwesome icon available as additional column in search results, when the condition matches.

#### Example

```perl
Set($SearchResult_HighlightOnCFCondition,
[
{
  "conditions" => { "TicketReceived" => "yes" },
  "color" => "green",
  "icon" => "fa-check"
},
{
  "conditions" => { "TicketBought" => "yes" },
  "color" => "red",
  "icon" => "fa-pause"
}
]
);
```

### Highlight On Last Updated By Condition

```perl
Set($SearchResult_HighlightOnLastUpdatedByCondition,
[
{
  "conditions" => { "owner" => 1 },
  "color" => "blue",
  "icon" => "fa-star"
}
]
);
```

### Font Awesome Icons

[Font Awesome](https://fontawesome.com) 4.0 SVG icon set is
included, you can use for example:

* fa-envelope
* fa-comment
* fa-share
* fa-folder-open
* fa-check
* fa-ban
* fa-trash-alt
* fa-star
* fa-sync-alt
* fa-pause
* fa-copy
* fa-check-circle
* fa-pause-circle
* fa-user-secret
* fa-recycle
* fa-cloud-upload-alt



### Status Background Color

```perl
Set($SearchResult_StatusBackgroundColor, 1);
```

### Example

```perl
```
