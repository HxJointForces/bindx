package ;

import haxe.unit.TestCase;
import bindx.IBindable;

using bindx.Bind;

class AbstractBindxTest extends TestCase {

	public function new() {
		super();
	}

	function createSimpleValue() : SimpleValue {
		return new SimpleValue();
	}

	function createClassLevelValue() : ClassLevelValue {
		return new ClassLevelValue();
	}

}

class SimpleValue implements IBindable
{
	@bindable public var def:Int;

	public function new() {
	}
}

@bindable class ClassLevelValue implements IBindable
{
	@bindable public var def:Int;

	public function new() {
	}
}