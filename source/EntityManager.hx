package ;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Vector;
import openfl.Assets;

/**
 * ...
 * @author Hortobágyi Tamás
 */

class EntityManager
{
	private var spriteSheet:LiteSpriteSheet;
	static private var SpritePerRow:Int = 8;
	static private var SpritePerCol:Int = 8;
	// újrahasznosításhoz pool
	private var entityPool:Vector<Entity>;
	// minden poligon, ami a scene-hez kell
	public var batch:LiteSpriteBatch;
	// statisztikához
	public var numCreated:Int;
	public var numReused:Int;
	
	private var minX:Int;
	private var minY:Int;
	private var maxX:Int;
	private var maxY:Int;
	
	public function new(view:Rectangle)
	{
		numCreated = numReused = 0;
		
		entityPool = new Vector<Entity>();
		setpos(view);
	}
	
	/**
	 * Ez mindenkor meg van hívva, ha átméretezzük a scenet, vagy a NEW-nál.
	 * Adunk a széleihez pár extra pixelt, hogy ne csak úgy hirtelen jelenjenek meg a sprite-ok.
	 * @param	view
	 */
	public function setpos(view:Rectangle):Void
	{
		// engedjük, hogy teljesen elhagyja a képernyőt, mielőtt újrahasznosítjuk
		maxX = Std.int(view.x + view.width + 32); // ehhez tudni kell a max méretét 1 sprite-nak
		minX = Std.int(view.x - 32);
		maxY = Std.int(view.y + view.height);
		minY = Std.int(view.y);
	}
	
	/**
	 * Az entity manager induláskor egyszer futtatja le ezt. Létrehoz egy új geometry batch-t,
	 * a spritesheet képet használva. Elküldi a bitmapData-t a spritesheet osztály konstruktorának,
	 * ami texturát generál minden rajta lévő sprite-képből. Ezek a képek leszenk felhasználva a batch geometry renderer által.
	 *
	 * Ha akarjuk, több spritesheet is használható, több képet inicializálva. A jövőben itt lesz implementálva
	 * a 2. batch a talaj-kockáihoz az űrhajó alá, vagy lehet 3. batchnak minden fölé részecske effekteket, stb.
	 * @param	context3D
	 * @return
	 */
	public function createBatch(context3D:Context3D):LiteSpriteBatch
	{
		var sourceBitmap:BitmapData = Assets.getBitmapData("assets/sprites.png");
		
		// spriteSheetek legenerálása 8x8 (64) sprittal
		spriteSheet = new LiteSpriteSheet(sourceBitmap, SpritePerRow, SpritePerCol);
		// új render batch generálás
		batch = new LiteSpriteBatch(context3D, spriteSheet);
		
		return batch;
	}
	
	/**
	 * Keres egy nem használt entity-t és újrahasználatba veszi
	 * Ha mind használatban van, akkor létre hoz 1 újat.
	 * @param	sprID
	 * @return
	 */
	public function respawn(sprID:UInt = 0):Entity
	{
		var anEntity:Entity;
		for (i in 0 ... entityPool.length)
		{
			anEntity = entityPool[i];
			if (!anEntity.active && anEntity.sprite.spriteId == sprID)
			{
				anEntity.active = true;
				anEntity.sprite.visible = true;
				numReused++;
				return anEntity;
			}
		}
		// egyet sem találtumk, így létrehozunk egyet
		anEntity = new Entity(batch.createChild(sprID));
		entityPool.push(anEntity);
		numCreated++;
		return anEntity;
	}
	
	/**
	 * teszthez kreálunk véletlenszerű entity-t, ami balról jobbra mozog véletlenszerű sebességgel, és méretben
	 */
	public function addEntity():Void
	{
		var anEntity:Entity, randomSpriteID:UInt = Std.int(Math.random() * 64);
		// megpróbálunk egy nem használt elemet újrahasználni
		anEntity = respawn(randomSpriteID);
		// adunk neki új pozíciót, sebességet, méretet
		anEntity.sprite.pos.x = maxX;
		anEntity.sprite.pos.y = Math.random() * (maxY - minY) + minY;
		anEntity.speedX = Math.random() * ( -10) - 2;
		anEntity.speedY = Math.random() * 5 - 2.5;
		anEntity.sprite.scaleX = 0.5 + Math.random() * 1.5;
		anEntity.sprite.scaleY = anEntity.sprite.scaleX;
		anEntity.sprite.rotation = 15 - Math.random() * 30;
	}
	
	/**
	 * Minden frame-ben meghívódik: frissít és szimulációt végez.
	 * Ide fog kerülni az AI, fizika, stb.
	 * @param	currentTime
	 */
	public function update(currentTime:Float):Void
	{
		var anEntity:Entity;
		
		for (i in 0 ... entityPool.length)
		{
			anEntity = entityPool[i];
			if (anEntity.active) // csak aktívra frissít
			{
				anEntity.sprite.pos.x += anEntity.speedX;
				anEntity.sprite.pos.y += anEntity.speedY;
				anEntity.sprite.rotation += 0.1;
				
				if (anEntity.sprite.pos.x > maxX) // ha rossz irányba menne...
				{
					anEntity.speedX *= -1;
					anEntity.sprite.pos.x = maxX;
				}
				else if (anEntity.sprite.pos.x < minX) // ha elérte a kép szélét
				{
					// inaktiváljuk
					anEntity.die();
				}
				// függőleges ellenőrzés
				if (anEntity.sprite.pos.y > maxY)
				{
					anEntity.speedY *= -1;
					anEntity.sprite.pos.y = maxY;
				}
				else if (anEntity.sprite.pos.y < minY)
				{
					anEntity.speedY *= -1;
					anEntity.sprite.pos.y = minY;
				}
			}
		}
	}
}