package deep.tools.base;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
interface IReusable
{
	public function free():Void;
	
	public var isFree(default, null):Bool;
}