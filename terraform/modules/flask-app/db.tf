resource "aws_dynamodb_table" "dynamodb_table" {
  # name is hardcoded in the app currently, so has to be this.
  name = "dateTable"

  read_capacity  = 1
  write_capacity = 1
  hash_key       = "date"

  attribute {
    name = "date"
    type = "S"
  }
}