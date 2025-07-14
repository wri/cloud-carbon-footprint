data "aws_s3_bucket" "billing_data_bucket" {
  bucket = "wri-cloud-carbon-footprint-cur"
}

data "aws_s3_bucket" "athena_query_results_bucket" {
  bucket = "aws-athena-query-results-838255262149-us-east-1"
}
