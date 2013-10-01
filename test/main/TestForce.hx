package main;

import haxe.unit.TestCase;
import bindx.IBindable;

using bindx.Bind;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class TestForce extends TestCase
{
	
	function testValue() {
		
		var v = new Value();

		var globalCall = 0;
		var toStringCall = 0;
		var aCall = 0;
		var lastS = null;

		v.bindxGlobal(function (varName:String, old:Dynamic, val:Dynamic) {
			globalCall ++;
		});
		
		var methodListener = function () { toStringCall ++; };
		v.toString.bindx(function () { toStringCall ++; });
		v.toString.bindx(methodListener);
		
		v.def = 12;
		v.def = 14;
		
		v.s.bindx(function (f, t) { lastS = t; } );
		v.s = "23";
		v.s = null;
		
		var listener = function (old:Float, val:MyInt) { aCall ++; }
		v.a.bindx(listener);
		v.a = 4;
		v.a.unbindx(listener);
		v.a = 5;

		assertEquals(aCall, 1 + 1);
		assertEquals(toStringCall, 2 * 2 + 2); // +2 auto
		assertEquals(lastS, "");
		assertEquals(Type.getClass(lastS), String);
	}
	
}

private typedef TypeDef = {
	@bindable var x:Float;
}

private enum EnumA {
	CtorA;
	CtorB(i:Int);
	CtorC(s:String);
}

private typedef MyInt = Int;

@bindable private class Value implements IBindable {
	
	@bindable({force:true}) public var a(default, set):MyInt;
	
	//@bindable public var never(default, never):Int;
	//@bindable public var no(default, null):Int;
	@bindable({force:true}) public var def(default, set):Int;
	//@bindable public var dyn(default, dynamic):Int;
	
	@bindable({force:true}) public var s(default, set):String;
	
	@bindable public function toString():String {
		return '$a + $def + $s';
	}
	
	function set_a(v:MyInt):MyInt {
		var old = a;
		Bind.notify(this.a, old, a = v);
		return v;
	}
	
	function set_def(v) {
		var old = def;
		def = v;
		Bind.notify(this.def, old, v);
		return v;
	}
	
	function set_s(v):String {
		var old = s;
		if (v == null) {
			Bind.notify(this.toString);
			Bind.notify(this.s, old, s = "");
			return s;
		}
		Bind.notify(this.s, old, s = v);
		Bind.notify(this.toString);
		return v;
	}
	
	public function test():Void {
	}
	
	public function new() {
		
	}
}