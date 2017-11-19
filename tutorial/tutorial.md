# Tutorial

Create a file `.aws-credentials` in your home directory:

```
export AWS_ACCESS_KEY_ID=<access-key-id>
export AWS_SECRET_ACCESS_KEY="<secret-key>"
```

Change file permissions:
```
chmod 700 .aws-credentials
```

In your `~/.bashrc` add the following line to the end of the file in
order to source `~/.aws-credentials`:

```
. ~/.aws-credentials
```

Create a directory `terraform` within your project
directory. `terraform` will contain all our Terraform scripts. Now
create a file `terraform/variables.tf`. This file will contain all
Terraform variables.

```
variable region {
  default = "eu-west-1"
}

```

We will use this variable in `terraform/aws.tf`. This file initially
has this content:

```
provider "aws" {
  access_key = ""
  secret_key = ""
  region = "${var.region}"
}
```

The empty `access_key` and `secret_key` indicates Terraform to take
these parameters from the environment. Within the `terraform`
directory run:

```
$ terraform init

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "aws" (1.3.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 1.3"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Running `terraform plan` should not display any changes that need to done:

```
$ terraform plan

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

Perfect. Let's continue setting up a first resource: a VPC or Virtual
Private Cloud that is a network zone within that we will deploy all
our Kubernetes setup.

Open a new file `vpc.tf` and enter this content:

```
resource "aws_vpc" "kubernetes" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  
  tags {
    Name = "${var.vpc_name}"
    Owner = "${var.owner}"
  }
}
```

Here we are using three more variables `var.vpc_cidr`, `var.vpc_name`
and `var.owner`. Let's add these to `variables.tf`:

```
variable vpc_cidr {
  default = "10.43.0.0/16"
}

variable vpc_name {
  description = "Name of the VPC"
  default = "kubernetes"
}

variable owner {
  default = "kubernetes"
}
```

We can again check `terraform plan`. This time we should see the VPC
resource to be added:

```
$ terraform plan

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_vpc.kubernetes
      id:                               <computed>
      assign_generated_ipv6_cidr_block: "false"
      cidr_block:                       "10.43.0.0/16"
      default_network_acl_id:           <computed>
      default_route_table_id:           <computed>
      default_security_group_id:        <computed>
      dhcp_options_id:                  <computed>
      enable_classiclink:               <computed>
      enable_classiclink_dns_support:   <computed>
      enable_dns_hostnames:             "true"
      enable_dns_support:               "true"
      instance_tenancy:                 <computed>
      ipv6_association_id:              <computed>
      ipv6_cidr_block:                  <computed>
      main_route_table_id:              <computed>


Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

```

We can run `terraform apply` to apply the changes and create the VPC:

```
$ terraform apply

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_vpc.kubernetes
      id:                               <computed>
      assign_generated_ipv6_cidr_block: "false"
      cidr_block:                       "10.43.0.0/16"
      default_network_acl_id:           <computed>
      default_route_table_id:           <computed>
      default_security_group_id:        <computed>
      dhcp_options_id:                  <computed>
      enable_classiclink:               <computed>
      enable_classiclink_dns_support:   <computed>
      enable_dns_hostnames:             "true"
      enable_dns_support:               "true"
      instance_tenancy:                 <computed>
      ipv6_association_id:              <computed>
      ipv6_cidr_block:                  <computed>
      main_route_table_id:              <computed>


Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_vpc.kubernetes: Creating...
  assign_generated_ipv6_cidr_block: "" => "false"
  cidr_block:                       "" => "10.43.0.0/16"
  default_network_acl_id:           "" => "<computed>"
  default_route_table_id:           "" => "<computed>"
  default_security_group_id:        "" => "<computed>"
  dhcp_options_id:                  "" => "<computed>"
  enable_classiclink:               "" => "<computed>"
  enable_classiclink_dns_support:   "" => "<computed>"
  enable_dns_hostnames:             "" => "true"
  enable_dns_support:               "" => "true"
  instance_tenancy:                 "" => "<computed>"
  ipv6_association_id:              "" => "<computed>"
  ipv6_cidr_block:                  "" => "<computed>"
  main_route_table_id:              "" => "<computed>"
aws_vpc.kubernetes: Creation complete after 10s (ID: vpc-3b24185c)

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

No we have a brand new VPC setup in AWS. Let's check the setup in the AWS console!

[[added-vpc.png]]


Next we can add a subnet to the VPC. This subnet shall be publicly
accesible. Add the following resource definition to `vpc.tf`:

```
resource "aws_subnet" "kubernetes" {
  vpc_id = "${aws_vpc.kubernetes.id}"
  cidr_block = "${var.vpc_cidr}"
  availability_zone = "${var.zone}"

  tags {
    Name = "kubernetes"
    Owner = "${var.owner}"
  }
}
```

The resource contains one new variable `var.zone`. We add this to
`variables.tf` below the variable `region`:

```
variable zone {
  default = "eu-west-1a"
}
```

Let's again look at the Terraform plan:

```
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

