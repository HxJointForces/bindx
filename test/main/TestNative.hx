package main;

/**
 *  @author Dima Granetchi <system.grand@gmail.com>
 */

import bindx.IBindable;
import haxe.unit.TestCase;

using bindx.Bind;

class TestNative extends TestCase
{
	
	public function new()
	{
		super();
		new SampleNativeBase();
	}

	function testNative() {
		var o = new NativeChild();
		var last:Int = 0;
		o.number.bindx(function(_,v:Int) last = v);
		assertEquals(5, last);
		o.number = 10;
		assertEquals(10, last);
	}
}

class NativeChild extends SampleNativeClass implements IBindable {
	@bindable public var number:Int = 5;
	public function new() {
		super();
	}
}

@:native('SampleNativeBase')
extern class SampleNativeClass {
	function new();
}
