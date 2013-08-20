package main;

import AbstractBindxTest.SimpleValue;

using bindx.Bind;

class TestSimple extends AbstractBindxTest
{

	public function testSimpleBind() {
		var v = createSimpleValue();

		var oldDef = v.def;
		var newDef = 42;
		var bindingDispatched = 0;

		v.def.bindx(function(oldValue, newValue) {
			if (bindingDispatched == 0) {
				assertEquals(0, oldValue);
				assertEquals(newValue, oldDef);
			} else {
				assertEquals(oldDef, oldValue);
				assertEquals(newDef, newValue);
			}
			bindingDispatched++;
		});

		v.def = newDef;
	}

	public function testMultiDispatch() {
		var v = createSimpleValue();

		var times = 5;
		var bindingDispatched = 0;

		v.def.bindx(function(oldValue, newValue) { bindingDispatched++; } );

		for(i in 0...times)
			v.def = i+1;

		assertEquals(times + 1, bindingDispatched);
	}

	public function testSimpleUnbind() {
		var v = createSimpleValue();

		var bindingDispatched = 0;

		var unbind = v.def.bindx(function(oldValue, newValue) bindingDispatched++ );
		unbind();

		v.def = 42;

		assertEquals(0 + 1, bindingDispatched); // 1 auto call
	}
}