aws_vpc.kubernetes: Refreshing state... (ID: vpc-3b24185c)

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_subnet.kubernetes
      id:                              <computed>
      assign_ipv6_address_on_creation: "false"
      availability_zone:               "eu-west-1a"
      cidr_block:                      "10.43.0.0/16"
      ipv6_cidr_block:                 <computed>
      ipv6_cidr_block_association_id:  <computed>
      map_public_ip_on_launch:         "false"
      tags.%:                          "2"
      tags.Name:                       "kubernetes"
      tags.Owner:                      "kubernetes"
      vpc_id:                          "vpc-3b24185c"


Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

```

The plan shows us that a new subnet is to be creates. Perfect.

Apply the changes:

```
$ terraform apply

aws_vpc.kubernetes: Refreshing state... (ID: vpc-3b24185c)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_subnet.kubernetes
      id:                              <computed>
      assign_ipv6_address_on_creation: "false"
      availability_zone:               "eu-west-1a"
      cidr_block:                      "10.43.0.0/16"
      ipv6_cidr_block:                 <computed>
      ipv6_cidr_block_association_id:  <computed>
      map_public_ip_on_launch:         "false"
      tags.%:                          "2"
      tags.Name:                       "kubernetes"
      tags.Owner:                      "kubernetes"
      vpc_id:                          "vpc-3b24185c"


Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_subnet.kubernetes: Creating...
  assign_ipv6_address_on_creation: "" => "false"
  availability_zone:               "" => "eu-west-1a"
  cidr_block:                      "" => "10.43.0.0/16"
  ipv6_cidr_block:                 "" => "<computed>"
  ipv6_cidr_block_association_id:  "" => "<computed>"
  map_public_ip_on_launch:         "" => "false"
  tags.%:                          "" => "2"
  tags.Name:                       "" => "kubernetes"
  tags.Owner:                      "" => "kubernetes"
  vpc_id:                          "" => "vpc-3b24185c"
aws_subnet.kubernetes: Creation complete after 3s (ID: subnet-d489bc9d)

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

The subnet is not accessible by default. We can make it publicly
visible by adding an Internet Gateway and route all outbound traffic
through the Internet Gateway. For this setup we place three more
resources in `vpc.tf`:

```
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.kubernetes.id}"

  tags {
    Name = "kubernetes"
    Owner = "${var.owner}"
  }
}

resource "aws_route_table" "kubernetes" {
    vpc_id = "${aws_vpc.kubernetes.id}"

    # Default route through Internet Gateway
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.gw.id}"
    }

    tags {
      Name = "kubernetes"
      Owner = "${var.owner}"
    }
}

resource "aws_route_table_association" "kubernetes" {
  subnet_id = "${aws_subnet.kubernetes.id}"
  route_table_id = "${aws_route_table.kubernetes.id}"
}
```

So the first resource sets up the gateway. The second resource defines
a route table entry saying that all outbound traffic shall be routed
through the gateway. The third resource associates the new route table
entry with our subnet created earlier.

Let's look at the Terrform plan:

```
$ terraform plan

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

aws_vpc.kubernetes: Refreshing state... (ID: vpc-3b24185c)
aws_subnet.kubernetes: Refreshing state... (ID: subnet-d489bc9d)

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_internet_gateway.gw
      id:                                          <computed>
      tags.%:                                      "2"
      tags.Name:                                   "kubernetes"
      tags.Owner:                                  "kubernetes"
      vpc_id:                                      "vpc-3b24185c"

  + aws_route_table.kubernetes
      id:                                          <computed>
      propagating_vgws.#:                          <computed>
      route.#:                                     "1"
      route.~2599208424.cidr_block:                "0.0.0.0/0"
      route.~2599208424.egress_only_gateway_id:    ""
      route.~2599208424.gateway_id:                "${aws_internet_gateway.gw.id}"
      route.~2599208424.instance_id:               ""
      route.~2599208424.ipv6_cidr_block:           ""
      route.~2599208424.nat_gateway_id:            ""
      route.~2599208424.network_interface_id:      ""
      route.~2599208424.vpc_peering_connection_id: ""
      tags.%:                                      "2"
      tags.Name:                                   "kubernetes"
      tags.Owner:                                  "kubernetes"
      vpc_id:                                      "vpc-3b24185c"

  + aws_route_table_association.kubernetes
      id:                                          <computed>
      route_table_id:                              "${aws_route_table.kubernetes.id}"
      subnet_id:                                   "subnet-d489bc9d"


Plan: 3 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

```

