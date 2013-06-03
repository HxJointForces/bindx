package wrong;
import AbstractBindxTest.SimpleValue;
import haxe.unit.TestCase;
import bindx.Bind;

using Bind;

class WrongTests extends AbstractBindxTest 
{
	public function testLocalVariable() {
		var def;

		def.bindx(function(_, _) {});

		def = 14;
	}

	public function testLocalVariable2() {
		var def;

		def.bindx(function(_, _) {});
	}

}