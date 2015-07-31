<?php
$name_options = array('options' => array('regexp' => '/^[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?$/'));
$domain_options = array('options' => array('regexp' => '/^(?!.{256})(?:[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?\.)+(?:[A-Za-z]{2,3})$/'));
$alias_options = array('options' => array('regexp' => '/^(?!.{256})(?:[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?\.)+(?:[A-Za-z]{2,3})$/'));
$address_options = array('flags' => FILTER_FLAG_IPV4);
$priority_options = array('options' => array('default' => 5, 'min_range' = 0, 'max_range' => 10));
$ttl_options = array('options' => array('default' => 3600, 'min_range' => 60, 'max_range' => 86400));

$type = $_REQUEST['type'];
$name = filter_var($_REQUEST['name'], FILTER_VALIDATE_REGEXP, $name_options);
$domain = filter_var($_REQUEST['domain'], FILTER_VALIDATE_REGEXP, $domain_options);
$alias = filter_var($_REQUEST['alias'], FILTER_VALIDATE_REGEXP, $alias_options);
$address = filter_var($_REQUEST['address'], FILTER_VALIDATE_IP, $address_options);
$priority = filter_var($_REQUEST['priority'], FILTER_VALIDATE_INT, $priority_options);
$ttl = filter_var($_REQUEST['ttl'], FILTER_VALIDATE_INT, $ttl_options);

function bad_request() {
	header('HTTP/1.0 400 Bad Request');
	exit;
}

switch ($type) {
	case SOA:
		if (!$domain || !$address || !$name || !$ttl) bad_request();
		$fmt = '.%s:%s:%s:%u:%u:%s';
		printf($fmt . PHP_EOL, $domain, $address, $name, $ttl, '', '');
		break;
	case NS:
		if (!$domain || !$address || !$name || !$ttl) bad_request();
		$fmt = '&%s:%s:%s:%u:%u:%s';
		printf($fmt . PHP_EOL, $domain, $address, $name, $ttl, '', '');
		break;
	case PTR:
		if (!$name || !$domain || !$address || !$ttl) bad_request();
		$fmt = '=%s.%s:%s:%u:%u:%s';
		printf($fmt . PHP_EOL, $name, $domain, $address, $ttl, '', '');
		break;
	case A:
		if (!$name || !$domain || !$address || !$ttl) bad_request();
		$fmt = '+%s.%s:%s:%u:%u:%s';
		printf($fmt . PHP_EOL, $name, $domain, $address, $ttl, '', '');
		break;
	case MX:
		if (!$domain || !$address || !$name || !$priority || !$ttl) bad_request();
		$fmt = '@%s:%s:%s:%u:%u:%u:%s';
		printf($fmt . PHP_EOL, $domain, $address, $name, $priority, $ttl, '', '');
		break;
	case CNAME:
		if (!$name || !$domain || !$alias || !$ttl) bad_request();
		$fmt = 'C%s.%s:%s:%u:%u:%s';
		printf($fmt . PHP_EOL, $name, $domain, $alias, $ttl, '', '');
		break;
	default:
		bad_request();
}
?>
