package bindx;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class Bind {
	
	macro static public function on<T>(field:Expr, listener:ExprOf<Dynamic->Dynamic->Void>) {
		switch (field.expr) {
			case EField(e, f):
				switch (listener.expr) {
					case EFunction(_, f):
						if (f.args.length != 2)
							Context.error("listener must have 2 arguments", listener.pos);
							
						var type = Context.typeof(field);
						if (!Context.unify(type, ComplexTypeTools.toType(f.args[0].type)))
							Context.error('listener first argument type mismatch ${type.toString()} vs ${f.args[0].type.toString()}', listener.pos);
						
						if (!Context.unify(type, ComplexTypeTools.toType(f.args[1].type)))
							Context.error('listener second argument type mismatch ${type.toString} vs ${f.args[1].type.toString()}', listener.pos);
					
					case _:
				}
				var res = macro $e.__bindings__.add($v { f }, $listener);
				return res;
			
			case _ : 
				Context.error('first parameter must be field call', field.pos);
				return null;
		}
	}
	
}

