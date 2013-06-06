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
	var type:Type;
	var bindable:Bool;
}

class Bind {
	
	#if macro
		inline static var FIELD_BINDINGS_NAME = BindMacros.FIELD_BINDINGS_NAME;
		inline static var LISTENER_PREFIX = "listener";
	#end

	macro static public function bindx(expr:Expr, listener:Expr):ExprOf<Void->Void> {
		
		var fields:Array<FieldCall> = [];
		
		checkField(expr, fields);
		checkFunction(listener, fields[fields.length - 1].eType, true);

		var first = fields.shift();
		
		var res = [];
		var listeners = [];
		var unbinds = [];
		
		var listener0Name = LISTENER_PREFIX + "0";
		var listener0NameExpr = macro $i { listener0Name };
		
		res.push(macro var $listener0Name = $listener);
		
		var firstFieldName = first.f;
		if (fields.length == 0) {

			res.push(getBindMacro(true, first.e, firstFieldName, listener0NameExpr, first.eType));
			res.push(macro $listener0NameExpr(null, $ { first.e } .$firstFieldName));
			unbinds.push(getBindMacro(false, first.e, firstFieldName, listener0NameExpr, first.eType));
			
		} else {
			
			var listenerName;
			var i = 0;
			while (i < fields.length) {
				
				var f = fields[i++];
				listenerName = LISTENER_PREFIX + i;
				var nextListenerName = i == fields.length ? listener0Name : LISTENER_PREFIX + (i + 1);
				var nextListenerNameExpr = macro $i { nextListenerName };
				var listenerTarget = nextListenerName + "target";
				var listenerTargetExpr = macro $i { listenerTarget };
				var fieldName = f.f;
				var type = f.type.toComplexType();
				
				if (f.bindable) {
					
					unbinds.push(macro
							if ($listenerTargetExpr != null)
								$listenerTargetExpr.__fieldBindings__.remove($v { fieldName }, $nextListenerNameExpr)
					);
					
					res.push(macro var $listenerTarget:$type = null);
					unbinds.push(macro $listenerTargetExpr = null );
					
					listeners.unshift(macro
						var $listenerName = function (o:$type, n:$type) {
							if (o == null) o = $listenerTargetExpr;
							if (o != null)
								${getBindMacro(false, macro o, fieldName, nextListenerNameExpr, f.eType)}

							$listenerTargetExpr = n;
							if (n != null) {
								${getBindMacro(true, macro n, fieldName, nextListenerNameExpr, f.eType)}
								$nextListenerNameExpr(o != null ? o.$fieldName : null, n.$fieldName);
							} 
						}
					);
				} else {
					
					listeners.unshift(macro
						var $listenerName = function (o:$type, n:$type)
							if (n != null)
								$nextListenerNameExpr(o != null ? o.$fieldName : null, n.$fieldName)
					);
				}
			}
			res = res.concat(listeners);
			
			i = 1;
			listenerName = LISTENER_PREFIX + i;
			var listenerNameExpr = macro $i { listenerName };
		
			res.push(getBindMacro(true, first.e, firstFieldName, listenerNameExpr, first.eType ));
			res.push(macro $listenerNameExpr(null, $ { first.e } .$firstFieldName));
			unbinds.push(getBindMacro(false, first.e, firstFieldName, listenerNameExpr, first.eType));
			unbinds.push(macro $listenerNameExpr = null);
		}
		unbinds.push(macro $listener0NameExpr = null);
		
		res.push(macro return function () $b{unbinds});
		
		var result = macro (function (_) $b { res })(this);
		trace(result.toString());
		return result;
	}
	
	inline static public function bindxGlobal<T>(bindable:IBindable, listener:GlobalFieldListener<T>) {
		bindable.__fieldBindings__.addGlobal(listener);
	}
	
	inline static public function unbindxGlobal<T>(bindable:IBindable, listener:GlobalFieldListener<T>) {
		bindable.__fieldBindings__.removeGlobal(listener);
	}
	
	macro static public function notify(field:Expr) {
		var fields = [];
		checkField(field, fields, 0);
		
		var f = fields[fields.length - 1];
		
		return switch (f.eType.kind) {
			case FMethod(_):
				
				if (!f.bindable)
					Context.error("can't notify non bindable method", f.e.pos);
			
				switch (f.eType.type) {
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
	inline static private function getBindMacro(bind:Bool, field:Expr, fieldName:String, listener:Expr, eType:ClassField) {
		var m = bind ? "add" : "remove";
		return switch (eType.kind) {
			case FVar(_,_):
				macro ${field}.__fieldBindings__.$m($v { fieldName }, $listener);
			case FMethod(_):
				macro ${field}.__methodBindings__.$m($v { fieldName }, $listener);
		}
	}
	
	static private function checkField(expr:Expr, fields:Array<Dynamic>, depth:Int = 0):Void {
		
		switch (expr.expr) {
			
			case EField(e, f):
				
				var type = Context.typeof(e);
				var classField:ClassField = null;
				var bindable = true;
				
				switch (type) {
					
					case TInst(t, _): 
						var classType = t.get();
						
						if (!BindMacros.isIBindable(classType)) {
							if (depth == 0)
								Context.error("can't bind expr", e.pos);
							else {
								Context.warning('"${e.toString()}" must be bindx.IBindable', e.pos);
								bindable = false;
							}
						}

						while (classType != null) {
							for (cf in classType.fields.get()) {
								if (cf.name == f) {
									if (!cf.meta.has(BindMacros.BINDING_META_NAME)) {
										Context.warning('field "${expr.toString()}" is not bindable', expr.pos);
										bindable = false;
									}
									classField = cf;
									break;
								}
							}
							if (classField != null) break;
							classType = classType.superClass != null ? classType.superClass.t.get() : null;
						}
					
					case _:
						bindable = false;
						if (depth == 0)
							Context.error('can\'t bind expr "${expr.toString()}"', e.pos);
						else
							Context.warning('"${e.toString()}" must be bindx.IBindable', e.pos);
				}
				
				checkField(e, fields, depth + 1);
				
				fields.push( { e:e, f:f, eType:classField, type:type, bindable:bindable } );
				
			case EConst(CIdent(_)): 
				if (depth == 0)
					Context.error('"${expr.toString()}" must be field call', expr.pos);
					
			case _ : 
				trace(depth);
				trace(expr);
				Context.error('"${expr.toString()}" must be field call', expr.pos);
				return null;
		}
	}
	
	inline static private function checkFunction(listener:Expr, classField:ClassField, bind:Bool) {

		var argsNum;
		var reassign;
		switch (classField.kind) {
			case FMethod(k):
				argsNum = 1;
				reassign = switch (classField.type) {
					case TFun(_, ret): ret;
					case _: classField.type;
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
		if (!ok) switch (Context.typeof(listener)) {
				
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
	#end
	
}

