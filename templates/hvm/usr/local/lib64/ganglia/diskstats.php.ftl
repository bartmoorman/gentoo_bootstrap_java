#!/usr/bin/php
<?php
$devices = array('xvda');

$units = array(
	'reads' => 'iops',
	'writes' => 'iops',
	'util' => '%'
);

if (file_exists('/tmp/diskstats')) {
	$saved = unserialize(file_get_contents('/tmp/diskstats'));

	foreach ($devices as $device) {
		$stats[$device] = preg_split('/ /', file_get_contents(sprintf('/sys/block/%s/stat', $device)), 0, PREG_SPLIT_NO_EMPTY);
		$stats['time'][$device] = time();

		$delta = $stats['time'][$device] - $saved['time'][$device];

		$send['reads'][$device] = ($stats[$device][0] - $saved[$device][0]) / $delta;
		$send['writes'][$device] = ($stats[$device][4] - $saved[$device][4]) / $delta;
		$send['util'][$device] = ($stats[$device][9] - $saved[$device][9]) / 10 / $delta;
	}

	foreach ($send as $type => $metrics) {
		foreach ($metrics as $key => $value) {
			$cmd = sprintf('/usr/bin/gmetric -n %s_%s -v %.2f -t float -u %s', $key, $type, $value, $units[$type]);
			system($cmd);
		}
	}
} else {
	foreach ($devices as $device) {
		$stats[$device] = preg_split('/ /', file_get_contents(sprintf('/sys/block/%s/stat', $device)), 0, PREG_SPLIT_NO_EMPTY);
		$stats['time'][$device] = time();
	}
}

file_put_contents('/tmp/diskstats', serialize($stats));
?>
