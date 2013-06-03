package wrong;
import AbstractBindxTest.SimpleValue;
class WrongTest1  extends AbstractBindxTest
{
	function createValue() : SimpleValue {
		return new SimpleValue();
	}

	public function testGeneratedValue () {
		var v = createValue();

		v.def.bindx(function(_,_) {});
	}

	function createValue2() {
		return new SimpleValue();
	}

	public function testGeneratedValue2 () {
		var v = createValue2();

		v.def.bindx(function(_,_) {});
	}
}