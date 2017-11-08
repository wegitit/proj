<?php
# exec with php -f <filespec>.php

$iFILE='composer-setup.php';

$refHash = @file_get_contents('https://composer.github.io/installer.sha384sum');

if ($refHash === false) {
 exit ('Failed to retrieve hash file'.PHP_EOL);
}

$copy = @copy('https://getcomposer.org/installer', $iFILE);

if ($copy === false) {
 exit('Failed to retrieve installer'.PHP_EOL);
}

$genHash = hash_file('SHA384', $iFILE);

if (strpos($refHash, $genHash) !== 0) {
 exit('Installer Corrupt'.PHP_EOL);
}

echo 'Installer Verified'.PHP_EOL;

@exec('php -f '.$iFILE);
@unlink ($iFILE);

echo exec('php composer.phar --version') . PHP_EOL;

