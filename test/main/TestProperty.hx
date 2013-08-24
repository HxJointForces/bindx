package main;
import bindx.IBindable;
import haxe.unit.TestCase;

using bindx.Bind;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class TestProperty extends TestCase {

	public function new() {
		super();
	}
	
	function testSimple() {
		var v = new Bs();
		var newValue = 0.0;
		var listener = function (from, to) { newValue = to; }
		v.b.bindx(listener );
		
		v.b = 20;
		
		assertEquals(newValue, v.b);
		
		v.b.unbindx(listener);
		
		v.b = 10;
		
		assertTrue(newValue != v.b);
	}
	
	function testRecursive() {
		var a = new A();
		var b = new Bs();
		var call = 0;
		a.a.b.bindx(function (from, to) {
			if (call == 0) {
				assertEquals(from, 0);
				assertEquals(to, 10);
			}
			call++;
		}, true);
		
		a.a = b;
		b.b = 12;
		
		assertEquals(call, 2);
	}
	
	function testRecursive2() {
		var a = new A();
		var b = new Bs();
		var call = 0;
		a.a = b;
		a.a.b.bindx(function (from, to) {
			call++;
		}, true);
		
		assertEquals(call, 1);
	}
	
	function testNonRecursive() {
		var a = new A();
		var b = new Bs();
		var call = 0;
		a.a = b;
		a.a.b.bindx(function (from, to) {
			call++;
		});
		
		a.a.b = 12;
		
		assertEquals(call, 2);
	}
	
}
@:keep class Bs implements IBindable {
	
	@bindable public var b(get, set):Float;
	var _b:Float;
	
	public function get_b():Float {
		return _b;
	}
	
	function set_b(v:Float):Float {
		_b = v;
		return v;
	}
	
	public function new() {
		_b = 10;
	}
}

@:keep private class A implements IBindable {
	
	@bindable public var a(get, set):Bs;
	var _a:Bs;
	
	public function get_a():Bs {
		return _a;
	}
	
	function set_a(v:Bs):Bs {
		_a = v;
		return v;
	}
	
	public function new() {
		//a = new Bs();
	}
}
