package bindx;

import haxe.macro.Type;
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
	static public inline var BINDING_INTERFACE_NAME = "bindx.IBindable";
	
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
				
				if (!f.access.has(APublic))
					continue;
					
				switch (f.kind) {
					case FVar(_, _):
						f.meta.push( { name:BINDING_META_NAME, params:[], pos:f.pos } );
						toBind.push(f);
					case FProp(_, set, _, _):
						if (set == "default" || set == "set") {
							f.meta.push( { name:BINDING_META_NAME, params:[], pos:f.pos } );
							toBind.push(f);
						}
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
			
			var force = false;
			var inlineSetter = true;
			for (m in f.meta) {
				if (m.name == BINDING_META_NAME) {
					for (p in m.params) {
						switch (p.expr) {
							case EObjectDecl(fields):
								for (f in fields) {
									switch (f.field) {
										case "inlineSetter": inlineSetter = expr2Bool(f.expr);
										case "force": force = expr2Bool(f.expr);
									}
								}
							case _: Context.error("unsupported parameters in @bindable() meta", f.pos);
						}
					}
					break;
				}
			}
					
			switch (f.kind) {
				
				case FFun(fun):
					if (fun.ret == null)
						Context.error("unknown return type", f.pos);
					if (fun.ret.toString() == "Void")
						Context.error("can't bind Void function", f.pos);
					continue;
					
				case FVar(ct, e):
					if (force) continue;
					f.kind = FProp("default", "set", ct, e);
					add.push(genSetter(f.name, ct, f.pos, inlineSetter));
					
				case FProp(get, set, ct, e):
					if (force) continue;
							
					switch (set) {
						case "never", "dynamic", "null":
							Context.error('can\'t bind "$set" write-access variable. Use @bindable({force:true})', f.pos);
							
						case "default":
							f.kind = FProp(get, "set", ct, e);
							add.push(genSetter(f.name, ct, f.pos, inlineSetter));
							
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
									var fieldName = fn.args[0].name;
									fn.expr = macro {
										var $OLD_VALUE_NAME = $i { f.name };
										if ($i { fieldName } == $i{OLD_VALUE_NAME}) return $i{OLD_VALUE_NAME};
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
	
	inline static function expr2Bool(expr:Expr):Bool {
		return switch (expr.expr) {
			case EConst(CIdent("true")): true;
			case EConst(CIdent("false")): false;
			case _: Context.error("expr must be bool value", expr.pos);
		}
	}
	
	inline static function checkField(f:Field) {
		for (a in f.access) {
			switch (a) {
				case AStatic: Context.error("can't bind static fields", f.pos);
				case AMacro: Context.error("can't bind macro fields", f.pos);
				case ADynamic: Context.error("can't bind dynamic fields", f.pos);
				case AInline: Context.error("can't bind inline fields", f.pos);
				case _:
			}
		}
	}
	
	inline static private function genSetter(name:String, type:ComplexType, pos:Position, inlineSetter:Bool):Field 
	{
		var old = macro $i { OLD_VALUE_NAME };
		var val = macro $i { VALUE_NAME };
		var access = [APrivate];
		if (inlineSetter) access.push(AInline);
		return {
			name: "set_" + name,
			pos: pos,
			access: access,
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
	
	static function addBindingInSetter(expr:Expr):Expr {
		return switch (expr.expr) {
			case EReturn(e) :
				if (e == null) Context.error("setter must return value", expr.pos);
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
				
			case _: expr.map(addBindingInSetter);
		}
	}

	public static function isIBindable(classType:ClassType) {
		while (classType != null) {
			if (classType.interfaces.exists(
				function (i) return i.t.toString() == BINDING_INTERFACE_NAME)
			) return true;

			classType = classType.superClass != null ? classType.superClass.t.get() : null;
		}
		return false;
	}
	#end
	
}