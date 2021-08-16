?php
ini_set('display_errors',1);
ini_set('display_startup_erros',1);
error_reporting(E_ERROR | E_ERROR | E_NOTICE);
?>


 <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" dir="ltr">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    </head>
    <body>


<?php
/**
 * @file Generate an index page which includes a list of any virtual hosts 
 * configured on the local system
 * @author Alister Lewis-Bowen [alister@different.com]
 * ----------------------------------------------------------------------------
 * This software is distributed under the the MIT License.
 * 
 * Copyright (c) 2008 Alister Lewis-Bowen
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * ----------------------------------------------------------------------------
 */

function setVar($server_var,$default=null) {
  return isset($_SERVER[$server_var]) ? $_SERVER[$server_var] : $default;
}

function parseVirtualHosts($file) {
  $fh = fopen($file, 'r') or exit("Unable to read $file");

  $hostname = null;
  $port = '';
  $documentRoot = '';
  $serverName = '';
  $rule = false;
  $object = new stdClass();
  while(!feof($fh)) {
        $line = fgets($fh);
        $obj = new stdClass();

        if(!empty($line) && preg_replace('/\s+/', '', $line) ){
          //echo "-> FILE: $file| LINHA: $line| <br />";

                if ( preg_match("/<VirtualHost/i", $line) ) {
                        preg_match("/<VirtualHost\s+(.+):(.+)\s*>/i", $line, $results);
                        if (empty($hostname) && isset($results[1])) {
                                $hostname = $results[1];
                        }
                        if (empty($port) && isset($results[2])) {
                                $port = $results[2];
                        }

                        $rule = true;
                }

                if (preg_match("/<\/VirtualHost>/i", $line) && $hostname != $_SERVER['HTTP_HOST']) {
                        if (preg_match("/DocumentRoot/i", $line)) {
                                preg_match("/DocumentRoot\s+(.+)\s*/i", $line, $results);
                                if (empty($documentRoot) && isset($results[1])) {
                                        $documentRoot = $results[1];
                                        if(!is_dir($documentRoot))unset($documentRoot);
                                }
                        }

                        $port = '80';
                        $rule = false;
                }


                if ($rule) {
                        //echo "          ~>|RULE: $line| <br />";
                        if (preg_match("/DocumentRoot/i", $line)) {
                                preg_match("/DocumentRoot\s+(.+)\s*/i", $line, $results);
                                if (empty($documentRoot) && isset($results[1])) {
                                        $documentRoot = $results[1];
                                        if(!is_dir($documentRoot))unset($documentRoot);
                                }
                        }
                }

                if (empty($documentRoot) && preg_match("/DocumentRoot/i", $line)) {
                        preg_match("/DocumentRoot\s+(.+)\s*/i", $line, $results);
                        if (isset($_rresults[1])) {
                                $documentRoot = $results[1];
                                if(!is_dir($documentRoot))unset($documentRoot);

                        }
                }

                if (empty($serverName) && preg_match("/ServerName/i", $line)) {
                        preg_match("/ServerName\s+(.+)\s*/i", $line, $results);
                        if (isset($_rresults[2])) {
                                $serverName = $results[2];
                        }
                }

echo "-> FILE: $file | LINHA: $line | HOSTNAME: $hostname | DOCUMENTROOT: $documentRoot | PORT: $port | SERVERNAME: $serverName<br />";
//echo "-> HOSTNAME: $hostname | DOCUMENTROOT: $documentRoot | PORT: $port <br />";
echo "=====================================================> <br />";

                if(isset($obj))$object = $obj;
        }
  }

echo "<pre>";
print_r($object);
echo "</pre>";

  fclose($fh);
  return $object;
}
      
$vhost_conf = setVar('VHOSTINDEXER_VHOST_CONFIG', '/etc/httpd/conf.d/vhost.conf');
$title = setVar('VHOSTINDEXER_TITLE', 'Virtual hosts on '. $_SERVER['HTTP_HOST']);

$path = "/etc/apache2/sites-available/";
$diretorio = dir($path);

echo "Lista de Arquivos do diretório '<strong>".$path."</strong>':<br />";
while($vhost_conf = $diretorio->read()){
        echo "<a href='".$path.$vhost_conf."'>". $vhost_conf ."</a><br />";
        $vhosts = parseVirtualHosts($path.$vhost_conf);
//echo "<pre>";
//      print_r($vhosts);
//echo "</pre>";
}
$diretorio -> close();

?>

</body>
</html>

