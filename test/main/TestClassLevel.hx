package main;

import AbstractBindxTest.SimpleValue;
import haxe.unit.TestCase;
import bindx.IBindable;

using bindx.Bind;

class TestClassLevel extends AbstractBindxTest
{

	public function testSimpleBind() {
		var v = createClassLevelValue();

		var oldDef = v.def;
		var newDef = 42;
		var bindingDispatched = 0;

		v.def.bindx(function(oldValue, newValue) {
			assertEquals(0, bindingDispatched);

			assertEquals(oldDef, oldValue);
			assertEquals(newDef, newValue);

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
			v.def = i;

		assertEquals(times, bindingDispatched);
	}

	public function testSimpleUnbind() {
		var v = createClassLevelValue();

		var bindingDispatched = 0;

		v.def.unbindx(function(oldValue, newValue) bindingDispatched++ );

		v.def = 42;

		assertEquals(0, bindingDispatched);
	}
}