package aws;

import aws.SignatureVersion4;
import aws.CloudFormationTypes;

class CloudFormation extends SignatureVersion4{

	public function new(accessKey:String, secretKey:String){
		var props = {
				accessKey:accessKey,
				secretKey:secretKey,
				method:null,
				service:'cloudformation',
				host:'cloudformation.us-west-2.amazonaws.com',
				region:'us-west-2',
				contentType:'application/json',
				amzTarget:null,
				path:null,
				signedHeaders:'content-type;host;x-amz-date',
				algorithm:'AWS4-HMAC-SHA256',
				version:"2010-05-15"
			}
			super("", props);
	}

	public function createStack(data:CreateStackRequestData){
		props.method = "POST";
		props.path = "/";
		endpoint = "https://" + props.host + props.path;
		data = convertArraysToParams(data);
		var args = "?Action=CreateStack";
		args += createQueryString(data);
		props.path += args;
		call();
	}

	public function updateStack(data:UpdateStackRequestData){
		props.method = "POST";
		props.path = "/";
		endpoint = "https://" + props.host + props.path;
		data = convertArraysToParams(data);
		var args = "?Action=UpdateStack";
		args += createQueryString(data);
		props.path += args;
		call();
	}


	function convertArraysToParams(data:StackRequestBase):Dynamic{
		if(data.Capabilities != null){
			var index = 1;
			for(c in data.Capabilities){
				var propName = "Capabilities.member." + index;
				Reflect.setField(data, propName, c);
				++index;
			}
			data.Capabilities = null;
		}

		if(data.NotificationARNs != null){
			var index = 1;
			for(c in data.NotificationARNs){
				var propName = "NotificationARNs.member." + index;
				Reflect.setField(data, propName, c);
				++index;
			}
			data.NotificationARNs = null;
		}

		if(data.ResourceTypes != null){
			var index = 1;
			for(c in data.ResourceTypes){
				var propName = "ResourceTypes.member." + index;
				Reflect.setField(data, propName, c);
				++index;
			}
			data.ResourceTypes = null;
		}

		if(data.Parameters != null){
			var index = 1;
			for(c in data.Parameters){
				var propName = "Parameters.member." + index + ".";
				if(c.ParameterKey != null) Reflect.setField(data, propName + "ParameterKey", c.ParameterKey);
				if(c.ParameterValue != null) Reflect.setField(data, propName + "ParameterValue", c.ParameterValue);
				if(c.ResolvedValue != null) Reflect.setField(data, propName + "ResolvedValue", c.ResolvedValue);
				++index;
			}
			data.Parameters = null;
		}


		if(data.Tags != null){
			var index = 1;
			for(c in data.Tags){
				var propName = "Tags.member." + index + ".";
				if(c.Key != null) Reflect.setField(data, propName + "Key", c.Key);
				if(c.Value != null) Reflect.setField(data, propName + "Value", c.Value);
				++index;
			}
			data.Tags = null;
		}

		return data;
	}


	public function listStacks(){
		props.method = "POST";
		props.path = "/";
		endpoint = "https://" + props.host + props.path;

		var args = "?Action=ListStacks";

		props.path += args;
		endpoint += args;
		call();
	}


	public function deleteStack(stackName:String){
		props.method = "POST";
		props.path = "/";
		endpoint = "https://" + props.host + props.path;

		var args = "?Action=DeleteStack&StackName=" + stackName;

		props.path += args;
		endpoint += args;
		call();
	}

	
}