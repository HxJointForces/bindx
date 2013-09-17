package ;

import main.TestForce;
import main.TestNested;
import main.TestProperty;
import main.TestBindTo;
import main.TestDeepBind;
import main.TestBasicBind;
import main.TestSubClass;
import main.WrongTests;
import main.WrongTest1;
import main.TestFunctionBind;
import main.TestClassLevel;
import main.TestSimple;

class TestRunner extends haxe.unit.TestRunner
{
	public static function main()
	{
		var runner = new TestRunner();
		runner.add(new TestProperty());
		runner.add(new TestSimple());
		runner.add(new TestClassLevel());
		runner.add(new TestFunctionBind());
		runner.add(new WrongTest1());
		runner.add(new WrongTests());
		runner.add(new TestSubClass());
		runner.add(new TestBasicBind());
		runner.add(new TestDeepBind());
		runner.add(new TestBindTo());
		runner.add(new TestForce());
		runner.add(new TestNested());
		runner.run();
	}
}