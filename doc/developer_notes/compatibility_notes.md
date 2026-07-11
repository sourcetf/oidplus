
Compatibility notes
===================

Requirements regarding compatibility
------------------------------------

- The minimum required PHP version should be PHP 8.2, at least until the Debian old-old-stable distro has lost its extended support (see below).
- OIDplus should always be compatible with the latest available PHP version
- OIDplus must be compatible with all modern browsers
- Search engines must be able to crawl all public content. This is the reason why a page contains static content (loaded in index.php) for the first navigation, instead of fetching everything through ajax.php.

Regarding the PHP version, we follow the [Debian LTS cycle](https://wiki.debian.org/LTS), so that we have the following constraints:

- PHP 7.1 - 7.3 is allowed after 2022-06-30, because this is the LTS end of Debian "Stretch" (that bundled PHP 7.0)
- PHP 7.4 is allowed after 2024-06-30, because this is the LTS end of Debian "Buster" (that bundled PHP 7.3), [PHP 7.0 to PHP 7.4 see issue 56](https://github.com/danielmarschall/oidplus/issues/56)
- PHP 8.0 - 8.2 is allowed after 2026-08-31, because this is the LTS end of Debian "Bullseye" (that bundled PHP 7.4), [PHP 7.4 to PHP 8.2 see issue 88](https://github.com/danielmarschall/oidplus/issues/88)
- PHP 8.3 - 8.4 is allowed after 2028-06-30, because this is the LTS end of Debian "Bookworm" (that bundled PHP 8.2)
- PHP 8.5+ is allowed after 2030-06-30, because this is the LTS end of Debian "Trixie" (that bundled PHP 8.4)

Note: How to check the effective PHP version in composer?

    composer show --tree

Checklist: New PHP extension
----------------------------

When a new PHP extension is required, then please change the following:

- README file
- OIDplus product website https://oidplus.com/download.php
- Add checks in includes/oidplus_dependency.inc.php

Checklist: New PHP version
--------------------------

If OIDplus requires a new PHP version, then the following things should be changed:

- README.md: Change the minimum required PHP version
- composer.json: Change our own PHP min version
- dev/vendor_update.sh: Change the code regarding "composer config platform.php 8.2.0" (4x) and remove hotfixes to 3p code
- doc/developer_notes/compatibility_notes.md (this document)
- doc/website/download.html (website backup)
- includes/oidplus.inc.php: Change version check
- plugins/viathinksoft/adminPages/900_software_update/private/funcs.inc.php : Change generator to generate a check for the PHP check, to avoid that a system with an old PHP version will get bricked if it updates. The update must cancel if the old PHP version is used.
	* Note that you should define a new "major" version
	* 2.0.2.x was for PHP 7.4
	* 2.0.3.x was for PHP 8.2
- Search for PHP_VERSION comparisons and remove comparisons that will now be always true; but do not accidentally change funcs.inc.php in the software update, the oidplus.inc.php main version check, and do not change vendor code
- Search for the old version to see if there is anything else we need to address
	grep -r "7\.4" | grep -v "cache/" | grep -v "\.log" | grep -v "js:" | grep -v "css:" | cut -d ':' -f 1 | sort | uniq
- Do a check with PHPStan to see if it detects PHP version compatibility issues
- Release a new version with the previously assigned version
- Update webpage: oidplus.com

