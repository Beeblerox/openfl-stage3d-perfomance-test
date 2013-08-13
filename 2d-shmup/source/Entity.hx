package ;

/**
 * Ez tartalmazz a ajáték specifikus elemek logikáját űrhajókhoz, lövésekhez, effektekhez
 * Kezdetnek csak referenciák a gpu sprite-hoz és pár demó értékhez.
 * Később kiegészül ütközésvizygálattal, fegyverekkel, képeségekkel, stb.
 * @author Hortobágyi Tamás
 */

class Entity
{
	
	public var speedX:Float;
	public var speedY:Float;
	public var sprite:LiteSprite;
	public var active:Bool;
	
	public function new(?gs:LiteSprite)
	{
		active = true;
		sprite = gs;
		speedX = speedY = 0.0;
	}
	
	public function die():Void
	{
		// engedélyezzük az újrahasznosíthatóságot
		active = false;
		// átugrunk minden rajzolást, frissítést
		sprite.visible = false;
	}
}