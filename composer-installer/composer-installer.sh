#!/bin/bash

# This file contains the install commands at:
#  https://getcomposer.org/download/
#
# To use the script across releases, replace the hardcoded hash with a downloaded one from:
#  https://composer.github.io/installer.sha384sum
#
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "copy('https://composer.github.io/installer.sha384sum', 'composer-setup.sha384sum');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

