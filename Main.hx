package;

import aws.*;
import util.*;
import sys.FileSystem;
import sys.io.Process;
import neko.Lib;


class Main{

	static var configDir:String;
	static var command:String;
	static var config:Dynamic;
	static var cloudFormation:CloudFormation;

    public static function main(){
		var args:Array<String> = Sys.args();

		if(args.length == 2 && (args[0] == "?" || args[0] == "help") )
		{
			Lib.println("Commands");
			Lib.println('cli_install			installs command line shortcut "hcf"');
			Lib.println('create            		Creates a stack using the directory "cloudformation" and the config "config.json"');
			Lib.println('create [config] [baseDir]  	Creates a stack using the directory "cloudformation" and the config file [config]');
			Lib.println('update            		Updates a stack. Args are the same as create');

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

		config = new JsonInputHandler(configDir).handle(sys.io.File.getContent(configDir + configFile));

		trace(config);

		cloudFormation = new CloudFormation(config.creds.accessKey, config.creds.secretKey);
		cloudFormation.onComplete = onComplete;
		cloudFormation.onError = onError;

		

		switch(command){
			case "make": cloudFormation.createStack(config.stack);
			case "update": cloudFormation.updateStack(config.stack);
		}
	}

	static function onComplete(sig:SignatureVersion4){
		trace("\n\n" + sig.request + "\n\n\n" +sig.rawResponse);
	}

	static function onError(sig:SignatureVersion4){
		trace("Error:" + sig.responseCode + ":" + sig.error + "\n" + sig.request + "\n\n\n" + sig.response);
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
}