package ;

class TestRunner extends haxe.unit.TestRunner
{
	public static function main()
	{
		var runner = new TestRunner();
		runner.add(new TestSimple());
		runner.add(new TestClassLevel());
		runner.run();
	}
}