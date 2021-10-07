# Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  role = aws_iam_role.my-role.name
}


# create ASG EC2 role, grant s3 access, and ec2 describe tags
resource "aws_iam_role" "my-role" {
  name                = "${terraform.workspace}-${var.ApplicationName}-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"]
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  
  inline_policy {
    name = "s3getputdelete"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Effect = "Allow"
          Resource = [
            "${aws_s3_bucket.imgmgr_bucket.arn}/*",
            "${aws_s3_bucket.imgmgr_bucket.arn}"
          ]
        },
        {
          Action = ["ec2:DescribeTags"]
          Effect = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}