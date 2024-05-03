data "aws_availability_zones" "az" {
  state = "available"
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "wp-key"
  public_key = "<PUBLIC KEY CONTENT>"
}

module "wordpress" {
  source      = "./wordpress-ha"
  title       = "My Blog"
  name        = "my-blog"
  environment = "prod"
  vpc_id      = aws_vpc.main.id

  host = "myblog.com.br"

  admin_user  = "admin"
  admin_email = "admin@myblog.com.br"

  cluster = {
    key_name          = aws_key_pair.ec2_key_pair.key_name
    instance_image_id = "<AMI ID>"
    min_size          = 1
    max_size          = 4
    desired_size      = 2

    public_subnets = [
      module.public_subnet_1.id,
      module.public_subnet_2.id,
    ]

    private_subnets = [
      module.private_subnet_1.id,
      module.private_subnet_2.id,
    ]
  }

  db = {
    subnets = [
      module.private_subnet_3.id,
      module.private_subnet_4.id,
    ]
  }
}
