package ;

import bindx.Bindable;
import bindx.IBindable;

using bindx.BindTools;
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
		v.def.on(function () { trace("on def update"); } );
		v.def = 12;
		trace(v.def);
	}
	
	static function test<T>(a:BindableBase<T>) {
		a.add(function () { trace("foobar"); } );
		a.dispatch();
	}
	
}

class Value implements IBindable {
	
	@bindable public var a:Int;
	@bindable public var ab:Null<Int>;
	
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