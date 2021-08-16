<?php

function parseVirtualHosts($file) {
	try{
		$fh = fopen($file, 'r');
		$port = '';
		$obj = new stdClass();
		if($fh)
		while(!feof($fh)) {
			$line = fgets($fh);
			if(!empty($line) && preg_replace('/\s+/', '', $line) ){
				if ( preg_match("/<VirtualHost/i", $line) ) {
					preg_match("/<VirtualHost\s+(.+):(.+)\s*>/i", $line, $results);
					if( !empty($results[1]) && $results[1] == "*" && !empty($results[2]) ) {
						$obj->port = $port = $results[2];
					}
				}
				if((isset($port) && !empty($port)) && !empty($file))$obj->file = $file;

				if ((isset($port) && !empty($port)) && preg_match("/DocumentRoot/i", $line)) {
					preg_match("/DocumentRoot\s+(.+)\s*/i", $line, $results);
					if (isset($results[0]) && !empty($results[1]) ) {
						$values = array_values(array_filter(explode(' ', $results[0])));
						if($values[0] == "DocumentRoot")$obj->documentRoot = trim($values[1]);
					}
				}

				if ((isset($port) && !empty($port)) && preg_match("/ServerName/i", $line)) {
					preg_match("/ServerName\s+(.+)\s*/i", $line, $results);
					if (isset($results[0]) && !empty($results[1]) ) {
						$values = array_values(array_filter(explode(' ', $results[0])));
						if(!empty($values[1]))$obj->serverName = trim($values[1]);
					}
				}

				if((isset($port) && !empty($port)) && preg_match("/ServerAlias/i", $line)) {
					preg_match("/ServerAlias\s+(.+)\s*/i", $line, $results);
					if (isset($results[0]) && !empty($results[1]) ) {
						$values = array_values(array_filter(explode(' ', $results[0])));
						if(!empty($values[1]))$obj->serverAlias = trim($values[1]);
					}
				}
			}
		}
	} catch (\Throwable $e) {
		$e->getMessage();
	} finally {
		if ($fh)fclose($fh);
	}

	return $obj;
}

$path = "/etc/apache2/sites-available/";

$diretorio = dir($path);
$obj = [];

while($vhost_conf = $diretorio->read()){
	$vhosts = parseVirtualHosts($path.$vhost_conf);
	if(!empty($vhosts) && is_object($vhosts) && isset($vhosts->serverName)){
		$obj[] = $vhosts;
	}
}
$diretorio->close();

//echo "<pre>";
//print_r($obj);
//echo "</pre>";

echo json_encode($obj);


?>
