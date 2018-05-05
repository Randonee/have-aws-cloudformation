package util;

import sys.io.File;

class JsonInputHandler{

    var baseDir:String;
    public function new(baseDir:String){
        this.baseDir = baseDir;        
    }

    public function handle(str:String):Dynamic{
        var splitter = ~/(:::[A-Za-z0-9_ ()&|!+=\/><*."-]+:::|\$\$([A-Za-z0-9_-]+)\()/;
        var oldSplitter = Reflect.field(haxe.Template, "splitter");
        Reflect.setField(haxe.Template, "splitter", splitter);
        var template = new haxe.Template(str);
        var output = template.execute({}, this);
        Reflect.setField(haxe.Template, "splitter", oldSplitter);
        return haxe.Json.parse(output);
    }

    function file(resolve:String->Dynamic, path:String):String{
        var content = File.getContent(baseDir + path);
        var template = new haxe.Template(content);
        return template.execute({}, this);
    }

    function base64File(resolve:String->Dynamic, path:String):String{
        var content = file(resolve, path);
        return haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(content));
    }
}