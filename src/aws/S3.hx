package aws;

import sys.io.File;
import neko.Lib;

class S3 extends SignatureVersion4{

    public function new(accessKey:String, secretKey:String){
		var props = {
				accessKey:accessKey,
				secretKey:secretKey,
				method:null,
				service:'s3',
				host:'',
				region:'us-west-2',
				contentType:'application/json',
				amzTarget:null,
				path:"/",
				signedHeaders:'host;x-amz-content-sha256;x-amz-date',
				algorithm:'AWS4-HMAC-SHA256',
				version:"2012-10-17"
			}
			super("", props);
	}


    public function createBucket(name:String){
        props.method = "PUT";
        props.host = name + ".s3-" + props.region + ".amazonaws.com";
		Lib.println('Create Bucket: ' + props.host);
		requestPrameters = '<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> 
  <LocationConstraint>' + props.region + '</LocationConstraint> 
  </CreateBucketConfiguration>';
		call();
    }

	public function addBucketObject(name:String, bucketName:String, data:String){
		props.contentType = null;
		props.signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
        props.method = "PUT";

        props.host = bucketName + ".s3-" + props.region + ".amazonaws.com";
		props.path = "/" + name;
		requestPrameters = data;
		Lib.println('Add Bucket Object: ' + props.path + '    ' + props.host);
		call();
    }

	public function bucketVersioning(enabled:Bool, bucketName:String){
		var status = enabled ? "Enabled" : "Suspended";

		props.method = "PUT";
        props.host = bucketName + ".s3-" + props.region + ".amazonaws.com";
		Lib.println('Bucket Versioning Bucket: ' + status);
		props.path = "/?versioning=true";
		props.contentType = null;
		requestPrameters = '<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> 
  <Status>' + status + '</Status> 
</VersioningConfiguration>';

		call();
	}

	public function addCloudFormationPolicy(bucketName:String){

		var policy = '{
"Version":"2008-10-17",
"Statement" : [
    {
        "Effect":"Allow",
        "Principal" : {
			"Service" : [
				"cloudformation.amazonaws.com"
			]
        },
        "Action":["s3:*"],
        "Resource":"arn:aws:s3:::' + bucketName +'" 
    }
 ] 
}';

		props.contentType = null;
		props.signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
        props.method = "PUT";
        props.host = bucketName + ".s3-" + props.region + ".amazonaws.com";
		props.path = "/?policy=true";
		requestPrameters = policy;
		Lib.println('Add Bucket Policy: ' + props.host);
		call();
    }

	public function headBucket(name:String){
		props.method = "HEAD";
        props.host = name + ".s3-" + props.region + ".amazonaws.com";
		props.path = "/";
		call();
	}


}