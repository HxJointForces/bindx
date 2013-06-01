package deep.tools;
import haxe.ds.ObjectMap;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class ObjectCache<K:{}, V> {

	var keys:Array<K>;
	var items:Map<K, V>;
	
	public var size(default, set):Int;
	
	function set_size(v) {
		if (v < 0) v = 0;
		size = v;
		update();
		return v;
	}
	
	public dynamic function canRemove(item:V):Bool return true;
	
	public function new(size = 10) {
		keys = [];
		items = new Map();
		
		this.size = size;
	}
	
	public function set(k:K, v:V) {
		remove(k);
		keys.push(k);
		items.set(k, v);
		update();
	}
	
	public function exists(k:K) {
		return items.exists(k);
	}
	
	inline public function remove(k:K) {
		if (keys.remove(k)) items.remove(k);
	}
	
	public function get(k:K) {
		return items.get(k);
	}
	
	function update() {
		if (keys.length > size) {
			var i = 0;
			var p = 0;
			while (i++ < keys.length && keys.length > size) {
				var k = keys[p];
				if (canRemove(get(k))) {
					keys.shift();
					items.remove(k);
				} else p++;
			}
		}
	}
	
	
	
}