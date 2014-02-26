package dox;

class Dox {
	static public function main() {
		// check if we're running from haxelib (last arg is original working dir)
		var owd = Sys.getCwd();
		var args = Sys.args();
		var last = new haxe.io.Path(args[args.length-1]).toString();
		if (sys.FileSystem.exists(last) && sys.FileSystem.isDirectory(last)
		    && (args.length < 2 || args[args.length - 2].charCodeAt(0) != "-".code))
		{
			args.pop();
			Sys.setCwd(last);
		}

		var cfg = new Config();

		cfg.resourcePaths.push(owd + "resources");
		cfg.outputPath = "pages";
		cfg.xmlPath = "xml";
		cfg.addTemplatePath(owd + "templates");
		cfg.addTemplatePath("templates");
		
		var argHandler = hxargs.Args.generate([
			@doc("Set the document root path")
			["-r", "--document-root"] => function(path:String) cfg.rootPath = path,
			
			@doc("Set the output path for generated pages")
			["-o", "--output-path"] => function(path:String) cfg.outputPath = path,
			
			@doc("Set the xml input path")
			["-i", "--input-path"] => function(path:String) cfg.xmlPath = path,
			
			@doc("Add template directory")
			["-t", "--template-path"] => function(path:String) cfg.addTemplatePath(path),
			
			@doc("Add a resource directory whose contents are copied to the output directory")
			["-res", "--resource-path"] => function(dir:String) cfg.resourcePaths.push(dir),
			
			@doc("Add a path include filter")
			["-in", "--include"] => function(regex:String) cfg.addFilter(regex, true),
			
			@doc("Add a path exclude filter")
			["-ex", "--exclude"] => function(regex:String) cfg.addFilter(regex, false),
			
			@doc("Set the page main title")
			["--title"] => function(name:String) cfg.pageTitle = name,
			
			_ => function(arg:String) throw "Unknown command: " +arg
		]);
				
		if (args.length == 0) {
			Sys.println("Dox 1.0");
			Sys.println(argHandler.getDoc());
			Sys.exit(0);
		}
		
		argHandler.parse(args);
			
		if (cfg.rootPath == null && cfg.outputPath != null) {
			cfg.rootPath = cfg.outputPath;
		}
		
		try {
			if (!sys.FileSystem.exists(cfg.outputPath))
				sys.FileSystem.createDirectory(cfg.outputPath);
		} catch (e:Dynamic) {
			Sys.println('Could not create output directory ${cfg.outputPath}');
			Sys.println(Std.string(e));
			Sys.exit(1);
		}
		
		if (!sys.FileSystem.exists(cfg.xmlPath)) {
			Sys.println('Could not read input path ${cfg.xmlPath}');
			Sys.exit(1);
		}
		var parser = new haxe.rtti.XmlParser();
		
		var tStart = haxe.Timer.stamp();
		
		function parseFile(path) {
			var name = new haxe.io.Path(path).file;
			Sys.println('Parsing $path');
			var data = sys.io.File.getContent(path);
			var xml = try Xml.parse(data).firstElement() catch(err:Dynamic) {
				trace('Error while parsing $path');
				throw err;
			};
			if (name == "flash8") transformPackage(xml, "flash", "flash8");
			parser.process(xml, name);
			cfg.platforms.push(name);
		}
		
		if (sys.FileSystem.isDirectory(cfg.xmlPath)) {
			for (file in sys.FileSystem.readDirectory(cfg.xmlPath)) {
				if (!StringTools.endsWith(file, ".xml")) continue;
				parseFile(cfg.xmlPath + "/" +file);
			}
		} else {
			parseFile(cfg.xmlPath);
		}
		
		Sys.println("Processing types");
		var proc = new Processor(cfg);
		var root = proc.process(parser.root);
		
		var api = new Api(cfg, proc.infos);
		var gen = new Generator(api, cfg);
		
		Sys.println("");
		Sys.println("Generating navigation");
		gen.generateNavigation(root);
		
		Sys.println('Generating to ${cfg.outputPath}');
		gen.generate(root);
		
		Sys.println("");
		Sys.println('Generated ${api.infos.numGeneratedTypes} types in ${api.infos.numGeneratedPackages} packages');
		
		for (dir in cfg.resourcePaths) {
			Sys.println('Copying resources from $dir');
			for (file in sys.FileSystem.readDirectory(dir)) {
				sys.io.File.copy('$dir/$file', cfg.outputPath + "/" + file);
			}
		}
		
		var elapsed = Std.string(haxe.Timer.stamp() - tStart).substr(0, 5);
		Sys.println('Done (${elapsed}s)');
	}
	
	static function transformPackage(x:Xml, p1, p2) {
		switch( x.nodeType ) {
		case Xml.Element:
			var p = x.get("path");
			if( p != null && p.substr(0,6) == p1 + "." )
				x.set("path",p2 + "." + p.substr(6));
			for( x in x.elements() )
				transformPackage(x,p1,p2);
		default:
		}
	}
}