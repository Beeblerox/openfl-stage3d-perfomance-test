////////////////////////////////////////////////////////////
// Stage3D Game Template - Chapter 5
// (c) by Christer Kaitila (http://www.mcfunkypants.com)
// http://www.mcfunkypants.com/molehill/chapter_5_demo/
////////////////////////////////////////////////////////////
// With grateful acknowledgements to:
// Thibault Imbert, Ryan Speets, Alejandro Santander, 
// Mikko Haapoja, Evan Miller and Terry Patton
// for their valuable contributions.
////////////////////////////////////////////////////////////
// Please buy the book:
// http://link.packtpub.com/KfKeo6
////////////////////////////////////////////////////////////
package;

import com.adobe.utils.PerspectiveMatrix3D;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.Stage3D;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Context3DProgramType;
import flash.display3D.shaders.glsl.GLSLProgram;
import flash.display3D.textures.Texture;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;
import flash.Vector;
import openfl.Assets;

import flash.display3D.shaders.glsl.GLSLFragmentShader;
import flash.display3D.shaders.glsl.GLSLVertexShader;

using OpenFLStage3D;

class Stage3dGame extends Sprite
{
	// used by the GUI
	private var fpsLast:Int = 0;
	private var fpsTicks:Int = 0;
	private var fpsTf:TextField;
	private var scoreTf:TextField;
	private var score:Int = 0;

	// constants used during inits
	private var swfWidth:Int = 640;
	private var swfHeight:Int = 480;
	// for this demo, ensure ALL textures are 512x512
	private var textureSize:Int = 512;

	// the 3d graphics window on the stage
	private var context3D:Context3D;
	private var stage3D:Stage3D;
	// the compiled shaders used to render our mesh
	private var shaderProgram1:GLSLProgram;
	private var shaderProgram2:GLSLProgram;
	private var shaderProgram3:GLSLProgram;
	private var shaderProgram4:GLSLProgram;

	// matrices that affect the mesh location and camera angles
	private var projectionmatrix:PerspectiveMatrix3D;
	private var modelmatrix:Matrix3D;
	private var viewmatrix:Matrix3D;
	private var terrainviewmatrix:Matrix3D;
	private var modelViewProjection:Matrix3D;

	// a simple frame counter used for animation
	private var t:Float = 0;
	// a reusable loop counter
	private var looptemp:Int = 0;

	private var myTextureData:BitmapData;
	private var terrainTextureData:BitmapData;

	// The Stage3d Texture that uses the above myTextureData
	private var myTexture:Texture;
	private var terrainTexture:Texture;

	// The spaceship mesh data
	private var myMesh:Stage3dObjParser;
	private var terrainMesh:Stage3dObjParser;

	public function new() 
	{
		super();
		
		if (stage != null) 
		{
			init();
		}
		else 
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(e:Event = null):Void 
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		stage.frameRate = 60;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		fpsLast = Lib.getTimer();
		
		projectionmatrix = new PerspectiveMatrix3D();
		modelmatrix = new Matrix3D();
		viewmatrix = new Matrix3D();
		terrainviewmatrix = new Matrix3D();
		modelViewProjection = new Matrix3D();
		
		myTextureData = Assets.getBitmapData("assets/spaceship_texture.jpg");
		terrainTextureData = Assets.getBitmapData("assets/terrain_texture.jpg");
		
		// add some text labels
		initGUI();
		
		// and request a context3D from Stage3d
		stage3D = stage.getStage3D(0);
		stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
		stage3D.addEventListener(ErrorEvent.ERROR, onError);
		stage3D.requestContext3D();
	}
	
	private function onError(event:ErrorEvent):Void
	{
	    trace(event);
    }

