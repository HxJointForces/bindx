package bindx;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class BindMacros
{

	#if macro
	static inline var BINDINGS_FIELD = "__bindings__";
	static inline var BINDING_META = "bindable";
	
	#end
	
	public static function build():Array<Field> {
		
		var res:Array<Field> = Context.getBuildFields();
		
		var ctor = null;
		var hasBindings = false;
		
		var bindables = [];
		for (f in res) {
			if (f.name == "new") ctor = f;
			if (f.name == BINDINGS_FIELD) hasBindings = true;
			
			var meta = null;
			if (f.meta != null)
				for (m in f.meta)
					if (m.name == BINDING_META) {
						meta = m;  // TODO: @bindable("foo") support
						break;
					}
			if (meta == null) continue;
			
			if (Lambda.has(f.access, AStatic)) 
				Context.error("can't bind static fields", f.pos);
			switch (f.kind) {
				case FVar(ct, e):
					f.kind = FProp("default", "set", ct, e);
					res.push(genSetter(f.name, ct, f.pos));
					bindables.push(f.name);
					
				case FProp(get, set, ct, e):
					switch (set) {
						case "never", "dynamic":
							Context.error('can\'t bind $set write-access variable', f.pos);
							
						case "default", "null":
							f.kind = FProp(get, "set", ct, e);
							res.push(genSetter(f.name, ct, f.pos));
							bindables.push(f.name);
							
						case "set":
							f.kind = FProp(get, set, ct, e);
							
							var methodName = "set_" + f.name;
							var setter = null;
							for (f in res) if (f.name == methodName) {
								setter = f;
								break;
							}
							if (setter == null) 
								Context.error("can't find setter", f.pos);
							
							switch (setter.kind) {
								case FFun(fn):
									setterField = f.name;
									fn.ret = ct;
									var arg = fn.args[0];
									arg.type = ct;
									fn.expr = macro {
										var __oldValue__ = $i { f.name };
										${fn.expr.map(addBindingInSetter)};
									}
									
								case _: throw "setter must be function";
							}
							bindables.push(f.name);
						case _: throw "unknown setter accesssor - " + set;
					}
				case _: Context.error("only variables must be bindable", f.pos);
			}
		}
		
		if (bindables.length == 0) return res;
		
		if (ctor == null) {
			Context.error("define constructor for binding support", Context.currentPos());
		}
		
		if (!hasBindings) {
			res.push( {
				name:BINDINGS_FIELD,
				pos:Context.currentPos(),
				access: [APublic],
				kind:FVar(macro : bindx.BindingSignal)
				
			});
		}
		
		switch (ctor.kind) {
			case FFun(f):
				f.expr = macro {
					$i { BINDINGS_FIELD } = new bindx.BindingSignal();
					${f.expr}
				}
			case _:
		}
		
		return res;
	}
	
	#if macro
	
	static private function genSetter(name:String, type:ComplexType, pos:Position):Field 
	{
		return {
			name: "set_" + name,
			pos: pos,
			access: [APrivate],
			kind:FFun( {
				ret:type,
				params:[],
				args:[{name:"__value__", opt:false, type:type}],
				expr: macro {
					var __oldValue__ = $i { name };
					$i { name } = __value__;
					__bindings__.dispatch($v{name}, __oldValue__, $i{name});
					return __value__;
				}
			})
		}
	}
	
	static var setterField:String;
	
	static function addBindingInSetter(e:Expr):Expr {
		return switch (e.expr) {
			case EReturn(e) :
				
				switch (e.expr) {
					case EConst(c):
						macro {
							__bindings__.dispatch($v{setterField}, __oldValue__, $i{setterField});
							return $e;
						}
					case _:
						macro {
							${e.map(addBindingInSetter)};
							__bindings__.dispatch($v{setterField}, __oldValue__, $i{setterField});
							return $i{setterField};
						}
				}
				
			case _: e.map(addBindingInSetter);
		}
	}
	#end
	
}