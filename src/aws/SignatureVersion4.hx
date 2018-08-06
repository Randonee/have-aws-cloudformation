package aws;

import sys.ssl.Socket;
import sys.net.Host;
import haxe.crypto.Sha256;
import haxe.crypto.Hmac;
import haxe.io.Bytes;
import haxe.Utf8;
import geo.UnixDate;

using StringTools;

typedef SignatureVersion4Props = {
	accessKey:String,
	secretKey:String,
	method:String,
	path:String,
	service:String,
	host:String,
	region:String,
	?contentType:String,
	?logType:String,
	?invocationType:String,
	?clientContext:String,
	amzTarget:String,
	signedHeaders:String,
	algorithm:String,
	?version:String
}

class SignatureVersion4{

	public var props:SignatureVersion4Props;
	public var time:UnixDate = UnixDate.now();
	var used:Bool = false;
	var payload_hash:String;

	public var stringPayload:Bool = true;

	public var request(default, null):String;
	var requestPrameters:String = "";
	var requestHeaders:Array<String> = [];

	public var responseHeaders(default, null):Array<String>;
	public var responseCode(default, null):Int;
	public var response(default, null):String;
	public var rawResponse(default, null):String;

	public var error(default, null):Dynamic;

	public var onComplete:SignatureVersion4->Void;
	public var onError:SignatureVersion4->Void;



	public function new(requestPrameters:String="", props:SignatureVersion4Props = null){
		this.props = props;
		this.requestPrameters = requestPrameters;
	}

	public static inline function getKSecret(key:String):Bytes{return Bytes.ofString("AWS4" + key);}
	public static inline function getDateStamp(d:UnixDate){return d.format("%Y%m%d");}
	public static inline function getAMZDate(d:UnixDate){return d.format("%Y%m%dT%H%M%SZ");}
	public static inline function getKDate(d:UnixDate, kSecret:Bytes){return sign(kSecret, Bytes.ofString(getDateStamp(d)));}
	public static inline function getKRegion(region:String, kDate:Bytes):Bytes{return sign(kDate, Bytes.ofString(region));}
	public static inline function getKService(service:String, kRegion:Bytes):Bytes{return sign(kRegion, Bytes.ofString(service));}
	public static inline function getKSigning(kService:Bytes):Bytes{return sign(kService, Bytes.ofString("aws4_request"));}
	public static inline function sign(key:Bytes, msg:Bytes):Bytes{return new Hmac(HashMethod.SHA256).make(key, msg);}

	static public inline function getStringToSign(credentialScope:String, canonicalRequest:String, props:SignatureVersion4Props, time:UnixDate):String{
		return props.algorithm + '\n' +  getAMZDate(time) + '\n' +  credentialScope + '\n' + Sha256.encode(canonicalRequest);
	}

	static public inline function getCredentialScope(props:SignatureVersion4Props, time:UnixDate):String{
		return getDateStamp(time) + '/' + props.region + '/' + props.service + '/' + 'aws4_request';
	}

	public static function createCanonicalRequest(time:UnixDate, requestHeaders:Array<String>, payload:String, props:SignatureVersion4Props):String{
		var canonical_uri = props.path;
		var canonical_querystring = '';
		
		var parts = props.path.split("?");
		if(parts.length == 2){
			canonical_uri = parts[0];
			canonical_querystring = parts[1];
		}

		var payload_hash = createPayloadHash(payload);
		var canonicalHeaders = createCanonicalHeaders(props, requestHeaders, payload, time);
		var canonical_request = props.method + '\n' + canonical_uri + '\n' + canonical_querystring + '\n' + canonicalHeaders + '\n' + props.signedHeaders + '\n' + payload_hash;
		return canonical_request;
	}

	static public function createPayloadHash(payload:String):String{
		return Sha256.encode(payload);
	}

	static public function getRequestHeaders(props:SignatureVersion4Props, payload:String, time:UnixDate):Array<String>{
		var headers:Array<String> = [];

		if(payload != "" && payload != null) headers.push('content-Length: ' + payload.length);

		if(props.contentType != null) headers.push('content-type:' + props.contentType );
		headers.push('host:' + props.host);
		if(props.clientContext != null) headers.push('x-amz-client-context:' + props.clientContext);
		if(props.signedHeaders.indexOf("x-amz-content-sha256") >= 0) headers.push('x-amz-content-sha256:' + createPayloadHash(payload));
		if(props.signedHeaders.indexOf("amz-date") >= 0) headers.push('x-amz-date:' + getAMZDate(time));
		if(props.invocationType != null) headers.push('x-amz-invocation-Type:' + props.invocationType);
		if(props.logType != null) headers.push('x-amz-log-type:' + props.logType);
		if(props.amzTarget != null) headers.push('x-amz-target:' + props.amzTarget);

		return headers;
	}

