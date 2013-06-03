package ;

import main.TestFunctionBind;
import main.TestClassLevel;
import main.TestSimple;
class TestRunner extends haxe.unit.TestRunner
{
	public static function main()
	{
		var runner = new TestRunner();
		runner.add(new TestSimple());
		runner.add(new TestClassLevel());
		runner.add(new TestFunctionBind());
		runner.run();
	}
}