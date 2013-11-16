The entire process for building the image is exploiting dependency injection to move forward through the process. The console is loading `Bootstrapper` which itself merely gets the final image information, which has its dependencies met so on and so forth back to the beginning of the process. Here we are trying to be able to see the process in one place.

Dependencies Legend:

* A -> B (`binder.bind(A.class).to(B.class);`)
* C => D (`binder.bind(C.class).toProvider(D.class);`)

## Bootstrapper

Class: Bootstrapper

Dependencies:

* @Named("Gentoo Image") Optional<Image> => DefaultGentooImageProvider

## DefaultGentooImageProvider

Implements: Provider<Optional<Image>>

Dependencies:

* AmazonEC2 => DefaultAmazonEC2Provider
* TestResultInformation => DefaultTestResultInformationProvider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.GentooImage.checkInstanceSleep` (default: `10000`)
* `com.dowdandassociates.gentoo.bootstrap.GentooImage.checkVolumeSleep` (default: `10000`)
* `com.dowdandassociates.gentoo.bootstrap.GentooImage.checkSnapshotSleep` (default: `10000`)

## DefaultTestResultInformationProvider

Class: DefaultTestResultInformationProvider

Impelements: Provider<TestResultInformation>

Dependencies:

* TestSessionInformation => DefaultTestSessionInformationProvider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.Script.sudo` (default: `uname -a`)

## DefaultTestSessionInformationProvider

Implements: Provider<TestSessionInformation>

Dependencies:

* Optional<JSch> => JSchProvider
* UserInfo -> DefaultUserInfo
* TestInstanceInformation => EbsOnDemandTestInstanceInformationProvider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.TestSession.user` (default: `ec2-user`)
* `com.dowdandassociates.gentoo.bootstrap.TestSession.port` (default: `22`)

## EbsOnDemandTestInstanceInformationProvider

Extends: AbstractTestInstanceInformationProvider

Dependencies:

* AmazonEC2 => DefaultAmazonEC2Provider
* @Named("Test Image") Optional<Image> => DefaultTestImageProvider
* KeyPairInformation -> DefaultKeyPairInformation
* SecurityGroupInformation -> SecurityGroupInformation

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.TestInstance.checkInstanceSleep` (default: `10000`)

### AbstractTestInstanceInformationProvider

Implements: Provider<TestInstanceInformation>

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.TestInstance.instanceType`
* `com.dowdandassociates.gentoo.bootstrap.TestInstance.availabilityZone`

## DefaultTestImageProvider

Implements: Provider<Optional<Image>>

Dependencies:

* AmazonEC2 => DefaultAmazonEC2Provider
* @Named("Test Snapshot") Optional<Snapshot> => DefaultTestSnapshotProvider
* ImageInformation -> ParavirtualEbsImageInformation
* @Named("Kernel Image") Optional<Image> => DefaultKernelImageProvider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.TestImage.prefix` (default: `Gentoo_EBS`)
* `com.dowdandassociates.gentoo.bootstrap.TestImage.dateFormat` (default: `-yyyy-MM-dd-HH-mm-ss`)
* `com.dowdandassociates.gentoo.bootstrap.TestImage.description` (default: `Gentoo EBS`)
* `com.dowdandassociates.gentoo.bootstrap.TestImage.rootDeviceName` (default: `/dev/sda1`)
* `com.dowdandassociates.gentoo.bootstrap.TestImage.checkImageSleep` (default: `10000`)

## DefaultTestSnapshotProvider

Class: DefaultTestSnapshotProvider

Implements: Provider<Optional<Snapshot>>

Dependencies:

* AmazonEC2 => DefaultAmazonEC2Provider
* BootstrapResultInformation => DefaultBootstrapResultInformationProvider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.TestSnapshot.checkInstanceSleep` (default: `10000`)
* `com.dowdandassociates.gentoo.bootstrap.TestSnapshot.checkVolumeSleep` (default: `10000`)
* `com.dowdandassociates.gentoo.bootstrap.TestSnapshot.checkSnapshotSleep` (default: `10000`)

## DefaultBootstrapResultInformationProvider

Impelements: Provider<BootstrapResultInformation>

Dependencies:

* BootstrapCommandInformation -> DefaultBootstrapCommandInformationProvider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.Script.sudo` (default: `true`)

## DefaultBootstrapCommandInformationProvider

Implements: Provider<BootstrapCommandInformation>

Dependencies:

* BootstrapSessionInformation => DefaultBootstrapSessionInformationProvider
* ProcessedTemplate => DefaultProcessedTemplateProvider
* @Named("Script Name") Supplier<String> => DefaultScriptNameProvider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.Script.directory` (default: `/tmp`)

## DefaultProcessedTemplateProvider

Implements: Provider<ProcessedTemplate>

Dependencies:

* @Named("Script Name") Supplier<String> => DefaultScriptNameProvider
* Optional<Template> => DefaultTemplateProvider
* @Named("Template Data Model") Object => DefaultTemplateDataModelProvider

## DefaultScriptNameProvider

Implements: Provider<Supplier<String>>

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.Script.name` (default: `bootstrap.sh`)

