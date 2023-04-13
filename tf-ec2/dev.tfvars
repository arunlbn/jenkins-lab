project_name = "monstack"
env_name = "dev"
ami_id = "ami-0c6c29c5125214c77"
srv_type = "t4g.small"
srv_key = "tf-test"
azs = [
  "us-east-1a",
  "us-east-1c",
  "us-east-1b",
]

srvsmon = [
  "monitorserver",
]

srvsnode = [
  "nodeserver",
]

awsregion = "us-east-1"
