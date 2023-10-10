#!/bin/bash

PYTHON_VERSION="python3.10"
APP=main.zip

FUNC_NAME=mangun-demo

zip  $APP main.py

pip3 install -r requirements.txt -t tmp/python
cd tmp/ && zip -r ../myLayer.zip .

ROLE=$(aws iam create-role \
  --role-name myrole \
  --assume-role-policy-document file://../trust-policy.json --query "Role.Arn" --output text)

aws iam attach-role-policy \
  --role-name myrole  \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole


LAYER=$(aws lambda publish-layer-version \
  --compatible-architectures x86_64 \
  --layer-name $FUNC_NAME \
  --description "fastapi+mangum" \
  --zip-file fileb://../myLayer.zip \
  --compatible-runtimes $PYTHON_VERSION \
  --license-info "egal" --query "LayerVersionArn" --output text)

FUNCTION=$(aws lambda create-function \
  --function-name $FUNC_NAME \
  --runtime $PYTHON_VERSION \
  --role $ROLE \
  --handler main.handler \
  --layers $LAYER \
  --zip-file fileb://../$APP)

aws lambda add-permission \
    --function-name $FUNC_NAME \
    --statement-id AllowPublic \
    --action lambda:InvokeFunctionUrl \
    --principal "*" \
    --function-url-auth-type NONE


URL=$(aws lambda create-function-url-config \
  --function-name $FUNC_NAME \
  --auth-type NONE \
  --query 'FunctionUrlConfig.FunctionUrl' \
  --output text)

# aws lambda get-function-url-config --function-name mangun-demo --output text --query FunctionUrl
echo "Endpoint: $URL"

