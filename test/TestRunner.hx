package ;

class TestRunner extends haxe.unit.TestRunner
{
	public static function main()
	{
		var runner = new GeneratedTestRunner();
		runner.add(new TestBindx());
		runner.run();
	}
}