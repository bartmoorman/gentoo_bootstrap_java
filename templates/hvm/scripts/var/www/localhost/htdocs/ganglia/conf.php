<?php
$conf['auth_system'] = 'enabled';
$conf['template_name'] = 'default';
$conf['graphreport_stats'] = false;
$conf['max_graphs'] = 0;
$conf['hostcols'] = 3;
$conf['metriccols'] = 2;
$conf['meta_designator'] = '';
$conf['strip_domainname'] = true;

$acl = GangliaAcl::getInstance();

$acl->addPrivateCluster('Database');
$acl->addPrivateCluster('Deploy');
$acl->addPrivateCluster('Dialer');
$acl->addPrivateCluster('Event Handler');
$acl->addPrivateCluster('Inbound');
$acl->addPrivateCluster('Joule Processor');
$acl->addPrivateCluster('Message Queue');
$acl->addPrivateCluster('MongoDB');
$acl->addPrivateCluster('Monitor');
$acl->addPrivateCluster('Name Server');
$acl->addPrivateCluster('Public Web');
$acl->addPrivateCluster('Socket');
$acl->addPrivateCluster('Statistics');
$acl->addPrivateCluster('Systems');
$acl->addPrivateCluster('Web');
$acl->addPrivateCluster('Worker');

$acl->addRole('bmoorman', GangliaAcl::ADMIN);
$acl->addRole('npeterson', GangliaAcl::ADMIN);
$acl->addRole('sdibb', GangliaAcl::ADMIN);
$acl->addRole('tlosee', GangliaAcl::ADMIN);
$acl->addRole('tpurdy', GangliaAcl::ADMIN);
?>
