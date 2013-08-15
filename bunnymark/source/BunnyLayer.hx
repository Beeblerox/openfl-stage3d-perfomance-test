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
import flash.Vector;
import lite.LiteSprite;
import lite.LiteSpriteBatch;
import lite.LiteSpriteSheet;
import openfl.Assets;

class BunnyLayer
{
	private var _bunnies:Vector<BunnySprite>;
	private var _spriteSheet:LiteSpriteSheet;
	public var _renderLayer:LiteSpriteBatch;
	private var _bunnySpriteID:UInt;
	
	private var gravity:Float = 0.5;
	private var maxX:Int;
	private var minX:Int;
	private var maxY:Int;
	private var minY:Int;	
	
	public function new(view:Rectangle)
	{
		setPosition(view);
		_bunnies = new Vector<BunnySprite>();
		
	}
	public function setPosition(view:Rectangle):Void 
	{
		maxX = Std.int(view.width);
		minX = Std.int(view.x);
		maxY = Std.int(view.height);
		minY = Std.int(view.y);
	}
	
	public function createRenderLayer(context3D:Context3D):LiteSpriteBatch 
	{
		_spriteSheet = new LiteSpriteSheet(64, 64);
		//add bunny image to sprite sheet
		var bunnyBitmap:BitmapData = Assets.getBitmapData("assets/wabbit_alpha.png");
		var destPt:Point = new Point(0, 0);
		_bunnySpriteID = _spriteSheet.addSprite(bunnyBitmap, bunnyBitmap.rect, destPt);
		
		// Create new render layer 
		_renderLayer = new LiteSpriteBatch(context3D, _spriteSheet);
		
		return _renderLayer;
	}
	
	public function addBunny(numBunnies:Int):Void 
	{
		var bunny:BunnySprite;
		var sprite:LiteSprite;
		for (i in 0...numBunnies) 
		{	
			sprite = _renderLayer.createChild(_bunnySpriteID);
			bunny = new BunnySprite(sprite);
			bunny.speedX = Math.random() * 5;
			bunny.speedY = (Math.random() * 5) - 2.5;
			bunny.gpuSprite.scaleX = 0.3 + Math.random();
			bunny.gpuSprite.scaleY = bunny.gpuSprite.scaleX;
			bunny.gpuSprite.rotation = 15 - Math.random() * 30;
			_bunnies.push(bunny);
		}
	}
	
	public function update(currentTime:Float):Void
	{		
		var bunny:BunnySprite;
		var len:Int = _bunnies.length;
		for (i in 0...len)
		{
			bunny = _bunnies[i];
			bunny.gpuSprite.position.x += bunny.speedX;
			bunny.gpuSprite.position.y += bunny.speedY;
			bunny.speedY += gravity;
			bunny.gpuSprite.alpha = 0.3 + 0.7 * bunny.gpuSprite.position.y / maxY;
			
			if (bunny.gpuSprite.position.x > maxX)
			{
				bunny.speedX *= -1;
				bunny.gpuSprite.position.x = maxX;
			}
			else if (bunny.gpuSprite.position.x < minX)
			{
				bunny.speedX *= -1;
				bunny.gpuSprite.position.x = minX;
			}
			if (bunny.gpuSprite.position.y > maxY)
			{
				bunny.speedY *= -0.8;
				bunny.gpuSprite.position.y = maxY;
				if (Math.random() > 0.5) bunny.speedY -= 3 + Math.random() * 4;
			} 
			else if (bunny.gpuSprite.position.y < minY)
			{
				bunny.speedY = 0;
				bunny.gpuSprite.position.y = minY;
			}	
		}
	}
}