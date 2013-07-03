bindx
====

Powerful and fast macro-based data binding engine inspired by Flex Bindings with easy-to-use syntax.

====


*Basic Usage*

Bind field
```
@bindable class Value implements IBindable {
	
	public var a:Int;
	
	public function new() {
		
	}
}

...

using bindx.Bind;
...

var v = new Value();
v.a = 12;

var a = { t:0 };
var unbindTo = v.a.bindxTo(a.t); // a.t == 12

var unbind = v.a.bindx(function (from:Int, to:Int) { trace('v.a changed from:$from to:$to'); } );
v.a = 10; // v.a changed from 12 to 10

unbind();
unbindTo();
```


Bind method
```
using bindx.Bind;

class Value implements IBindable {
	
	@bindable public var a:Int;
	
	@bindable public function toString() {
		return Std.string("Value: a=" + a);
	
	public function update() {
		toString.notify();  // bindx.Bind.notify(this.toString);
	}
	
	public function new() {
		
	}
}

...

using bindx.Bind;
...

var v = new Value();
v.a = 12;

var unbind = v.toString.bindx(function (res:String) { trace(res); } ); // Value: a=12

v.a = 0;
v.update(); // Value: a=0

v.a = 5;
v.toString.notify(); // Value: a=5

unbind();
```

Recursive fields and methods bind https://github.com/HxJointForces/bindx/blob/master/test/main/TestDeepBind.hx