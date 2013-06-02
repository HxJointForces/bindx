package bindx;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using Lambda;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class BindMacros
{

	#if macro
	static public inline var BINDINGS_FIELD = "__fieldBindings__";
	static public inline var BINDINGS_METHOD = "__methodBindings__";
	static public inline var BINDING_META = "bindable";
	#end
	
	public static function build():Array<Field> {
		
		var res = Context.getBuildFields();
		
		var type = Context.getLocalClass();
		var classType = type.get();
		var toBind = [];
		var ctor = null;
		var hasBindings = false;
		
		if (classType.meta.get().exists(function (m) return m.name == BINDING_META)) {

			var ignoreAccess = [APrivate, AStatic, ADynamic, AMacro];
			// first step
			for (f in res) {
				if (f.name == "new") {
					ctor = f;
					continue;
				}
				if (f.name == BINDINGS_FIELD) hasBindings = true;
				
				if (f.meta.exists(function (m) return m.name == BINDING_META)) {
					checkField(f);
					toBind.push(f);
					continue;
				}
				
				if (f.access.exists(function (a) return ignoreAccess.has(a))) {
					continue;
				}
				
				switch (f.kind) {
					case FProp(_, _, _, _), FVar(_, _):
						f.meta.push( { name:BINDING_META, params:[], pos:f.pos } );
						toBind.push(f);
					case FFun(_):
				}
			}
		} else {
			
			for (f in res) {
				if (f.name == "new") {
					ctor = f;
					continue;
				}
				if (f.name == BINDINGS_FIELD) hasBindings = true;
				
				if (!f.meta.exists(function (m) return m.name == BINDING_META))
					continue;
				
				checkField(f);
				
				toBind.push(f);
			}
		}
		
		var updated = false;
		
		var add = [];
		for (f in toBind) {
			
			switch (f.kind) {
				case FFun(fun):
					if (fun.ret == null)
						Context.error("unknown return type", f.pos);
					if (fun.ret.toString() == "Void")
						Context.error("can't bind Void function", f.pos);
					continue;
				case _:
			}
				
			switch (f.kind) {
				case FVar(ct, e):
					f.kind = FProp("default", "set", ct, e);
					add.push(genSetter(f.name, ct, f.pos));
					updated = true;
					
				case FProp(get, set, ct, e):
					switch (set) {
						case "never", "dynamic":
							Context.error('can\'t bind $set write-access variable', f.pos);
							
						case "default", "null":
							f.kind = FProp(get, "set", ct, e);
							add.push(genSetter(f.name, ct, f.pos));
							updated = true;
							
						case "set":
							f.kind = FProp(get, set, ct, e);
							
							var methodName = "set_" + f.name;
							var setter = null;
							for (f in res) if (f.name == methodName) {
								setter = f;
								break;
							}
							if (setter == null) 
								Context.error("can't find setter: " + methodName, f.pos);
							
							switch (setter.kind) {
								case FFun(fn):
									setterField = f.name;
									fn.expr = macro {
										var __oldValue__ = $i { f.name };
										${fn.expr.map(addBindingInSetter)};
									}
									
								case _: Context.error("setter must be function", setter.pos);
							}
							updated = true;
							
						case _: Context.warning("unknown setter accesssor: " + set, f.pos);
					}
				case _: // functions
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
				kind:FVar(macro : bindx.BindSignal)
			});
			res.push( {
				name:BINDINGS_METHOD,
				pos:Context.currentPos(),
				access: [APublic],
				kind:FVar(macro : bindx.BindSignal)
			});
		}
		
		switch (ctor.kind) {
			case FFun(f):
				f.expr = macro {
					$i { BINDINGS_FIELD } = new bindx.BindSignal();
					$i { BINDINGS_METHOD } = new bindx.BindSignal();
					${f.expr}
				}
			case _:
		}
		
		return res.concat(add);
	}
	
	#if macro
	
	inline static function checkField(f:Field) {
		for (a in f.access) {
			switch (a) {
				case AStatic: Context.error("can't bind static fields", f.pos);
				//case AInline: Context.error("can't bind inline fields", f.pos);
				case AMacro: Context.error("can't bind macro fields", f.pos);
				case ADynamic: Context.error("can't bind dynamic fields", f.pos);
				case _:
			}
		}
	}
	
	inline static private function genSetter(name:String, type:ComplexType, pos:Position):Field 
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
					if (__oldValue__ == __value__) return __value__;
					$i { name } = __value__;
					$i{ BINDINGS_FIELD }.dispatch($v { name }, __oldValue__, $i { name } );
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
							$i{ BINDINGS_FIELD }.dispatch($v{setterField}, __oldValue__, $i{setterField});
							return $e;
						}
					case _:
						macro {
							${e.map(addBindingInSetter)};
							$i{ BINDINGS_FIELD }.dispatch($v{setterField}, __oldValue__, $i{setterField});
							return $i{setterField};
						}
				}
				
			case _: e.map(addBindingInSetter);
		}
	}
	#end
	
}