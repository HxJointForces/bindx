package bindx;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

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
	
	static var bindableType:ComplexType;
	static var bindablePath:TypePath;
	
	static function buildBindableType() {
		bindableType = macro : bindx.Bindable;
		switch (bindableType) {
			case TPath(p): bindablePath = p;
			case _: throw "assert";
		}
	}
	
	static function generateBindableType(type:Null<ComplexType>):ComplexType {
		if (type == null) return bindableType;
		return TPath( { 
			pack: bindablePath.pack,
			name: bindablePath.name,
			params: [TPType(type)],
			sub: bindablePath.sub
			});
	}
	#end
	
	public static function build():Array<Field> {
		var res:Array<Field> = Context.getBuildFields();
		
		if (bindableType == null) buildBindableType();
		
		var updated = false;
		
		for (f in res) {
			
			var found = false;
			if (f.meta != null)
				for (m in f.meta)
					if (m.name == BINDING_META) {
						found = true;
						break;
					}
			if (!found) continue;
			
			updated = true;
			if (Lambda.has(f.access, AStatic)) 
				Context.error("can't bind static fields", f.pos);
			switch (f.kind) {
				case FVar(ct, e):
					ct = generateBindableType(ct);
					f.kind = FProp("default", "set", ct, e);
					res.push(genSetter(f.name, ct, f.pos));
					
				case FProp(get, set, ct, e):
					switch (set) {
						case "never", "dynamic":
							Context.error('can\'t bind $set write-access variable', f.pos);
							
						case "default", "null":
							ct = generateBindableType(ct);
							f.kind = FProp(get, "set", ct, e);
							res.push(genSetter(f.name, ct, f.pos));
							
						case "set":
							ct = generateBindableType(ct);
							trace(ct);
							var methodName = "set_" + f.name;
							var setter = null;
							for (f in res) if (f.name == methodName) {
								setter = f;
								break;
							}
							if (setter == null) 
								Context.error("can't find setter", f.pos);
							
							f.kind = FProp(get, "set", ct, e);
								
							setter.name = "def_" + setter.name;
							var name = f.name;
							
							res.push({
								name: "set_" + name,
								pos: f.pos,
								access: [APrivate],
								kind:FFun( {
									ret:ct,
									params:[],
									args:[{name:"__value__", opt:false, type:ct}],
									expr: macro {
										
										var oldValue = $i { name };
										__value__ = $i { setter.name } (__value__);
										if (oldValue != null) {
											oldValue.setValue(__value__);
											$i { name } = oldValue;
										}
										$i { name } .__dispatch__();
										return __value__;
									}
								})
							});
						case _: throw "unknown setter accesssor - " + set;
					}
				case _: Context.error("only variables must be bindable", f.pos);
			}
		}
		
		if (!updated) return res;
		
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
					if ($i{name} == null)
						$i { name } = __value__;
					else 
						$i { name } .setValue(__value__);
					$i { name } .__dispatch__();
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
							//__bindings__.dispatch($v{setterField});
							return $e;
						}
					case _:
						macro {
							$e;
							//__bindings__.dispatch($v{setterField});
							return $i{setterField};
						}
				}
				
			case _: e.map(addBindingInSetter);
		}
	}
	#end
	
}