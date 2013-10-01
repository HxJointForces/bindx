package ;


class TestRunner extends haxe.unit.TestRunner
{
	public static function main()
	{
		var runner = new TestRunner();
		runner.add(new main.TestProperty());
		runner.add(new main.TestSimple());
		runner.add(new main.TestClassLevel());
		runner.add(new main.TestFunctionBind());
		runner.add(new main.WrongTest1());
		runner.add(new main.WrongTests());
		runner.add(new main.TestSubClass());
		runner.add(new main.TestBasicBind());
		runner.add(new main.TestDeepBind());
		runner.add(new main.TestBindTo());
		runner.add(new main.TestForce());
		runner.run();
	}
}