So, as we expect, this will us set up three more resources. Let's
apply the changes:

```
$ terraform apply

aws_vpc.kubernetes: Refreshing state... (ID: vpc-3b24185c)
aws_subnet.kubernetes: Refreshing state... (ID: subnet-d489bc9d)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_internet_gateway.gw
      id:                                          <computed>
      tags.%:                                      "2"
      tags.Name:                                   "kubernetes"
      tags.Owner:                                  "kubernetes"
      vpc_id:                                      "vpc-3b24185c"

  + aws_route_table.kubernetes
      id:                                          <computed>
      propagating_vgws.#:                          <computed>
      route.#:                                     "1"
      route.~2599208424.cidr_block:                "0.0.0.0/0"
      route.~2599208424.egress_only_gateway_id:    ""
      route.~2599208424.gateway_id:                "${aws_internet_gateway.gw.id}"
      route.~2599208424.instance_id:               ""
      route.~2599208424.ipv6_cidr_block:           ""
      route.~2599208424.nat_gateway_id:            ""
      route.~2599208424.network_interface_id:      ""
      route.~2599208424.vpc_peering_connection_id: ""
      tags.%:                                      "2"
      tags.Name:                                   "kubernetes"
      tags.Owner:                                  "kubernetes"
      vpc_id:                                      "vpc-3b24185c"

  + aws_route_table_association.kubernetes
      id:                                          <computed>
      route_table_id:                              "${aws_route_table.kubernetes.id}"
      subnet_id:                                   "subnet-d489bc9d"


Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_internet_gateway.gw: Creating...
  tags.%:     "0" => "2"
  tags.Name:  "" => "kubernetes"
  tags.Owner: "" => "kubernetes"
  vpc_id:     "" => "vpc-3b24185c"
aws_internet_gateway.gw: Creation complete after 7s (ID: igw-82fc00e5)
aws_route_table.kubernetes: Creating...
  propagating_vgws.#:                         "" => "<computed>"
  route.#:                                    "" => "1"
  route.1332771133.cidr_block:                "" => "0.0.0.0/0"
  route.1332771133.egress_only_gateway_id:    "" => ""
  route.1332771133.gateway_id:                "" => "igw-82fc00e5"
  route.1332771133.instance_id:               "" => ""
  route.1332771133.ipv6_cidr_block:           "" => ""
  route.1332771133.nat_gateway_id:            "" => ""
  route.1332771133.network_interface_id:      "" => ""
  route.1332771133.vpc_peering_connection_id: "" => ""
  tags.%:                                     "" => "2"
  tags.Name:                                  "" => "kubernetes"
  tags.Owner:                                 "" => "kubernetes"
  vpc_id:                                     "" => "vpc-3b24185c"
aws_route_table.kubernetes: Creation complete after 8s (ID: rtb-e41d6a82)
aws_route_table_association.kubernetes: Creating...
  route_table_id: "" => "rtb-e41d6a82"
  subnet_id:      "" => "subnet-d489bc9d"
aws_route_table_association.kubernetes: Creation complete after 1s (ID: rtbassoc-9d82d2e4)

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Now create a new SSH key. We will use it later to connect to our
instances.

```
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/jens/.ssh/id_rsa): /home/jens/.ssh/k8 
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/jens/.ssh/k8.
Your public key has been saved in /home/jens/.ssh/k8.pub.
The key fingerprint is:
SHA256:3/z7TbjBd3E9AmWfcSg6byr8Di/0kHjniJ5m9ELmIVw jens@wh
The key's randomart image is:
+---[RSA 2048]----+
|             o o.|
|            + o +|
|           o . o |
|      E   o .   .|
|   . . .S. o . oo|
|    o * =..oo...+|
|     * B.*.oo + +|
|      *.*o+  . =o|
|     +o. =+   +oo|
+----[SHA256]-----+
$ ls -lha ~/.ssh/k8*
-rw------- 1 jens jens 1.7K Nov 19 20:54 /home/jens/.ssh/k8
-rw-r--r-- 1 jens jens  389 Nov 19 20:54 /home/jens/.ssh/k8.pub
```

Now we can add a resource to `vpc.tf` that declares the SSH keypair:

```
resource "aws_key_pair" "default_keypair" {
  key_name = "${var.default_keypair_name}"
  public_key = "${var.default_keypair_public_key}"
}
```

This declaration contains two more variables that we have to add to
`variables.tf`:

```
variable default_keypair_public_key {
  description = "Public Key of the default keypair"
  default = "ssh-rsa AAAAB3Nza..."
}

