package wrong;
import AbstractBindxTest.SimpleValue;
import haxe.unit.TestCase;

using bindx.Bind;

class WrongTests extends AbstractBindxTest 
{
var a:String;
	public function testLocalVariable() {
		var def = 14;

		//def.bindx(function(_, _) {});

		assertTrue(true);
	}

	public function testLocalVariable2() {
		var def;

		//def.bindx(function(_, _) {});

		assertTrue(true);
	}

}