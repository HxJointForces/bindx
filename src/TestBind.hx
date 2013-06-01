package ;

import bindx.IBindable;

using bindx.Bind;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class TestBind
{

	static function main() {
		/*var a:Bind<Int> = 12;
		a.add("test");
		trace(a);
		a = 13;*/
		
		var v = new Value();
		//v.no = 10;
		v.on("def", function (value) trace("def update to: " + value));
		v.on("s", function (value) trace("s update to: '" + value + "'"));
		
		v.__bindings__.addListener(function (varName:String) { trace("updated: " + varName); } );
		v.def = 12;
		v.def = 14;
		v.s = "23";
		v.s = null;
		v.a = 4;
	}
	
}

class Value implements IBindable {
	
	@bindable public var a:Int;
	
	//@bindable public var never(default, never):Int;
	//@bindable public var no(default, null):Int;
	@bindable public var def(default, default):Int;
	//@bindable public var dyn(default, dynamic):Int;
	
	@bindable public var s(default, set):String;
	
	function set_s(v) {
		if (v == null) {
			s = "";
			return s;
		}
		return s = v;
	}
	
	public function new() {
		
	}
}