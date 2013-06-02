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
	static public inline var BINDINGS_FIELD = "__bindings__";
	static public inline var BINDING_META = "bindable";
	#end
	
	public static function build():Array<Field> {
		
		var res:Array<Field> = Context.getBuildFields();
		
		var ctor = null;
		var hasBindings = false;
		var updated:Bool = false;
		
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
				Context.warning("can't bind static fields", f.pos);
			
			switch (f.kind) {
				case FVar(ct, e):
					f.kind = FProp("default", "set", ct, e);
					res.push(genSetter(f.name, ct, f.pos));
					updated = true;
					
				case FProp(get, set, ct, e):
					switch (set) {
						case "never", "dynamic":
							Context.warning('can\'t bind $set write-access variable', f.pos);
							
						case "default", "null":
							f.kind = FProp(get, "set", ct, e);
							res.push(genSetter(f.name, ct, f.pos));
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
		}
		
		switch (ctor.kind) {
			case FFun(f):
				f.expr = macro {
					$i { BINDINGS_FIELD } = new bindx.BindSignal();
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