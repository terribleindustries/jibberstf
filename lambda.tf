########
# Route 53
########

data "aws_route53_zone" "movienight" {
  name         = "${var.route53_domain}"
}

resource "aws_route53_record" "movienight" {
  zone_id = "${data.aws_route53_zone.movienight.zone_id}"
  name    = "${var.route53_domain}"
  type    = "A"
  ttl     = "300"
}

########
# Zip
########

resource "null_resource" "lambda_package" {
  provisioner "local-exec" {
    command = "rm -f lambda_function_payload.zip ; zip lambda_function_payload.zip function.py"
  }
}

########
# IAM
########

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

########
# Cloudwatch
########

resource "aws_cloudwatch_event_rule" "new_instance" {
  name        = "instance-state-change"
  description = "Capture all EC2 state change events"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {}
}
PATTERN
}

resource "aws_cloudwatch_event_target" "new_instance" {
    rule = "${aws_cloudwatch_event_rule.new_instance}"
    target_id = "check_foo"
    arn = "${aws_lambda_function.dns_lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_new_instance" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.dns_lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.new_instance.arn}"
}

#######
# Lambda
#######

resource "aws_lambda_function" "dns_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "movienight-dns"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "function.my_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("lambda_function_payload.zip")}"

  runtime = "python3.8"

  environment {
    variables = {
      RECORD_NAME = "${var.route53_domain}",
      ZONE_ID = "${data.aws_route53_zone.movienight.zone_id}"
    }
  }
}
