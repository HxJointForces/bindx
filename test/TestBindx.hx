package ;

import haxe.unit.TestCase;
import bindx.IBindable;

using bindx.Bind;

class TestBindx extends TestCase
{
	public function testBind() {
		var v : SimpleValue = new SimpleValue();
		
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

	public function testUnbind() {
		var v : SimpleValue = new SimpleValue();

		var bindingDispatched = 0;

		v.def.unbindx(function(oldValue, newValue) {
			bindingDispatched++;
		});

		v.def = 42;

		assertEquals(0, bindingDispatched);
	}

}


class SimpleValue implements IBindable
{
	@bindable public var def:Int;

	public function new() {
	}
}