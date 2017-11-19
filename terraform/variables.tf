variable region {
  default = "eu-west-1"
}

variable zone {
  default = "eu-west-1a"
}

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

variable default_keypair_public_key {
  description = "Public Key of the default keypair"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEmz3Vh6nBMop7kiJ6FIodlxewVLXCy97PtJV0rf2vw+0tNNHCfTBBDbZqDNbP3x3vBjXUrtePQi8ztZ7w5QUtjoITWkJNnhfbZJzTSXpgXGN7A97EfNJeb4KAR6rdo8gajumUSJaAceid6ilbp4TOxUTPotXrjDzBNbg6kSTkyDFjse45JGdemLkzI4ZiVzP3J0U8n7RaiANLzK2ekhlNfhUpnCuysh05Cwidb0fK9hJIn45gRjOEk9IGQxKEXN2GXbSry5iOcxglrdsanWi32P1FgimaKQ3AekmBF4YnnmUeg2V1S3LUwk+6cHQqMF6K6BWgt7YI18XCbPJtq3I7 jens@wh"
}

variable default_keypair_name {
  description = "Name of the KeyPair used for all nodes"
  default = "k8"
}

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

variable etcd_instance_type {
  default = "t2.small"
}

variable controller_instance_type {
  default = "t2.small"
}

variable worker_instance_type {
  default = "t2.small"
}
