#!/usr/bin/php
<?php
include('include/settings.inc');

$db = 'web_stats';

$log = '/var/log/stats_log';
$buffer = 100;
$hostname = gethostname();
$table_format = '%s_stats';

$day = date('z');
$date = date('Ymd');
$table = sprintf($table_format, $date);
$skeleton = 'skel_stats';

function doLog($msg) {
	global $log;

	file_put_contents($log, sprintf('%s: %s' . PHP_EOL, date('Y-m-d H:i:s'), $msg), FILE_APPEND);
}

function checkDb() {
	global $statsDb, $host, $user, $pass, $db, $table, $skeleton;

	if (!$statsDb->ping()) {
		$statsDb = @new mysqli($host, $user, $pass, $db);
		if ($statsDb->connect_error) {
			doLog("Failed while connecting to MySQL on {$host}: {$statsDb->connect_error}");
		}
	}

	$query = "CREATE TABLE IF NOT EXISTS {$table} LIKE {$skeleton}";
	if(!$statsDb->query($query)) {
		doLog("Query failed: {$statsDb->error}");
		doLog($query);
	}
}

function writeBuffer($values) {
	global $statsDb, $table;

	$values = implode(', ', $values);
	$query = "INSERT INTO {$table} (host, pid, vhost, rhost, date, method, page, standard, status, size, time) VALUES {$values}";

	$pid = pcntl_fork();

	if ($pid == -1) {
		doLog('Could not fork. Running query in parent.');

		checkDb();

		if(!$statsDb->query($query)) {
			doLog("Query failed: {$statsDb->error}");
			doLog($query);
		}
	} elseif ($pid == 0) {
		checkDb();

		if(!$statsDb->query($query)) {
			doLog("Query failed: {$statsDb->error}");
			doLog($query);
		}

		exit();
	}
}

function signalHandlerParent($signo) {
	global $values;

	doLog("Got signal {$signo}. Shutting down.");

	if (isset($values)) {
		doLog('Writing partial buffer.');

		writeBuffer($values);
		unset($values);
	}

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

$statsDb = @new mysqli($host, $user, $pass, $db);
if ($statsDb->connect_error) {
	doLog("Failed while connecting to MySQL on {$host}: {$statsDb->connect_error}");
}

while ($hit = trim(fgets(STDIN))) {
	$hit = preg_split('/ /', $hit, NULL, PREG_SPLIT_NO_EMPTY);
	$time = strtotime("{$hit[3]} {$hit[4]} {$hit[5]}");

	if ($day != date('z', $time)) {
		doLog('The day has changed.');

		if (isset($values)) {
			doLog('Writing partial buffer.');

			writeBuffer($values);
			unset($values);
		}

		$day = date('z', $time);
		$date = date('Ymd', $time);
		$table = sprintf($table_format, $date);	
	}

	if (count($hit) != 12) {
		array_splice($hit, 7, count($hit) - 11, implode(' ', array_slice($hit, 7, count($hit) - 11)));
	}

	if (count($hit) == 12) {
		$hit[5] = str_split($hit[5], 3);
		$hit[7] = addslashes($hit[7]);

		$values[] = "('{$hostname}', '{$hit[0]}', '{$hit[1]}', INET_ATON('{$hit[2]}'), CONVERT_TZ('{$hit[3]} {$hit[4]}', '{$hit[5][0]}:{$hit[5][1]}', 'America/Denver'), '{$hit[6]}', '{$hit[7]}', '{$hit[8]}', '{$hit[9]}', '{$hit[10]}', '{$hit[11]}')";

		if (count($values) >= $buffer) {
			writeBuffer($values);
			unset($values);
		}
	} else {
		doLog('Invalid entry: ' . implode(' ', $hit));
	}

	pcntl_signal_dispatch();
}

pcntl_signal_dispatch();
?>
