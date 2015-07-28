#!/usr/bin/php
<?php
$shortopts = 'n:h:e:s:l:o:c:a:t:';
$longopts = array('notificationtype:', 'hostname:', 'hostaddress:', 'hoststate:', 'datetime:', 'hostoutput:', 'notificationcomment:', 'notificationauthor:', 'contactalias:');
$options = getopt($shortopts, $longopts);

foreach($options as $k => $v):
	switch($k):
		case 'n':
		case 'notificationtype':
			$notificationtype = $v;
			break;
		case 'h':
		case 'hostname':
			$hostname = $v;
			break;
		case 'e':
		case 'hostaddress':
			$hostaddress = $v;
			break;
		case 's':
		case 'hoststate':
			$hoststate = $v;
			break;
		case 'l':
		case 'datetime':
			$datetime = $v;
			break;
		case 'o':
		case 'hostoutput':
			$hostoutput = $v;
			break;
		case 'c':
		case 'notificationcomment':
			$notificationcomment = $v;
			break;
		case 'a':
		case 'notificationauthor':
			$notificationauthor = $v;
			break;
		case 't':
		case 'contactalias':
			$contactalias = $v;
			break;
	endswitch;
endforeach;

function shortenUrl($longUrl) {
	$api = 'api.isus.cc';
	$token = 'a6e760181471a6d63f478a5a8990b100';
	$longUrl = preg_replace('/ /','+', $longUrl);

	$ch = curl_init();

	$curlopts = array(
		CURLOPT_RETURNTRANSFER => TRUE,
		CURLOPT_CONNECTTIMEOUT => 1,
		CURLOPT_TIMEOUT => 2,
		CURLOPT_URL => sprintf('%s/shorten?token=%s&url=%s', $api, $token, urlencode($longUrl))
	);
	curl_setopt_array($ch, $curlopts);

	$shortUrl = curl_exec($ch);

	curl_close($ch);

	if($shortUrl !== FALSE):
		$shortUrl = json_decode($shortUrl);

		if($shortUrl->status_code == 200):
			return $shortUrl->data->url;
		endif;
	endif;

	return $longUrl;
}

if($notificationcomment && $notificationauthor):
	$additional = <<<EOM
Comment: {$notificationcomment}
Author: {$notificationauthor}
EOM;
else:
	$acknowledgeUrl	= shortenUrl(sprintf('http://i2monitor.salesteamautomation.com/noauth/?cmd=39&host_name=%s&sticky=0&author=%s&comment=Problem acknowledged', $hostname, $contactalias));
	$availableUrl = shortenUrl(sprintf('http://i2monitor.salesteamautomation.com/noauth/?cmd=134&host_name=%s&options=1&author=%s&comment=Available to help', $hostname, $contactalias));
	$unavailableUrl = shortenUrl(sprintf('http://i2monitor.salesteamautomation.com/noauth/?cmd=134&host_name=%s&options=1&author=%s&comment=Currently unavailable', $hostname, $contactalias));
	$helpUrl = shortenUrl(sprintf('http://i2monitor.salesteamautomation.com/noauth/?cmd=134&host_name=%s&options=1&author=%s&comment=Need help', $hostname, $contactalias));

	$additional = <<<EOM
Acknowledge: {$acknowledgeUrl}
Available: {$availableUrl}
Unavailable {$unavailableUrl}
Help: {$helpUrl}
EOM;
endif;

$message = <<<EOM
Notification Type: {$notificationtype}
Host: {$hostname}
Address: {$hostaddress}
State: {$hoststate}
Date/Time: {$datetime}

Info: {$hostoutput}

{$additional}
EOM;

echo $message;
?>
