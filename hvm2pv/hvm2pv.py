#!/usr/bin/env python

import argparse
import boto.ec2
import logging
import sys

logging.basicConfig(format = "%(levelname)s:%(asctime)s:%(pathname)s:%(funcName)s:%(message)s", datefmt = "%Y-%m-%dT%H:%M:%S%Z", level = logging.INFO)

parser = argparse.ArgumentParser(description="Convert hvm AMI to a paravirtual one")
parser.add_argument("--region", type=str, nargs=1, help="Region to connect to.")
parser.add_argument("--image-id", type=str, nargs=1, help="Image ID to convert.")

args = parser.parse_args()

if args.region is not None:
    region = args.region[0]
else:
    region = "us-east-1"

if args.image_id is not None:
    image_id = args.image_id[0]
else:
    logging.error("--image-id not set")
    exit(1)

logging.info("region = " + region)
logging.info("image_id = " + image_id)

ec2_client = boto.ec2.connect_to_region(region)

images = ec2_client.get_all_images(image_ids = [image_id])
if len(images) == 0:
    logging.error("Cannot find image id " + image_id)
    exit(1)
image = images[0]

if image.virtualization_type != "hvm":
    logging.error("Image id " + image_id + " has virtualization type " + image.virtualization_type)
    exit(1)

if image.root_device_type != "ebs":
    logging.error("Image id " + image_id + " has root device type " + image.root_device_type)
    exit(1)

kernels = ec2_client.get_all_images(
        owners = ["amazon"],
        filters = {
            "image-type": "kernel",
            "architecture": image.architecture,
            "manifest-location": "*pv-grub-hd0_*"
        }
        )
kernels = sorted(kernels, key=lambda kernel: kernel.name, reverse=True)
kernel = kernels[0]
logging.info("Kernel id " + kernel.id + " name " + kernel.name)

new_name = image.name.replace("HVM", "64-bit-EBS")
logging.info("old name = " + image.name + "; new name = " + new_name)

new_description = image.description.replace("HVM", "64-bit EBS")
logging.info("old description = " + image.description + "; new description = " + new_description)

new_root_device_name = image.root_device_name.replace("xv", "s")
logging.info("old root device name = " + image.root_device_name + "; new root device name = " + new_root_device_name)

bdm = boto.ec2.blockdevicemapping.BlockDeviceMapping()
for key in image.block_device_mapping:
    new_key = key.replace("xv", "s")
    logging.info("old device name = " + key + "; new device name = " + new_key)
    bdm[new_key] = boto.ec2.blockdevicemapping.BlockDeviceType()
    if image.block_device_mapping[key].ephemeral_name is not None:
        bdm[new_key].ephemeral_name = image.block_device_mapping[key].ephemeral_name
    if image.block_device_mapping[key].no_device is not None:
        bdm[new_key].no_device = image.block_device_mapping[key].no_device
    if image.block_device_mapping[key].snapshot_id is not None:
        bdm[new_key].snapshot_id = image.block_device_mapping[key].snapshot_id
    if image.block_device_mapping[key].delete_on_termination is not None:
        bdm[new_key].delete_on_termination = image.block_device_mapping[key].delete_on_termination
    if image.block_device_mapping[key].size is not None:
        bdm[new_key].size = image.block_device_mapping[key].size
    if image.block_device_mapping[key].volume_type is not None:
        bdm[new_key].volume_type = image.block_device_mapping[key].volume_type
    if image.block_device_mapping[key].iops is not None:
        bdm[new_key].iops = image.block_device_mapping[key].iops

new_image_id = ec2_client.register_image(
        name = new_name,
        description = new_description,
        architecture = image.architecture,
        kernel_id = kernel.id,
        root_device_name = new_root_device_name,
        block_device_map = bdm,
        virtualization_type = "paravirtual"
        )

print(new_image_id)

