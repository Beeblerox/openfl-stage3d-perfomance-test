package ;

import flash.display.Shader;
import flash.Vector;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.shaders.glsl.GLSLProgram;
import flash.display3D.textures.Texture;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;

import flash.display3D.shaders.glsl.GLSLFragmentShader;
import flash.display3D.shaders.glsl.GLSLVertexShader;

/**
 * ...
 * @author Hortobágyi Tamás
 */
class LiteSpriteBatch
{
	public var _sprites:LiteSpriteSheet;
	public var _verteces:Vector<Float>;
	public var _indices:Vector<UInt>;
	public var _uvs:Vector<Float>;
	
	private var _context3D:Context3D;
	public var parent:LiteSpriteStage;
	private var _children:Vector<LiteSprite>;
	
	private var _indexBuffer:IndexBuffer3D;
	private var _vertexBuffer:VertexBuffer3D;
	private var _uvBuffer:VertexBuffer3D;
	private var _sceneProgram:GLSLProgram;
	private var _updateVBOs:Bool = true;
	
	public function new(context3D:Context3D, spriteSheet:LiteSpriteSheet)
	{
	//	_context3D = context3D;
		_sprites = spriteSheet;
		
		_verteces = new Vector<Float>();
		_indices = new Vector<UInt>();
		_uvs = new Vector<Float>();
		
		_children = new Vector<LiteSprite>();
		onContext(context3D);
	}
	
	public function onContext(context3D:Context3D):Void
	{
		_context3D = context3D;
		setupShaders();
		updateTexture();
	}
	
	public function getNumChildren():UInt { return _children.length; }
	
	// egy új gyerek sprite-ot hoz létre, és hozzáadja a batch-hoz
	public function createChild(spriteId:UInt):LiteSprite
	{
		var sprite:LiteSprite = new LiteSprite();
		addChild(sprite, spriteId);
		return sprite;
	}
	
	public function addChild(sprite:LiteSprite, spriteId:UInt):Void
	{
		sprite.parent = this;
		sprite.spriteId = spriteId;
		
		// a gyerekek listához addjuk
		sprite.childId = _children.length;
		_children.push(sprite);
		
		// vertex adatokat is hozzáadjuk, ami a rajzoláshoz kell
		var i:UInt, childVertexFirstIndex:UInt = sprite.childId * 4;// (sprite.childId * 12) / 3;
		i = _verteces.length;
		_verteces[i++] = 0;
		_verteces[i++] = 0;
		_verteces[i++] = 1;
		_verteces[i++] = 0;
		_verteces[i++] = 0;
		_verteces[i++] = 1;
		_verteces[i++] = 0;
		_verteces[i++] = 0;
		_verteces[i++] = 1;
		_verteces[i++] = 0;
		_verteces[i++] = 0;
		_verteces[i++] = 1;
		//_verteces.push(0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1); // placeholders
		i = _indices.length;
		_indices[i++] = childVertexFirstIndex;
		_indices[i++] = childVertexFirstIndex + 1;
		_indices[i++] = childVertexFirstIndex + 2;
		_indices[i++] = childVertexFirstIndex;
		_indices[i++] = childVertexFirstIndex + 2;
		_indices[i++] = childVertexFirstIndex + 3;
		//_indices.push(	childVertexFirstIndex, childVertexFirstIndex + 1, childVertexFirstIndex + 2,
		//				childVertexFirstIndex, childVertexFirstIndex + 2, childVertexFirstIndex + 3);
		
		var childUVCoords:Vector<Float> = _sprites.getUVCoords(spriteId);
		i = _uvs.length;
		_uvs[i++] = childUVCoords[0];
		_uvs[i++] = childUVCoords[1];
		_uvs[i++] = childUVCoords[2];
		_uvs[i++] = childUVCoords[3];
		_uvs[i++] = childUVCoords[4];
		_uvs[i++] = childUVCoords[5];
		_uvs[i++] = childUVCoords[6];
		_uvs[i++] = childUVCoords[7];
		
		_updateVBOs = true;
	}
	
	public function removeChild(child:LiteSprite):Void
	{
		var childId:Int = child.childId;
		if (child.parent == this && childId < _children.length)
		{
			child.parent = null;
			_children.splice(childId, 1);
			
			// child id-ket frissítjük
			for (idx in childId ... _children.length) _children[idx].childId = idx;
			
			// Realign vertex data with updated list of children
			var vertexIdx:UInt = childId * 12, indexIdx:UInt = childId * 6;
			_verteces.splice(vertexIdx, 12);
			_indices.splice(indexIdx, 6);
			_uvs.splice(vertexIdx, 8);
			
			_updateVBOs = true;
		}
	}
	
