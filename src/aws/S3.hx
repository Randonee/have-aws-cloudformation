package aws;

import sys.io.File;

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
		requestPrameters = '<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> 
  <LocationConstraint>' + props.region + '</LocationConstraint> 
  </CreateBucketConfiguration>';
		call();
    }

	public function addBucketObject(name:String, bucketName:String, data:String){
        props.method = "PUT";
        props.host = bucketName + ".s3-" + props.region + ".amazonaws.com";
		props.path = "/" + name;
		requestPrameters = data;
		call();
    }

	public function headBucket(name:String){
		props.method = "HEAD";
        props.host = name + ".s3-" + props.region + ".amazonaws.com";
		props.path = "/";
		call();
	}


}