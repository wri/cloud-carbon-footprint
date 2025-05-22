resource "aws_s3_bucket" "ccf_terraform_state" {
  bucket = var.terraform_state_bucket
}

resource "aws_s3_bucket_versioning" "ccf_terraform_state_versioning" {
  bucket = aws_s3_bucket.ccf_terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ccf_terraform_state_encryption" {
  bucket = aws_s3_bucket.ccf_terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_security_group" "ccf_instance_sg" {
  name   = "ccf-instance-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_instance_profile" "ccf_instance_profile" {
  name = "ccf-instance-profile"
  role = aws_iam_role.ccf_api_role.name
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.ccf_instance_sg.id]
  subnet_id              = var.private_subnet_id
  private_ip             = var.private_ip
  user_data              = file("install.sh")
  iam_instance_profile   = aws_iam_instance_profile.ccf_instance_profile.name

  tags = local.tags

  depends_on = [aws_athena_workgroup.ccf_workgroup]
}

resource "aws_athena_workgroup" "ccf_workgroup" {
  name = "cloud-carbon-footprint"
  configuration {
    enforce_workgroup_configuration = true
    result_configuration {
      output_location = "s3://aws-athena-query-results-838255262149-us-east-1/athena-output/"  # Bucket in the main account #
    }
  }
  tags = local.tags
}

resource "aws_glue_catalog_database" "ccf_database" {
  name = "cloud_carbon_footprint"
  description = "Database for Cloud Carbon Footprint Athena queries"
  depends_on = [aws_athena_workgroup.ccf_workgroup]
}

resource "aws_glue_catalog_table" "cur_table" {
  name          = "aws_cost_and_usage_data"
  database_name = aws_glue_catalog_database.ccf_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "projection.enabled"  = "true"
    "storage.location.template" = "s3://wri-billing-reports/cost-and-usage/"
  }

  storage_descriptor {
    location      = "s3://wri-billing-reports/ccost-and-usage/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "cur-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    # Define the columns according to the CUR schema #
    columns {
      name = "line_item_usage_account_id"
      type = "string"
    }
    columns {
      name = "line_item_usage_start_date"
      type = "timestamp"
    }
  }
  depends_on = [aws_glue_catalog_database.ccf_database]
}
