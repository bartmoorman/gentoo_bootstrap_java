#!/usr/bin/php
<?php
require('include/prowl.php');

$prowl = new Prowl();

$prowl->setProviderKey('a5e11e84f938bd81b650c60cdcc86dabf707a74f');

$shortopts = 'k:a:e:d:u:t:s:';
$longopts = array('apikey:', 'application:', 'event:', 'description:', 'url:', 'type:', 'severity:');
$options = getopt($shortopts, $longopts);

foreach($options as $k => $v):
	switch($k):
		case 'k':
		case 'apikey':
			$prowl->addApiKey($v);
			break;
		case 'a':
		case 'application':
			$prowl->setApplication($v);
			break;
		case 'e':
		case 'event':
			$prowl->setEvent($v);
			break;
		case 'd':
		case 'description':
			$prowl->setDescription($v);
			break;
		case 'u':
		case 'url':
			$prowl->setUrl($v);
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
				$prowl->setPriority(1);
				break;
			case 'UNKNOWN':
				$prowl->setPriority(1);
				break;
			case 'CRITICAL':
				$prowl->setPriority(2);
				break;
			case 'DOWN':
				$prowl->setPriority(2);
				break;
			case 'UNREACHABLE':
				$prowl->setPriority(2);
				break;
			default:
				$prowl->setPriority(2);
		endswitch;
		break;
	case 'RECOVERY':
		$prowl->setPriority(-1);
		break;
	case 'ACKNOWLEDGEMENT':
		$prowl->setPriority(-2);
		break;
	case 'FLAPPINGSTART':
		$prowl->setPriority(0);
		break;
	case 'FLAPPINGSTOP':
		$prowl->setPriority(0);
		break;
	case 'FLAPPINGDISABLED':
		$prowl->setPriority(-2);
		break;
	case 'DOWNTIMESTART':
		$prowl->setPriority(0);
		break;
	case 'DOWNTIMESTOP':
		$prowl->setPriority(0);
		break;
	case 'DOWNTIMECANCELLED':
		$prowl->setPriority(-2);
		break;
	default:
		$prowl->setPriority(2);
endswitch;

$prowl->send();
?>
