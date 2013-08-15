package lite;

import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Vector;

/**
 * ...
 * @author Hortobágyi Tamás
 */
class LiteSpriteSheet
{
	public var texture:Texture;
	
	private var spriteSheet:BitmapData;
	private var uvCoords:Vector<Float>;
	private var rects:Vector<Rectangle>;
	
	public function new(width:UInt, height:UInt)
	{
		spriteSheet = new BitmapData(width, height, true, 0);
        uvCoords = new Vector<Float>();
        rects = new Vector<Rectangle>();
	}
	
	// TODO: reimplement
	public function createUVs(numSpritesW:Int, numSpritesH:Int, start:Point = null, end:Point = null):Void
	{
		/*if (start == null)	start = new Point(0, 0);
		if (end == null) end = new Point(spriteSheet.width, spriteSheet.height);
		
		var destRect:Rectangle, i:Int = uvCoords.length;
		
		for (y in 0 ... (numSpritesH))
		{
			for (x in 0 ... (numSpritesW))
			{
				uvCoords[i++] = x / numSpritesW; uvCoords[i++] = (y + 1) / numSpritesH;
				uvCoords[i++] = x / numSpritesW; uvCoords[i++] = y / numSpritesH;
				uvCoords[i++] = (x + 1) / numSpritesW; uvCoords[i++] = y / numSpritesH;
				uvCoords[i++] = (x + 1) / numSpritesW; uvCoords[i++] = (y + 1) / numSpritesH;
				
				destRect = new Rectangle();
				destRect.left = 0.0;
				destRect.top = 0.0;
				destRect.right = spriteSheet.width / numSpritesW;
				destRect.bottom = spriteSheet.height / numSpritesH;
				rects.push(destRect);
			}
		}*/
	}
	
	// Very simplistic for now...assume client will manage the packing of the sprite sheet bitmap
	// Returns sprite ID
	public function addSprite(srcBits:BitmapData, srcRect:Rectangle, destPt:Point):UInt
	{
		spriteSheet.copyPixels(srcBits, srcRect, destPt);
		
		var destRect:Rectangle = new Rectangle();
		destRect.left = destPt.x;
		destRect.top = destPt.y;
		destRect.right = destRect.left + srcRect.width;
		destRect.bottom = destRect.top + srcRect.height;
		
		rects.push(destRect);
		
		uvCoords.push(destRect.x / spriteSheet.width);
		uvCoords.push(destRect.y / spriteSheet.height + destRect.height / spriteSheet.height);
		uvCoords.push(destRect.x / spriteSheet.width);
		uvCoords.push(destRect.y / spriteSheet.height);
		uvCoords.push(destRect.x / spriteSheet.width + destRect.width / spriteSheet.width);
		uvCoords.push(destRect.y / spriteSheet.height);
		uvCoords.push(destRect.x / spriteSheet.width + destRect.width / spriteSheet.width);
		uvCoords.push(destRect.y / spriteSheet.height + destRect.height / spriteSheet.height);

		return rects.length - 1;
	}
	
	public function removeSprite(spriteId:Int):Void
	{
		if (spriteId < uvCoords.length)
		{
			uvCoords = uvCoords.splice(spriteId * 8, 8);
			rects.splice(spriteId, 1);
		}
	}
	
	public function getNumSprites():UInt { return rects.length; }
	
	public function getRect(spriteID:UInt):Rectangle { return rects[spriteID]; }
	
	public function getUVCoords(spriteID:UInt):Vector<Float>
	{
		var startIdx:UInt = spriteID * 8;
		return uvCoords.slice(startIdx, startIdx + 8);
	}
	
	/**
	 * Ez generálja a mipmap-okat
	 * @param	context3D
	 */
	public function uploadTexture(context3D:Context3D):Void
	{
		if (texture != null) 
		{
			texture.dispose();
		}
		
		texture = context3D.createTexture(spriteSheet.width, spriteSheet.height, Context3DTextureFormat.BGRA, false);
		texture.uploadFromBitmapData(spriteSheet);
		
		// generate mipmaps
		var currentWidth:Int = spriteSheet.width >> 1;
		var currentHeight:Int = spriteSheet.height >> 1;
		var level:Int = 1;
		var canvas:BitmapData = new BitmapData(currentWidth, currentHeight, true, 0);
		var transform:Matrix = new Matrix(0.5, 0, 0, 0.5);
		while (currentWidth >= 1 || currentHeight >= 1)
		{
			canvas.fillRect(new Rectangle(0, 0, Math.max(currentWidth, 1), Math.max(currentHeight, 1)), 0);
			canvas.draw(spriteSheet, transform, null, null, null, true);
			texture.uploadFromBitmapData(canvas, level++);
			transform.scale(0.5, 0.5);
			currentWidth >>= 1;
			currentHeight >>= 1;
		}
	}
}