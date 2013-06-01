package bindx;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class Bind {
	
	static public function on(src:IBindable, srcProp:String, listener:Dynamic->Void) {
		src.__bindings__.addListener(function (n) {
			if (n == srcProp)
				listener(Reflect.getProperty(src, srcProp));
		});
	}
	
	static public function bind(src:IBindable, srcProp:String, target:Dynamic, targetProp:String) {
		src.__bindings__.addListener(function (n) {
			if (n == srcProp)
				Reflect.setProperty(target, targetProp, Reflect.getProperty(src, srcProp));
		});
	}
	
}

