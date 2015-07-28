#!/usr/bin/php
<?php
include('include/settings.inc');

$threshold = .80;

while (true) {
	$interval = 5;
	$message = '';

	$localDb = @new mysqli($mhost, $muser, $mpass);

	if ($localDb->connect_error) {
		sleep($interval);
		continue;
	}

	$query = <<<EOQ
SHOW STATUS LIKE 'Threads_connected'
EOQ;
	$status = $localDb->query($query);
	$status = $status->fetch_object();

	$query = <<<EOQ
SHOW VARIABLES LIKE 'max_connections'
EOQ;
	$variables = $localDb->query($query);
	$variables = $variables->fetch_object();

	if ($status->Value > $variables->Value * $threshold) {
		$query = <<<EOQ
SELECT * FROM information_schema.PROCESSLIST
EOQ;
		$processes = $localDb->query($query);

		while ($process = $processes->fetch_object()) {
			$message .= sprintf("%u %s %s %s %s %u %s %s\n", $process->ID, $process->USER, $process->HOST, $process->DB, $process->COMMAND, $process->TIME, $process->STATE, preg_replace('/\s+/', ' ', $process->INFO));
		}

		mail('Bart Moorman <bmoorman@insidesales.com>, NOC <noc@insidesales.com>', "TOO MANY CONNECTIONS ({$status->Value})", $message, 'From: mysql@' . gethostname());

		$interval = 60;
	}

	$localDb->close();

	sleep($interval);
}
?>
