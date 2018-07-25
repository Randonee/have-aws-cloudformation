package aws;

class S3 extends SignatureVersion4{

    public function new(accessKey:String, secretKey:String){
		var props = {
				accessKey:accessKey,
				secretKey:secretKey,
				method:null,
				service:'s3',
				host:'s3.amazonaws.com',
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
        props.host = name + ".s3-us-west-2.amazonaws.com";
		call();
    }


}