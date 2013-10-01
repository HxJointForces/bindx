package main;

import AbstractBindxTest.SimpleValue;

using bindx.Bind;

class TestClassLevel extends AbstractBindxTest
{

	public function testSimpleBind() {
		var v = createClassLevelValue();

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
		var v = createClassLevelValue();

		var times = 5;
		var bindingDispatched = 0;

		v.def.bindx(function(oldValue, newValue) bindingDispatched++ );

		for(i in 0...times)
			v.def = i+1;

		assertEquals(times + 1, bindingDispatched);
	}

	public function testSimpleUnbind() {
		var v = createClassLevelValue();

		var bindingDispatched = 0;

		var listener = function(oldValue, newValue) bindingDispatched++;
		var unbind = v.def.bindx(listener);
		v.def.unbindx(listener);

		v.def = 42;

		assertEquals(0 + 1, bindingDispatched);
	}
}