	static public function createCanonicalHeaders(props:SignatureVersion4Props, requestHeaders:Array<String>, payload:String="", time:UnixDate = null):String{
		var canonicalHeaders = '';
		var signedHeaders = props.signedHeaders.split(";");
		signedHeaders.sort(alphaSort);
		for(header in signedHeaders){
			for(rHeader in requestHeaders){
				var headerName = rHeader.split(":")[0];
				if(headerName.toLowerCase().indexOf(header.toLowerCase()) >= 0)
					canonicalHeaders += rHeader + '\n';
			}
		}
		return canonicalHeaders;
	}	

	static public function createAuthorizationHeader(canonicalRequest:String, props:SignatureVersion4Props, time:UnixDate):String{
		var kSecret = getKSecret(props.secretKey);
		var kDate = getKDate(time, kSecret);
    	var kRegion = getKRegion(props.region, kDate);
    	var kService = getKService(props.service, kRegion);
    	var kSigning = getKSigning(kService);
    	var credentialScope = getCredentialScope(props, time);
		var stringToSign = getStringToSign(credentialScope, canonicalRequest, props, time);
		var signature = sign(kSigning, Bytes.ofString(stringToSign)).toHex();
		var authorizationHeader = props.algorithm + ' ' + 'Credential=' + props.accessKey + '/' + credentialScope + ', ' +  'SignedHeaders=' + props.signedHeaders + ', ' + 'Signature=' + signature;
		return authorizationHeader;
	}

	public function createRequest():String{
		var request = props.method + " " + props.path + " HTTP/1.1\r\n";

		requestHeaders = requestHeaders.concat(getRequestHeaders(props, requestPrameters, time));
		requestHeaders.sort(alphaSort);

		for(header in requestHeaders){
			request += header + '\r\n';
		}
		
		var canonicalRequest = createCanonicalRequest(time, requestHeaders, requestPrameters, props);
		var authorizationHeader = createAuthorizationHeader(canonicalRequest, props, time);

		request += 'Authorization: ' + authorizationHeader + "\r\n";
		request += 'Connection: close\r\n';
		request += '\r\n';
		if(requestPrameters != "" && requestPrameters != null){
			request += requestPrameters;
		}
		return request;
	}

	public function addHeader(header:String){
		requestHeaders.push(header);
	}

	public function call(){

		if(used) throw "Instances can not make more than one request";
		used = true;

		var socket = new Socket();

		try{
			socket.connect(new Host(props.host), 443);
		}
		catch(msg:Dynamic){
			finishError(msg);
			return;
		}

		request = createRequest();

		try {
			socket.write(request);
		}
		catch(msg:Dynamic){
			finishError(msg);
			return;
		}

		rawResponse = '';
		var data = '';
		while(true){
			try {
		        var ln = socket.input.readLine();
		        data += ln + '\n';
		        rawResponse  += ln + '\n';
		        if(ln == ''){
		        	responseHeaders = data.split('\n');
		        	if(responseHeaders.length == 0){
		        		finishError("Bad Response");
		        		return;
		        	}
		        	var statusLine:Array<String> = responseHeaders.shift().split(" ");
		        	if(statusLine.length < 3){
		        		finishError("Bad Response");
		        		return;
		        	}
		        	responseCode = Std.parseInt(statusLine[1]);
		        	data = '';
		        }
      		}
      		catch(eof:haxe.io.Eof){
      			socket.close();
      			response = data;
      			if(responseCode >= 400)
      				finishError("")
      			else
		        	finishSuccess();
		        return;
      		}
      		catch (msg:Dynamic) {
        		socket.close();
				response = data;
        		finishError(msg);
        		return;
			}
		}
	}

	private function finishSuccess():Void{
		if(onComplete != null)
			onComplete(this);
	}

	private function finishError(error:Dynamic):Void{
		this.error = error;
		if(onError != null)
			onError(this);
	}

	function createQueryString(data:Dynamic):String{

		if(props.logType != null)
			data.version = props.version;

		var keys = Reflect.fields(data);

		keys.sort(function(a, b):Int {
			if (a < b) return -1;
			else if (a > b) return 1;
			return 0;
		});

		var str = "";

		for(key in keys){
			var prop = Reflect.getProperty(data, key);
			if(Std.is(prop, String) || Std.is(prop, Int) || Std.is(prop, Float) || Std.is(prop, Bool)  ){
				str += "&" + key + "=" + Reflect.getProperty(data, key);
			}
			else{
				str += "&" + key + "=" + haxe.Json.stringify(prop).urlEncode();
			}
		}

		return str;
	}

	private static function alphaSort(a:String, b:String):Int
	{
		a = a.toLowerCase();
		b = b.toLowerCase();
		if (a < b) return -1;
		if (a > b) return 1;
		return 0;
	}

}