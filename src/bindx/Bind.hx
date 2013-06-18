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
	var classField:ClassField;
	var type:Type;
	var bindable:Bool;
	var depth:Int;
	var method:{args:Array<{e:Expr}>};
}

class Bind {
	
	#if macro
		inline static var FIELD_BINDINGS_NAME = BindMacros.FIELD_BINDINGS_NAME;
		inline static var LISTENER_PREFIX = "listener";
		
		inline static var MAX_DEPTH = 100000;
		
		inline static function doBind(fields:Array<FieldCall>, listener:Expr, res:Array<Expr>, unbinds:Array<Expr>) {
			
			var first = fields.shift();
			var listeners = [];
			var listener0Name = LISTENER_PREFIX + "0";
			var listener0NameExpr = macro $i { listener0Name };
			
			res.push(macro var $listener0Name = $listener);
			
			var firstFieldName = first.f;
			if (fields.length == 0) {

				res.push(getBindMacro(true, first.e, firstFieldName, listener0NameExpr, first.classField));
				if (first.method != null)
					res.push(macro $listener0NameExpr());
				else
					res.push(macro $listener0NameExpr(null, $ { first.e } .$firstFieldName));
				unbinds.push(getBindMacro(false, first.e, firstFieldName, listener0NameExpr, first.classField));
				
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
					var prev = i == 1 ? first : fields[i - 2];
					var listener = null;
					
					if (f.bindable) {
						
						unbinds.push(macro
								if ($listenerTargetExpr != null)
									$ { getBindMacro(false, listenerTargetExpr, fieldName, nextListenerNameExpr, f.classField) }
						);
							
						if (f.method != null) {
							
							listener = macro
									if (n != null) {
										${getBindMacro(true, macro n, fieldName, nextListenerNameExpr, f.classField)}
										$nextListenerNameExpr();
									}
						}
						else {
							
							listener = macro
									if (n != null) {
										${getBindMacro(true, macro n, fieldName, nextListenerNameExpr, f.classField)}
										$nextListenerNameExpr(o != null ? o.$fieldName : null, n.$fieldName);
									} 
						}
						
						if (prev.method != null) 
							listeners.unshift(macro var $listenerName = function() {
								var o = $listenerTargetExpr;
								var n = $ { f.e };
								if (o != null)
									${getBindMacro(false, macro o, fieldName, nextListenerNameExpr, f.classField)}

								$listenerTargetExpr = n;
								$listener;
							});
						else
							listeners.unshift(macro var $listenerName = function(o:$type, n:$type) {
								if (o == null) o = $listenerTargetExpr;
								if (o != null)
									${getBindMacro(false, macro o, fieldName, nextListenerNameExpr, f.classField)}

								$listenerTargetExpr = n;
								$listener;
							});
						
						res.push(macro var $listenerTarget:$type = null);
						unbinds.push(macro $listenerTargetExpr = null );
						
						
					} else { // !f.bindable
						
						if (f.method != null) {
							if (f.method.args.length > 0)
								Context.error("can't bind method with args", f.e.pos);
							
							listener = macro if (n != null) $nextListenerNameExpr();
								
						} else {
							
							listener = macro
								if (n != null)
									$nextListenerNameExpr(o != null ? o.$fieldName : null, n.$fieldName);
						}
						if (prev.method != null) {
							
							listeners.unshift(macro
								var $listenerName = function () {
									var o = null;
									var n = $ { f.e };
									$listener;
								}
							);
						} else {
							
							listeners.unshift(macro
								var $listenerName = function (o:$type, n:$type)
									$listener
							);
						}
					}
				}
				for (l in listeners) res.push(l);
				
				i = 1;
				listenerName = LISTENER_PREFIX + i;
				var listenerNameExpr = macro $i { listenerName };
			
				res.push(getBindMacro(true, first.e, firstFieldName, listenerNameExpr, first.classField ));
				if (first.method != null)
					res.push(macro $listenerNameExpr());
				else
					res.push(macro $listenerNameExpr(null, $ { first.e } .$firstFieldName));
				
				unbinds.push(getBindMacro(false, first.e, firstFieldName, listenerNameExpr, first.classField));
				unbinds.push(macro $listenerNameExpr = null);
			}
			unbinds.push(macro $listener0NameExpr = null);
		}
	#end
	
		macro static public function bindxTo(expr:Expr, target:Expr, recursive:Bool = false) {
		
		var fields:Array<FieldCall> = [];
		
		checkField(expr, fields, 0, true, recursive ? MAX_DEPTH : 0);
		
		var listener = if (fields[fields.length-1].method != null) {
				macro function () {
					$target = $expr;
				}
			} else {
				macro function (_, b) {
					$target = b;
				}
			}
		//checkFunction(listener, fields[fields.length - 1], true);
		
		var res = [];
		var unbinds = [];
		
		doBind(fields, listener, res, unbinds);
		
		res.push(macro return function () $b{unbinds});
		
		var result = macro (function (_) $b { res })(this);
		//trace(result.toString());
		return result;
	}

	macro static public function bindx(expr:Expr, listener:Expr, recursive:Bool = false):ExprOf<Void->Void> {
		
		var fields:Array<FieldCall> = [];
		
		checkField(expr, fields, 0, true, recursive ? MAX_DEPTH : 0);
		checkFunction(listener, fields[fields.length - 1], true);
		
		var res = [];
		var unbinds = [];
		
		doBind(fields, listener, res, unbinds);
		
		res.push(macro return function () $b{unbinds});
		
		var result = macro (function (_) $b { res })(this);
		//trace(result.toString());
		return result;
	}
	
	inline static public function bindxGlobal<T>(bindable:IBindable, listener:GlobalFieldListener<T>) {
		bindable.__fieldBindings__.addGlobal(listener);
	}
	
	inline static public function unbindxGlobal<T>(bindable:IBindable, listener:GlobalFieldListener<T>) {
		bindable.__fieldBindings__.removeGlobal(listener);
	}
	
	macro static public function notify(field:Expr) {
		var fields:Array<FieldCall> = [];
		checkField(field, fields, 0, false, 0);
		
		var f = fields[0];
		if (f.method != null) {
			
			if (!f.bindable)
				Context.error("can't notify non bindable method", f.e.pos);
				
			if (f.method.args.length > 0)
				Context.error("can't notify method with args", field.pos);
				
			if (f.type.toString() == "Void")
				Context.error("can't notify Void return function", field.pos);
				
			return macro $ { f.e } .__methodBindings__.dispatch($v { f.f });  // $ { f.e }.$fieldName ($a{args})
		} else {
			
			Context.error("notify works only with methods", field.pos);
			return null;
		}
	}
	
	#if macro
	inline static private function getBindMacro(bind:Bool, field:Expr, fieldName:String, listener:Expr, classField:ClassField) {
		var m = bind ? "add" : "remove";
		return switch (classField.kind) {
			case FVar(_,_):
				macro ${field}.__fieldBindings__.$m($v { fieldName }, $listener);
			case FMethod(_):
				macro ${field}.__methodBindings__.$m($v { fieldName }, $listener);
		}
	}
	
	static private function checkField(expr:Expr, fields:Array<FieldCall>, depth = 0, warnNonBindable = true, maxDepth = MAX_DEPTH):Void {
		
		if (depth > maxDepth) return ;
		switch (expr.expr) {
			
			case ECall(e, params):
				checkField(e, fields, depth, warnNonBindable, maxDepth);

				var args = [for (p in params) { e:p }];

				var last = fields[fields.length - 1];
				last.method = {args:args};
			
			case EField(e, f):
				
				var type = Context.typeof(e);
				var classField:ClassField = null;
				var bindable = true;

				switch (type) {
					
					case TInst(t, _): 
						var classType = t.get();
						
						if (!BindMacros.isIBindable(classType)) {
							if (depth == 0)
								Context.error('"${e.toString()}" must be bindx.IBindable', e.pos);
							else {
								bindable = false;
								if (warnNonBindable) Context.warning('"${e.toString()}" is not bindx.IBindable', e.pos);
							}
						}

						while (classType != null) {
							for (cf in classType.fields.get()) {
								if (cf.name == f) {
									if (!cf.meta.has(BindMacros.BINDING_META_NAME)) {
										bindable = false;
										if (warnNonBindable) Context.warning('field "${expr.toString()}" is not bindable', expr.pos);
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
							Context.error('"${e.toString()}" must be bindx.IBindable', e.pos);
						else {
							bindable = false;
							if (warnNonBindable) 
								Context.warning('"${e.toString()}" is not bindx.IBindable', e.pos);
						}
				}
				
				var method = null;
				
				switch (classField.kind) {
					case FMethod(k): 
						method = { args:[] };
						/*switch(Context.typeof(expr)) {
							case TFun(_, ret): method.type = ret;
							case _: null;
						}*/
						
					case FVar(_, _):
				}
				
				fields.unshift( {
					e: e,
					f: f,
					classField: classField,
					type: type,
					bindable: bindable,
					depth: depth,
					method:method
				} );
				
				checkField(e, fields, depth + 1, warnNonBindable, maxDepth);
				
			/*case EConst(CIdent(_)): 
				if (depth == 0)
					Context.error('"${expr.toString()}" must be field call', expr.pos);
			*/		
			case _ :
				//trace(depth);
				//trace(expr);
				if (depth == 0) {
					
					Context.error('"${expr.toString()}" must be field call', expr.pos);
				}
				return null;
		}
	}
	
	inline static private function checkFunction(listener:Expr, field:FieldCall, bind:Bool) {

		var argsNum = field.method != null ? 0 : 2;
		var reassign = field.method != null ? field.type : field.classField.type;
		
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

