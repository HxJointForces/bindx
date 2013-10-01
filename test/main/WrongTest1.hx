package main;

import AbstractBindxTest.SimpleValue;

using bindx.Bind;

class WrongTest1  extends AbstractBindxTest
{
	function createValue() : SimpleValue {
		return new SimpleValue();
	}

	public function testGeneratedValue () {
		var v = createValue();

		v.def.bindx(function(_,_) {});
		v.toString.bindx(function() {});

		assertTrue(true);
	}

	function createValue2() {
		return new SimpleValue();
	}

	public function testGeneratedValue2 () {
		var v = createValue2();

		v.def.bindx(function(_,_) {});

		assertTrue(true);
	}
}