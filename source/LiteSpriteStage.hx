package ;

import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.Vector;

/**
 * ...
 * @author Hortobágyi Tamás
 */

class LiteSpriteStage
{
	private var _stage3D:Stage3D;
	private var _context3D:Context3D;
	
	private var _rect:Rectangle;
	
	public var rect(get, set):Rectangle;
	private var _batches:Vector<LiteSpriteBatch>;
	public var _modelViewMatrix(get, null):Matrix3D;
	
	public function new(stage3D:Stage3D, context3D:Context3D, rect:Rectangle)
	{
		_stage3D = stage3D;
		_context3D = context3D;
		_batches = new Vector<LiteSpriteBatch>();
		
		this.rect = rect;
	}
	
	private function get_rect():Rectangle { return _rect; }
	
	private function set_rect(rect:Rectangle):Rectangle
	{
		_stage3D.x = rect.x;
		_stage3D.y = rect.y;
		configureBackBuffer(rect.width, rect.height);
		
		_modelViewMatrix = new Matrix3D();
		_modelViewMatrix.appendTranslation( -rect.width / 2.0, -rect.height / 2.0, 0);
		_modelViewMatrix.appendScale(2.0 / rect.width, -2.0 / rect.height, 1);
		
		return (_rect = rect);
	}
	
	private function get__modelViewMatrix():Matrix3D { return _modelViewMatrix; }
	
	public function configureBackBuffer(width:Float, height:Float):Void
	{
		_context3D.configureBackBuffer(Std.int(width), Std.int(height), 0, false);
	}
	
	public function addBatch(batch:LiteSpriteBatch):Void
	{
		batch.parent = this;
		_batches.push(batch);
	}
	
	public function removeBatch(batch:LiteSpriteBatch):Void
	{
		var i:UInt = _batches.indexOf(batch);
		if (i >= 0)
		{
			batch.parent = null;
			_batches.splice(i, 1);
		}
	}

	/**
	 * Minden batch-t itt rajzol ki, ha több is lenne, ide kerülne
	 */
	public function render():Void
	{
		for (i in 0 ... _batches.length) _batches[i].draw();
	}
}