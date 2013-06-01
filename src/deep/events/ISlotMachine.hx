package deep.events;

import deep.tools.base.IDestructable;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

interface ISignal<T> extends ISlotMachine<T> {
	
	public function addListener(listener:T, ?priority:Int = 0):Slot<T>;
	public function existsListener(listener:T):Bool;
	public function removeListener(listener:T = null):Slot<T>;
	
	public function listener(listener:T, add:Bool):Slot<T>;
	
	public function getSlot(listener:T):Slot<T>;
	
	public function getNumListeners():Int;
}
 
interface IDispatcher<T> extends ISlotMachine<T> {
	
	public function addListener(type:Dynamic, listener:T, ?priority:Int = 0):Slot<T>;
	public function existsListener(type:Dynamic, listener:T):Bool;
	public function removeListener(type:Dynamic = null, listener:T = null):Slot<T>;
	
	public function listener(type:Dynamic, listener:T, add:Bool):Slot<T>;
	
	public function getSlot(type:Dynamic, listener:T):Slot<T>;
	
	public function getNumListeners(type:Dynamic = null):Int;
}

interface ISlotMachine<T> extends IDestructable {
	
	public function addSlot(s:Slot<T>):Slot<T>;
	public function removeSlot(s:Slot<T>):Slot<T>;
	
	public function slot(slot:Slot<T>, add:Bool):Slot<T>;
}

