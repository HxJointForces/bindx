package ;

import bindx.Bind;
import haxe.Log;

import bindx.IBindable;

using bindx.Bind;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class A {
	public function new() {
		
	}
	
	public function toString() {
		return "a";
	}
}
class TestBind
{
	var a:Int;
	static var b:Int;
	
	static function main() {
		
		var v = new Value();
		//v.no = 10;
		trace(v.a);
		v.a.on(function (old:Float, val:Int) trace('a updated from $old to $val'));
		//v.__bindings__.add(function (varName:String) { trace("updated: " + varName); } );
		v.def = 12;
		v.def = 14;
		v.s = "23";
		v.s = null;
		v.a = 4;
		v.a = 5;
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