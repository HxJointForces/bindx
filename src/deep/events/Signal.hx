package deep.events;

import deep.tools.base.IDestructable;
import deep.events.ISlotMachine;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class Signal0 extends Signal<Void -> Void> {
	public function new() {
		super();
	}
	
	public function dispatch():Void {
		needCopy ++;
		for (l in listeners) {
			l.listener();
			if (l.onExecute != null) l.onExecute();
		}
		needCopy --;
    }
}

class Signal1<T> extends Signal< T -> Void > {
	
	public function new() {
		super();
	}
	
	public function dispatch(v:T):Void {
        needCopy ++;
		for (l in listeners) {
			l.listener(v);
			if (l.onExecute != null) l.onExecute();
		}
		needCopy --;
    }
}

class Signal2<T, K> extends Signal<T -> K -> Void>
{
	public function new() {
		super();
	}
	
	public function dispatch(v1:T, v2:K):Void {
        needCopy ++;
		for (l in listeners) {
			l.listener(v1, v2);
			if (l.onExecute != null) l.onExecute();
		}
		needCopy --;
    }
}

class Signal3<T, K, L> extends Signal<T -> K -> L -> Void>
{
	public function new() {
		super();
	}
	
	public function dispatch(v1:T, v2:K, v3:L):Void {
        needCopy ++;
		for (l in listeners) {
			l.listener(v1, v2, v3);
			if (l.onExecute != null) l.onExecute();
		}
		needCopy --;
    }
}

class Signal<T> implements ISignal<T>
{

    function new() {
		listeners = [];
    }

    var listeners:Array<Slot<T>>;
    var needCopy:Int;

    public function addListener(listener:T, ?priority:Int = null):Slot<T> {
        var s = findSlot(listener);
        if (s != null) {
			if (s.priority == priority) return s;
			removeSlot(s);
		}
        return addSlot(new Slot(null, listener, priority));
    }
	
    public function addSlot(s:Slot<T>):Slot<T> {
        if (s.dispatcher != null) throw "remove slot from prevent dispatcher";
        if (needCopy > 0) listeners = listeners.slice(0);
        var priority = s.priority;

		if (priority != null)
		{
			var n = listeners.length;
			var i = 0;
			while (i < n) {
				var p = listeners[i].priority;
				if (p != null && priority > p) {
					listeners.insert(i, s);
					break;
				}
				i++;
			}
			if (i == n) listeners.push(s);
		}
		else listeners.push(s);
        s.setDispatcher(this);

        return s;
    }
	
	public function listener(listener:T, add:Bool):Slot<T> {
		return if (add) addListener(listener); else removeListener(listener);
	}
	
	public function slot(slot:Slot<T>, add:Bool):Slot<T> {
		return if (add) addSlot(slot); else removeSlot(slot);
	}

    public function getSlot(listener:T):Slot<T> {
        return findSlot(listener);
    }

    public function existsListener(listener:T):Bool {
        return findSlot(listener) != null;
    }

    function findSlot(listener:T, remove:Bool = false):Slot<T> {
        if (remove && needCopy > 0) listeners = listeners.slice(0);
        var i = 0;
        for (s in listeners) {
            if (s.listener == listener) {
                if (remove) {
                    s.setDispatcher(null);
                    listeners.splice(i, 1);
                }
                return s;
            }
            i++;
        }
        return null;
    }

    public function removeListener(listener:T = null):Slot<T> {
        if (listener == null) {
			for (l in listeners) l.setDispatcher(null);
			listeners = [];
            return null;
        }
        return findSlot(listener, true);
    }

    public function removeSlot(s:Slot<T>):Slot<T> {
		#if debug if (s.dispatcher != this) throw "dispatcher doesn't contains slot"; #end
        if (needCopy > 0) listeners = listeners.slice(0);
		var pos = Lambda.indexOf(listeners, s);
		if (pos != -1)
		{
			s.setDispatcher(null);
			listeners.splice(pos, 1);
			return s;
		}
        return null;
    }
	
	public function getNumListeners():Int {
		return listeners.length;
	}
	
    public function destroy(deep:Bool = true) {
        removeListener();
        listeners = null;
		
		destructed = true;
    }
	
	public var destructed(default, null):Bool = false;
}