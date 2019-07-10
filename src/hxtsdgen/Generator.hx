package hxtsdgen;

import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;

enum ExposeKind {
    EClass(c:ClassType);
    EEnum(c:ClassType);
    ETypedef(t:DefType, anon:AnonType);
    EMethod(c:ClassType, cf:ClassField);
}

class Generator {

    public static inline var GEN_ENUM_TS = #if hxtsdgen_enums_ts true #else false #end;
    public static var SKIP_HEADER = #if hxtsdgen_skip_header true #else false #end;
    public static var HEADER = "// Generated by Haxe TypeScript Declaration Generator :)";
    public static var NO_EXPOSE_HINT = "// No types were @:expose'd.\n// Read more at http://haxe.org/manual/target-javascript-expose.html";

    static function use() {
        if (Context.defined("display") || !Context.defined("js"))
            return;

        Context.onGenerate(new Generator().onGenerate);
    }

    static function setHeader(header:String) {
        HEADER = header;
    }

    var outName:String;
    var outDTS:String;
    var outETS:String;
    var selector:Selector;

    function new() {
    }

    public function onGenerate(types:Array<Type>) {
        var outJS = Compiler.getOutput();
        var outPath = Path.directory(outJS);
        outName = Path.withoutDirectory(Path.withoutExtension(outJS));
        outDTS = Path.join([outPath, outName + ".d.ts"]);
        outETS = Path.join([outPath, outName + "-enums.ts"]);

        selector = createSelector();
        var exposed = selector.getExposed(types);

        if (exposed == 0) {
            var src = NO_EXPOSE_HINT;
            if (!SKIP_HEADER) src = HEADER + "\n\n" + src;
            sys.io.File.saveContent(outDTS, src);
        } else {
            Context.onAfterGenerate(onAfterGenerate);
        }
    }

    function onAfterGenerate() {
        var codeGen = createCodeGen();
        var declarations = codeGen.generate();

        if (GEN_ENUM_TS && declarations.ets.length > 0) {
            if (!SKIP_HEADER) declarations.ets.unshift(HEADER);
            sys.io.File.saveContent(outETS, declarations.ets.join("\n\n"));

            // import enum from the d.ts
            var exports = declarations.exports.join(', ');
            declarations.dts.unshift('import { $exports } from "./$outName-enums";');
        }

        if (declarations.dts.length > 0) {
            if (!SKIP_HEADER) declarations.dts.unshift(HEADER);
            sys.io.File.saveContent(outDTS, declarations.dts.join("\n\n"));
        }
    }

    function createSelector() {
        return new Selector();
    }

    function createCodeGen() {
        return new CodeGen(selector);
    }
}
