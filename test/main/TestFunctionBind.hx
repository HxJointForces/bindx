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

		v.returnMyObj.bindx(function() bindingDispatched++ );

		for(i in 0...times)
			Bind.notify(v.returnMyObj);

		assertEquals(times + 1, bindingDispatched);
	}

	public function testBind() {
		var obj = {};
		var v = createFunctionValue(obj);

		var bindingDispatched = 0;

		v.returnMyObj.bindx(function() {

			assertEquals(obj, v.returnMyObj());

			bindingDispatched++;
		});

		Bind.notify(v.returnMyObj);
		assertEquals(2, bindingDispatched);
	}

	public function testUnbind() {
		var obj = {};
		var v = createFunctionValue(obj);

		var bindingDispatched = 0;

		var listener;
		var unBind = v.returnMyObj.bindx(listener = function() bindingDispatched++);

		v.returnMyObj.unbindx(listener);

		Bind.notify(v.returnMyObj);

		assertEquals(0 + 1, bindingDispatched); // +1 AUTO
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