## DefaultTemplateDataModelProvider

Implements: Provider<Object>

Dependencies:

* ImageInformation -> ParavirtualEbsImageInformation

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.mirror` (default: `http://gentoo.mirrors.pair.com/`)
* `com.dowdandassociates.gentoo.bootstrap.rootfstype` (default: `ext4`)
* `com.dowdandassociates.gentoo.bootstrap.mountPoint` (default: `/mnt/gentoo`)

## ParavirtualEbsImageInformation

Extends: AbstractParavirtualImageInformation

### AbstractParavirtualImageInformation

Implements: ImageInformation

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.Image.architecture` (default: `x86_64`)
* `com.dowdandassociates.gentoo.bootstrap.Image.bootPartition` (default: `hd0`)

## DefaultTemplateProvider

Implements: Provider<Optional<Template>>

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.Template.base`
* `com.dowdandassociates.gentoo.bootstrap.Template.localized` (default: `false`)
* `com.dowdandassociates.gentoo.bootstrap.Template.path`

## DefaultBootstrapSessionInformationProvider

Implements: Provider<BootstrapSessionInformation>

Dependencies:

* Optional<JSch> => JSchProvider
* UserInfo -> DefaultUserInfo
* BootstrapInstanceInformation => EbsOnDemandBootstrapInstanceInformationProvider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.BootstrapSession.user` (default: `ec2-user`)
* `com.dowdandassociates.gentoo.bootstrap.BootstrapSession.port` (default: `22`)
* `com.dowdandassociates.gentoo.bootstrap.BootstrapSession.waitToConnect` (default: `0`)

## EbsOnDemandBootstrapInstanceInformationProvider

Extends: AbstractOnDemandBootstrapInstanceInformationProvider

Dependencies:

* AmazonEC2 => DefaultAmazonEC2Provider
* @Named("Bootstrap Image") Optional<Image> => DefaultBootstrapImageProvider
* KeyPairInformation -> DefaultKeyPairInformation
* SecurityGroupInformation -> DefaultSecurityGroupInformation
* BlockDeviceInformation -> DefaultBlockDeviceInformation

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.volumeSize` (default: `10`)
* `com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.checkVolumeSleep` (default: `10000`)

### AbstractOnDemandBootstrapInstanceInformationProvider

Extends: AbstractBootstrapInstanceInformationProvider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.checkInstanceSleep` (default: `10000`)

#### AbstractBootstrapInstanceInformationProvider

Implements: Provider<BootstrapInstanceInformation>

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.instanceType`
* `com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.availabilityZone`
* `com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.checkAttachmentSleep` (default: `10000`)

## DefaultBlockDeviceInformation

Implements: BlockDeviceInformation

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.BootstrapInstance.device` (default: `f`)

## JSchProvider

Implements: Provider<Optional<JSch>>

Dependencies:

* KeyPairInformation -> DefaultKeyPairInformation

## DefaultUserInfo

Implements: UserInfo

Configurations

* `com.dowdandassociates.gentoo.bootstrap.UserInfo.passphrase`
* `com.dowdandassociates.gentoo.bootstrap.UserInfo.password`
* `com.dowdandassociates.gentoo.bootstrap.UserInfo.yesNo` (default: `true`)

## DefaultKernelImageProvider

Extends: LatestImageProvider

Dependencies:

* AmazonEC2 => DefaultAmazonEC2Provider
* ImageInformation -> ParavirtualEbsImageInformation

### LatestImageProvider

Implements: Provider<Optional<Image>>

## DefaultBootstrapImageProvider

Extends: LatestImageProvider

Dependencies:

* AmazonEC2 => DefaultAmazonEC2Provider
* ImageInformation -> ParavirtualEbsImageInformation

## DefaultSecurityGroupInformation

Implements: SecurityGroupInformation

Dependencies:

* AmazonEC2 => DefaultAmazonEC2Provider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.SecurityGroup.name` (default: `gentoo-bootstrap`)
* `com.dowdandassociates.gentoo.bootstrap.SecurityGroup.description` (default: `Gentoo Bootstrap`)
* `com.dowdandassociates.gentoo.bootstrap.SecurityGroup.cidr` (default: `0.0.0.0/0`)
* `com.dowdandassociates.gentoo.bootstrap.SecurityGroup.port` (default: `22`)

## DefaultKeyPairInformation

Implements: KeyPairInformation

Dependencies:

* AmazonEC2 => DefaultAmazonEC2Provider

Configurations:

* `com.dowdandassociates.gentoo.bootstrap.KeyPair.filename`
* `com.dowdandassociates.gentoo.bootstrap.KeyPair.name`

## DefaultAmazonEC2Provider

Implements: Provider<AmazonEC2>

Configurations:

* `com.amazonaws.services.ec2.AmazonEC2.endpoint` (default: `https://ec2.us-east-1.amazonaws.com`)

