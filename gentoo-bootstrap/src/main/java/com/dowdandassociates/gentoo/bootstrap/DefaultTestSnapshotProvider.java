
package com.dowdandassociates.gentoo.bootstrap;

import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.CreateSnapshotRequest;
import com.amazonaws.services.ec2.model.CreateSnapshotResult;
import com.amazonaws.services.ec2.model.DeleteVolumeRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesResult;
import com.amazonaws.services.ec2.model.DescribeSnapshotsRequest;
import com.amazonaws.services.ec2.model.DescribeSnapshotsResult;
import com.amazonaws.services.ec2.model.DescribeVolumesRequest;
import com.amazonaws.services.ec2.model.DescribeVolumesResult;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.Snapshot;
import com.amazonaws.services.ec2.model.TerminateInstancesRequest;
import com.amazonaws.services.ec2.model.TerminateInstancesResult;
import com.amazonaws.services.ec2.model.Volume;

import com.google.common.base.Optional;
import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;

import com.google.inject.Inject;
import com.google.inject.Provider;

import com.netflix.governator.annotations.Configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DefaultTestSnapshotProvider implements Provider<Optional<Snapshot>>
{
    private static Logger log = LoggerFactory.getLogger(DefaultTestSnapshotProvider.class);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestSnapshot.checkInstanceSleep")
    private Supplier<Long> instanceSleep = Suppliers.ofInstance(10000L);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestSnapshot.checkVolumeSleep")
    private Supplier<Long> volumeSleep = Suppliers.ofInstance(10000L);

    @Configuration("com.dowdandassociates.gentoo.bootstrap.TestSnapshot.checkSnapshotSleep")
    private Supplier<Long> snapshotSleep = Suppliers.ofInstance(10000L);

    private AmazonEC2 ec2Client;
    private BootstrapResultInformation bootstrapResultInformation;

    @Inject
    public DefaultTestSnapshotProvider(AmazonEC2 ec2Client, BootstrapResultInformation bootstrapResultInformation)
    {
        this.bootstrapResultInformation = bootstrapResultInformation;
    }

    public Optional<Snapshot> get()
    {
        BootstrapInstanceInformation instanceInfo = bootstrapResultInformation.getInstanceInfo();
        Optional<Instance> instance = instanceInfo.getInstance();
        Optional<Volume> volume = instanceInfo.getVolume();
        Optional<Integer> exitStatus = bootstrapResultInformation.getExitStatus();

        if (!instance.isPresent())
        {
            log.info("Instance is absent");
            return Optional.absent();
        }

        String instanceId = instance.get().getInstanceId();

        TerminateInstancesResult terminateInstancesResult = ec2Client.terminateInstances(new TerminateInstancesRequest().
                withInstanceIds(instanceId));
        
        if (!volume.isPresent())
        {
            log.info("Volume is absent");
            return Optional.absent();
        }

        String volumeId = volume.get().getVolumeId();

        DescribeInstancesRequest describeInstancesRequest = new DescribeInstancesRequest().
                withInstanceIds(instanceId);

        DescribeVolumesRequest describeVolumesRequest = new DescribeVolumesRequest().
                withVolumeIds(volumeId);
        try
        {
            while (true)
            {
                log.info("Sleeping for " + instanceSleep.get() + " ms");
                Thread.sleep(instanceSleep.get());
                DescribeInstancesResult describeInstancesResult = ec2Client.describeInstances(describeInstancesRequest);
                String state = describeInstancesResult.getReservations().get(0).getInstances().get(0).getState().getName();
                log.info("Instance State = " + state);
                if ("terminated".equals(state))
                {
                    break;
                }
            }

            CreateSnapshotResult createSnapshotResult = ec2Client.createSnapshot(new CreateSnapshotRequest().
                    withVolumeId(volumeId));

            log.info("SnapshotId = " + createSnapshotResult.getSnapshot().getSnapshotId());

            DescribeSnapshotsRequest describeSnapshotsRequest = new DescribeSnapshotsRequest().
                    withSnapshotIds(createSnapshotResult.getSnapshot().getSnapshotId());

            Snapshot snapshot;

            while (true)
            {
                log.info("Sleeping for " + snapshotSleep.get() + " ms");

                DescribeSnapshotsResult describeSnapshotsResult = ec2Client.describeSnapshots(describeSnapshotsRequest);
                String state = describeSnapshotsResult.getSnapshots().get(0).getState();
                log.info("Snapshot State = " + state);
                if ("error".equals(state))
                {
                    return Optional.absent();
                }
                if ("completed".equals(state))
                {
                    snapshot = describeSnapshotsResult.getSnapshots().get(0);
                    break;
                }
            }

            ec2Client.deleteVolume(new DeleteVolumeRequest().
                    withVolumeId(volumeId));
            
            if (!exitStatus.isPresent())
            {
                log.info("Exit status is not present");
                return Optional.absent();
            }

            log.info("exit status = " + exitStatus.get());

            if (0 != exitStatus.get())
            {
                return Optional.absent();
            }

            return Optional.fromNullable(snapshot);
        }
        catch (InterruptedException e)
        {
            return Optional.absent();
        }
    }
}

