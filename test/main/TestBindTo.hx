package main;
import bindx.IBindable;
import haxe.unit.TestCase;

using bindx.Bind;
/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class TestBindTo extends TestCase {

	public function new() {
		super();
	}
	
	function testBindTo() {
		var v = new Value();
		v.a = 12;
		
		var a = { t:10 };
		var unbind = v.a.bindxTo(a.t);
		
		assertEquals(a.t, 12);
		
		v.a = 15;
		
		assertEquals(a.t, 15);
		
		unbind();
		
		v.a = 0;
		
		assertEquals(a.t, 15);
	}
	
}

private typedef MyInt = Int;

@bindable private class Value implements IBindable {
	
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