	private function updateScore():Void
	{
		// for now, you earn points over time
		score++;
		// padded with zeroes
		if (score < 10) scoreTf.text = 'Score: 00000' + score;
		else if (score < 100) scoreTf.text = 'Score: 0000' + score;
		else if (score < 1000) scoreTf.text = 'Score: 000' + score;
		else if (score < 10000) scoreTf.text = 'Score: 00' + score;
		else if (score < 100000) scoreTf.text = 'Score: 0' + score;
		else scoreTf.text = 'Score: ' + score;
	}

	private function initGUI():Void
	{
		// a text format descriptor used by all gui labels
		var myFormat:TextFormat = new TextFormat();  
		myFormat.color = 0xFFFFFF;
		myFormat.size = 13;

		// create an FPSCounter that displays the framerate on screen
		fpsTf = new TextField();
		fpsTf.x = 0;
		fpsTf.y = 0;
		fpsTf.selectable = false;
		fpsTf.autoSize = TextFieldAutoSize.LEFT;
		fpsTf.defaultTextFormat = myFormat;
		fpsTf.text = "Initializing Stage3d...";
		addChild(fpsTf);

		// create a score display
		scoreTf = new TextField();
		scoreTf.x = 560;
		scoreTf.y = 0;
		scoreTf.selectable = false;
		scoreTf.autoSize = TextFieldAutoSize.LEFT;
		scoreTf.defaultTextFormat = myFormat;
		scoreTf.text = "000000";
		addChild(scoreTf);

		// add some labels to describe each shader
		var label1:TextField = new TextField();
		label1.x = 100;
		label1.y = 180;
		label1.selectable = false;  
		label1.autoSize = TextFieldAutoSize.LEFT;  
		label1.defaultTextFormat = myFormat;
		label1.text = "Shader 1: Textured";
		addChild(label1);

		var label2:TextField = new TextField();
		label2.x = 400;
		label2.y = 180;
		label2.selectable = false;  
		label2.autoSize = TextFieldAutoSize.LEFT;  
		label2.defaultTextFormat = myFormat;
		label2.text = "Shader 2: Vertex RGB";
		addChild(label2);
		
		var label3:TextField = new TextField();
		label3.x = 80;
		label3.y = 440;
		label3.selectable = false;  
		label3.autoSize = TextFieldAutoSize.LEFT;  
		label3.defaultTextFormat = myFormat;
		label3.text = "Shader 3: Vertex RGB + Textured";
		addChild(label3);
		
		var label4:TextField = new TextField();
		label4.x = 340;
		label4.y = 440;
		label4.selectable = false;  
		label4.autoSize = TextFieldAutoSize.LEFT;  
		label4.defaultTextFormat = myFormat;
		label4.text = "Shader 4: Textured + setProgramConstants";
		addChild(label4);
	}

	public function uploadTextureWithMipmaps(dest:Texture, src:BitmapData):Void
	{
		var ws:Int = src.width;
		var hs:Int = src.height;
		var level:Int = 0;
		var tmp:BitmapData;
		var transform:Matrix = new Matrix();
		var tmp2:BitmapData;

		tmp = new BitmapData(src.width, src.height, true, 0x00000000);

		while (ws >= 1 && hs >= 1)
		{                                
			tmp.draw(src, transform, null, null, null, true);    
			dest.uploadFromBitmapData(tmp, level);
			transform.scale(0.5, 0.5);
			level++;
			ws >>= 1;
			hs >>= 1;
			if (hs > 0 && ws > 0) 
			{
				tmp.dispose();
				tmp = new BitmapData(ws, hs, true, 0x00000000);
			}
		}
		tmp.dispose();
	}

