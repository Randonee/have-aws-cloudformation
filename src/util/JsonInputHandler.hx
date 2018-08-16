package util;

import sys.io.File;
import sys.FileSystem;
import haxe.io.Bytes;

using StringTools;

class JsonInputHandler{

    public var bucketFiles:Array<{name:String, data:Bytes}> = [];

    public var baseDir:String;

    public function new(baseDir:String=""){
        this.baseDir = baseDir;        
    }


    public function parseObject(obj:Dynamic, config:Dynamic):Void{
        var fields = Reflect.fields(obj);

        for(fName in fields){
            var field = Reflect.field(obj, fName);

            if(Std.is(field, String)){
                Reflect.setField(obj, fName, StringTools.replace(field, "&&bucketName&&", config.bucketName));
            }
            else if(Reflect.isObject(field)){
                parseObject(field, config);
            }
        }
    }

    public function parseTemplateFile(path:String):String{
        if(!FileSystem.exists(baseDir + path)) throw "File Not Found: " + baseDir + path;
        var content = File.getContent(baseDir + path);
        var template = new util.Template(content);
        var data = template.execute({}, this);

        return data;
    }

    public function handle(str:String):Dynamic{
        var template = new util.Template(str);
        var output = template.execute({}, this);
        var config = haxe.Json.parse(output);

        parseObject(config, config);
        return config;
    }

    function file(resolve:String->Dynamic, path:String):String{
        if(!FileSystem.exists(baseDir + path)) throw "File Not Found: " + baseDir + path;
        var content = File.getContent(baseDir + path);
        var template = new util.Template(content);
        return template.execute({}, this);
    }

    function replaceString(resolve:String->Dynamic, inSting:String, oldS:String, newS:String):String{
        return StringTools.replace(inSting, oldS, newS);
    }

    function zipBase64(resolve:String->Dynamic, path:String):String{
        var zip = new util.Zip(this);
        var name = path.split("/").pop();
        zip.add(path, name);
        return haxe.crypto.Base64.encode(zip.getBytes());
    }

    function lambdaCode(resolve:String->Dynamic, path:String, version=""){
        var zip = new util.Zip(this);
        var name = path.split("/").pop();
        zip.add(path, name);
        bucketFiles.push({name:name + version + ".zip", data:zip.getBytes()});
        return '{"S3Bucket":"&&bucketName&&", "S3Key":"' + name + version + '.zip"}';
    }

    function dir(resolve:String->Dynamic, path:String){
        if(!FileSystem.exists(baseDir + path)) throw "Directory Not Found: " + baseDir + path;
        if(!FileSystem.isDirectory(baseDir + path))  throw "Is not a directory: " + baseDir + path;

        var list = FileSystem.readDirectory(baseDir + path);

        var json = "";

        for(fileName in list){
            if(fileName.charAt(0) != "-"){
                if(FileSystem.isDirectory(baseDir + path + "/" + fileName)){
                    json += dir(resolve, path + "/" + fileName);
                }
                else if(fileName.indexOf(".json") > 0){
                    var stackName = fileName.substr(0, fileName.length - 5);
                    json += '"' + stackName + '":';
                    var content = File.getContent(baseDir + path + "/" + fileName);
                    var template = new util.Template(content);
                    json += template.execute({}, this); 
                    json += ",";
                }
            }
        }
        return json;
    }

    function urlEncode(resolve:String->Dynamic, str:String):String{
        return str.urlEncode();
    }

    function escape(resolve:String->Dynamic, str:String):String{
        str = str.replace("\"", "\\\"");
        str = str.replace("\n", "");
        return str.replace("\t", "");
    }

    function base64File(resolve:String->Dynamic, path:String):String{
        var content = file(resolve, path);
        return haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(content));
    }
}