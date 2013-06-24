package bindx;

#if macro
import haxe.macro.Expr.TypePath;
import haxe.macro.Type;
#end
/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class BindMacroTools
{
	#if macro
	
	static var IBINDABLE_TYPE: { t:Ref<ClassType>, params:Array<Type> };
	static var IBINDABLE_PATH:TypePath;
	
	static function buildIBindableType() {
		var bindType = Context.getType(BindMacros.BINDING_INTERFACE_NAME);
		switch (bindType) {
			case TInst(t, params): IBINDABLE_TYPE = { t:t, params:params };
			case _: throw "assers";
		}
	}
	
	static public function getIBindablePath():TypePath {
		if (IBINDABLE_PATH == null) {
			var path = BindMacros.BINDING_INTERFACE_NAME.split(".");
			var name = path.pop();
			IBINDABLE_PATH = {
				pack: path,
				name: name,
				params: []
			}
		}
		return IBINDABLE_PATH;
	}
	
	static public function implementIBindable(type:ClassType):Void {
		for (i in type.interfaces) {
			if (i.t.toString() == BindMacros.BINDING_INTERFACE_NAME) return;
		}
		
		if (IBINDABLE_TYPE == null) buildIBindableType();
		type.interfaces.push(IBINDABLE_TYPE);
	}
	
	#end
}