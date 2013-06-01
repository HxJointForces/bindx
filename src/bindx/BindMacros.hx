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
		
		var updated = false;
		var ctor = null;
		var hasBindings = false;
		
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
			
			updated = true;
			if (Lambda.has(f.access, AStatic)) 
				Context.error("can't bind static fields", f.pos);
			switch (f.kind) {
				case FVar(ct, e):
					f.kind = FProp("default", "set", ct, e);
					res.push(genSetter(f.name, ct, f.pos));
					
				case FProp(get, set, ct, e):
					switch (set) {
						case "never", "dynamic":
							Context.error('can\'t bind $set write-access variable', f.pos);
							
						case "default", "null":
							f.kind = FProp(get, "set", ct, e);
							res.push(genSetter(f.name, ct, f.pos));
							
						case "set":
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
									fn.expr = fn.expr.map(addBindingInSetter);
								case _: throw "setter must be function";
							}
						case _: throw "unknown setter accesssor - " + set;
					}
				case _: Context.error("only variables must be bindable", f.pos);
			}
		}
		
		if (!updated) return res;
		
		if (ctor == null) {
			Context.error("define constructor for binding support", Context.currentPos());
		}
		
		if (!hasBindings) {
			res.push( {
				name:BINDINGS_FIELD,
				pos:Context.currentPos(),
				access: [APublic],
				kind:FVar(macro : deep.events.Signal.Signal1<String>)
				
			});
		}
		
		switch (ctor.kind) {
			case FFun(f):
				f.expr = macro {
					__bindings__ = new deep.events.Signal.Signal1();
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
					$i { name } = __value__;
					__bindings__.dispatch($v{name});
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
							__bindings__.dispatch($v{setterField});
							return $e;
						}
					case _:
						macro {
							$e;
							__bindings__.dispatch($v{setterField});
							return $i{setterField};
						}
				}
				
			case _: e.map(addBindingInSetter);
		}
	}
	#end
	
}