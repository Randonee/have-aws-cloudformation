package util;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.zip.Entry;
import haxe.zip.Writer;
import util.JsonInputHandler;

import sys.io.File;
import sys.FileSystem;

class Zip
{
	var entries:List<Entry>;
	var handler:JsonInputHandler;

	public function new(handler)
	{
		this.handler = handler;
		entries = new List();
	}

	public function add(path:String, target:String):Void
	{
		var fullPath = handler.baseDir + path;
		if(!FileSystem.exists(fullPath))
			throw "Invalid path " + fullPath + "!";

		if(FileSystem.isDirectory(fullPath))
		{
			for(item in FileSystem.readDirectory(fullPath))
				add(fullPath + "/" + item, target + "/" + item);
		}
		else
		{
			addFile(path, target);
		}
	}

	private function addFile(path:String, target:String):Void
	{
		var bytes = Bytes.ofString(handler.parseTemplateFile(path));
		
		var entry:Entry =
		{
			fileName: target,
			fileSize: bytes.length,
			fileTime: Date.now(),
			compressed: false,
			dataSize: 0,
			data: bytes,
			crc32: Crc32.make(bytes),
			extraFields: new List()
		}
		entries.add(entry);
	}

    public function getBytes():Bytes{
        var bytesOutput = new BytesOutput();
		var writer = new Writer(bytesOutput);
		writer.write(entries);
		return bytesOutput.getBytes();
    }

	public function save(path:String):Void
	{
		var fullPath = handler.baseDir + path;
		var bytesOutput = new BytesOutput();
		var writer = new Writer(bytesOutput);
		writer.write(entries);
		var zipfileBytes = bytesOutput.getBytes();
		var file = File.write(fullPath, true);
		file.write(zipfileBytes);
		file.close();
	}
}