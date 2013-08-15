/*
========================================================================
=      ================================  =====  ==================  ====
=  ===  ===============================   ===   ==================  ====
=  ====  ==============================  =   =  ==================  ====
=  ===  ===  =  ==  = ===  = ===  =  ==  == ==  ===   ===  =   ===  =  =
=      ====  =  ==     ==     ==  =  ==  =====  ==  =  ==    =  ==    ==
=  ===  ===  =  ==  =  ==  =  ===    ==  =====  =====  ==  =======   ===
=  ====  ==  =  ==  =  ==  =  =====  ==  =====  ===    ==  =======    ==
=  ===  ===  =  ==  =  ==  =  ==  =  ==  =====  ==  =  ==  =======  =  =
=      =====    ==  =  ==  =  ===   ===  =====  ===    ==  =======  =  =
========================================================================

* Copyright (c) 2012 Julian Wixson / Aaron Charbonneau - Adobe Systems
*
* Special thanks to Iain Lobb - iainlobb@googlemail.com for the original BunnyMark:
*
* http://blog.iainlobb.com/2010/11/display-list-vs-blitting-results.html 
*
* Special thanks to Philippe Elsass - philippe.elsass.me for the modified BunnyMark benchmark:
*
* http://philippe.elsass.me/2011/11/nme-ready-for-the-show/
*
* This program is distributed under the terms of the MIT License as found 
* in a file called LICENSE. If it is not present, the license
* is always available at http://www.opensource.org/licenses/mit-license.php.
*
* This program is distributed in the hope that it will be useful, but
* without any waranty; without even the implied warranty of merchantability
* or fitness for a particular purpose. See the MIT License for full details.
*/

package;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import lite.LiteSprite;
import lite.LiteSpriteBatch;
import lite.LiteSpriteSheet;
import openfl.Assets;

class PirateLayer
{
	private var pirate:LiteSprite;
	private var pirateHalfWidth:Int;
	private var pirateHalfHeight:Int;
	private var _spriteSheet:LiteSpriteSheet;
	private var _pirateSpriteID:UInt;
	private var maxX:Int;
	private var minX:Int;
	private var maxY:Int;
	private var minY:Int;
	
	public var _renderLayer:LiteSpriteBatch;
	
	public function new(view:Rectangle)
	{
		setPosition(view);
	}
	
	public function createRenderLayer(context3D:Context3D):LiteSpriteBatch 
	{
		_spriteSheet = new LiteSpriteSheet(256, 256);
		//add pirate image to sprite sheet
		var pirateBitmap:BitmapData = Assets.getBitmapData("assets/pirate.png");
		//adjust for different anchor point of GPUSprite vs DisplayList
		pirateHalfWidth = Std.int(pirateBitmap.width / 2);
		pirateHalfHeight = Std.int(pirateBitmap.height / 2);
		
		var destPt:Point = new Point(0,0);	
		_pirateSpriteID = _spriteSheet.addSprite(pirateBitmap, pirateBitmap.rect, destPt);
		
		// Create new render layer 
		_renderLayer = new LiteSpriteBatch(context3D, _spriteSheet);
		
		return _renderLayer;
	}
	
	public function setPosition(view:Rectangle):Void 
	{
		maxX = Std.int(view.width);
		minX = Std.int(view.x);
		maxY = Std.int(view.height);
		minY = Std.int(view.y);
	}
	
	public function addPirate():Void {
		pirate = _renderLayer.createChild(_pirateSpriteID);
		pirate.position = new Point((maxX - pirateHalfWidth) * (0.5), (maxY - pirateHalfHeight + 70));
	}
	
	public function update(currentTime:Float):Void
	{		
		pirate.position.x = (maxX - (pirateHalfWidth)) * (0.5 + 0.5 * Math.sin(currentTime / 3000));
		pirate.position.y = (maxY - (pirateHalfHeight) + 70 - 30 * Math.sin(currentTime / 100));
	}
}