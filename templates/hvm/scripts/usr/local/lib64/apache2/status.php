#!/usr/bin/php
<?php
$log = '/var/log/status_log';
$interval = 10;

$start = time();
$statuses = array('200' => 0, '300' => 0, '400' => 0, '500' => 0, 'other' => 0, 'total' => 0);
$visitors = array();

function doLog($msg) {
	global $log;

	file_put_contents($log, sprintf('%s: %s' . PHP_EOL, date('Y-m-d H:i:s'), $msg), FILE_APPEND);
}

function signalHandlerParent($signo) {
	doLog("Got signal {$signo}. Shutting down.");

	exit();
}

function signalHandlerChild($signo) {
	pcntl_wait($status, WNOHANG);
}

function signalHandlerReport($signo) {
	global $start, $statuses, $visitors;

	$delta = time() - $start;

	foreach ($statuses as $status => $count) {
		$cmd = sprintf('/usr/bin/gmetric -n apache_%s -v %.2f -t float -u requests/sec', $status, $count / $delta);
		system($cmd);
	}

	$cmd = sprintf('/usr/bin/gmetric -n apache_visitors -v %u -t uint16', count($visitors));
	system($cmd);

	$start = time();
	$statuses = array('200' => 0, '300' => 0, '400' => 0, '500' => 0, 'other' => 0, 'total' => 0);
	$visitors = array();

	pcntl_alarm($interval);
}

doLog('Starting up.');

set_time_limit(0);

pcntl_signal(SIGTERM, 'signalHandlerParent');
pcntl_signal(SIGHUP, 'signalHandlerParent');
pcntl_signal(SIGCHLD, 'signalHandlerChild');
pcntl_signal(SIGALRM, 'signalHandlerReport');

pcntl_alarm($interval);

while ($hit = trim(fgets(STDIN))) {
	$hit = preg_split('/ /', $hit, NULL, PREG_SPLIT_NO_EMPTY);

	if (preg_match('/^2\d\d/', $hit[0])) {
		$statuses['200']++;
	} elseif (preg_match('/^3\d\d/', $hit[0])) {
		$statuses['300']++;
	} elseif (preg_match('/^4\d\d/', $hit[0])) {
		$statuses['400']++;
	} elseif (preg_match('/^5\d\d/', $hit[0])) {
		$statuses['500']++;
	} else {
		$statuses['other']++;
	}

	$statuses['total']++;
	$visitors[$hit[1]]++;

	pcntl_signal_dispatch();
}

pcntl_signal_dispatch();
?>
