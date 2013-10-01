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
	var method:{retType:Type, args:Array<{e:Expr}>};
}

class Bind {
	
	#if macro
		inline static var FIELD_BINDINGS_NAME = BindMacros.FIELD_BINDINGS_NAME;
		inline static var LISTENER_PREFIX = "listener";
		inline static var LISTENER_0_NAME = LISTENER_PREFIX + "0";
		inline static var GETTER_PREFIX = "get_";
		
		inline static var MAX_DEPTH = 100000;
		
		static var listener0NameExpr:Expr;
		
		static function __init__() {
			listener0NameExpr = macro $i { LISTENER_0_NAME };
		}
		
		static function getNullValue(type:Type):Dynamic {
			type = Context.follow(type, false);
			return switch (type) {
				case TAbstract(t, _): 
					
					var bt = t.get();
					if (bt.pack.length == 0)
						switch (bt.name) {
							case "Float" : 0.0;
							case "Int" : 0;
							case "Bool" : false;
							case _ : null;
						}
					else null;
				
				case _: null;
			}
		}
		
		inline static function doBind(fields:Array<FieldCall>, listener:Expr):Expr {
			
			var first = fields.shift();
			var listeners = [];
			var res = [];
			var unbinds = [];
			
			res.push(macro var $LISTENER_0_NAME = $listener);
			
			var firstFieldName = first.f;
			if (fields.length == 0) {
				
				res.push(getBindMacro(true, first.e, firstFieldName, listener0NameExpr, first.classField));
				if (first.method != null)
					res.push(macro $listener0NameExpr());
				else
					res.push(macro $listener0NameExpr($v{getNullValue(first.classField.type)}, $ { first.e } .$firstFieldName));
				unbinds.push(getBindMacro(false, first.e, firstFieldName, listener0NameExpr, first.classField));
				
			} else {
				
				var listenerName;
				var i = 0;
				while (i < fields.length) {
					
					var f = fields[i++];
					listenerName = LISTENER_PREFIX + i;
					var nextListenerName = i == fields.length ? LISTENER_0_NAME : LISTENER_PREFIX + (i + 1);
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
										$nextListenerNameExpr(o != null ? o.$fieldName : $v{getNullValue(f.classField.type)}, n.$fieldName);
									} 
						}
						
						if (prev.method != null) 
							listeners.unshift(macro var $listenerName = function() {
								var o = $listenerTargetExpr;
								if (o != null)
									${getBindMacro(false, macro o, fieldName, nextListenerNameExpr, f.classField)}

								var n = $ { f.e };
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
									$nextListenerNameExpr(o != null ? o.$fieldName : $v{getNullValue(f.classField.type)}, n.$fieldName);
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
					res.push(macro $listenerNameExpr($v{getNullValue(first.classField.type)}, $ { first.e } .$firstFieldName));
				
				unbinds.push(getBindMacro(false, first.e, firstFieldName, listenerNameExpr, first.classField));
				unbinds.push(macro $listenerNameExpr = null);
			}
			unbinds.push(macro $listener0NameExpr = null);
			
			res.push(macro return function () $b{unbinds});
		
			var result = macro (function (_) $b { res } )(this);
			//trace(result.toString());
			return result;
		}

		inline static function fixExpr(expr:Expr):Expr {
			switch (expr.expr) {
	    		case EMeta(_, _):
			        var pos = expr.pos;
			        //Context.warning("using Bind is deprecated", pos);
			        var posInfo = Context.getPosInfos(pos);
			        var f = sys.io.File.getContent(posInfo.file);
			        f = f.substring(posInfo.min, posInfo.max);
			        expr = Context.parseInlineString(f, pos);

			        switch (expr.expr) {
			        	case EField(e, _): expr = e;
			        	case _: throw "assert";
			        }
	    		case _:
	    	}
	    	return expr;
		}
	#end
	
	macro static public function bindxTo(expr:Expr, target:Expr, recursive:Bool = false):ExprOf<Void->Void> {
		expr = fixExpr(expr);
		return bindTo(expr, target, recursive);
	}
	
	#if macro
	static public function _bindxTo(expr:Expr, target:Expr, recursive:Bool = false):ExprOf<Void->Void> {
		return bindTo(expr, target, recursive);
	}
	
	inline static function bindTo(expr:Expr, target:Expr, recursive:Bool = true):ExprOf<Void->Void> {
		var fields:Array<FieldCall> = [];
		
		checkField(expr, fields, 0, true, recursive ? MAX_DEPTH : 0);
		var field = fields[fields.length - 1];
		
		var fname = field.f;
		var targetType = Context.typeof(target);
		var listener = null;
		
		if (field.method != null) {

				if (!Context.unify(field.method.retType, targetType))
					Context.error('${targetType.toString()} should be ${field.method.retType.toString()}', target.pos);
				
				listener = macro function () $target = ${field.e}.$fname();
			} else {
				
				if (!Context.unify(field.classField.type, targetType))
					Context.error('${targetType.toString()} should be ${field.classField.type.toString()}', target.pos);
				
				listener = macro function (_, b) $target = b;
			}
		
		return doBind(fields, listener);
	}
	#end

	macro static public function bindx(expr:Expr, listener:Expr, recursive:Bool = false):Expr {
		expr = fixExpr(expr);
		return exprBind(expr, listener, recursive);
	}
	
	macro static public function unbindx(expr:Expr, listener:Expr) {
		expr = fixExpr(expr);
		return _exprUnbind(expr, listener);
	}
	
	#if macro
	
	static public function _unbindx(expr:Expr, listener:Expr):Expr {
		return _exprUnbind(expr, listener);
	}
	
	inline static function _exprUnbind(expr:Expr, listener:Expr) {
		var fields:Array<FieldCall> = [];
		
		checkField(expr, fields, 0, true, 0);
		
		var field = fields[0];
		if (fields.length > 1) throw fields;
		return getBindMacro(false, field.e, field.f, listener, field.classField);
	}
	
	static public function _bindx(expr:Expr, listener:Expr, recursive:Bool = false):Expr {
		return exprBind(expr, listener, recursive);
	}
	
	static function exprBind(expr:Expr, listener:Expr, recursive:Bool):Expr {
		var fields:Array<FieldCall> = [];
		
		checkField(expr, fields, 0, true, recursive ? MAX_DEPTH : 0);
		checkFunction(listener, fields[fields.length - 1], true);
		
		return if (recursive)
				doBind(fields, listener);
			else {
				var field = fields[0];
				var fieldName = field.f;
				var res = [];
				switch (listener.expr) {
					case EBinop(OpAssign, left, right): 
						res.push(listener);
						listener = left;
					case _:
				}
				res.push(getBindMacro(true, field.e, field.f, listener, field.classField));
				if (field.method != null)
					res.push(macro $listener());
				else
					res.push(macro $listener($v { getNullValue(field.classField.type) }, $ { field.e } .$fieldName ));
				res.push(macro {});
				macro $b { res };
			}
	}
	
	inline static function isNullExpr(expr:Expr):Bool {
		return switch (expr.expr) {
			case EConst(CIdent("null")): true;
			case _: false;
		}
	}
	#end
	
	inline static public function bindxGlobal<T>(bindable:IBindable, listener:GlobalFieldListener<T>) {
		bindable.__fieldBindings__.addGlobal(listener);
	}
	
	inline static public function unbindxGlobal<T>(bindable:IBindable, listener:GlobalFieldListener<T>) {
		bindable.__fieldBindings__.removeGlobal(listener);
	}
	
	@:noUsing macro static public function notify(field:Expr, ?from:Expr, ?to:Expr) {
		field = fixExpr(field);
		var fields:Array<FieldCall> = [];
		checkField(field, fields, 0, false, 0);
		
		var f = fields[0];
		if (f.method != null) { 
			
			if (!(isNullExpr(from) && isNullExpr(to)))
				Context.error("method notify doesn't support from & to params", f.e.pos);
				
			if (!f.bindable)
				Context.error("can't notify non bindable method", f.e.pos);
				
			if (f.method.args.length > 0)
				Context.error("can't notify method with args", field.pos);
				
			if (f.type.toString() == "Void")
				Context.error("can't notify Void return function", field.pos);
				
			return macro $ { f.e } .__methodBindings__.dispatch($v { f.f });  // $ { f.e }.$fieldName ($a{args})
		} else {
			
			return macro $ { f.e } .__fieldBindings__.dispatch($v { f.f }, $from, $to);  // $ { f.e }.$fieldName ($a{args})
			return null;
		}
	}
	
	#if macro
	inline static private function getBindMacro(bind:Bool, field:Expr, fieldName:String, listener:Expr, classField:ClassField):Expr {
		var m = bind ? "add" : "remove";
		return switch (classField.kind) {
			case FVar(_,_):
				macro ${field}.__fieldBindings__.$m($v { fieldName }, $listener);
			case FMethod(_):
				macro ${field}.__methodBindings__.$m($v { fieldName }, $listener);
		}
	}
	
	static function checkField(expr:Expr, fields:Array<FieldCall>, depth = 0, warnNonBindable = true, maxDepth:Int):Void {

		if (depth > maxDepth) return ;
		switch (expr.expr) {
			
			case ECall(e, params):
				checkField(e, fields, depth, warnNonBindable, maxDepth);

				//var args = [for (p in params) { e:p }];

				/*var last = fields[fields.length - 1];
				last.method = {args:args, retType:switch(Context.typeof(e)) {
							case TFun(_, ret): ret;
							case _: null;
						}};
						
				trace(last);*/
			
			case EField(e, f):

				var type = Context.typeof(e);
				var classField:ClassField = null;
				var bindable = true;
				
				switch (type) {
					
					case TInst(t, _): 
						var mainType = t.get();
						var classType = mainType;
						
						if (!BindMacros.isIBindable(classType)) {
							if (depth == 0)
								Context.error('"${e.toString()}" must be ${BindMacros.BINDING_INTERFACE_NAME}', e.pos);
							else {
								bindable = false;
								if (warnNonBindable) Context.warning('"${e.toString()}" is not ${BindMacros.BINDING_INTERFACE_NAME}', e.pos);
							}
						}
						
						if (StringTools.startsWith(f, GETTER_PREFIX)) {
							var propName = f.substr(GETTER_PREFIX.length);
							var found = false;
							while (classType != null) {
								for (field in classType.fields.get()) {
									if (field.name == propName) {
										switch (field.kind) {
											case FVar(read, _):
												switch (read) {
													case AccCall:
														found = true;
														f = propName;
													case _:
												}
											case FMethod(_):
										}
									}
								}
								if (found) break;
								classType = classType.superClass != null ? classType.superClass.t.get() : null;
							}
							if (!found) classType = mainType;
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
							Context.error('1 "${e.toString()}" must be ${BindMacros.BINDING_INTERFACE_NAME}', e.pos);
						else {
							bindable = false;
							if (warnNonBindable) 
								Context.warning('2 "${e.toString()}" is not ${BindMacros.BINDING_INTERFACE_NAME}', e.pos);
						}
				}
				
				var method = null;
				switch (classField.kind) {
					case FMethod(k): 
						method = { args:[], retType : switch(Context.typeof(expr)) {
							case TFun(_, ret): ret;
							case _: null;
						}};
						
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
		}
	}
	
	inline static function checkFunction(listener:Expr, field:FieldCall, bind:Bool) {

		var argsNum = field.method != null ? 0 : 2;
		var reassign = field.method != null ? field.method.retType : field.classField.type;
		
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
						Context.error('${argType.toString()} should be ${reassign.toString()}', listener.pos);
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
						Context.error('${args[i].t.toString()} should be ${reassign.toString()}', listener.pos);
				
			case _:
				Context.error('listener must be a function', listener.pos);
		}
	}
	#end
	
}

