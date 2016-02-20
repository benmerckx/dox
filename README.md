# Dox
A Haxe documentation generator used by many popular projects such as:

- [Haxe](http://api.haxe.org/)
- [OpenFL](http://www.openfl.org/documentation/api/)
- [HaxeUI](http://haxeui.org/docs/api/haxe/ui/toolkit/index.html)
- [HaxeFlixel](http://api.haxeflixel.com/)
- [HaxePunk](http://haxepunk.com/documentation/api/)
- [Flambe](https://aduros.com/flambe/api/)
- [Kha](http://api.kha.technology/)

![](http://i.imgur.com/aQKBPsj.png)

### Installation

Install the library via [haxelib](http://lib.haxe.org/p/dox):
``` 
haxelib install dox 
```

### Usage

> **Note:** Dox requires Haxe 3.1 or higher due to some minor changes in 
abstract rtti xml generation. You'll also need an up-to-date haxelib 
(requires support for `classPath` in _haxelib.json_)

1. Compile all relevant code with Haxe using `haxe -xml dir`.
2. Invoke `haxelib run dox -i dir`, where dir points to the .xml file(s) generated by step 1.

##### Example: Generating Haxe standard library documentation:

	haxelib install hxcpp
	haxelib install hxjava
	haxelib install hxcs

	haxelib dev dox .

	// Compile dox's run.n
	haxe run.hxml
	
	// Generate .xml files of Haxe standard library
	haxe gen.hxml
	
	// Generate documentation
	haxe std.hxml

### Compiling Dox

This is only required if you want to modify any of the `.hx` sources.

Install dependencies

	haxelib git hxparse https://github.com/Simn/hxparse development src
	haxelib git hxtemplo https://github.com/Simn/hxtemplo master src
	haxelib install hxargs
	haxelib install markdown

Compile run.n:

	haxe run.hxml

### Testing

Dox currently has a non-automated test. Run `haxe test.hxml` or execute the steps individually:

	haxe gen-test.hxml
	haxe pages.hxml
	cd bin/pages
	nekotools server

Open `localhost:2000` in your browser and navigate to the types defined in `test/TestClass.hx` (`TestClass`, `TestTypeDef` etc..) to check whether the output looks as expected.
