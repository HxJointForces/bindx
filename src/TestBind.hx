package ;

import bindx.IBindable;

using bindx.Bind;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class TestBind
{
	var a:Int;
	static var b:Int;
	
	static function main() {
		
		var v = new Value();
		//v.no = 10;
		
		v.bindxGlobal(function (varName:String, old:Dynamic, val:Dynamic) {
			trace('changed $varName : $old -> $val'); 
		});
		
		var methodListener = function (_, newValue:String) { trace("listener " + newValue); };
		v.toString.bindx(function (_, newValue) { trace(newValue); } );
		v.toString.bindx(methodListener);
		
		v.def = 12;
		v.def = 14;
		
		v.s.bindx(function (f, t) { $type(f); $type(t); } );
		v.s = "23";
		v.s = null;
		
		var listener = function (old:Float, val:MyInt) { trace('a updated from $old to $val'); } 
		v.a.bindx(listener);
		
		v.a = 4;
		
		v.a.unbindx(listener);
		
		v.a = 5;
		
		Bind.notify(v.a);
		
		
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
	
	@bindable public function toString() {
		return '$a + $def + $s';
	}
	
	function set_s(v) {
		if (v == null) {
			s = "";
			Bind.notify(this.toString);
			return s;
		}
		s = v;
		Bind.notify(this.toString);
		return v;
	}
	
	public function new() {
		
	}
}