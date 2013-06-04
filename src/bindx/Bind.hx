package bindx;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import bindx.BindSignal;

using haxe.macro.Tools;
using Lambda;

/**
 * @author deep <system.grand@gmail.com>
 */

typedef FieldCall = {
	var e:Expr;
	var f:String;
	var eType:ClassField;
	var se:Array<String>;
}

typedef MapKey = {
	var name:Expr;
	var value:Expr;
}

class Bind {

	macro static public function bindx2(expr:Expr, listener:Expr) {
		var fields:Array<FieldCall> = [];
		
		var callStack = checkField2(expr, fields);
		
		
		trace("");
		trace(fields.join("\n\n"));
		
		checkFunction(listener, fields[fields.length - 1].eType, true);

		var first = fields.shift();
		
		var keys:Array<MapKey> = [];
		var listeners:Array<MapKey> = [];
		
		var res = [];
		var listenerName = "listener0";
		res.push(macro $i { listenerName } = $listener);
		
		var i = 1;
		listenerName = "listener" + i;
		res.push(getBindMacro(first, macro $i{listenerName}));
		
		for (f in fields) {
			
			var nextListenerName = i == fields.length ? macro listener0 : macro $i { "listener" + (i + 1) };
			var fieldName = f.f;
			var se = callStack.slice(f.se.length).join(".");
			var fullPath = fieldName + (se.length > 0 ? "." + se : "");
			keys.push( { name:macro $i{listenerName}, value:macro null } );
			listeners.push( { name:macro $i{listenerName}, value:macro null } );
			
			var lst = macro
				function $listenerName(o, n) {
					o.__fieldBindings__.remove($v{fieldName}, $nextListenerName);
					listeners.remove($nextListenerName);
				n.__fieldBindings__.add($v{fieldName}, $nextListenerName);
					listeners[$nextListenerName] = n.$fieldName;
					
					if (n.$fieldName != null)
						try {
							$nextListenerName(o.$fieldName != null ? o.$fullPath : null, n.$fullPath);
						} catch (e:Dynamic) {}
				}
			
			res.push(lst);
			i++;
			listenerName = "listener" + i;
		}
		
		trace(keys);
		trace(listeners);
		trace("");
		for (b in res) {
			trace(b.toString());
			trace("");
		}
		
		
		return macro {};
	}
	#if macro
	
	static private function getBindMacro(field:FieldCall, listener:Expr) {
		return switch (field.eType.kind) {
			case FVar(_,_):
				macro ${field.e}.__fieldBindings__.add($v { field.f }, $listener);
			case FMethod(_):
				macro ${field.e}.__methodBindings__.add($v { field.f }, $listener);
		}
	}
	
	static private function checkField2(expr:Expr, fields:Array<Dynamic>, depth:Int = 0):Array<String> {
		
		switch (expr.expr) {
			
			case EField(e, f):
				
				var type = Context.typeof(e);
				var classField:ClassField = null;
				
				switch (type) {
					
					case TInst(t, _): 
						var classType = t.get();
						
						if (!BindMacros.isIBindable(classType)) {
							if (depth == 0)
								Context.error("can't bind expr", e.pos);
							else
								Context.warning('"${e.toString()}" must be bindx.IBindable', e.pos);
						}

						while (classType != null) {
							for (cf in classType.fields.get()) {
								if (cf.name == f) {
									if (!cf.meta.has(BindMacros.BINDING_META_NAME)) {
										Context.warning('field "${e.toString()}.$f" is not bindable', expr.pos);
									}
									classField = cf;
									break;
								}
							}
							if (classField != null) break;
							classType = classType.superClass != null ? classType.superClass.t.get() : null;
						}
					
					case _:
						if (depth == 0)
							Context.error('can\'t bind expr "${expr.toString()}"', e.pos);
						else
							Context.warning('"${e.toString()}" must be bindx.IBindable', e.pos);
				}
				var se = checkField2(e, fields, depth + 1).copy();
				se.push(f);
				
				fields.push( { e:e, f:f, eType:classField, se:se } );
				return se;
				
			case EConst(CIdent(_)): 
				if (depth == 0)
					Context.error('first parameter must be field call', expr.pos);
					
				return [expr.toString()];
			case _ : 
				trace(depth);
				trace(expr);
				Context.error('first parameter must be field call', expr.pos);
				return null;
		}
	}
	#end
	
	inline static public function bindxGlobal<T>(bindable:IBindable, listener:GlobalFieldListener<T>) {
		bindable.__fieldBindings__.addGlobal(listener);
	}
	
