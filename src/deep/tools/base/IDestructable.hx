package deep.tools.base;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
interface IDestructable 
{
	public function destroy(deep:Bool = true):Void;
	
	public var destructed(default, null):Bool;
}