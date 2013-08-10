package ;

import flash.geom.Point;
import flash.geom.Rectangle;

/**
 * ...
 * @author Hortobágyi Tamás
 */

class LiteSprite
{
	public var parent:LiteSpriteBatch;
	public var spriteId:UInt;
	public var childId:UInt;
	//public var pos(getPosition, setPosition):Point;
	public var pos:Point;
	public var visible:Bool;
	public var scaleX:Float;
	public var scaleY:Float;
	public var rotation:Float;
	public var alpha:Float;
	
	/**
	 * Tipikusan LiteSpriteBatch.creatChild() hívás hoz létre újat.
	 */
	public function new()
	{
		parent = null;
		spriteId = 0;
		childId = 0;
		pos = new Point();
		scaleX = 1.0;
		scaleY = 1.0;
		rotation = 0.0;
		alpha = 1.0;
		visible = true;
	}
	
	public function rect():Rectangle { return parent._sprites.getRect(spriteId); }
}