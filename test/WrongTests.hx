package ;
import haxe.unit.TestCase;
import bindx.Bind;

using Bind;

class WrongTests extends TestCase 
{
	public function new() {
	}

	public function testLocalVariable() {
		var v : Int = 0;
		v.binx(function(_,_) {});
	}
}