	private function onContext3DCreate(event:Event):Void 
	{
		// Remove existing frame handler. Note that a context
		// loss can occur at any time which will force you
		// to recreate all objects we create here.
		// A context loss occurs for instance if you hit
		// CTRL-ALT-DELETE on Windows.			
		// It takes a while before a new context is available
		// hence removing the enterFrame handler is important!

		if (hasEventListener(Event.ENTER_FRAME))
		{
			removeEventListener(Event.ENTER_FRAME, enterFrame);
		}
		
		// Obtain the current context
		context3D = stage3D.context3D; 	

		if (context3D == null) 
		{
			// Currently no 3d context is available (error!)
			return;
		}
		
		// Disabling error checking will drastically improve performance.
		// If set to true, Flash sends helpful error messages regarding
		// AGAL compilation errors, uninitialized program constants, etc.
		context3D.enableErrorChecking = true;
		
		// Initialize our mesh data
		initData();
		
		// The 3d back buffer size is in pixels (2=antialiased)
		context3D.configureBackBuffer(swfWidth, swfHeight, 2, true);

		// assemble all the shaders we need
		initShaders();

		myTexture = context3D.createTexture(textureSize, textureSize, Context3DTextureFormat.BGRA, false);
		uploadTextureWithMipmaps(myTexture, myTextureData);

		terrainTexture = context3D.createTexture(textureSize, textureSize, Context3DTextureFormat.BGRA, false);
		uploadTextureWithMipmaps(terrainTexture, terrainTextureData);
		
		// create projection matrix for our 3D scene
		projectionmatrix.identity();
		// 45 degrees FOV, 640/480 aspect ratio, 0.1=near, 100=far
		projectionmatrix.perspectiveFieldOfViewRH(45.0, swfWidth / swfHeight, 0.01, 5000.0);
		
		// create a matrix that defines the camera location
		viewmatrix.identity();
		// move the camera back a little so we can see the mesh
		viewmatrix.appendTranslation(0, 0, -3);

		// tilt the terrain a little so it is coming towards us
		terrainviewmatrix.identity();
		terrainviewmatrix.appendRotation( -60, Vector3D.X_AXIS);
		
		// start the render loop!
		context3D.setBlendFactors(flash.display3D.Context3DBlendFactor.SOURCE_ALPHA, flash.display3D.Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
        context3D.setRenderCallback(enterFrame);
	}

	// create four different shaders
	private function initShaders():Void
	{
		var vertexShaderSource =
			"attribute vec3 vertexPosition;
		    attribute vec2 uv;
		    attribute vec4 col;
			uniform mat4 modelViewMatrix;
			varying vec2 vTexCoord;
			varying vec4 vTexColor;
			void main(void) {
				gl_Position = modelViewMatrix * vec4(vertexPosition, 1.0);
				vTexCoord = uv;
				vTexColor = col;
			}";

        var vertexAgalInfo = '{"varnames":{"vertexPosition":"va0","uv":"va1","col":"va2","modelViewMatrix":"vc0"},"agalasm":"m44 op, va0, vc0\\nmov v0, va0\\nmov v1, va1\\nmov v2, va2","storage":{},"types":{},"info":"","consts":{}}';
		
		var fragmentShaderSource1 =
			"varying vec2 vTexCoord;
			 uniform sampler2D texture;
		     void main(void) {
		        gl_FragColor = texture2D(texture, vTexCoord);
			}";
		
		var fragmentAgalInfo1 = '{"varnames":{"texture":"fs0"},"agalasm":"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\\nmov oc, ft0","storage":{},"types":{},"info":"","consts":{}}';
		
		var fragmentShaderSource2 =
			"varying vec4 vTexColor;
			 void main(void) {
		        gl_FragColor = vTexColor;
			}";
		
		var fragmentAgalInfo2 = '{"varnames":{"texture":"fs0"},"agalasm":"sub ft0, v2, fc1\\ntex ft1, v2, fs0 <2d,linear,repeat,miplinear>\\nmov oc, v2","storage":{},"types":{},"info":"","consts":{}}';
		
		var fragmentShaderSource3 =
			"varying vec2 vTexCoord;
			 varying vec4 vTexColor;
			 uniform sampler2D texture;
		     void main(void) {
		        vec4 texColor = texture2D(texture, vTexCoord);
				gl_FragColor = texColor * vTexColor;
			}";
		
		var fragmentAgalInfo3 = '{"varnames":{"texture":"fs0"},"agalasm":"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\\nmul ft1, v2, ft0\\nmov oc, ft1","storage":{},"types":{},"info":"","consts":{}}';
		
		var fragmentShaderSource4 =
			"varying vec2 vTexCoord;
			 uniform vec4 colorMultiplier;
			 uniform sampler2D texture;
		     void main(void) {
		        vec4 texColor = texture2D(texture, vTexCoord);
				gl_FragColor = texColor * vec4(1.0, 1.0, 1.0, 1.0);
			}";
		
		var fragmentAgalInfo4 = '{"varnames":{"texture":"fs0","colorMultiplier":"fc0"},"agalasm":"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\\nmul ft1, fc0, ft0\\nmov oc, ft1","storage":{},"types":{},"info":"","consts":{}}';
		
		var vertexShader = new GLSLVertexShader(vertexShaderSource, vertexAgalInfo);
        var fragmentShader1 = new GLSLFragmentShader(fragmentShaderSource1, fragmentAgalInfo1);
        var fragmentShader2 = new GLSLFragmentShader(fragmentShaderSource2, fragmentAgalInfo2);
        var fragmentShader3 = new GLSLFragmentShader(fragmentShaderSource3, fragmentAgalInfo3);
        var fragmentShader4 = new GLSLFragmentShader(fragmentShaderSource4, fragmentAgalInfo4);
		
		shaderProgram1 = new GLSLProgram(context3D);
        shaderProgram1.upload(vertexShader, fragmentShader1);
		
		shaderProgram2 = new GLSLProgram(context3D);
        shaderProgram2.upload(vertexShader, fragmentShader2);
		
		shaderProgram3 = new GLSLProgram(context3D);
        shaderProgram3.upload(vertexShader, fragmentShader3);
		
		shaderProgram4 = new GLSLProgram(context3D);
        shaderProgram4.upload(vertexShader, fragmentShader4);
	}

	private function initData():Void 
	{
		// parse the OBJ file and create buffers
		myMesh = new Stage3dObjParser(Assets.getText("assets/spaceship.obj"), context3D, 1, true, true);
		// parse the terrain mesh as well
		terrainMesh = new Stage3dObjParser(Assets.getText("assets/terrain.obj"), context3D, 1, true, true);
	}		

	private function renderTerrain():Void
	{
		// simple textured shader
		shaderProgram1.attach();
		shaderProgram1.setTextureAt("texture", terrainTexture);
		// position
		shaderProgram1.setVertexBufferAt("vertexPosition", terrainMesh.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		// tex coord
		shaderProgram1.setVertexBufferAt("uv", terrainMesh.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		// vertex rgba
		shaderProgram1.setVertexBufferAt("col", terrainMesh.colorsBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
		// set up camera angle
		modelmatrix.identity();
		// make the terrain face the right way
		modelmatrix.appendRotation( -90, Vector3D.Y_AXIS);
		// slowly move the terrain around
		modelmatrix.appendTranslation(Math.cos(t / 300) * 1000, Math.cos(t / 200) * 1000 + 500, -130);
		// clear the matrix and append new angles
		modelViewProjection.identity();
		modelViewProjection.append(modelmatrix);
		modelViewProjection.append(terrainviewmatrix);
		modelViewProjection.append(projectionmatrix);	
		// pass our matrix data to the shader program
		shaderProgram1.setVertexUniformFromMatrix("modelViewMatrix",modelViewProjection,true);
        
		context3D.drawTriangles(terrainMesh.indexBuffer, 0, terrainMesh.indexBufferCount);		
	}

	private function enterFrame(e:Event):Void 
	{
		if (context3D == null)
		{
			return;
		}
		
		// clear scene before rendering is mandatory
		context3D.clear(0, 0, 0);
		// move or rotate more each frame
		t += 2.0;
		// scroll and render the terrain once
		renderTerrain();
		// how far apart each of the 4 spaceships is
		var dist:Float = 0.8; 
		
		var program:GLSLProgram = null;
		
		// loop through each mesh we want to draw
		for (looptemp in 0...4)
		{
			// clear the transformation matrix to 0,0,0
			modelmatrix.identity();
			// each mesh has a different texture, 
			// shader, position and spin speed
			switch (looptemp)
			{
				case 0:
					program = shaderProgram1;
					shaderProgram1.attach();
					shaderProgram1.setTextureAt("texture", myTexture);
					modelmatrix.appendRotation(t * 0.7, Vector3D.Y_AXIS);
					modelmatrix.appendRotation(t * 0.6, Vector3D.X_AXIS);
					modelmatrix.appendRotation(t * 1.0, Vector3D.Y_AXIS);
					modelmatrix.appendTranslation( -dist, dist, 0);
				case 1:
					program = shaderProgram2;
					shaderProgram2.attach();
					shaderProgram2.setTextureAt("texture", myTexture);
					modelmatrix.appendRotation(t * -0.2, Vector3D.Y_AXIS);
					modelmatrix.appendRotation(t * 0.4, Vector3D.X_AXIS);
					modelmatrix.appendRotation(t * 0.7, Vector3D.Y_AXIS);
					modelmatrix.appendTranslation(dist, dist, 0);
				case 2:
					program = shaderProgram3;
					shaderProgram3.attach();
					shaderProgram3.setTextureAt("texture", myTexture);
					modelmatrix.appendRotation(t * 1.0, Vector3D.Y_AXIS);
					modelmatrix.appendRotation(t * -0.2, Vector3D.X_AXIS);
					modelmatrix.appendRotation(t * 0.3, Vector3D.Y_AXIS);
					modelmatrix.appendTranslation( -dist, -dist, 0);
				case 3:
					program = shaderProgram4;
					shaderProgram4.attach();
					shaderProgram4.setTextureAt("texture", myTexture);
					shaderProgram4.setFragmentUniformFromVector("colorMultiplier", Vector.ofArray([1, Math.abs(Math.cos(t/50)), 0, 1]));
					modelmatrix.appendRotation(t * 0.3, Vector3D.Y_AXIS);
					modelmatrix.appendRotation(t * 0.3, Vector3D.X_AXIS);
					modelmatrix.appendRotation(t * -0.3, Vector3D.Y_AXIS);
					modelmatrix.appendTranslation(dist, -dist, 0);
			}

			// clear the matrix and append new angles
			modelViewProjection.identity();
			modelViewProjection.append(modelmatrix);
			modelViewProjection.append(viewmatrix);
			modelViewProjection.append(projectionmatrix);
			
			finishPreparingDataForShip(program);
			
			// render it
			context3D.drawTriangles(myMesh.indexBuffer, 0, myMesh.indexBufferCount);		
		}

		// present/flip back buffer
		// now that all meshes have been drawn
		context3D.present();
		
		// update the FPS display
		fpsTicks++;
		var now:Int = Lib.getTimer();
		var delta:Int = now - fpsLast;
		// only update the display once a second
		if (delta >= 1000) 
		{
			var fps:Float = fpsTicks / delta * 1000;
			fpsTf.text = Std.int(fps) + " fps";
			fpsTicks = 0;
			fpsLast = now;
		}
		
		// update the rest of the GUI
		updateScore();
	}
	
	private function finishPreparingDataForShip(shaderProgram:GLSLProgram):Void
	{
		// pass our matrix data to the shader program
		shaderProgram.setVertexUniformFromMatrix("modelViewMatrix", modelViewProjection, true);
		// draw a spaceship mesh
		// position
		shaderProgram.setVertexBufferAt("vertexPosition", myMesh.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		// tex coord
		shaderProgram.setVertexBufferAt("uv", myMesh.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		// vertex rgba
		shaderProgram.setVertexBufferAt("col", myMesh.colorsBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
	}

}