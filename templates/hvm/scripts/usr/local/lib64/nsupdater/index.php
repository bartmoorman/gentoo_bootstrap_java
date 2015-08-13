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
function read_data(&$data, $file = '/var/tinydns/root/data') {
	$data = file_get_contents($file);
}

// Check if record exists
function check_name($args, $fmt) {
	read_data($data);

	if (preg_match(sprintf('/%s%s\.%s/', preg_quote($args['prefix']), $args['name'], preg_quote($args['domain'])), $data)) {
		update_name($data, $args, $fmt);
		echo 'Updating' . PHP_EOL;
	} else {
		echo 'Inserting' . PHP_EOL;
		insert_name($data, $args, $fmt);
	}

	write_data($data);
}

// Insert a record
function insert_name(&$data, $args, $fmt) {
	$data .= vsprintf($fmt . PHP_EOL, $args);
}

// Update a record
function update_name(&$data, $args, $fmt) {
	$data = preg_replace(sprintf('/%s%s\.%s.*/', preg_quote($args['prefix']), $args['name'], preg_quote($args['domain'])), vsprintf($fmt, $args), $data);
}

// Backup data file
function backup_data($file = '/var/tinydns/root/data') {
	copy($file, sprintf('%s-%u', $file, date('YmdHis')));
}

// Write data file
function write_data($data, $file = '/var/tinydns/root/data') {
	backup_data();
	file_put_contents($file, $data);
	commit();
}

// Make
function commit($dir = '/var/tinydns/root') {
	shell_exec("cd {$dir} && make");
}

// Determine which type of record we need to update/create
switch ($type) {
	// Create A and PTR
	case 'PTR':
		$args = array('prefix' => '=', 'name' => $name, 'domain' => $domain, 'address' => $address, 'ttl' => $ttl, 'location' => 'lo');
		if (!check_args($args)) bad_request($args);
		$fmt = '%s%s.%s:%s:%u::%s';
		check_name($args, $fmt);
		break;
	// Create A
	case 'A':
		$args = array('prefix' => '+', 'name' => $name, 'domain' => $domain, 'address' => $address, 'ttl' => $ttl, 'location' => 'lo');
		if (!check_args($args)) bad_request($args);
		$fmt = '%s%s.%s:%s:%u::%s';
		check_name($args, $fmt);
		break;
	// Create CNAME
	case 'CNAME':
		$args = array('prefix' => 'C', 'name' => $name, 'domain' => $domain, 'alias' => $alias, 'ttl' => $ttl, 'location' => 'lo');
		if (!check_args($args)) bad_request($args);
		$fmt = '%s%s.%s:%s:%u::%s';
		check_name($args, $fmt);
		break;
	// Unidentified
	default:
		bad_request(array('error' => 'Shaniqua (Don\'t Live Here No More)'));
}
?>
