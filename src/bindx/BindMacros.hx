package bindx;

import haxe.macro.Type.ClassType;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using Lambda;

/**
 * @author deep <system.grand@gmail.com>
 */
class BindMacros
{

	#if macro
	static public inline var OLD_VALUE_NAME = "__oldValue__";
	static public inline var VALUE_NAME = "__value__";
	static public inline var FIELD_BINDINGS_NAME = "__fieldBindings__";
	static public inline var METHOD_BINDINGS_NAME = "__methodBindings__";
	static public inline var BINDING_META_NAME = "bindable";

	static var processed:Map<String, Bool> = new Map();
	#end
	
	public static function build():Array<Field> {

		var res = Context.getBuildFields();
		
		var type = Context.getLocalClass();
		var typeName = type.toString();
		if (processed.exists(typeName)) return res;
		processed[typeName] = true;

		var classType:ClassType = type.get();

		var injectSignals = if (classType.superClass != null)
			!isIBindable(classType.superClass.t.get())
			else true;

		var toBind = [];
		var ctor = null;
		var hasBindings = false;

		if (classType.meta.get().exists(function (m) return m.name == BINDING_META_NAME)) {
			var ignoreAccess = [APrivate, AStatic, ADynamic, AMacro];

			for (f in res) {
				if (f.name == "new") {
					ctor = f;
					continue;
				}
				if (f.name == FIELD_BINDINGS_NAME) hasBindings = true;
				
				if (f.meta.exists(function (m) return m.name == BINDING_META_NAME)) {
					checkField(f);
					toBind.push(f);
					continue;
				}
				
				if (f.access.exists(function (a) return ignoreAccess.has(a)))
					continue;
				
				switch (f.kind) {
					case FProp(_, _, _, _), FVar(_, _):
						f.meta.push( { name:BINDING_META_NAME, params:[], pos:f.pos } );
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
				if (f.name == FIELD_BINDINGS_NAME) hasBindings = true;
				
				if (!f.meta.exists(function (m) return m.name == BINDING_META_NAME))
					continue;
				
				checkField(f);
				toBind.push(f);
			}
		}
		
		if (injectSignals && ctor == null) {
			Context.error(
				"define constructor for binding support",
				res.length > 0 ? res[0].pos : Context.currentPos()
			);
		}
		
		var add = [];
		for (f in toBind) {
			
			switch (f.kind) {
				
				case FFun(fun):
					if (fun.ret == null)
						Context.error("unknown return type", f.pos);
					if (fun.ret.toString() == "Void")
						Context.error("can't bind Void function", f.pos);
					continue;
					
				case FVar(ct, e):
					f.kind = FProp("default", "set", ct, e);
					add.push(genSetter(f.name, ct, f.pos));
					
				case FProp(get, set, ct, e):
					switch (set) {
						case "never", "dynamic":
							Context.error('can\'t bind $set write-access variable', f.pos);
							
						case "default", "null":
							f.kind = FProp(get, "set", ct, e);
							add.push(genSetter(f.name, ct, f.pos));
							
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
										var $OLD_VALUE_NAME = $i { f.name };
										${fn.expr.map(addBindingInSetter)};
									}
									
								case _: Context.error("setter must be function", setter.pos);
							}
							
						case _: Context.warning("unknown setter accesssor: " + set, f.pos);
					}
			}
		}

		if (injectSignals) {
			if (!hasBindings) {
				res.push( {
					name:FIELD_BINDINGS_NAME,
					pos:Context.currentPos(),
					access: [APublic],
					kind:FProp("default", "null", macro : bindx.BindSignal.FieldsBindSignal)
				});
				res.push( {
					name:METHOD_BINDINGS_NAME,
					pos:Context.currentPos(),
					access: [APublic],
					kind:FProp("default", "null", macro : bindx.BindSignal.MethodsBindSignal)
				});
			}

			switch (ctor.kind) {
				case FFun(f):
					f.expr = macro {
						$i { FIELD_BINDINGS_NAME } = new bindx.BindSignal.FieldsBindSignal();
						$i { METHOD_BINDINGS_NAME } = new bindx.BindSignal.MethodsBindSignal();
						${f.expr}
					}
				case _:
			}
		}

		return res.concat(add);
	}
	
	#if macro
	
	inline static function checkField(f:Field) {
		for (a in f.access) {
			switch (a) {
				case AStatic: Context.error("can't bind static fields", f.pos);
				case AMacro: Context.error("can't bind macro fields", f.pos);
				case ADynamic: Context.error("can't bind dynamic fields", f.pos);
				case _:
			}
		}
	}
	
	inline static private function genSetter(name:String, type:ComplexType, pos:Position):Field 
	{
		var old = macro $i { OLD_VALUE_NAME };
		var val = macro $i { VALUE_NAME };
		return {
			name: "set_" + name,
			pos: pos,
			access: [APrivate, AInline],
			kind:FFun( {
				ret:type,
				params:[],
				args:[{name:VALUE_NAME, opt:false, type:type}],
				expr: macro {
					var $OLD_VALUE_NAME = $i { name };
					if ($old == $val) return $val;
					else {
						$i { name } = $val;
						$i{ FIELD_BINDINGS_NAME }.dispatch($v { name }, $old, $i { name } );
						return $val;
					}
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
							$i{ FIELD_BINDINGS_NAME }.dispatch($v{setterField}, $i{ OLD_VALUE_NAME }, $i{setterField});
							return $e;
						}
					case _:
						macro {
							${e.map(addBindingInSetter)};
							$i{ FIELD_BINDINGS_NAME }.dispatch($v{setterField}, $i{ OLD_VALUE_NAME }, $i{setterField});
							return $i{setterField};
						}
				}
				
			case _: e.map(addBindingInSetter);
		}
	}

	public static function isIBindable(classType:ClassType) {
		while (classType != null) {
			if (classType.interfaces.exists(
				function (i) return i.t.toString() == "bindx.IBindable")
			) return true;

			classType = classType.superClass != null ? classType.superClass.t.get() : null;
		}
		return false;
	}
	#end
	
}