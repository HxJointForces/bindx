package bindx;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import bindx.BindSignal;

using haxe.macro.Tools;
using Lambda;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class Bind {
	
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
						if (!classType.interfaces.exists(
								function (i) return i.t.toString() == "bindx.IBindable")
							)
							Context.error('"${e.toString()}" must be bindx.IBindable', e.pos);
						
						for (cf in classType.fields.get()) {
							if (cf.name == f) {
								if (!cf.meta.has(BindMacros.BINDING_META_NAME)) {
									Context.warning("field is not bindable", field.pos);
								}
								classField = cf;
								break;
							}
						}
					
					case _: Context.error('"${e.toString()}" must be bindx.IBindable', e.pos);
				}
				return { e:e, f:f, eType:type, classField:classField };
			
			case _ : 
				Context.error('first parameter must be field call', field.pos);
				return null;
		}
	}
	
	inline static private function checkFunction(listener:ExprOf<Dynamic -> Dynamic -> Void>, classField:ClassField, bind:Bool) 
	{
		var argsNum = switch (classField.kind) {
			case FMethod(_): 1;
			case FVar(_, _): 2;
		}
		var reassign = switch (classField.kind) {
						case FMethod(k): 
							switch (classField.type) {
								case TFun(_, ret): ret;
								case _: classField.type;
							}
						case _: classField.type;
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
					Context.error('listener must be function', listener.pos);
			}
		}
	}
	#end
	
}

