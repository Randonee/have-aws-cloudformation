package;

import aws.*;
import util.*;
import sys.FileSystem;
import sys.io.Process;
import neko.Lib;
import haxe.io.Bytes;

using StringTools;


class Main{

	static var configDir:String;
	static var command:String;
	static var config:Dynamic;
	static var templateBody:Dynamic;
	static var cloudFormation:CloudFormation;
	static var bucketObjects:Array<{name:String, data:Bytes}>;

    public static function main(){
		var args:Array<String> = Sys.args();

		if(args.length == 2 && (args[0] == "?" || args[0] == "help") )
		{
			Lib.println('');
			Lib.println("Commands");
			Lib.println('cli_install				installs command line shortcut "hcf"');
			Lib.println('create            			Creates a stack using the directory "cloudformation" and the config "config.json"');
			Lib.println('create [config] [baseDir]  		Creates a stack using the directory "cloudformation" and the config file [config]');
			Lib.println('update            			Updates a stack. Args are the same as create');
			Lib.println('');

			return;
		}
		else if(args[0] == "cli_install")
		{
			var targetDir:String = (Sys.systemName() == "Mac") ? "/usr/local/bin/" : "/usr/bin";
			var targetPath:String = targetDir + "hcf";
			
			if(FileSystem.exists(targetPath)) {
				Sys.command("sudo", ["rm", targetPath]);
			}
			Sys.command("sudo", ["ln", "-s", getHaxelib("haxe-aws-cloudformation") + "../script/hcf.sh", targetDir + "hcf"]);
			Sys.command("sudo", ["chmod", "755", getHaxelib("haxe-aws-cloudformation") + "../script/hcf.sh"]);
			return;
		}
		else{
			handleCloudFormation();
		}
	}

	static function getRootPath(path:String, rootPath:String):String{
		var p = path;
		if(path.charAt(0) != "/")
			p = rootPath + path;
	
		return p;
	}

	static function uploadStack(){
		var addObjectS3 = new S3(config.creds.accessKey, config.creds.secretKey);
		var headS3 = new S3(config.creds.accessKey, config.creds.secretKey);
		var createBucketS3 = new S3(config.creds.accessKey, config.creds.secretKey);
		var bucketPolicy = new S3(config.creds.accessKey, config.creds.secretKey);

		addObjectS3.props.region = config.region;
		bucketPolicy.props.region = config.region;
		headS3.props.region = config.region;
		createBucketS3.props.region = config.region;
		
		createBucketS3.onError = onError;
		addObjectS3.onError = onError;
		bucketPolicy.onError = onError;


		var addObject = function(){
			addObjectS3.addBucketObject("stack.json", config.bucketName, haxe.Json.stringify(templateBody));
		}

		headS3.onComplete = function(sig){
			addObject();};

		headS3.onError = function(sig){
			Lib.println('Creating Bucket');
			createBucketS3.createBucket(config.bucketName);
		}

		var onCreateComplete = function(sig){
			bucketPolicy.addCloudFormationPolicy(config.bucketName);
		}

		createBucketS3.onComplete = onCreateComplete;
		bucketPolicy.onComplete = function(sig){addObject();};

		addObjectS3.onComplete = function(sig){

			var onRunCloudFormation = function(){
				switch(command){
					case "create": cloudFormation.createStack(config.stack);
					case "update": cloudFormation.updateStack(config.stack);
				}
			}
			addObjectsToBucket(bucketObjects, onRunCloudFormation, onError);
		}

		headS3.headBucket(config.bucketName);
	}

	static function handleCloudFormation(){
		var args:Array<String> = Sys.args();
		command = args[0];

		configDir = args[args.length-1];
		if(args.length > 2){
			if(args[1].charAt(0) != "/")
				configDir += args[1];
			else
				configDir = args[1];
		}

		if(configDir.charAt(configDir.length-1) != "/")
			configDir += "/";

		var configFile = "config.json";
		if(args.length == 4)
			configFile = args[2];

		var jih = new JsonInputHandler(configDir);
		config = jih.handle(sys.io.File.getContent(configDir + configFile));
		bucketObjects = jih.bucketFiles;
		templateBody = config.stack.TemplateBody;
		Reflect.deleteField(config.stack, "TemplateBody");
		config.stack.TemplateURL = "https://s3-" + config.region + ".amazonaws.com/" + config.bucketName + "/stack.json";
		config.stack.TemplateURL = StringTools.urlEncode(config.stack.TemplateURL.toLowerCase());


		cloudFormation = new CloudFormation(config.creds.accessKey, config.creds.secretKey);
		cloudFormation.props.region = config.region;
		cloudFormation.onComplete = onComplete;
		cloudFormation.onError = onError;
		
		uploadStack();
	}

	static function onComplete(sig:SignatureVersion4){
		Lib.println("Complete" + "\n\n" +sig.rawResponse);
	}

	static function onError(sig:SignatureVersion4){
		Lib.println("Error:" + sig.responseCode + "\n" + sig.error + "\n\n" + sig.rawResponse);
		Lib.println("\n\n\n\n" + sig.request);
	}

	public static function getHaxelib(library:String):String
	{
		var proc = new Process ("haxelib", ["path", library ]);
		var result = "";
		
		try
		{
			while (true)
			{
				var line = proc.stdout.readLine ();
				if (line.substr (0,1) != "-")
				{
					result = line;
					break;
				}
			}
		}
		catch (e:Dynamic) { };
		
		proc.close();
		
		if (result == "")
		{
			throw ("Could not find haxelib path  " + library + " - perhaps you need to install it?");
		}
		return result;
	}

	public static function addObjectsToBucket(objects:Array<{name:String, data:Bytes}>, onComplete:Void->Void, onError:SignatureVersion4->Void){
		var index = 0;
		var loadNext:Void->Void;

		var onObjComplete = function(sig:SignatureVersion4){
			++index;
			loadNext();
		}

		loadNext = function(){
			if(index >= objects.length){
				onComplete();
			}
			else{
				var s3 = new S3(config.creds.accessKey, config.creds.secretKey);
				s3.onError = onError;
				s3.onComplete = onObjComplete;
				Lib.println('Adding ' + objects[index].name + ' file to Bucket');
				s3.addBucketObject(objects[index].name, config.bucketName, objects[index].data.toString());
			}
		}


		loadNext();
	}
}