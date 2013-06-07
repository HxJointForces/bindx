package bindx;

/**
 * @author deep <system.grand@gmail.com>
 */

typedef FieldListener<T> = T->T->Void;
typedef GlobalFieldListener<T> = String->T->T->Void;

typedef MethodListener<T> = Void->Void;

typedef GlobalMethodListener<T> = String->Void;

class FieldsBindSignal extends BindSignal<FieldListener<Dynamic>, GlobalFieldListener<Dynamic>> {

	public function new() {
		super();
	}

	public function dispatch(type:String, oldValue:Dynamic, newValue:Dynamic):Void {
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

class MethodsBindSignal extends BindSignal<MethodListener<Dynamic>, GlobalMethodListener<Dynamic>> {

	public function new() {
		super();
	}

	public function dispatch(type:String):Void {
		if (globalListeners.length > 0) {
			needCopyGlobal ++;
			for (g in globalListeners) g(type);
			if (needCopyGlobal > 0) needCopyGlobal --;
		}

		if (!listeners.exists(type)) return;

		var ls = listeners[type];
		needCopy[type] = needCopy[type] + 1;
		for (l in ls) l();
		if (needCopy[type] > 0) needCopy[type] = needCopy[type] - 1;
	}
}

class BindSignal<ListenerType, GlobalListenerType> {

	function new() {
		clear();
	}
	
	public function clear():Void {
		listeners = new Map();
		needCopy = new Map();
		globalListeners = [];
		needCopyGlobal = 0;
	}
	
	public function destroy():Void {
		listeners = null;
		needCopy = null;
		globalListeners = null;
	}
	
	var globalListeners:Array<GlobalListenerType>;
	var needCopyGlobal:Int;
	
	var listeners:Map < String, Array < ListenerType >> ;
	var needCopy:Map<String, Int>;
	
	public function addGlobal(listener:GlobalListenerType):Void {
		if (needCopyGlobal > 0) {
			globalListeners = globalListeners.copy();
			needCopyGlobal --;
		}
		
		globalListeners.remove(listener);
		globalListeners.push(listener);
	}
	
	public function removeGlobal(listener:GlobalListenerType):Bool {
		if (needCopyGlobal > 0) {
			globalListeners = globalListeners.copy();
			needCopyGlobal --;
		}
		
		return globalListeners.remove(listener);
	}
	
	public function add(type:String, listener:ListenerType):Void {
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
	
	public function remove(type:String, listener:ListenerType):Bool {
		if (!listeners.exists(type)) return false;
		var ls;
		if (needCopy[type] > 0) {
			needCopy[type] = needCopy[type] - 1;
			listeners[type] = ls = listeners[type].copy();
		} else ls = listeners[type];
		
		var res = ls.remove(listener);
		if (res && ls.length == 0) {
			listeners.remove(type);
			needCopy[type] = 0;
		}

		return res;
	}
}