package bindx;

import bindx.Bindable;
/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class BindTools {
	
	static public function on<T>(bindable:BindableBase<T>, listener:Void->Void) {
		bindable.add(listener);
	}
	
}

