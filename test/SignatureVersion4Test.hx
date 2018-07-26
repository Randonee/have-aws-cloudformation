
import aws.SignatureVersion4;

import haxe.crypto.Hmac;
import haxe.io.Bytes;

import geo.UnixDate;


class SignatureVersion4Test extends haxe.unit.TestCase {

	public function testKs() {
		var key = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY";
		var kSecret = SignatureVersion4.getKSecret(key);

		assertEquals('41575334774a616c725855746e46454d492f4b374d44454e472b62507852666943594558414d504c454b4559', kSecret.toHex());

		//20120215
		var d = UnixDate.fromDay(2012, 1, 14);
		var kDate = SignatureVersion4.getKDate(d, kSecret);
		assertEquals("969fbb94feb542b71ede6f87fe4d5fa29c789342b0f407474670f0c2489e0a0d", kDate.toHex());

		var kRegion = SignatureVersion4.getKRegion('us-east-1', kDate);
		assertEquals('69daa0209cd9c5ff5c8ced464a696fd4252e981430b10e3d3fd8e2f197d7a70c', kRegion.toHex());

		var kService = SignatureVersion4.getKRegion('iam', kRegion);
		assertEquals('f72cfd46f26bc4643f06a11eabb6c0ba18780c19a8da0c31ace671265e3c87fa', kService.toHex());

		var kSigning = SignatureVersion4.getKSigning(kService);
		assertEquals('f4780e2d9f65fa895f9c67b32ce1baf0b0d8a43505a000a1a9e090d414db404d', kSigning.toHex());
	}

	public function testHeaders(){

		//20150830T123600Z
		var d = UnixDate.fromDay(2015, 7, 29);
		var t = d.getTime();
		t += ((12 * 60) + 36) * 60;
		d = new UnixDate(t);
		var props = {
				accessKey:'',
				secretKey:'',
				method:'POST',
				path:'/',
				service:'service',
				host:'example.amazonaws.com',
				region:'us-east-1',
				contentType:'application/x-amz-json-1.0',
				amzTarget:'DynamoDB_20120810.CreateTable',
				signedHeaders:'host;x-amz-date',
				algorithm:'AWS4-HMAC-SHA256'
			}

		var canonicalRequest = SignatureVersion4.createCanonicalRequest(d, SignatureVersion4.getRequestHeaders(props, "", d), "", props);

		var exp = "POST\n";
		exp += "/\n";
		exp += "\n";
		exp += "host:example.amazonaws.com\n";
		exp += "x-amz-date:20150830T123600Z\n";
		exp += "\n";
		exp += "host;x-amz-date\n";
		exp += "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

		assertEquals(exp, canonicalRequest);
		var strToSignExp = 'AWS4-HMAC-SHA256\n';
		strToSignExp += '20150830T123600Z\n';
		strToSignExp += '20150830/us-east-1/service/aws4_request\n';
		strToSignExp += '553f88c9e4d10fc9e109e2aeb65f030801b70c2f6468faca261d401ae622fc87';

		var scope = SignatureVersion4.getCredentialScope(props, d);
		var strToSign = SignatureVersion4.getStringToSign(scope, canonicalRequest, props, d);

		assertEquals(strToSignExp, strToSign);
	}

	public function testGet(){
		var key = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY";

		var d = UnixDate.fromDay(2015, 7, 29);
		var t = d.getTime();
		t += ((12 * 60) + 36) * 60;
		d = new UnixDate(t);

		var props = {
				accessKey:'',
				secretKey:key,
				method:'GET',
				path:'/?Param1=Value1&Param1=value2',
				service:'service',
				host:'example.amazonaws.com',
				region:'us-east-1',
				contentType:'application/x-amz-json-1.0',
				amzTarget:'DynamoDB_20120810.CreateTable',
				signedHeaders:'host;x-amz-date',
				algorithm:'AWS4-HMAC-SHA256'
			}


var conexp = "GET
/
Param1=Value1&Param1=value2
host:example.amazonaws.com
x-amz-date:20150830T123600Z

host;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

		var canonicalRequest = SignatureVersion4.createCanonicalRequest(d, SignatureVersion4.getRequestHeaders(props, "", d), "", props);
		assertEquals(conexp, canonicalRequest);

	}


	public function testContentSha256(){

		var d = UnixDate.fromDay(2013, 4, 23);
		var t = d.getTime();
		d = new UnixDate(t);
		var props = {
				accessKey:'AKIAIOSFODNN7EXAMPLE',
				secretKey:"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
				method:'GET',
				path:"/test.txt",
				service:'s3',
				host:'examplebucket.s3.amazonaws.com',
				region:'us-east-1',
				contentType:'application/x-amz-json-1.0',
				amzTarget:null,
				signedHeaders:'host;x-amz-content-sha256;x-amz-date',
				algorithm:'AWS4-HMAC-SHA256'
			}


var conexp = "GET
/test.txt

host:examplebucket.s3.amazonaws.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20130524T000000Z

host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

		var canonicalRequest = SignatureVersion4.createCanonicalRequest(d, SignatureVersion4.getRequestHeaders(props, "", d), "", props);
		assertEquals(conexp, canonicalRequest);
	}






}




