package bindx;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class BindableBase<T> {
	
	public var value:T;
	
	var listeners:Array<Dynamic>;
	
	public function add(f:Void->Void) {
		listeners.remove(f);
		listeners.push(f);
	}
	
	public function remove(f:Void->Void) {
		listeners.remove(f);
	}
	
	public function dispatch() {
		for (l in listeners) {
			l();
		}
	}
	
	public function new(value:T) {
		this.value = value;
		listeners = [];
	}
	
}
abstract Bindable<T>(BindableBase<T>)
{

	public function new(value:BindableBase<T>) 
	{
		this = value;
	}
	
	@:from inline static function fromT<T>(v:T):Bindable<T>
		return new Bindable<T>(new BindableBase<T>(v));
		
	inline public function __dispatch__() this.dispatch();
	
	inline public function setValue(v:T) this.value = v;
	
	@:to inline function toT():T return this.value;
	
	@:to inline function toBT():BindableBase<T> return this;
	
}
