package bindx;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

@:autoBuild(bindx.BindMacros.build())
interface IBindable
{
	public var __bindings__:BindingSignal; // autogenerated field
}