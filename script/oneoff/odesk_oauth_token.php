<?php

require 'oDeskAPI.oauth.php';

$json_content = file_get_contents("/findmjob.com/conf/findmjob_local.json");
$json_data = json_decode($json_content);
$config = $json_data->api->odesk;

$odesk_user = $config->user;
$odesk_pass = $config->pass;
$api_key    = $config->key;
$secret     = $config->secret;

// our app
$api = new oDeskAPI($secret, $api_key);

// setup options
$api->option('amode','headers');
$api->option('mode', 'nonweb'); // obligatory option for non web-based applications
#$api->option('verify_ssl', TRUE); // whether to verify SSL certificate, FALSE by default (supports self-signed certs)
$api->option('cookie_file', '/tmp/odesk.cookies.txt'); // cookie file, used for nonweb apps

$oauth_cred = $api->auth($odesk_user, $odesk_pass);
if (! isset($oauth_cred['token'])) die("BROKEN!");

$out = $oauth_cred['token'] . ':' . $oauth_cred['secret'];
file_put_contents("/findmjob.com/script/oneoff/odesk.token.txt", $out);

echo 'Success!';

?>
