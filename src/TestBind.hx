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
		
		v.bindGlobal(function (varName:String, old:Dynamic, val:Dynamic) {
			trace('changed $varName : $old -> $val'); 
		});
		
		v.def = 12;
		v.def = 14;
		
		v.s.bind(function (f, t) { $type(f); $type(t); } );
		v.s = "23";
		v.s = null;
		
		var listener = function (old:Int, val:Int) { trace('a updated from $old to $val'); } 
		v.a.bind(listener);
		
		v.a = 4;
		
		v.a.unbind(listener);
		
		v.a = 5;
	}
	
}

typedef MyInt = Int;

class Value implements IBindable {
	
	@bindable public var a:MyInt;
	
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