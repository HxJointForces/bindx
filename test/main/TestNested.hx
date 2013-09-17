package main;

import haxe.unit.TestCase;
import bindx.IBindable;

using bindx.Bind;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class TestNested extends TestCase
{

	public function new() {
		super();
	}
	
	function testNested() {
		var b = new main.nested.B();
		
		var aChanged = 0;
		b.a.bindx(function (_, _) { aChanged++; } );
		b.a = 12;
		assertTrue(aChanged == 2);
		
		var newB = 0;
		b.b.bindx(function (_, n) { newB = n; } );
		b.b = 10;
		
		assertEquals(newB, 10);
	}
	
}