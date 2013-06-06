package dox;

class Dox {
	static public function main() {
		var cfg = new Config();

		cfg.rootPath = Sys.getCwd() + "pages/";
		cfg.outputPath = "pages";
		cfg.xmlPath = "xml";
		#if hxtemplo
		cfg.templateDir = "templates";
		#end
		
		var argHandler = Args.generate([
			@doc("Set the document root path")
			["-r", "--document-root"] => function(path:String) cfg.rootPath = path,
			@doc("Set the output path for generated pages")
			["-o", "--output-path"] => function(path:String) cfg.outputPath = path,
			@doc("Set the xml input path")
			["-i", "--input-path"] => function(path:String) cfg.xmlPath = path,
			#if hxtemplo
			@doc("Set the template directory")
			["-t", "--template-path"] => function(path:String) cfg.templateDir = path,
			#end
			@doc("Add a resource directory whose contents are copied to the output directory")
			["-res", "--resource-path"] => function(dir:String) cfg.resourcePaths.push(dir)
		]);
		
		var args = Sys.args();
		if (args.length == 0) {
			Sys.println("Dox 1.0");
			Sys.println(argHandler.getDoc());
			Sys.exit(0);
		}
		
		argHandler.parse(args);
				
		var parser = new haxe.rtti.XmlParser();
		
		for (file in sys.FileSystem.readDirectory(cfg.xmlPath)) {
			if (!StringTools.endsWith(file, ".xml")) continue;
			var name = new haxe.io.Path(file).file;
			Sys.println('Parsing $name');
			var data = sys.io.File.getContent(cfg.xmlPath + file);
			var xml = Xml.parse(data).firstElement();
			if (name == "flash8") transformPackage(xml, "flash", "flash8");
			parser.process(xml, name);
			cfg.platforms.push(name);
		}
		
		Sys.println("Processing types");
		var proc = new Processor(cfg);
		var root = proc.process(parser.root);
		
		var api = new Api(cfg, proc.infos);
		var gen = new Generator(api);

		Sys.println("Generating navigation");
		gen.generateNavigation(root);
		
		Sys.println('Generating to ${cfg.outputPath}');
		gen.generate(root);
		
		Sys.println("");
		Sys.println('Generated ${api.infos.numGeneratedTypes} types in ${api.infos.numGeneratedPackages} packages');
		
		for (dir in cfg.resourcePaths) {
			Sys.println('Copying resources from $dir');
			for (file in sys.FileSystem.readDirectory(dir)) {
				sys.io.File.copy('$dir/$file', cfg.outputPath + file);
			}
		}
		Sys.println("Done");
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