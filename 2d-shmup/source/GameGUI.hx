package ;

import flash.events.Event;
import flash.events.TimerEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.Lib;

/**
 * gui statisztika: FPS, Memória használat, stb.
 * @author Hortobágyi Tamás
 */

class GameGUI extends TextField
{
	public var titleText:String;
	public var statsText:String;
	public var statsTarget:EntityManager;
	private var frameCount:Int;
	private var timer:Int;
	private var ms_prev:Int;
	private var lastfps:Float;
	
	public function new(title:String = "", inX:Float = 8.0, inY:Float = 8.0, inCol:Int = 0xffffff)
	{
		super();
		
		frameCount = 0;
		lastfps = 60;
		statsText = "";
		
		titleText = title;
		x = inX;
		y = inY;
		width = 500;
		selectable = false;
		defaultTextFormat = new TextFormat("_sans", 9, 0, true);
		text = "";
		textColor = inCol;
		addEventListener(Event.ADDED_TO_STAGE, onAddedHandler);
	}
	
	private function onAddedHandler(e:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedHandler);
		stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	private function onEnterFrame(e:Event):Void
	{
		timer = Lib.getTimer();
		
		if (timer - 1000 > ms_prev) // 1 másodperc eltelt
		{
			lastfps = Math.round(frameCount / (timer - ms_prev) * 1000);
			ms_prev = timer;
			// statisztikai adatokat az Entity manager-től
			if (statsTarget != null)
			{
				statsText = statsTarget.numCreated + ' created ' +
							statsTarget.numReused + ' reused';
			}
			
			text = titleText + " - " + statsText + " - FPS: " + lastfps;
			frameCount = 0;
		}
		// framek számolása
		frameCount++;
	}
}