variable default_keypair_name {
  description = "Name of the KeyPair used for all nodes"
  default = "k8"
}
```

Let's look at the Terraform plan again:

```
$ terraform plan

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

aws_vpc.kubernetes: Refreshing state... (ID: vpc-3b24185c)
aws_internet_gateway.gw: Refreshing state... (ID: igw-82fc00e5)
aws_subnet.kubernetes: Refreshing state... (ID: subnet-d489bc9d)
aws_route_table.kubernetes: Refreshing state... (ID: rtb-e41d6a82)
aws_route_table_association.kubernetes: Refreshing state... (ID: rtbassoc-9d82d2e4)

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_key_pair.default_keypair
      id:          <computed>
      fingerprint: <computed>
      key_name:    "k8"
      public_key:  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEmz3Vh6nBMop7kiJ6FIodlxewVLXCy97PtJV0rf2vw+0tNNHCfTBBDbZqDNbP3x3vBjXUrtePQi8ztZ7w5QUtjoITWkJNnhfbZJzTSXpgXGN7A97EfNJeb4KAR6rdo8gajumUSJaAceid6ilbp4TOxUTPotXrjDzBNbg6kSTkyDFjse45JGdemLkzI4ZiVzP3J0U8n7RaiANLzK2ekhlNfhUpnCuysh05Cwidb0fK9hJIn45gRjOEk9IGQxKEXN2GXbSry5iOcxglrdsanWi32P1FgimaKQ3AekmBF4YnnmUeg2V1S3LUwk+6cHQqMF6K6BWgt7YI18XCbPJtq3I7 jens@wh"


Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

```

And apply the plan:


```
aws_vpc.kubernetes: Refreshing state... (ID: vpc-3b24185c)
aws_subnet.kubernetes: Refreshing state... (ID: subnet-d489bc9d)
aws_internet_gateway.gw: Refreshing state... (ID: igw-82fc00e5)
aws_route_table.kubernetes: Refreshing state... (ID: rtb-e41d6a82)
aws_route_table_association.kubernetes: Refreshing state... (ID: rtbassoc-9d82d2e4)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_key_pair.default_keypair
      id:          <computed>
      fingerprint: <computed>
      key_name:    "k8"
      public_key:  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEmz3Vh6nBMop7kiJ6FIodlxewVLXCy97PtJV0rf2vw+0tNNHCfTBBDbZqDNbP3x3vBjXUrtePQi8ztZ7w5QUtjoITWkJNnhfbZJzTSXpgXGN7A97EfNJeb4KAR6rdo8gajumUSJaAceid6ilbp4TOxUTPotXrjDzBNbg6kSTkyDFjse45JGdemLkzI4ZiVzP3J0U8n7RaiANLzK2ekhlNfhUpnCuysh05Cwidb0fK9hJIn45gRjOEk9IGQxKEXN2GXbSry5iOcxglrdsanWi32P1FgimaKQ3AekmBF4YnnmUeg2V1S3LUwk+6cHQqMF6K6BWgt7YI18XCbPJtq3I7 jens@wh"


Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_key_pair.default_keypair: Creating...
  fingerprint: "" => "<computed>"
  key_name:    "" => "k8"
  public_key:  "" => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEmz3Vh6nBMop7kiJ6FIodlxewVLXCy97PtJV0rf2vw+0tNNHCfTBBDbZqDNbP3x3vBjXUrtePQi8ztZ7w5QUtjoITWkJNnhfbZJzTSXpgXGN7A97EfNJeb4KAR6rdo8gajumUSJaAceid6ilbp4TOxUTPotXrjDzBNbg6kSTkyDFjse45JGdemLkzI4ZiVzP3J0U8n7RaiANLzK2ekhlNfhUpnCuysh05Cwidb0fK9hJIn45gRjOEk9IGQxKEXN2GXbSry5iOcxglrdsanWi32P1FgimaKQ3AekmBF4YnnmUeg2V1S3LUwk+6cHQqMF6K6BWgt7YI18XCbPJtq3I7 jens@wh"
