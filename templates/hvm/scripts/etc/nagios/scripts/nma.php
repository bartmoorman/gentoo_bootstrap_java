#!/usr/bin/php
<?php
require('include/nma.php');

$nma = new NMA();

//$nma->setDeveloperKey('');

$shortopts = 'k:a:e:d:u:t:s:';
$longopts = array('apikey:', 'application:', 'event:', 'description:', 'url:', 'type:', 'severity:');
$options = getopt($shortopts, $longopts);

foreach($options as $k => $v):
	switch($k):
		case 'k':
		case 'apikey':
			$nma->addApiKey($v);
			break;
		case 'a':
		case 'application':
			$nma->setApplication($v);
			break;
		case 'e':
		case 'event':
			$nma->setEvent($v);
			break;
		case 'd':
		case 'description':
			$nma->setDescription($v);
			break;
		case 'u':
		case 'url':
			$nma->setUrl($v);
			break;
		case 't':
		case 'type':
			$type = $v;
			break;
		case 's':
		case 'severity':
			$severity = $v;
			break;
	endswitch;
endforeach;

/**
 *  2   Mission Critical
 *  1   Needs Attention
 *  0   General Notification
 * -1   Recovery
 * -2   Informational
 */
switch($type):
	case 'PROBLEM':
		switch($severity):
			case 'WARNING':
				$nma->setPriority(1);
				break;
			case 'UNKNOWN':
				$nma->setPriority(1);
				break;
			case 'CRITICAL':
				$nma->setPriority(2);
				break;
			case 'DOWN':
				$nma->setPriority(2);
				break;
			case 'UNREACHABLE':
				$nma->setPriority(2);
				break;
			default:
				$nma->setPriority(2);
		endswitch;
		break;
	case 'RECOVERY':
		$nma->setPriority(-1);
		break;
	case 'ACKNOWLEDGEMENT':
		$nma->setPriority(-2);
		break;
	case 'FLAPPINGSTART':
		$nma->setPriority(0);
		break;
	case 'FLAPPINGSTOP':
		$nma->setPriority(0);
		break;
	case 'FLAPPINGDISABLED':
		$nma->setPriority(-2);
		break;
	case 'DOWNTIMESTART':
		$nma->setPriority(0);
		break;
	case 'DOWNTIMESTOP':
		$nma->setPriority(0);
		break;
	case 'DOWNTIMECANCELLED':
		$nma->setPriority(-2);
		break;
	default:
		$nma->setPriority(2);
endswitch;

$nma->send();
?>
