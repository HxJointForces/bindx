package ;

import haxe.unit.TestCase;
import bindx.IBindable;

using bindx.Bind;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class TestBindx extends AbstractBindxTest
{
	@bindable public var def:Int;

	@bindable public function toString():String {
		return '$def!';
	}

	public function new() {
		super();
	}

	public function testBasic() {
		var oldDef = this.def;
		var newDef = 12;
		var bindingDispatched = 0;

		this.def.bindx(function(oldValue, newValue) {
			bindingDispatched++;
			assertEquals(oldDef, oldValue);
			assertEquals(newDef, newValue);
		});

		this.def = newDef;

		assertEquals(1, bindingDispatched);
	}

}