#!/bin/bash

# OIDplus 2.0
# Copyright 2019 - 2025 Daniel Marschall, ViaThinkSoft
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DIR=$( dirname "$0" )

cd "$DIR/.."

# Choose the latest version of composer
if [ ! -f composer.phar ]; then
	wget https://getcomposer.org/download/latest-stable/composer.phar
	chmod +x composer.phar
fi
./composer.phar self-update

# We temporarily move the .svn directory, otherwise
# we cannot checkout fileformats and vnag in the vendor
# directory
if [ -d ".svn" ]; then
	mv .svn _svn
fi

# For some reason, sometimes composer downgrades packages for now reason.
# Clearing the cache helps!
./composer.phar clear-cache

# Remove vendor and composer.lock, so we can download everything again
# (We need to receive everything again, because we had to delete the .git
# .svn files and therefore we cannot do a simple "svn update" delta update anymore)
rm -rf vendor
rm composer.lock

# Download everything again
# Use PHP 8.2, since this is our current minimum version we want to release in the full-build
# (Users who build the sources can use their own platform, of course)
# see also below for 3 more occurrences of "composer update".
./composer.phar config platform.php 8.2.0
./composer.phar update --no-dev
./composer.phar config --unset platform.php

# Remove stuff we don't want to publish or PHP files which could be
# executed (which would be a security risk, because the vendor/ directory
# can be accessed via the web-browser)
remove_vendor_rubbish() {
	shopt -s globstar
	rm -rf $1vendor/**/.svn
	rm -rf $1vendor/**/.git
	rm -rf $1vendor/**/.gitignore
	rm -rf $1vendor/**/.gitattributes
	rm -rf $1vendor/**/.github
	rm -rf $1vendor/**/demo
	rm -rf $1vendor/**/demos
	rm -rf $1vendor/twbs/bootstrap/package*
	rm -rf $1vendor/twbs/bootstrap/*.js
	rm -rf $1vendor/twbs/bootstrap/*.yml
	rm -rf $1vendor/twbs/bootstrap/.* 2>/dev/null
	rm -rf $1vendor/twbs/bootstrap/nuget/
	rm -rf $1vendor/twbs/bootstrap/scss/
	rm -rf $1vendor/twbs/bootstrap/js/
	rm -rf $1vendor/twbs/bootstrap/build/
	rm -rf $1vendor/twbs/bootstrap/site/
	rm -rf $1vendor/google/recaptcha/examples/
	rm -rf $1vendor/**/tests
	rm -rf $1vendor/**/test
	rm $1vendor/**/*.phpt
	rm $1vendor/**/example.php
	rm -rf $1vendor/danielmarschall/vnag/logos
	rm -rf $1vendor/danielmarschall/vnag/doc
	rm -rf $1vendor/danielmarschall/vnag/bin
	rm -rf $1vendor/danielmarschall/vnag/web
	rm -rf $1vendor/danielmarschall/vnag/create_conf_symlinks.phps
	rm -rf $1vendor/danielmarschall/vnag/set_chmod.sh
	rm -rf $1vendor/danielmarschall/vnag/Makefile
	rm -rf $1vendor/danielmarschall/vnag/src/build.phps
	rm -rf $1vendor/danielmarschall/vnag/src/plugins
	rm -rf $1vendor/danielmarschall/uuid_mac_utils/*.php
	rm -rf $1vendor/danielmarschall/uuid_mac_utils/*.sh
	rm -rf $1vendor/danielmarschall/uuid_mac_utils/*.css
	rm -rf $1vendor/danielmarschall/uuid_mac_utils/includes/OidDerConverter.class.php
	rm -rf $1vendor/paragonie/random_compat/other
}
remove_vendor_rubbish ./

# It is important that symlinks are not existing, otherwise the .tar.gz dir
# cannot be correctly extracted in Windows
rm -rf vendor/bin
rm -rf vendor/matthiasmullie/minify/bin

# Remove docker stuff since it might confuse services like synk
rm vendor/matthiasmullie/minify/Dockerfile
rm vendor/matthiasmullie/minify/docker-compose.yml

# Enable SVN again
if [ -d "_svn" ]; then
	mv _svn .svn
fi

./composer.phar license > vendor/licenses

# -------
# Update composer dependencies of plugins
# -------

rm -rf plugins/viathinksoft/publicPages/100_whois/whois/xml/vendor/
./composer.phar config platform.php 8.2.0
./composer.phar update --no-dev -d plugins/viathinksoft/publicPages/100_whois/whois/xml/
./composer.phar config --unset platform.php
./composer.phar license -d plugins/viathinksoft/publicPages/100_whois/whois/xml/ > plugins/viathinksoft/publicPages/100_whois/whois/xml/vendor/licenses
remove_vendor_rubbish plugins/viathinksoft/publicPages/100_whois/whois/xml/

rm -rf plugins/viathinksoft/publicPages/100_whois/whois/json/vendor/
./composer.phar config platform.php 8.2.0
./composer.phar update --no-dev -d plugins/viathinksoft/publicPages/100_whois/whois/json/
./composer.phar config --unset platform.php
./composer.phar license -d plugins/viathinksoft/publicPages/100_whois/whois/json/ > plugins/viathinksoft/publicPages/100_whois/whois/json/vendor/licenses
remove_vendor_rubbish plugins/viathinksoft/publicPages/100_whois/whois/json/

rm -rf plugins/viathinksoft/publicPages/002_rest_api/vendor/
./composer.phar config platform.php 8.2.0
./composer.phar update --no-dev -d plugins/viathinksoft/publicPages/002_rest_api/
./composer.phar config --unset platform.php
./composer.phar license -d plugins/viathinksoft/publicPages/002_rest_api/ > plugins/viathinksoft/publicPages/002_rest_api/vendor/licenses
rm -rf plugins/viathinksoft/publicPages/002_rest_api/swagger-ui
mv plugins/viathinksoft/publicPages/002_rest_api/vendor/swagger-api/swagger-ui/dist plugins/viathinksoft/publicPages/002_rest_api/swagger-ui
mv plugins/viathinksoft/publicPages/002_rest_api/vendor/licenses plugins/viathinksoft/publicPages/002_rest_api/swagger-ui/
rm plugins/viathinksoft/publicPages/002_rest_api/swagger-ui/*.map
rm -rf plugins/viathinksoft/publicPages/002_rest_api/vendor
sed -i 's@url: "https:\/\/petstore\.swagger\.io\/v2\/swagger\.json",@url: new URL(window\.location\.origin+window\.location\.pathname+"\.\.\/openapi_json\.php")\.href,@g' plugins/viathinksoft/publicPages/002_rest_api/swagger-ui/swagger-initializer.js

# Get latest version of WEID converter
curl https://raw.githubusercontent.com/WEID-Consortium/weid.info/gh-pages/WeidOidConverter.js > plugins/viathinksoft/objectTypes/oid/WeidOidConverter.js
curl https://raw.githubusercontent.com/WEID-Consortium/weid.info/gh-pages/WeidOidConverter.php > plugins/viathinksoft/objectTypes/oid/WeidOidConverter.class.php
sed -i 's@namespace Frdl\\Weid;@namespace ViaThinkSoft\\OIDplus\\Plugins\\ObjectTypes\\OID;@g' plugins/viathinksoft/objectTypes/oid/WeidOidConverter.class.php
sed -i 's@\\Frdl\\Weid\\WeidOidConverter::@WeidOidConverter::@g' plugins/viathinksoft/objectTypes/oid/WeidOidConverter.class.php

# --- Various hotfixes ---

# !!! Great tool for escaping these hotfixes: https://dwaves.de/tools/escape/ !!!
# Then insert into   sed -i 's@...@...@g' filename

# Apply hotfix: https://github.com/aywan/php-json-canonicalization/issues/1
# (Still not fixed!)
sed -i 's@\$formatted = rtrim(\$formatted, \x27\.0\x27);@\$formatted = rtrim(\$formatted, \x270\x27);\$formatted = rtrim(\$formatted, \x27\.\x27); \/\/Hotfix: https:\/\/github\.com\/aywan\/php-json-canonicalization\/issues\/1@g' plugins/viathinksoft/publicPages/100_whois/whois/json/vendor/aywan/php-json-canonicalization/src/Utils.php
sed -i 's@\$parts\[0\] = rtrim(\$parts\[0\], \x27\.0\x27);@\$parts\[0\] = rtrim(\$parts\[0\], \x270\x27);\$parts\[0\] = rtrim(\$parts\[0\], \x27\.\x27); \/\/Hotfix: https:\/\/github\.com\/aywan\/php-json-canonicalization\/issues\/1@g' plugins/viathinksoft/publicPages/100_whois/whois/json/vendor/aywan/php-json-canonicalization/src/Utils.php

# Fix symfony/polyfill-mbstring to make it compatible with PHP 8.2
# The author does know about the problem (I have opened a GitHub issue), but they did not sync it from the symfony main repo (as polyfill-mbstring is just a fraction of it, for composer)
# see https://github.com/symfony/polyfill-mbstring/pull/11
### FIXED IN https://github.com/symfony/polyfill-mbstring/commit/d1f7f1a4c86c2ca7d9bba3c7e5e8ae3e1a268c1a

# Fix https://github.com/firebase/php-jwt/pull/572 (also for older PHP 7.4 versions of the lib)
### FIXED IN https://github.com/googleapis/php-jwt/commit/76808fa227f3811aa5cdb3bf81233714b799a5b5

# Fix https://github.com/SergeyBrook/php-jws/pull/3 (also for older PHP 7.4 versions of the lib)
### FIXED IN https://github.com/SergeyBrook/php-jws/commit/2570011014deae26e85a49f6c7042fc490bb1246

# Minify JS which have not been minified by the vendor
chmod +x dev/minify_js.sh
dev/minify_js.sh vendor/spamspan/spamspan/spamspan.js > vendor/spamspan/spamspan/spamspan.min.js
dev/minify_js.sh vendor/emn178/js-sha3/src/sha3.js > vendor/emn178/js-sha3/src/sha3.min.js
dev/minify_js.sh vendor/script47/bs5-utils/dist/js/Bs5Utils.js > vendor/script47/bs5-utils/dist/js/Bs5Utils.min.js

# oid-base.com sets short-lived constraints on 1.3.6.1.4.1, but since OIDplus does not update its vendor files too often
# new PEN users might fall in that constraint. Lower the constraint for OIDplus users by setting it to 1.3.6.1.4.1.(999999+) as illegal.
perl -pe '
if (/1\.3\.6\.1\.4\.1\.\((\d+)\+\)(.*?)<code>(\d+)<\/code>/) {
    if ($3 == $1 - 1) {
        s/1\.3\.6\.1\.4\.1\.\(\d+\+\)/1.3.6.1.4.1.(999999+)/;
        s/<code>\d+<\/code>/<code>999998<\/code>/;
    }
}
' vendor/danielmarschall/oidinfo_api/oid_illegality_rules \
> vendor/danielmarschall/oidinfo_api/oid_illegality_rules.new
rm vendor/danielmarschall/oidinfo_api/oid_illegality_rules
mv vendor/danielmarschall/oidinfo_api/oid_illegality_rules.new vendor/danielmarschall/oidinfo_api/oid_illegality_rules
