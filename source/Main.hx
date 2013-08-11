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
import flash.geom.Rectangle;
import flash.Lib;

using OpenFLStage3D;

/**
 * Stage3D teszt program, spriteokkal
 * @author Hortobágyi Tamás
 * @link http://active.tutsplus.com/tutorials/games/build-a-stage3d-shoot-em-up-sprite-test/
 */

class Main extends Sprite
{
	private var _entities:EntityManager;
	private var _spriteStage:LiteSpriteStage;
	private var _gui:GameGUI;
	private var stage3D:Stage3D;
	public static var _width:Float = 600;
	public static var _height:Float = 400;
	public var context3D:Context3D;
	
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
		
		_gui = new GameGUI("Egyszerű Stage3D Sprite Demo v1");
		addChild(_gui);
		
		stage3D = stage.getStage3D(0);
		stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
		stage3D.addEventListener(ErrorEvent.ERROR, errorHandler);
		stage3D.requestContext3D();
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
		
		// Korrekt méret beállítása
		_width = stage.stageWidth;
		_height = stage.stageHeight;
		// Stage3D átméretezése, hogy igazodjon az ablakhoz
		var view:Rectangle = new Rectangle(0, 0, _width, _height);
		if (_spriteStage != null) _spriteStage.rect = view;
		if (_entities != null) _entities.setpos(view);
	}
	
	private function initSpriteEngine():Void
	{
		// init gpu sprite system
		var stageRect:Rectangle = new Rectangle(0, 0, _width, _height);
		_spriteStage = new LiteSpriteStage(stage3D, context3D, stageRect);
		_spriteStage.configureBackBuffer(_width, _height);
		
		// create single rendering batch, which will draw all sprites in one pass
		var view:Rectangle = new Rectangle(0, 0, _width, _height);
		_entities = new EntityManager(stageRect);
		_entities.createBatch(context3D);
		_spriteStage.addBatch(_entities.batch);
		// első entity azonnali hozzáadása
		_entities.addEntity();
		// gui-nak megadni, honnan vegye a statisztikát
		_gui.statsTarget = _entities;
		
		// render loop indítása
		context3D.setRenderCallback(onEnterFrame);
	}
	
	// Ez rajzolja a scenet, minden képkockában
	private function onEnterFrame(e:Event):Void
	{
		try
		{
			// egyre több sprite-ot ad hozzá - ÖRÖKKÉ!
			_entities.addEntity();
			// töröljük az előző képkockát
			context3D.clear(0, 0, 0, 1);
			// mozgatjuk, animáljuk az összes sprite-ot
			_entities.update(Lib.getTimer());
			// kirajzoljuk az összes elemet
			_spriteStage.render();
			// frissítjük a képernyőt
			context3D.present();
		}
		catch (e:Error)
		{
			// this can happen if the computer goes to sleep and
			// then re-awakens, requiring reinitialization of stage3D
			// (the onContext3DCreate will fire again)
		}
	}
}