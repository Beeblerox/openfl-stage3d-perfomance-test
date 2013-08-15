package;

import flash.display.Sprite;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display.StageAlign;
import flash.display.StageQuality;
import flash.display.StageScaleMode;
import flash.display3D.Context3DRenderMode;
import flash.errors.Error;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.text.TextFieldAutoSize;
import flash.ui.Keyboard;

import lite.LiteSpriteStage;

using OpenFLStage3D;

/**
 * Stage3D teszt program, spriteokkal
 * @author Hortobágyi Tamás
 * @link http://active.tutsplus.com/tutorials/games/build-a-stage3d-shoot-em-up-sprite-test/
 */

class Main extends Sprite
{
	private var _spriteStage:LiteSpriteStage;
	private var stage3D:Stage3D;
	public static var _width:Float = 480;
	public static var _height:Float = 640;
	public var context3D:Context3D;
	
	private var bg:Background;
	private var tf:TextField;	
	
	private var fps:FPS;
	private var _bunnyLayer:BunnyLayer;
	private var _pirateLayer:PirateLayer;
	private var numBunnies:Int = 100;	
	private var incBunnies:Int = 100;
	
	static function main()
	{
		new Main();
	}
	
	public function new()
	{
		super();
		
		if (stage != null) init(0);
		else addEventListener(Event.ADDED_TO_STAGE, init);
		
		Lib.current.addChild(this);
	}
	
	private function init(_):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, init);
		stage.quality = StageQuality.LOW;
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.addEventListener(Event.RESIZE, onResizeEvent);
		
		stage.frameRate = 60;
		
		fps = new FPS();
		addChild(fps);
		createCounter();
		
		stage3D = stage.getStage3D(0);
		stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
		stage3D.addEventListener(ErrorEvent.ERROR, errorHandler);
		stage3D.requestContext3D();
	}
	
	private function createCounter():Void
	{
		var format:TextFormat = new TextFormat("_sans", 20, 0, true);
		format.align = TextFormatAlign.RIGHT;
		
		tf = new TextField();
		tf.selectable = false;
		tf.defaultTextFormat = format;
		tf.text = "Click here\n"+ "Bunnies:" + numBunnies;
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.x = _width - 145;
		tf.y = 10;
		addChild(tf);
		
		tf.addEventListener(MouseEvent.CLICK, counter_click);
	}
	
	private function counter_click(e:MouseEvent):Void 
	{
		if (numBunnies == 16250) 
		{
			//we've reached the limit for vertex buffer length
			tf.text = "Bunnies \n(Limit):\n" + numBunnies;
		}
		else 
		{
			if (numBunnies >= 1500) incBunnies = 250;
		
			_bunnyLayer.addBunny(incBunnies);
			numBunnies += incBunnies;
		
			tf.text = "Click here\n"+ "Bunnies:" + numBunnies;
		}
	}
	
	private function onContext3DCreate(e:Event):Void
	{
		context3D = stage3D.context3D;
		initSpriteEngine();
	}
	
	private function errorHandler(e:ErrorEvent):Void
	{
		trace(e);
	}
	
	private function onResizeEvent(e:Event):Void
	{
		if (stage3D.context3D != null)
		{
			context3D = stage3D.context3D;
			_spriteStage.onContext(context3D);
		}
		
		_width = stage.stageWidth;
		_height = stage.stageHeight;
		
		// Resize Stage3D to continue to fit screen
		var view:Rectangle = new Rectangle(0, 0, _width, _height);
		if (_spriteStage != null) 
		{
			_spriteStage.rect = view;
		}
		if (_bunnyLayer != null) 
		{
			_bunnyLayer.setPosition(view);
		}
		if (_pirateLayer != null) 
		{
			_pirateLayer.setPosition(view);	
		}
		if (bg != null) 
		{
			bg.setPosition(view);
		}
		if (tf != null) 
		{
			tf.x = _width - 100;
		}
	}
	
	private function initSpriteEngine():Void
	{
		// init gpu sprite system
		var stageRect:Rectangle = new Rectangle(0, 0, _width, _height);
		_spriteStage = new LiteSpriteStage(stage3D, context3D, stageRect);
		_spriteStage.configureBackBuffer(_width, _height);
		
		//add background which does not use any framework, use render() to make the necessary draw calls
		bg = new Background(context3D,_width,_height);
		
		//add bunny layer
		var view:Rectangle = new Rectangle(0, 0, _width, _height);
		_bunnyLayer = new BunnyLayer(view);
		_bunnyLayer.createRenderLayer(context3D);
		_spriteStage.addBatch(_bunnyLayer._renderLayer);
		_bunnyLayer.addBunny(numBunnies);
		
		//add pirate layer on top
		_pirateLayer = new PirateLayer(view);
		_pirateLayer.createRenderLayer(context3D);
		_spriteStage.addBatch(_pirateLayer._renderLayer);
		_pirateLayer.addPirate();
		
		// render loop indítása
		context3D.setRenderCallback(onEnterFrame);
	}
	
	// Ez rajzolja a scenet, minden képkockában
	private function onEnterFrame(e:Event):Void
	{
		try
		{
			context3D.clear(0,1,0,1);
			bg.render();
			var timer:Float = Lib.getTimer();
			_bunnyLayer.update(timer);
			_pirateLayer.update(timer);
			_spriteStage.renderDeferred();

			context3D.present();
			
			fps.update();
		}
		catch (e:Error)
		{
			// this can happen if the computer goes to sleep and
			// then re-awakens, requiring reinitialization of stage3D
			// (the onContext3DCreate will fire again)
		}
	}
}