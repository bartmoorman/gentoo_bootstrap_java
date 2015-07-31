<?php
// Setup options for validation
$name_options = array('options' => array('regexp' => '/^[A-z0-9](?:[A-z0-9\-]{0,61}[A-z0-9])?$/'));
$domain_options = array('options' => array('regexp' => '/^(?!.{256})(?:[A-z0-9](?:[A-z0-9\-]{0,61}[A-z0-9])?\.)+(?:[A-z]{2,3})$/'));
$alias_options = array('options' => array('regexp' => '/^(?!.{256})(?:[A-z0-9](?:[A-z0-9\-]{0,61}[A-z0-9])?\.)+(?:[A-z]{2,3})$/'));
$address_options = array('flags' => FILTER_FLAG_IPV4);
$priority_options = array('options' => array('default' => 5, 'min_range' => 0, 'max_range' => 10));
$ttl_options = array('options' => array('default' => 3600, 'min_range' => 60, 'max_range' => 86400));

// Validate arguments
$type = $_REQUEST['type']; // The switch() block below should be enough validation
$name = filter_var($_REQUEST['name'], FILTER_VALIDATE_REGEXP, $name_options);
$domain = filter_var($_REQUEST['domain'], FILTER_VALIDATE_REGEXP, $domain_options);
$alias = filter_var($_REQUEST['alias'], FILTER_VALIDATE_REGEXP, $alias_options);
$address = filter_var($_REQUEST['address'], FILTER_VALIDATE_IP, $address_options);
$priority = filter_var($_REQUEST['priority'], FILTER_VALIDATE_INT, $priority_options);
$ttl = filter_var($_REQUEST['ttl'], FILTER_VALIDATE_INT, $ttl_options);

// Inform the user something went wrong
function bad_request($args = array()) {
	header('HTTP/1.0 400 Bad Request');
	print_r($args);
	exit;
}

// Check for required arguments
function check_args($args = array()) {
	foreach ($args as $arg) {
		if (!$arg) return false;
	}
	return true;
}

// Get data file
function read_data() {
}

// Check if record exists
function check_name() {
}

// Update a record
function update_name() {
}

// Insert a record
function insert_name() {
}

// Delete a record
function remove_record() {
}

// Backup data file
function backup_data() {
}

// Write data file
function write_data() {
}

// Make
function commit() {
}

// Determine which type of record we need to update/create
switch ($type) {
	// Create NS, A, and SOA
	case SOA:
		$args = array('domain' => $domain, 'address' => $address, 'name' => $name, 'ttl' => $ttl);
		if (!check_args($args)) bad_request($args);
		$fmt = '.%s:%s:%s:%u::%s';
		printf($fmt . PHP_EOL, $args['domain'], $args['address'], $args['name'], $args['ttl'], '');
		break;
	// Create NS and A
	case NS:
		$args = array('domain' => $domain, 'address' => $address, 'name' => $name, 'ttl' => $ttl);
		if (!check_args($args)) bad_request($args);
		$fmt = '&%s:%s:%s:%u::%s';
		printf($fmt . PHP_EOL, $args['domain'], $args['address'], $args['name'], $args['ttl'], '');
		break;
	// Create A and PTR
	case PTR:
		$args = array('name' => $name, 'domain' => $domain, 'address' => $address, 'ttl' => $ttl);
		if (!check_args($args)) bad_request($args);
		$fmt = '=%s.%s:%s:%u::%s';
		printf($fmt . PHP_EOL, $args['name'], $args['domain'], $args['address'], $args['ttl'], '');
		break;
	// Create A
	case A:
		$args = array('name' => $name, 'domain' => $domain, 'address' => $address, 'ttl' => $ttl);
		if (!check_args($args)) bad_request($args);
		$fmt = '+%s.%s:%s:%u::%s';
		printf($fmt . PHP_EOL, $args['name'], $args['domain'], $args['address'], $args['ttl'], '');
		break;
	// Create MX and A
	case MX:
		$args = array('domain' => $domain, 'address' => $address, 'name' => $name, 'priority' => $priority, 'ttl' => $ttl);
		if (!check_args($args)) bad_request($args);
		$fmt = '@%s:%s:%s:%u:%u::%s';
		printf($fmt . PHP_EOL, $args['domain'], $args['address'], $args['name'], $args['priority'], $args['ttl'], '');
		break;
	// Create CNAME
	case CNAME:
		$args = array('name' => $name, 'domain' => $domain, 'alias' => $alias, 'ttl' => $ttl);
		if (!check_args($args)) bad_request($args);
		$fmt = 'C%s.%s:%s:%u::%s';
		printf($fmt . PHP_EOL, $args['name'], $args['domain'], $args['alias'], $args['ttl'], '');
		break;
	// Unidentified
	default:
		bad_request(array('error' => 'Shaniqua (Don\'t Live Here No More)'));
}
?>
