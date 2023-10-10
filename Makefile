PYTHON_VERSION=python3.9
APP=main.zip
FUNC_NAME=mangun-demo
ROLE_NAME=myrole
LAYER_NAME=$(FUNC_NAME)
POLICY_ARN=arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

all: echo_url

.PHONY: echo_url
echo_url: create_function_url_config
	@echo "Endpoint: $$(aws lambda create-function-url-config \
		--function-name $(FUNC_NAME) \
		--auth-type NONE \
		--query 'FunctionUrlConfig.FunctionUrl' \
		--output text)"

.PHONY: create_function_url_config
create_function_url_config: add_permission

.PHONY: add_permission
add_permission: create_function
	aws lambda add-permission \
		--function-name $(FUNC_NAME) \
		--statement-id AllowPublic \
		--action lambda:InvokeFunctionUrl \
		--principal "*" \
		--function-url-auth-type NONE

.PHONY: create_role
create_role:
	$(eval ROLE := $(shell aws iam create-role \
		--role-name $(ROLE_NAME) \
		--assume-role-policy-document file://trust-policy.json \
		--query "Role.Arn" --output text))

.PHONY: attach_policy
attach_policy: create_role
	aws iam attach-role-policy \
		--role-name $(ROLE_NAME) \
		--policy-arn $(POLICY_ARN)

.PHONY: create_function
create_function: publish_layer #create_role attach_policy publish_layer 
	$(eval FUNCTION := $(shell aws lambda create-function \
		--function-name $(FUNC_NAME) \
		--runtime $(PYTHON_VERSION) \
		--role $(ROLE) \
		--handler main.handler \
		--layers $(LAYER) \
		--zip-file fileb://$(APP)))

.PHONY: publish_layer
publish_layer: myLayer.zip
	$(eval LAYER := $(shell aws lambda publish-layer-version \
		--compatible-architectures x86_64 \
		--layer-name $(LAYER_NAME) \
		--description "fastapi+mangum" \
		--zip-file fileb://myLayer.zip \
		--compatible-runtimes $(PYTHON_VERSION) \
		--license-info "egal" --query "LayerVersionArn" --output text))

myLayer.zip: tmp
	cd tmp/ && zip -r ../myLayer.zip .

.PHONY: tmp
tmp: $(APP)
	pip3 install -r requirements.txt -t tmp/python

$(APP):
	zip $(APP) main.py

.PHONY: detach_policy
detach_policy:
	aws iam detach-role-policy \
		--role-name $(ROLE_NAME) \
		--policy-arn $(POLICY_ARN)

.PHONY: delete_role
delete_role: detach_policy
	aws iam delete-role \
		--role-name $(ROLE_NAME)

.PHONY: clean
clean: detach_policy delete_role
	rm -f $(APP) myLayer.zip
	rm -rf tmp

