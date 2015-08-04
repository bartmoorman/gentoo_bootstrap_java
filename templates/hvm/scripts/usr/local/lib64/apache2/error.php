#!/usr/bin/php
<?php
$log = '/var/log/error_log';
$local_path = "/var/log/apache2";
$remote_path = "/mnt/log/web";
$hostname = gethostname();

function doLog($msg) {
	global $log;

	file_put_contents($log, sprintf('%s: %s' . PHP_EOL, date('Y-m-d H:i:s'), $msg), FILE_APPEND);
}

function doTee($msg) {
	global $local_path, $remote_path, $hostname;

	file_put_contents(sprintf('%s/error_log', $local_path), $msg, FILE_APPEND);
	file_put_contents(sprintf('%s/eror_log.%s.%s', $remote_path, date('Ymd'), $hostname), $msg, FILE_APPEND);
}

function signalHandlerParent($signo) {
	doLog("Got signal {$signo}. Shutting down.");

	exit();
}

function signalHandlerChild($signo) {
	pcntl_wait($status, WNOHANG);
}

doLog('Starting up.');

set_time_limit(0);

pcntl_signal(SIGTERM, 'signalHandlerParent');
pcntl_signal(SIGHUP, 'signalHandlerParent');
pcntl_signal(SIGCHLD, 'signalHandlerChild');

if (!file_exists($remote_path)) {
	doLog('Creating remote log path.');

	mkdir($remote_path, 0755, true);
}

while ($hit = fgets(STDIN)) {
	doTee($hit);

	pcntl_signal_dispatch();
}

pcntl_signal_dispatch();
?>
