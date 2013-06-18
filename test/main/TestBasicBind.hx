package main;

import haxe.unit.TestCase;
import bindx.IBindable;

using bindx.Bind;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class TestBasicBind extends TestCase
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
		v.toString.bindx(function () { toStringCall ++; } );
		v.toString.bindx(methodListener);
		
		v.def = 12;
		v.def = 14;
		
		v.s.bindx(function (f, t) { lastS = t; } );
		v.s = "23";
		v.s = null;
		
		var listener = function (old:Float, val:MyInt) { aCall ++; }
		var unbindVA = v.a.bindx(listener);
		v.a = 4;
		unbindVA();
		v.a = 5;

		assertEquals(aCall, 1 + 1);
		assertEquals(toStringCall, 2 * 2 + 2); // +2 auto
		assertEquals(lastS, "");
		assertEquals(Type.getClass(lastS), String);
		
	}
	
}

typedef TypeDef = {
	@bindable var x:Float;
}

enum EnumA {
	CtorA;
	CtorB(i:Int);
	CtorC(s:String);
}

private typedef MyInt = Int;

@bindable class Value implements IBindable {
	
	public var a:MyInt;
	
	//@bindable public var never(default, never):Int;
	//@bindable public var no(default, null):Int;
	public var def(default, default):Int;
	//@bindable public var dyn(default, dynamic):Int;
	
	public var s(default, set):String;
	
	@bindable public function toString():String {
		return '$a + $def + $s';
	}
	
	function set_s(v):String {
		if (v == null) {
			s = "";
			Bind.notify(this.toString);
			return s;
		}
		s = v;
		Bind.notify(this.toString);
		return v;
	}
	
	public function test():Void {
	}
	
	public function new() {
		
	}
}