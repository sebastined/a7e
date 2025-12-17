# Terraform assignment

Welcome to the Terraform assignment. In this assignment we kindly ask you to provision
some AWS resources by using Terraform. To be independent of any AWS accounts, we've prepared
a docker-compose configuration that will start the [localstack](https://github.com/localstack) 
AWS cloud stack on your machine. Terraform is already fully configured to work together with 
localstack. Please see the usage section on how to authenticate.

# Assignment

![Assignment](assignment.drawio.png)

The goal of this assignment is to build a serverless, event-driven architecture using AWS services and Terraform to handle file uploads to S3 and ensure security measures are taken place. 

Specifically, the architecture will: 
	• Track uploaded files in a DynamoDB table using Step Functions and Lambda. 
	• Trigger the workflow on file uploads to an S3 bucket. 
	• Sent notification to SNS Topic if there is any unencrypted S3 buckets and unencrypted dynamodb is found.

The practical use of the assignment shouldn't be questioned :-)

Few things will be tested on basis of this assessement -

1. End to end architecture implementation. 
2. Secure architecture like SSE, KMS etc in place.
3. DynamoDB tale will have following attributes: "Filename" and "Upload Timestamp".
4. Ensure old objects in s3 bucket expired after 90 days.
5. Have least privileges for services used.
6. Send a alert to SNS Topic if an unencrypted bucket or unencrypted DynamoDB table is found, and notify the security team. 

Additional Requirements:
    . Error Handling: 
		○ Add error handling in the Step Function to gracefully handle file validation failures and DynamoDB write errors.
		○ Implement logging in the Lambda function to capture event details and Step Function execution status. 
	
	• Unit Testing 
		○ To ensure the quality and reliability of the solution, unit testing should be integrated into the development process, especially for Lambda functions.

For any questions, reach to us.

# Usage

## Start localstack

```shell
docker-compose up
```

Watch the logs for `Execution of "preload_services" took 986.95ms`

## Authentication
```shell
export AWS_ACCESS_KEY_ID=foobar
export AWS_SECRET_ACCESS_KEY=foobar
export AWS_REGION=eu-central-1
```

## AWS CLI examples
### S3
```shell
aws --endpoint-url http://localhost:4566 s3 cp README.md s3://test-bucket/
```

## StepFunctions
```shell
aws --endpoint-url http://localhost:4566 stepfunctions list-state-machines
```

## DynamoDb

```shell
aws --endpoint-url http://localhost:4566 dynamodb scan --table-name Files
```
