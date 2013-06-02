package bindx;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

typedef BindingListener<T> = T->T->Void;
class BindingSignal
{

	public function new() 
	{
		clear();
	}
	
	public function clear() {
		listeners = new Map();
		needCopy = new Map();
	}
	
	var listeners:Map < String, Array < BindingListener<Dynamic> >> ;
	var needCopy:Map<String, Int>;
	
	public function add(type:String, listener:BindingListener<Dynamic>) {
		var ls = listeners.exists(type) ? listeners[type] : listeners[type] = [];
		if (needCopy.exists(type)) {
			if (needCopy[type] > 0)
				ls = listeners[type] = listeners[type].copy();
		} else needCopy[type] = 0;
		
		ls.remove(listener);
		ls.push(listener);
	}
	
	public function remove(type:String, listener:BindingListener<Dynamic>) {
		var ls = listeners.exists(type) ? listeners[type] : listeners[type] = [];
		if (needCopy.exists(type)) {
			if (needCopy[type] > 0)
				ls = listeners[type] = listeners[type].copy();
		} else needCopy[type] = 0;
		
		ls.remove(listener);
	}
	
	public function dispatch(type:String, oldValue:Dynamic, newValue:Dynamic) {
		if (!listeners.exists(type)) return;
		
		var ls = listeners[type];
		needCopy[type] = needCopy[type] + 1;
		for (l in ls) l(oldValue, newValue);
		needCopy[type] = needCopy[type] - 1;
	}
	
}