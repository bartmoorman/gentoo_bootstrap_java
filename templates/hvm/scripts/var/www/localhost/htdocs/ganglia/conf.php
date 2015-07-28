<?php
$acl = GangliaAcl::getInstance();

$acl->addPrivateCluster('Database');
$acl->addPrivateCluster('Deplopy');
$acl->addPrivateCluster('Dialer');
$acl->addPrivateCluster('Event Handler');
$acl->addPrivateCluster('Inbound');
$acl->addPrivateCluster('Joule Processor');
$acl->addPrivateCluster('Log');
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
?>
