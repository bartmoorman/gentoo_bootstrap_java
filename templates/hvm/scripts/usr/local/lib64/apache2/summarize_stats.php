#!/usr/bin/php
<?php
include('include/settings.inc');

$dbs = array('web_stats', 'public_web_stats');

$statsDb = @new mysqli($host, $user, $pass);

foreach ($dbs as $db) {
	$statsDb->select_db($db);

	$query = <<<EOQ
SELECT TABLE_NAME, TABLE_ROWS, UPDATE_TIME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = '{$db}'
AND TABLE_NAME LIKE '%_stats'
AND TABLE_NAME NOT IN ('skel_stats', 'summary_stats')
EOQ;
	$tables = $statsDb->query($query);

	while ($table = $tables->fetch_object()) {
		$date = substr($table->TABLE_NAME, 0, strpos($table->TABLE_NAME, '_'));
		$hits = $table->TABLE_ROWS;
		$updated = $table->UPDATE_TIME;

		$query = <<<EOQ
SELECT hits, updated
FROM summary_stats
WHERE date = '{$date}'
EOQ;
		$result = $statsDb->query($query);
		$summary = $result->fetch_object();

		if ($summary->updated != $updated) {
			$_99_limit = round($hits / 100);
			$_95_limit = round($hits / 20);

			$query = <<<EOQ
(SELECT 'average' AS metric, AVG(time) AS value
FROM {$table->TABLE_NAME})
UNION
(SELECT '_99_percentile', time
FROM {$table->TABLE_NAME}
ORDER BY time DESC
LIMIT {$_99_limit}, 1)
UNION
(SELECT '_95_percentile', time
FROM {$table->TABLE_NAME}
ORDER BY time DESC
LIMIT {$_95_limit}, 1)
EOQ;
			$stats = $statsDb->query($query);

			while ($stat = $stats->fetch_object()) {
				${$stat->metric} = $stat->value;
			}

			$query = <<<EOQ
REPLACE
INTO summary_stats (date, hits, average, _99_percentile, _95_percentile, updated)
VALUES ('{$date}', '{$hits}', '{$average}', '{$_99_percentile}', '{$_95_percentile}', '{$updated}')
EOQ;
			$statsDb->query($query);
		}
	}
}

$statsDb->close();
?>
