package ;

using bindx.Bind;

/**
 *  @author Dima Granetchi <system.grand@gmail.com>
 */

import bindx.IBindable;
class Main
{
	static function main() {
		var a = new A();

		//a.b.c.bindx2(function (o, n) {trace('$o -> $n'); });
		a.b.c.d.bindx2(function (o, n) {trace('$o -> $n'); });
	}
}

class A implements IBindable {

	@bindable public var b:B;
	
	@bindable public var b2:B2;
	
	public function test(i:Int):B {
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
}
