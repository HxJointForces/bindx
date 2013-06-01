package deep.events;

import deep.events.ISlotMachine;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class Slot<T> {
	
    public var type(default, null):Dynamic;
    public var listener(default, null):T;
    public var priority(default, null):Null<Int>;
	
    public var dispatcher(default, null):ISlotMachine<Dynamic>;

    public function new(type:Dynamic, listener:T, priority:Null<Int> = null) {
		#if debug if (listener == null) throw "listener can't be null"; #end
        this.type = type;
        this.listener = listener;
        this.priority = priority;
    }
	
	@:allow(deep.events.Dispatcher)
	@:allow(deep.events.Signal)
	function setDispatcher(d:ISlotMachine<Dynamic>) {
		dispatcher = d;
	}
	
	public var onExecute:Void->Void;
}

class OnceSlot<T> extends Slot<T> {
	
	public function new(type:Dynamic, listener:T, priority:Null<Int> = null) {
		super(type, listener, priority);
		onExecute = function () {
			if (dispatcher != null) dispatcher.removeSlot(this);
		}
	}
}