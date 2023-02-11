terraform {
  backend "s3" {
    bucket  = "zhuldyztentech"
    key     = "tf_project_state_file"
    region  = "us-east-1"
    profile = "default"
  }
}
