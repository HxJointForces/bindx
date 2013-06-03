package ;

class TestRunner extends haxe.unit.TestRunner
{
	public static function main()
	{
		var runner = new TestRunner();
		runner.add(new TestBindx());
		runner.run();
	}
}