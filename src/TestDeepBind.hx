package ;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import bindx.IBindable;

using bindx.Bind;

/**
 *  @author Dima Granetchi <system.grand@gmail.com>
 */

class TestDeepBind extends TestCase
{
	static function main() {
		var r = new TestRunner();
		r.add(new TestDeepBind());
		r.run();
	}
	
	function testDeepBind() {
		var info = "";
		
		var a = new A();
		a.b = new B();
		a.b.c = new C();
		a.b.c.d = "0";
		
		var unbind = a.b.c.d.bindx(function (o, n) { info += n; } );
		
		a.b.c.d = "1";
		
		var c = new C();
		c.d = "2";
		a.b.c = c;
		
		var b = new B();
		b.c = new C();
		b.c.d = "3";
		a.b = b;
		b.c.d = "4";
		
		c.d = "5";
		b.c = c;
		
		unbind();
		
		a.b = b;
		a.b.c = c;
		a.b.c.d = "6";
		
		assertEquals(info, "012345");
	}
}

class A implements IBindable {

	@bindable public var b:B;
	
	@bindable public var b2:B2;
	
	public function test(i:Int):B {
		Bind.notify(b.c.toString);
		return b;
	}

	public function new() {

	}
}

class B2 {
	public function new() {
		
	}
	public var c:String;
}

class B implements IBindable {

	@bindable public var c:C;
	
	@bindable public function toString():String {
		return "";
	}
	
	public var c2:B2;

	public function new() {

	}
}
class C implements IBindable {
	
	@bindable public var d:String;
	
	public function new() {
		
	}
	
	@bindable public function toString():String {
		return '{C d:$d}';
	}
}
