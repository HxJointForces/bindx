package bindx;

import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

import bindx.BindSignal;

using haxe.macro.Tools;
using Lambda;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class Bind {
	
	inline static public function bindGlobal<T>(bindable:IBindable, listener:GlobalBindingListener<T>) {
		bindable.__bindings__.addGlobal(listener);
	}
	
	inline static public function unbindGlobal<T>(bindable:IBindable, listener:GlobalBindingListener<T>) {
		bindable.__bindings__.removeGlobal(listener);
	}
	
	macro static public function bind<T>(field:Expr, listener:ExprOf<Dynamic->Dynamic->Void>) {
		var field = fieldBinding(field, listener, true);
		return macro ${field.e}.__bindings__.add($v { field.f }, $listener);
	}
	
	macro static public function unbind<T>(field:Expr, listener:ExprOf<Dynamic->Dynamic->Void>) {
		var field = fieldBinding(field, listener, false);
		return macro ${field.e}.__bindings__.remove($v { field.f }, $listener);
	}
	
	#if macro
	
	static function fieldBinding(field:Expr, listener:ExprOf < Dynamic -> Dynamic -> Void >, bind:Bool) {
		switch (field.expr) {
			
			case EField(e, f):
				
				checkField(e);
				checkFunction(listener, Context.typeof(field), bind);
				return { e:e, f:f };
			
			case _ : 
				Context.error('first parameter must be field call', field.pos);
				return null;
		}
	}
	
	static private function checkField(e:Expr) {
		var type = Context.typeof(e);
		switch (type) {
			
			case TInst(t, _): 
				var classType = t.get();
				if (!classType.interfaces.exists(function (i) return i.t.toString() == "bindx.IBindable")) {
					Context.error('"${e.toString()}" must be bindx.IBindable', e.pos);
				}
			
			case _: Context.error('"${e.toString()}" must be bindx.IBindable', e.pos);
		}
	}
	
	static private function checkFunction(listener:ExprOf<Dynamic -> Dynamic -> Void>, fieldType:Type, bind:Bool) 
	{
		switch (listener.expr) {
			case EFunction(_, f): // inline function
				if (f.args.length != 2)
					Context.error("listener must have 2 arguments", listener.pos);
				
				for (i in 0...2) {
					var argType = f.args[i].type;
					if (argType == null) {
						if (bind) f.args[i].type = fieldType.toComplexType();
					} else if (!Context.unify(fieldType, argType.toType()))
						Context.error('listener argument type mismatch ${fieldType.toString()} vs ${argType.toString()}', listener.pos);
				}
				return;
				
			case _:
		}
		
		var funcType = Context.typeof(listener);
		
		switch (funcType) {
			
			case TFun(args, ret):
				if (args.length != 2)
					Context.error("listener must have 2 arguments", listener.pos);
				
				if (!Context.unify(fieldType, args[0].t))
					Context.error('listener first argument type mismatch ${fieldType.toString()} vs ${args[0].t.toString()}', listener.pos);
				
				if (!Context.unify(fieldType, args[1].t))
					Context.error('listener second argument type mismatch ${fieldType.toString()} vs ${args[1].t.toString()}', listener.pos);
					
			case _:
				Context.error('listener must be function', listener.pos);
		}
	}
	#end
	
}

