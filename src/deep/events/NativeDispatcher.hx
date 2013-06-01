package deep.events;

#if (flash || nme)

import deep.events.Dispatcher;
import flash.events.Event;
import flash.events.IEventDispatcher;
/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class NativeDispatcher<E:Event> extends Dispatcher<E -> Void> {
	
	public var target(default, null):IEventDispatcher;
	
	public function new(target:IEventDispatcher) {
		#if debug if (target == null) throw "target can't be null"; #end
		this.target = target;
		super();
	}
	
	override public function addSlot(s:Slot < E -> Void > ):Slot < E -> Void > {
		target.addEventListener(s.type, dispatch);
		return super.addSlot(s);
	}
	
	override public function removeSlot(s:Slot<E -> Void>):Slot<E -> Void> {
		var res = super.removeSlot(s);
		if (!listeners.exists(s.type))
			target.removeEventListener(s.type, dispatch);
			
		return res;
	}
	
	override public function removeListener(type:Dynamic = null, listener:E -> Void = null):Slot<E -> Void> {
		if (listener == null) {
            if (type == null) {
				for (a in listeners.keys())
					target.removeEventListener(a, dispatch);
			}
        }
		
		var res = super.removeListener(type, listener);
		
		if (type != null && !listeners.exists(type))
			target.removeEventListener(type, dispatch);
			
		return res;
	}
	
	public function dispatch(v:E):Void {
        var ls = listeners.get(v.type);
        if (ls != null) {
            incCopy(v.type);
            for (l in ls) {
				l.listener(v);
				if (l.onExecute != null) l.onExecute();
			}
            decCopy(v.type);
        }
    }
}

#else
#error
#end