	inline static public function unbindxGlobal<T>(bindable:IBindable, listener:GlobalFieldListener<T>) {
		bindable.__fieldBindings__.removeGlobal(listener);
	}
	
	macro static public function bindx(field:Expr, listener:Expr) {
		var field = fieldBinding(field, listener, true);
		return switch (field.classField.kind) {
			case FVar(_,_):
				macro ${field.e}.__fieldBindings__.add($v { field.f }, $listener);
			case FMethod(_):
				macro ${field.e}.__methodBindings__.add($v { field.f }, $listener);
		}
		
	}
	
	macro static public function unbindx(field:Expr, listener:Expr) {
		var field = fieldBinding(field, listener, false);
		return switch (field.classField.kind) {
			case FVar(_,_):
				macro ${field.e}.__fieldBindings__.remove($v { field.f }, $listener);
			case FMethod(_):
				macro ${field.e}.__methodBindings__.remove($v { field.f }, $listener);
		}
	}
	
	macro static public function notify(field:Expr) {
		var f = checkField(field);
		return switch (f.classField.kind) {
			case FMethod(_):
				switch (f.classField.type.follow()) {
					case TFun(_, ret):
						if (ret.toString() == "Void")
							Context.error("can't notify Void return function", field.pos);
					case _:
				}
				macro $ { f.e } .__methodBindings__.dispatch($v { f.f }, $ { field } ());
			case FVar(_, _):
				Context.error("notify works only with methods", field.pos);
		}
	}
	
	#if macro
	
	inline static function fieldBinding(field:Expr, listener:ExprOf < Dynamic -> Dynamic -> Void > , bind:Bool) {
		
		var res = checkField(field);
		checkFunction(listener, res.classField, bind);
		return res;
	}
	
	inline static private function checkField(field:Expr) {
		switch (field.expr) {
			
			case EField(e, f):
				var type = Context.typeof(e);
				var classField:ClassField = null;
				
				switch (type) {
					
					case TInst(t, _): 
						var classType = t.get();
						if (!BindMacros.isIBindable(classType))
							Context.error('"${e.toString()}" must be bindx.IBindable', e.pos);

						while (classType != null) {
							for (cf in classType.fields.get()) {
								if (cf.name == f) {
									if (!cf.meta.has(BindMacros.BINDING_META_NAME)) {
										Context.warning("field is not bindable", field.pos);
									}
									classField = cf;
									break;
								}
							}
							if (classField != null) break;
							classType = classType.superClass != null ? classType.superClass.t.get() : null;
						}
					
					case _: Context.error('"${e.toString()}" must be bindx.IBindable', e.pos);
				}
				return { e:e, f:f, eType:type, classField:classField };
			
			case _ : 
				Context.error('first parameter must be field call', field.pos);
				return null;
		}
	}
	
	inline static private function checkFunction(listener:ExprOf<Dynamic -> Dynamic -> Void>, classField:ClassField, bind:Bool) {

		var argsNum;
		var reassign;
		switch (classField.kind) {
			case FMethod(k):
				argsNum = 1;
				switch (classField.type) {
					case TFun(_, ret): reassign = ret;
					case _: reassign = classField.type;
				}
			case _:
				argsNum = 2;
				reassign = classField.type;
		}
		
		var ok = false;
		switch (listener.expr) {

			case EFunction(_, f): // inline function
				if (f.args.length != argsNum)
					Context.error('listener must have $argsNum arguments', listener.pos);
				
				for (i in 0...argsNum) {
					var argType = f.args[i].type;
					if (argType == null) {
						if (bind) f.args[i].type = reassign.toComplexType();
					} else if (!Context.unify(reassign, argType.toType()))
						Context.error('listener argument type mismatch ${reassign.toString()} vs ${argType.toString()}', listener.pos);
				}
				ok = true;
				
			case _:
		}
		if (!ok) {
			var funcType = Context.typeof(listener);
			
			switch (funcType) {
				
				case TFun(args, ret):
					if (args.length != argsNum)
						Context.error('listener must have $argsNum arguments', listener.pos);
					
					for (i in 0...argsNum)
						if (!Context.unify(reassign, args[i].t))
							Context.error('listener argument type mismatch ${reassign.toString()} vs ${args[i].t.toString()}', listener.pos);
					
				case _:
					Context.error('listener must be a function', listener.pos);
			}
		}
	}
	#end
	
}