aws_key_pair.default_keypair: Creation complete after 1s (ID: k8)

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

We are now prepared to setup EC2 instances! First we create 3 etcd
instances running on Ubuntu. Store the following resource in a new
file `etcd.tf`:

```
resource "aws_instance" "etcd" {
    count = 3
    ami = "${lookup(var.amis, var.region)}"
    instance_type = "${var.etcd_instance_type}"

    subnet_id = "${aws_subnet.kubernetes.id}"
    private_ip = "${cidrhost(var.vpc_cidr, 10 + count.index)}"
    associate_public_ip_address = true # Instances have public, dynamic IP

    availability_zone = "${var.zone}"
    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = "${var.default_keypair_name}"

    tags {
      Owner = "${var.owner}"
      Name = "etcd-${count.index}"
    }
}
```

The value for the field `ami` is retrieved as lookup from a hash map
declared in `variables.tf`:

```
variable amis {
  description = "Default AMIs to use for nodes depending on the region"
  type = "map"
  default = {
    ap-northeast-1 = "ami-0567c164"
    ap-southeast-1 = "ami-a1288ec2"
    cn-north-1 = "ami-d9f226b4"
    eu-central-1 = "ami-8504fdea"
    eu-west-1 = "ami-0d77397e"
    sa-east-1 = "ami-e93da085"
    us-east-1 = "ami-40d28157"
    us-west-1 = "ami-6e165d0e"
    us-west-2 = "ami-a9d276c9"
  }
}
```

This map provides specific AMIs for each region we'll probably use. We
also need to define the `etcd_instance_type` in `variables.tf` as:

```
variable etcd_instance_type {
  default = "t2.small"
}
```

The `aws_instance` resource also requires an `aws_security_group`
associated. We can declare this resource in `vpc.tf`:

```
resource "aws_security_group" "kubernetes" {
  vpc_id = "${aws_vpc.kubernetes.id}"
  name = "kubernetes"

  tags {
    Owner = "${var.owner}"
    Name = "kubernetes"
  }
}
```

We can check again `terraform plan` before applying the changes to
AWS. Then run `terraform apply` to apply all changes. After a short
time you see three new EC2 instances running in your AWS console.

At this point having three EC2 instances plus a bunch of other
resources deployed we can try to destroy the whole setup and recreate
it afterwards... just for fun:

```
$ terraform destory
...
$ terraform apply
...
```

After this operations all resources should be setup as before.

The Kubernetes Controller instances are setup similar to the etcd
instances. Add a file `k8_controller.tf` with this content:

```
resource "aws_instance" "controller" {
    count = 3
    ami = "${lookup(var.amis, var.region)}"
    instance_type = "${var.controller_instance_type}"

    subnet_id = "${aws_subnet.kubernetes.id}"
    private_ip = "${cidrhost(var.vpc_cidr, 20 + count.index)}"
    associate_public_ip_address = true # Instances have public, dynamic IP
    source_dest_check = false # TODO Required??

    availability_zone = "${var.zone}"
    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = "${var.default_keypair_name}"

    tags {
      Owner = "${var.owner}"
      Name = "controller-${count.index}"
    }
}
```

We need to define the `controller_instance_type` in `variables.tf` as:

```
variable controller_instance_type {
  default = "t2.small"
}
```

Now we can setup the worker nodes. Create a file `worker.tf` with this content:

```
resource "aws_instance" "worker" {
    count = 3
    ami = "${lookup(var.amis, var.region)}"
    instance_type = "${var.worker_instance_type}"

    subnet_id = "${aws_subnet.kubernetes.id}"
    private_ip = "${cidrhost(var.vpc_cidr, 30 + count.index)}"
    associate_public_ip_address = true # Instances have public, dynamic IP
    source_dest_check = false # TODO Required??

    availability_zone = "${var.zone}"
    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = "${var.default_keypair_name}"

    tags {
      Owner = "${var.owner}"
      Name = "worker-${count.index}"
    }
}

output "kubernetes_workers_public_ip" {
  value = "${join(",", aws_instance.worker.*.public_ip)}"
}
```

And again we have to define the instance type for the worker nodes in
`variables.tf`:

```
variable worker_instance_type {
  default = "t2.small"
}
```

After applying this again we should then have 9 running EC2 instances
running in AWS.