	// shader beállítása
	private function setupShaders():Void
	{
		var vertexShaderSource =
			"attribute vec3 vertexPosition;
		    attribute vec2 uv;
			uniform mat4 modelViewMatrix;
			varying vec2 vTexCoord;
			varying float vTexAlpha;
			void main(void) {
				gl_Position = modelViewMatrix * vec4(vertexPosition.x, vertexPosition.y, 0.0, 1.0);
				vTexCoord = uv;
				vTexAlpha = vertexPosition.z;
			}";
		/*
		vertexShaderAssembler.assemble( Context3DProgramType.VERTEX,
			"dp4 op.x, va0, vc0 \n"+ // transform from stream 0 to output clipspace
			"dp4 op.y, va0, vc1 \n"+ // do the same for the y coordinate
			"mov op.z, vc2.z    \n"+ // we don't need to change the z coordinate
			"mov op.w, vc3.w    \n"+ // unused, but we need to output all data
			"mov v0, va1.xy     \n"+ // copy UV coords from stream 1 to fragment program
			"mov v0.z, va0.z"  // copy alpha from stream 0 to fragment program
		);
		*/	
        var vertexAgalInfo = '{"varnames":{"uv":"va1","modelViewMatrix":"vc0","vertexPosition":"va0"},"agalasm":"dp4 op.x, va0, vc0\\ndp4 op.y, va0, vc1\\nmov op.z, vc2.z\\nmov op.w, vc3.w\\nmov v0, va1.xy\\nmov v0.z, va0.z","storage":{},"types":{},"info":"","consts":{}}';
		
		// m44 vt0, va0, vc0\\nm44 op, vt0, vc4\\nmov v0, va1
		
		var fragmentShaderSource =
			"varying vec2 vTexCoord;
			 varying float vTexAlpha;
			 uniform sampler2D texture;
		     void main(void) {
		        vec4 texColor = texture2D(texture, vTexCoord);
				gl_FragColor = texColor * vec4(1.0, 1.0, 1.0, vTexAlpha);
			}";
		/*
		fragmentShaderAssembler.assemble( Context3DProgramType.FRAGMENT,
			"tex ft0, v0, fs0 <2d,clamp,linear,mipnearest> \n"+ // sample the texture
			"mul ft0, ft0, v0.zzzz\n" + // multiply by the alpha transparency
			"mov oc, ft0" // output the final pixel color
		);
		*/	
		// TODO: add "mipnearest" option into fragmentAgalInfo
        var fragmentAgalInfo = '{"varnames":{"texture":"fs0"},"agalasm":"tex ft0, v0, fs0 <2d,clamp,linear,mipnearest>\\nmul ft0, ft0, v0.zzzz\\nmov oc, ft0","storage":{},"types":{},"info":"","consts":{}}';
		
		//mov ft0, v0\\ntex ft1, ft0, fs0 <2d,wrap,linear>\\nmov oc, ft1
		
        var vertexShader = new GLSLVertexShader(vertexShaderSource, vertexAgalInfo);
        var fragmentShader = new GLSLFragmentShader(fragmentShaderSource, fragmentAgalInfo);

        _sceneProgram = new GLSLProgram(_context3D);
        _sceneProgram.upload(vertexShader, fragmentShader);
	}
	
	private function updateTexture():Void
	{
		_sprites.uploadTexture(_context3D);
	}
	
	private function updateChildVertexData(sprite:LiteSprite):Void
	{
		var childVertexIdx:UInt = sprite.childId * 12;
		
		if (sprite.visible)
		{
			var x:Float = sprite.pos.x, y:Float = sprite.pos.y, rect:Rectangle = sprite.rect(), alpha:Float = sprite.alpha,
				sinT:Float = Math.sin(sprite.rotation), cosT:Float = Math.cos(sprite.rotation),
				scaledWidth:Float = rect.width * sprite.scaleX, scaledHeight:Float = rect.height * sprite.scaleY,
				centerX:Float = scaledWidth * 0.5, centerY:Float = scaledHeight * 0.5;
			
			_verteces[childVertexIdx    ] = x - cosT * centerX - sinT * (scaledHeight - centerY);
			_verteces[childVertexIdx + 1] = y - sinT * centerX + cosT * (scaledHeight - centerY);
			_verteces[childVertexIdx + 2] = alpha;
			
			_verteces[childVertexIdx + 3] = x - cosT * centerX + sinT * centerY;
			_verteces[childVertexIdx + 4] = y - sinT * centerX - cosT * centerY;
			_verteces[childVertexIdx + 5] = alpha;
			
			_verteces[childVertexIdx + 6] = x + cosT * (scaledWidth - centerX) + sinT * centerY;
			_verteces[childVertexIdx + 7] = y + sinT * (scaledWidth - centerX) - cosT * centerY;
			_verteces[childVertexIdx + 8] = alpha;
			
			_verteces[childVertexIdx + 9] = x + cosT * (scaledWidth - centerX) - sinT * (scaledHeight - centerY);
			_verteces[childVertexIdx +10] = y + sinT * (scaledWidth - centerX) + cosT * (scaledHeight - centerY);
			_verteces[childVertexIdx +11] = alpha;
		}
		else for (i in 0 ... 12) _verteces[childVertexIdx + i] = 0;
	}
	
	// geometria kirajzolása
	public function draw():Void
	{
		var nChildren:UInt = _children.length;
		if (nChildren == 0) return;
		
		// update vertex data a kurrent
		for (i in 0 ... nChildren) updateChildVertexData(_children[i]);
		
		_sceneProgram.attach();
		_context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		_sceneProgram.setVertexUniformFromMatrix("modelViewMatrix", parent.modelViewMatrix, true);
		_sceneProgram.setTextureAt("texture", _sprites.texture);
		
		if (_updateVBOs)
		{
			_vertexBuffer = _context3D.createVertexBuffer(Std.int(_verteces.length / 3), 3);
			_indexBuffer = _context3D.createIndexBuffer(_indices.length);
			_uvBuffer = _context3D.createVertexBuffer(Std.int(_uvs.length / 2), 2);
			_indexBuffer.uploadFromVector(_indices, 0, _indices.length); // indieces nem változik
			_uvBuffer.uploadFromVector(_uvs, 0, Std.int(_uvs.length / 2)); // child UV-k nem változnak
			_updateVBOs = false;
		}
		
		// a vertex adatokat minden frame-ben fel akarjuk tölteni
		_vertexBuffer.uploadFromVector(_verteces, 0, Std.int(_verteces.length / 3));
		_sceneProgram.setVertexBufferAt("vertexPosition", _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		_sceneProgram.setVertexBufferAt("uv", _uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		_context3D.drawTriangles(_indexBuffer, 0, nChildren * 2);
	}

}