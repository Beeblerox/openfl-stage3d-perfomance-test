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
import flash.display3D.Context3DBlendFactor;
import flash.display3D.IndexBuffer3D;
import flash.display3D.textures.Texture;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.geom.Matrix3D;
import flash.Lib;
import flash.geom.Rectangle;
import flash.Vector;
import openfl.Assets;

import flash.display3D.shaders.glsl.GLSLProgram;
import flash.display3D.shaders.glsl.GLSLFragmentShader;
import flash.display3D.shaders.glsl.GLSLVertexShader;

class Background
{
	private var context3D:Context3D;
	private var vb:VertexBuffer3D;
	private var uvb:VertexBuffer3D;
	private var ib:IndexBuffer3D;
	private var shader_program:GLSLProgram;
	private var tex:Texture;
	private var _width:Float;
	private var _height:Float;
	private var texBM:BitmapData;
	private var _modelViewMatrix:Matrix3D;
	
	//variables for vertexBuffer manipulation
	private var vertices:Vector<Float>;
	private var indices:Vector<UInt>;
	private var uvt:Vector<Float>;
	
	//haxe variable
	public var cols:Int = 8;
	public var rows:Int = 12;
	public var numTriangles:Int;
	public var numVertices:Int;
	public var numIndices:Int;
	
	public function new(ctx3D:Context3D, w:Float, h:Float)
	{
		_width = w;
		_height = h;
		
		//create projection matrix
		_modelViewMatrix = new Matrix3D();
		_modelViewMatrix.appendTranslation( -(_width) / 2, -(_height) / 2, 0);        
		_modelViewMatrix.appendScale(2.0 / (_width - 50), -2.0 / (_height - 50), 1);
		
		// setup everything
		onContext(ctx3D);
	}
	
	public function onContext(ctx3D:Context3D):Void
	{
		context3D = ctx3D;
		setupShaders();
		updateTexture();
		//create vertices
		buildMesh();
		setupBuffers();
	}
	
	private function setupShaders():Void
	{
		var vertexShaderSource =
			"attribute vec2 vertexPosition;
		    attribute vec2 uv;
			uniform mat4 modelViewMatrix;
			varying vec2 vTexCoord;
			void main(void) {
				gl_Position = modelViewMatrix * vec4(vertexPosition, 0.0, 1.0);
				vTexCoord = uv;
			}";
		
        var vertexAgalInfo = '{"varnames":{"uv":"va1","modelViewMatrix":"vc0","vertexPosition":"va0"},"agalasm":"m44 op, va0, vc0\\nmov v0, va1","storage":{},"types":{},"info":"","consts":{}}';
		
		var fragmentShaderSource =
			"varying vec2 vTexCoord;
			 uniform sampler2D texture;
		     void main(void) {
		        vec4 texColor = texture2D(texture, vTexCoord);
				gl_FragColor = texColor;
			}";
		
        var fragmentAgalInfo = '{"varnames":{"texture":"fs0"},"agalasm":"tex oc, v0, fs0 <2d, nearest,wrap>","storage":{},"types":{},"info":"","consts":{}}';
		
        var vertexShader = new GLSLVertexShader(vertexShaderSource, vertexAgalInfo);
        var fragmentShader = new GLSLFragmentShader(fragmentShaderSource, fragmentAgalInfo);

        shader_program = new GLSLProgram(context3D);
        shader_program.upload(vertexShader, fragmentShader);	
	}
	
	private function updateTexture():Void
	{
		//create background texture
		if (tex != null) 
		{
			tex.dispose();
		}
		
		texBM = Assets.getBitmapData("assets/grass.png");
		tex = context3D.createTexture(texBM.width, texBM.height, Context3DTextureFormat.BGRA, false);
		tex.uploadFromBitmapData(texBM);
	}
	
	private function setupBuffers():Void
	{
		vb = context3D.createVertexBuffer(numVertices, 2);
		uvb = context3D.createVertexBuffer(numVertices, 2);
		
		ib = context3D.createIndexBuffer(numIndices);
		vb.uploadFromVector(vertices, 0, numVertices);
		ib.uploadFromVector(indices, 0, numIndices);
		uvb.uploadFromVector(uvt, 0, numVertices);
	}

	public function setPosition(view:Rectangle):Void 
	{
		_width = view.width;
		_height = view.height;
		//recreate the mesh coords
		buildMesh();
		//resize the projection
		_modelViewMatrix = new Matrix3D();
		_modelViewMatrix.appendTranslation( -(_width) / 2, -(_height) / 2, 0);           
		_modelViewMatrix.appendScale(2.0 / (_width - 50), -2.0 / (_height - 50), 1);
	}
	
	private function buildMesh():Void 
	{
		var uw:Float = _width / texBM.width;
		var uh:Float = _height / texBM.height;
		var kx:Float, ky:Float;
		var ci:Int, ci2:Int, ri:Int;
		
		vertices = new Vector<Float>();
		uvt = new Vector<Float>();
		indices = new Vector<UInt>();
		
		var i:Int;
		var j:Int;
		var len1:Int = rows + 1;
		var len2:Int = cols + 1;
		for (j in 0...len1)
		{
			ri = j * (cols + 1) * 2;
			ky = j / rows;
			for (i in 0...len2)
			{
				ci = ri + i * 2;
				kx = i / cols;
				vertices[ci] = _width * kx; 
				vertices[ci + 1] = _height * ky;
				uvt[ci] = uw * kx; 
				uvt[ci + 1] = uh * ky;
			}
		}
		for (j in 0...rows)
		{
			ri = j * (cols + 1);
			for (i in 0...cols)
			{
				ci = i + ri;
				ci2 = ci + cols + 1;
				indices.push(ci);
				indices.push(ci + 1);
				indices.push(ci2);
				indices.push(ci + 1);
				indices.push(ci2 + 1);
				indices.push(ci2);
			}
		}
		//now create the buffers
		numIndices = indices.length;
		numTriangles = Std.int(numIndices / 3);
		numVertices = Std.int(vertices.length / 2);	
	}
	
	public function render():Void 
	{
		if (_width == 0 || _height == 0) return;
		
		var t:Float = Lib.getTimer() / 1000.0;
		var sw:Float = _width;
		var sh:Float = _height;
		var kx:Float, ky:Float;
		var ci:Int, ri:Int;
		
		shader_program.attach();
		context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		shader_program.setTextureAt("texture", tex);  
		shader_program.setVertexUniformFromMatrix("modelViewMatrix", _modelViewMatrix, true);
		
		var i:Int = 0;
		var len1:Int = rows + 1;
		var len2:Int = cols + 1;
		for (j in 0...len1)
		{
			ri = j * (cols + 1) * 2;
			for (i in 0...len2) 
			{
				ci = ri + i * 2;
				kx = i / cols + Math.cos(t + i) * 0.02;
				ky = j / rows + Math.sin(t + j + i) * 0.02;
				vertices[ci] = sw * kx; 
				vertices[ci + 1] = sh * ky; 
			}
		}
		
		vb.uploadFromVector(vertices, 0, numVertices);
		shader_program.setVertexBufferAt("vertexPosition", vb, 0, Context3DVertexBufferFormat.FLOAT_2);  
		shader_program.setVertexBufferAt("uv", uvb, 0, Context3DVertexBufferFormat.FLOAT_2);
		context3D.drawTriangles(ib, 0, numTriangles);
	}
}