package main;

import bindx.IBindable;
import bindx.Bind;

using bindx.Bind;

class TestFunctionBind extends AbstractBindxTest
{
	function createFunctionValue(obj : Dynamic) : BindableFunctionValue{
		return new BindableFunctionValue(obj);
	}

	public function testMultiFunctionDispatch() {
		var obj = {};
		var v = createFunctionValue(obj);

		var times = 5;
		var bindingDispatched = 0;

		v.returnMyObj.bindx(function(_, _) bindingDispatched++ );

		for(i in 0...times)
			Bind.notify(v.returnMyObj);

		assertEquals(times, bindingDispatched);
	}

	public function testBind() {
		var obj = {};
		var v = createFunctionValue(obj);

		var bindingDispatched = 0;

		v.returnMyObj.bindx(function(_, _) {
			assertEquals(0, bindingDispatched);

			assertEquals(obj, v.returnMyObj());

			bindingDispatched++;
		});

		Bind.notify(v.returnMyObj);
	}

	public function testUnbind() {
		var v = createFunctionValue();

		var bindingDispatched = 0;

		v.returnMyObj.unbindx(function(_, _) bindingDispatched++ );

		Bind.notify(v.returnMyObj);

		assertEquals(0, bindingDispatched);
	}
}

class BindableFunctionValue implements IBindable
{
	private var obj : Dynamic;
	public function new(obj : Dynamic) {
		this.obj = obj;
	}

	@bindable public function returnMyObj() : Dynamic {
		return obj;
	}
}