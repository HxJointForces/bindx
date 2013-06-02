package bindx;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

typedef BindingListener<T> = T->T->Void;

typedef GlobalBindingListener<T> = String->T->T->Void;

class BindSignal {

	public function new() {
		clear();
	}
	
	public function clear() {
		listeners = new Map();
		needCopy = new Map();
		globalListeners = [];
		needCopyGlobal = 0;
	}
	
	public function destroy() {
		listeners = null;
		needCopy = null;
		globalListeners = null;
	}
	
	var globalListeners:Array<GlobalBindingListener<Dynamic>>;
	var needCopyGlobal:Int;
	
	var listeners:Map < String, Array < BindingListener<Dynamic> >> ;
	var needCopy:Map<String, Int>;
	
	public function addGlobal(listener:GlobalBindingListener<Dynamic>) {
		if (needCopyGlobal > 0) {
			globalListeners = globalListeners.copy();
			needCopyGlobal --;
		}
		
		globalListeners.remove(listener);
		globalListeners.push(listener);
	}
	
	public function removeGlobal(listener:GlobalBindingListener<Dynamic>) {
		if (needCopyGlobal > 0) {
			globalListeners = globalListeners.copy();
			needCopyGlobal --;
		}
		
		globalListeners.remove(listener);
	}
	
	public function add(type:String, listener:BindingListener<Dynamic>) {
		var ls;
		if (!listeners.exists(type)) {
			needCopy[type] = 0;
			listeners[type] = ls = [];
		} else if (needCopy[type] > 0) {
			needCopy[type] = needCopy[type] - 1;
			listeners[type] = ls = listeners[type].copy();
		} else ls = listeners[type];
		
		ls.remove(listener);
		ls.push(listener);
	}
	
	public function remove(type:String, listener:BindingListener<Dynamic>) {
		if (!listeners.exists(type)) return;
		var ls;
		if (needCopy[type] > 0) {
			needCopy[type] = needCopy[type] - 1;
			listeners[type] = ls = listeners[type].copy();
		} else ls = listeners[type];
		
		ls.remove(listener);
		if (ls.length == 0) {
			listeners.remove(type);
			needCopy.remove(type);
		}
	}
	
	public function dispatch(type:String, oldValue:Dynamic, newValue:Dynamic) {
		if (globalListeners.length > 0) {
			needCopyGlobal ++;
			for (g in globalListeners) g(type, oldValue, newValue);
			if (needCopyGlobal > 0) needCopyGlobal --;
		}
		
		if (!listeners.exists(type)) return;
		
		var ls = listeners[type];
		needCopy[type] = needCopy[type] + 1;
		for (l in ls) l(oldValue, newValue);
		if (needCopy[type] > 0) needCopy[type] = needCopy[type] - 1;
	}
	
}