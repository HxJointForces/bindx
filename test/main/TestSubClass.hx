package main;

/**
 *  @author Dima Granetchi <system.grand@gmail.com>
 */

import bindx.IBindable;
import haxe.unit.TestCase;

using bindx.Bind;

class TestSubClass extends TestCase
{
	public function new()
	{
		super();
	}

	function testSub() {
	    var b1 = new Bind1();
	    var b2 = new Bind2();

		var info = "";

		b1.b1.bindx(function (_, v) info += v);
		b2.b1.bindx(function (_, v) info += v);
		b2.b2.bindx(function (_, v) info += v);

		b1.b1 = "a";
		b2.b1 = "b";
		b2.b2 = "c";

		assertEquals("112abc", info);
	}
}

class Bind0 implements IBindable {
	function new() { }
}

class Bind1 extends Bind0 implements IBindable {

	public function new() {
		super();
	}

	@bindable({inlineSetter:false}) public var b1:String = "1";
}

@bindable class Bind2 extends Bind1 {

	public var b2:String = "2";
}
