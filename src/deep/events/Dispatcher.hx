package deep.events;

import deep.tools.base.IDestructable;
import deep.events.ISlotMachine;
import haxe.ds.ObjectMap;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class Dispatcher0 extends Dispatcher < Void -> Void > {
	
	public function new() {
		super();
	}
	
	public function dispatch(type:Dynamic):Void {
        var ls = listeners.get(type);
        if (ls != null) {
            incCopy(type);
            for (l in ls) {
				l.listener();
				if (l.onExecute != null) l.onExecute();
			}
            decCopy(type);
        }
    }
}

class Dispatcher1<T> extends Dispatcher < T -> Void > {
	
	public function new() {
		super();
	}
	
	public function dispatch(type:Dynamic, v:T):Void {
        var ls = listeners.get(type);
        if (ls != null) {
            incCopy(type);
            for (l in ls) {
				l.listener(v);
				if (l.onExecute != null) l.onExecute();
			}
            decCopy(type);
        }
    }
}

class Dispatcher2 < T, K > extends Dispatcher < T -> K -> Void > {
	
	public function new() {
		super();
	}
	
	public function dispatch(type:Dynamic, v1:T, v2:K):Void {
        var ls = listeners.get(type);
        if (ls != null) {
            incCopy(type);
            for (l in ls) {
				l.listener(v1, v2);
				if (l.onExecute != null) l.onExecute();
			}
            decCopy(type);
        }
    }
}

class Dispatcher3 < T, K, L > extends Dispatcher < T -> K -> L -> Void > {
	
	public function new() {
		super();
	}
	
	public function dispatch(type:Dynamic, v1:T, v2:K, v3:L):Void {
        var ls = listeners.get(type);
        if (ls != null) {
            incCopy(type);
            for (l in ls) {
				l.listener(v1, v2, v3);
				if (l.onExecute != null) l.onExecute();
			}
            decCopy(type);
        }
    }
}

class Dispatcher<T> implements IDispatcher<T>
{
    function new() {
		
		listeners = new ObjectMap();
		needCopy = new ObjectMap();
    }

    var listeners:ObjectMap<Dynamic, Array<Slot<T>>>;
    var needCopy:ObjectMap<Dynamic, Int>;
	
	@:extern inline function incCopy(type:Dynamic)
	{
		if (needCopy.exists(type)) needCopy.set(type, needCopy.get(type) + 1);
			else needCopy.set(type, 1);
	}
	
	@:extern inline function decCopy(type:Dynamic)
	{
		var v = needCopy.get(type);
		if (v > 1) needCopy.set(type, v - 1);
		else needCopy.remove(type);
	}

    public function addListener(type:Dynamic, listener:T, ?priority:Int = null):Slot<T> {
		#if debug if (type == null) throw "type can't be null"; #end
        var s = findSlot(type, listener);
        if (s != null) {
			if (s.priority == priority) return s;
			removeSlot(s);
		}
        return addSlot(new Slot(type, listener, priority));
    }
	
    public function addSlot(s:Slot<T>):Slot<T> {
        #if debug if (s.type == null) throw "s.type can't be null"; #end
		if (s.dispatcher != null) throw "remove slot from prevent dispatcher";
        var ls = listeners.get(s.type);
		if (ls == null) listeners.set(s.type, ls = []);
        else if (needCopy.exists(s.type)) listeners.set(s.type, ls = ls.copy());
        var priority = s.priority;

		if (priority != null)
		{
			var n = ls.length;
			var i = 0;
			var p:Null<Int> = null;
			while (i < n) {
				p = ls[i].priority;
				if (p != null && priority > p) {
					ls.insert(i, s);
					break;
				}
				i++;
			}
			if (i == n) {
				if (priority != null && p != null && p > priority) ls.unshift(s);
				else ls.push(s);
			}
		}
		else ls.push(s);
        s.setDispatcher(this);

        return s;
    }

    public function getSlot(type:Dynamic, listener:T):Slot<T> {
        return findSlot(type, listener);
    }

    public function existsListener(type:Dynamic, listener:T):Bool {
        return findSlot(type, listener) != null;
    }
	
	public function listener(type:Dynamic, listener:T, add:Bool):Slot<T> {
		return if (add) addListener(type, listener); else removeListener(type, listener);
	}
	
	public function slot(slot:Slot<T>, add:Bool):Slot<T> {
		return if (add) addSlot(slot); else removeSlot(slot);
	}

    function findSlot(type:Dynamic, listener:T, remove:Bool = false):Slot<T> {
		#if debug if (type == null) throw "type can't be null"; #end
		#if debug if (listener == null) throw "listener can't be null"; #end
        var ls = listeners.get(type);
		if (ls == null) return null;
        if (remove && needCopy.exists(type)) listeners.set(type, ls = ls.copy());
        var i = 0;
        for (s in ls) {
            if (s.listener == listener) {
                if (remove) {
                    s.setDispatcher(null);
                    ls.splice(i, 1);
                    if (ls.length == 0) listeners.remove(type);
                }
                return s;
            }
            i++;
        }
        return null;
    }

    public function removeListener(type:Dynamic = null, listener:T = null):Slot<T> {
        if (listener == null) {
            if (type == null) {
				for (a in listeners)
					for (l in a) l.setDispatcher(null);
				listeners = new ObjectMap();
			}
            else {
				if (listeners.exists(type)) {
					for (l in listeners.get(type)) l.setDispatcher(null);
					listeners.remove(type);
				}
			}
            return null;
        }
        return findSlot(type, listener, true);
    }

    public function removeSlot(s:Slot<T>):Slot<T> {
		#if debug if (s.dispatcher != this) throw "dispatcher doesn't contains slot"; #end
        var ls = listeners.get(s.type);
		if (ls == null) return null;
        if (needCopy.exists(s.type)) listeners.set(s.type, ls = ls.copy());
		var pos = Lambda.indexOf(ls, s);
		if (pos != -1)
		{
			s.setDispatcher(null);
			ls.splice(pos, 1);
			if (ls.length == 0) listeners.remove(s.type);
			return s;
		}
        return null;
    }
	
	public function getNumListeners(type:Dynamic = null):Int {
		if (type == null)
		{
			var n = 0;
			for (l in listeners) n += l.length;
			return n;
		}
		var l = listeners.get(type);
		return l != null ? l.length : 0;
	}
	
    public function destroy(deep:Bool = true) {
        removeListener(null);
        listeners = null;
		
		destructed = true;
    }
	
	public var destructed(default, null):Bool = false;
}