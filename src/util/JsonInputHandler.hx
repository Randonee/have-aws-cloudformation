package util;

import sys.io.File;
import sys.FileSystem;

using StringTools;

class JsonInputHandler{

    var baseDir:String;
    public function new(baseDir:String){
        this.baseDir = baseDir;        
    }

    public function handle(str:String):Dynamic{
        var template = new util.Template(str);
        var output = template.execute({}, this);
        return haxe.Json.parse(output);
    }

    function file(resolve:String->Dynamic, path:String):String{
        if(!FileSystem.exists(baseDir + path)) throw "File Not Found: " + baseDir + path;
        var content = File.getContent(baseDir + path);
        var template = new util.Template(content);
        return template.execute({}, this);
    }

    function zipBase64(resolve:String->Dynamic, path:String):String{
        var zip = new util.Zip();
        var name = path.split("/").pop();
        zip.add(baseDir + path, name);
        return haxe.crypto.Base64.encode(zip.getBytes());
    }

    function urlEncode(resolve:String->Dynamic, str:String):String{
        return str.urlEncode();
    }

    function quoteEscape(resolve:String->Dynamic, str:String):String{
        return str.replace("\"", "\\\"");
    }

    function base64File(resolve:String->Dynamic, path:String):String{
        var content = file(resolve, path);
        return haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(content));
    }
}