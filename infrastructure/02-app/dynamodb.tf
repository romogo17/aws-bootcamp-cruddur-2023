data "aws_region" "current" {}

resource "aws_dynamodb_table" "cruddur_messages_table" {
  name           = "cruddur-messages"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "pk"
  range_key      = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "message_group_uuid"
    type = "S"
  }


  global_secondary_index {
    name            = "message-group-sk-index"
    hash_key        = "message_group_uuid"
    range_key       = "sk"
    write_capacity  = 5
    read_capacity   = 5
    projection_type = "ALL"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

data "aws_lambda_function" "message_stream" {
  function_name = "MessageStream"
}

resource "aws_lambda_event_source_mapping" "cruddur_dynamodb_lambda_trigger" {
  event_source_arn  = aws_dynamodb_table.cruddur_messages_table.stream_arn
  function_name     = data.aws_lambda_function.message_stream.arn
  starting_position = "LATEST"
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "DynamoDB-Endpoint"
  }
}
