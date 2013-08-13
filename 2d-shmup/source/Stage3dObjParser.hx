// OBJ file format parser for Stage3d - version 2.31
// gratefully adapted from work by Alejandro Santander
//
// A one-file, zero dependencies solution!
// Just drop into your project and enjoy.
//
// This class only does ONE thing:
// it turns an OBJ file into Stage3d buffers.
//
// example:
//
// [Embed (source = "mesh.obj", mimeType = "application/octet-stream")] 
// private var myObjData:Class;
//
// ... set up your transforms, texture, vertex and fragment programs as normal ...
//
// var myMesh:Stage3dObjParser = new Stage3dObjParser(myObjData);
// context3D.setVertexBufferAt(0, myMesh.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
// context3D.setVertexBufferAt(1, myMesh.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
// context3D.drawTriangles(myMesh.indexBuffer, 0, myMesh.indexBufferCount);
//
// [Some older exporters (eg 3dsmax9) format things differently: zxy instead of xyz:]
// [var myMesh:Stage3dObjParser = new Stage3dObjParser(myObjData, 1, true);]
// [Also, some exporters flip the U texture coordinate:]
// [var myMesh:Stage3dObjParser = new Stage3dObjParser(myObjData, 1, true, true);]
//
// Note: no quads allowed!
// If your model isn't working, check that you 
// have triangulated your mesh so each polygon uses
// exactly three vertexes - no more and no less.
//
// No groups or sub-models - one mesh per file.
// No .mat material files are used - geometry only.

package;

import flash.errors.Error;
import flash.geom.Vector3D;
import flash.geom.Matrix3D;
import flash.utils.ByteArray;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.Vector;

class Stage3dObjParser
{
		
	// older versions of 3dsmax use an invalid vertex order: 
	private var _vertexDataIsZxy:Bool = false;
	// some exporters mirror the UV texture coordinates
	private var _mirrorUv:Bool = false;
	// OBJ files do not contain vertex colors
	// but many shaders will require this data
	// if false, the buffer is filled with pure white
	private var _randomVertexColors:Bool = true;
	// constants used in parsing OBJ data
	private static var LINE_FEED:String = String.fromCharCode(10);
	private static var SPACE:String = String.fromCharCode(32);
	private static var SLASH:String = "/";
	private static var VERTEX:String = "v";
	private static var NORMAL:String = "vn";
	private static var UV:String = "vt";
	private static var INDEX_DATA:String = "f";
	// temporary vars used during parsing OBJ data
	private var _scale:Float;
	private var _faceIndex:UInt;
	private var _vertices:Vector<Float>;
	private var _normals:Vector<Float>;
	private var _uvs:Vector<Float>;
	private var _cachedRawNormalsBuffer:Vector<Float>;
	// the raw data that is used to create Stage3d buffers
	private var _rawIndexBuffer:Vector<UInt>;
	private var _rawPositionsBuffer:Vector<Float>;
	private var _rawUvBuffer:Vector<Float>;
	private var _rawNormalsBuffer:Vector<Float>;
	private var _rawColorsBuffer:Vector<Float>;
	// the final buffers in Stage3d-ready format
	private var _indexBuffer:IndexBuffer3D;
	private var _positionsBuffer:VertexBuffer3D;
	private var _uvBuffer:VertexBuffer3D;
	private var _normalsBuffer:VertexBuffer3D;
	private var _colorsBuffer:VertexBuffer3D;
	// the context3D that we want to upload the buffers to
	private var _context3d:Context3D;
	
	// These properties return Stage3d buffers
	// (uploading them first if required)
	public var colorsBuffer(get, never):VertexBuffer3D;
	public var positionsBuffer(get, never):VertexBuffer3D;
	public var indexBuffer(get, never):IndexBuffer3D;
	public var indexBufferCount(get, never):Int;
	public var uvBuffer(get, never):VertexBuffer3D;
	public var normalsBuffer(get, never):VertexBuffer3D;
	
	// the class constructor - where everything begins
	public function new(fileContents:String, acontext:Context3D, scale:Float = 1, dataIsZxy:Bool = false, textureFlip:Bool = false)
	{
		LINE_FEED = String.fromCharCode(10);
		SPACE = String.fromCharCode(32);
		
		_vertexDataIsZxy = dataIsZxy;
		_mirrorUv = textureFlip;

		_rawColorsBuffer = new Vector<Float>();
		_rawIndexBuffer = new Vector<UInt>();
		_rawPositionsBuffer = new Vector<Float>();
		_rawUvBuffer = new Vector<Float>();
		_rawNormalsBuffer = new Vector<Float>();
		_scale = scale;
		_context3d = acontext;

		// Get data as string.
		var definition:String = fileContents;

		// Init raw data containers.
		_vertices = new Vector<Float>();
		_normals = new Vector<Float>();
		_uvs = new Vector<Float>();

		// Split data in to lines and parse all lines.
		var lines:Array<String> = definition.split(LINE_FEED);
		var loop:Int = lines.length;
		var i:Int = 0;
		while (i < loop)
		{
			parseLine(lines[i]);
			++i;
		}
	}

	private function parseLine(line:String):Void
	{
		// Split line into words.
		var words:Array<String> = line.split(SPACE);
		var data:Array<String> = null;
		// Prepare the data of the line.
		if (words.length > 0)
		{
			data = words.slice(1);
		}
		else
		{
			return;
		}

		// Check first word and delegate remainder to proper parser.
		var firstWord:String = words[0];
		switch (firstWord)
		{
			case Stage3dObjParser.VERTEX:
				parseVertex(data);
			case Stage3dObjParser.NORMAL:
				parseNormal(data);
			case Stage3dObjParser.UV:
				parseUV(data);
			case Stage3dObjParser.INDEX_DATA:
				parseIndex(data);
		}
	}

	private function parseVertex(data:Array<String>):Void
	{
		if ((data[0] == '') || (data[0] == ' ')) 
		{
			data = data.slice(1); // delete blanks
		}
		
		if (_vertexDataIsZxy)
		{
			_vertices.push(Std.parseFloat(data[1])*_scale);
			_vertices.push(Std.parseFloat(data[2])*_scale);
			_vertices.push(Std.parseFloat(data[0])*_scale);
		}
		else // normal operation: x,y,z
		{
			var loop:Int = data.length;
			var i:Int = 0;
			if (loop > 3) loop = 3;
			while (i < loop)
			{
				var element:String = data[i];
				_vertices.push(Std.parseFloat(element) * _scale);
				++i;
			}
		}
	}

	private function parseNormal(data:Array<String>):Void
	{
		if ((data[0] == '') || (data[0] == ' ')) 
		{
			data = data.slice(1); // delete blanks
		}
		
		var loop:Int = data.length;
		var i:Int = 0;
		if (loop > 3) loop = 3;
		while (i < loop)
		{
			var element:String = data[i];
			if (element != null) // handle 3dsmax extra spaces
			{
				_normals.push(Std.parseFloat(element));
			}
			++i;
		}
	}

	private function parseUV(data:Array<String>):Void
	{
		if ((data[0] == '') || (data[0] == ' ')) 
		{
			data = data.slice(1); // delete blanks
		}
		//if (!_uvs.length) trace('parseUV:' + data);
		var loop:Int = data.length;
		var i:Int = 0;
		if (loop > 2) loop = 2;
		while (i < loop)
		{
			var element:String = data[i];
			_uvs.push(Std.parseFloat(element));
			++i;
		}
	}

	private function parseIndex(data:Array<String>):Void
	{
		var triplet:String;
		var subdata:Array<String>;
		var vertexIndex:Int;
		var uvIndex:Int;
		var normalIndex:Int;
		var index:UInt;

		// Process elements.
		var i:Int;
		var loop:Int = data.length;
		var starthere:Int = 0;
		while ((data[starthere] == '') || (data[starthere] == ' ')) 
		{
			starthere++; // ignore blanks
		}

		loop = starthere + 3;

		// loop through each element and grab values stored earlier
		// elements come as vertexIndex/uvIndex/normalIndex
		i = starthere;
		while (i < loop)
		{
			triplet = data[i]; 
			subdata = triplet.split(SLASH);
			vertexIndex = Std.parseInt(subdata[0]) - 1;
			uvIndex     = Std.parseInt(subdata[1]) - 1;
			normalIndex = Std.parseInt(subdata[2]) - 1;

			// sanity check
			if (vertexIndex < 0) vertexIndex = 0;
			if (uvIndex < 0) uvIndex = 0;
			if (normalIndex < 0) normalIndex = 0;

			// Extract from parse raw data to mesh raw data.

			// Vertex (x,y,z)
			index = 3 * vertexIndex;
			_rawPositionsBuffer.push(_vertices[index + 0]);
			_rawPositionsBuffer.push(_vertices[index + 1]);
			_rawPositionsBuffer.push(_vertices[index + 2]);

			// Color (vertex r,g,b,a)
			if (_randomVertexColors)
			{
				_rawColorsBuffer.push(Math.random());
				_rawColorsBuffer.push(Math.random());
				_rawColorsBuffer.push(Math.random());
				_rawColorsBuffer.push(1);
			}
			else
			{
				// pure white
				_rawColorsBuffer.push(1);
				_rawColorsBuffer.push(1);
				_rawColorsBuffer.push(1);
				_rawColorsBuffer.push(1);
			}

			// Normals (nx,ny,nz) - *if* included in the file
			if (_normals.length > 0)
			{
				index = 3 * normalIndex;
				_rawNormalsBuffer.push(_normals[index + 0]); 
				_rawNormalsBuffer.push(_normals[index + 1]);
				_rawNormalsBuffer.push(_normals[index + 2]);
			}

			// Texture coordinates (u,v)
			index = 2 * uvIndex;
			if (_mirrorUv)
			{
				_rawUvBuffer.push(_uvs[index + 0]);
				_rawUvBuffer.push(1 - _uvs[index + 1]);
			}
			else
			{
				_rawUvBuffer.push(1 - _uvs[index + 0]);
				_rawUvBuffer.push(1 - _uvs[index + 1]);
			}
			
			++i;
		}

		// Create index buffer - one entry for each polygon
		_rawIndexBuffer.push(_faceIndex + 0);
		_rawIndexBuffer.push(_faceIndex + 1);
		_rawIndexBuffer.push(_faceIndex + 2);
		_faceIndex += 3;
	}
	
	private function get_colorsBuffer():VertexBuffer3D
	{
		if(_colorsBuffer == null)
		{
			updateColorsBuffer();
		}
		return _colorsBuffer;
	}
	
	private function get_positionsBuffer():VertexBuffer3D
	{
		if(_positionsBuffer == null)
		{
			updateVertexBuffer();
		}
		return _positionsBuffer;
	}

	private function get_indexBuffer():IndexBuffer3D
	{
		if (_indexBuffer == null)
		{
			updateIndexBuffer();
		}
		return _indexBuffer;
	}

	private function get_indexBufferCount():Int
	{
		return Std.int(_rawIndexBuffer.length / 3);
	}

	private function get_uvBuffer():VertexBuffer3D
	{
		if (_uvBuffer == null)
		{
			updateUvBuffer();
		}
		return _uvBuffer;
	}

	private function get_normalsBuffer():VertexBuffer3D
	{
		if (_normalsBuffer == null)
		{
			updateNormalsBuffer();
		}
		return _normalsBuffer;
	}

	// convert RAW buffers to Stage3d compatible buffers
	// uploads them to the context3D first

	public function updateColorsBuffer():Void
	{
		if (_rawColorsBuffer.length == 0) 
		{
			throw new Error("Raw Color buffer is empty");
		}
		var colorsCount:Int = Std.int(_rawColorsBuffer.length / 4); // 4=rgba
		_colorsBuffer = _context3d.createVertexBuffer(colorsCount, 4);
		_colorsBuffer.uploadFromVector(_rawColorsBuffer, 0, colorsCount);
	}

	public function updateNormalsBuffer():Void
	{
		// generate normals manually 
		// if the data file did not include them
		if (_rawNormalsBuffer.length == 0)
		{
			forceNormals();
		}
		if (_rawNormalsBuffer.length == 0)
		{
			throw new Error("Raw Normal buffer is empty");
		}
		var normalsCount:Int = Std.int(_rawNormalsBuffer.length / 3);
		_normalsBuffer = _context3d.createVertexBuffer(normalsCount, 3);
		_normalsBuffer.uploadFromVector(_rawNormalsBuffer, 0, normalsCount);
	}

	public function updateVertexBuffer():Void
	{
		if (_rawPositionsBuffer.length == 0)
		{
			throw new Error("Raw Vertex buffer is empty");
		}
		var vertexCount:Int = Std.int(_rawPositionsBuffer.length / 3);
		_positionsBuffer = _context3d.createVertexBuffer(vertexCount, 3);
		_positionsBuffer.uploadFromVector(_rawPositionsBuffer, 0, vertexCount);
	}

	public function updateUvBuffer():Void
	{
		if (_rawUvBuffer.length == 0)
		{
			throw new Error("Raw UV buffer is empty");
		}
		var uvsCount:Int = Std.int(_rawUvBuffer.length / 2);
		_uvBuffer = _context3d.createVertexBuffer(uvsCount, 2);
		_uvBuffer.uploadFromVector(_rawUvBuffer, 0, uvsCount);
	}

	public function updateIndexBuffer():Void
	{
		if (_rawIndexBuffer.length == 0)
		{
			throw new Error("Raw Index buffer is empty");
		}
		_indexBuffer = _context3d.createIndexBuffer(_rawIndexBuffer.length);
		_indexBuffer.uploadFromVector(_rawIndexBuffer, 0, _rawIndexBuffer.length);
	}

	public function restoreNormals():Void
	{	// utility function
		_rawNormalsBuffer = _cachedRawNormalsBuffer.concat();
	}

	public function get3PointNormal(p0:Vector3D, p1:Vector3D, p2:Vector3D):Vector3D
	{	// utility function
		// calculate the normal from three vectors
		var p0p1:Vector3D = p1.subtract(p0);
		var p0p2:Vector3D = p2.subtract(p0);
		var normal:Vector3D = p0p1.crossProduct(p0p2);
		normal.normalize();
		return normal;
	}

	public function forceNormals():Void
	{	// utility function
		// useful for when the OBJ file doesn't have normal data
		// we can calculate it manually by calling this function
		_cachedRawNormalsBuffer = _rawNormalsBuffer.concat();
		var i:Int = 0, index:UInt;
		// Translate vertices to vector3d array.
		var loop:Int = Std.int(_rawPositionsBuffer.length / 3);
		var vertices:Vector<Vector3D> = new Vector<Vector3D>();
		var vertex:Vector3D;
		while (i < loop)
		{
			index = 3 * i;
			vertex = new Vector3D(_rawPositionsBuffer[index], _rawPositionsBuffer[index + 1], _rawPositionsBuffer[index + 2]);
			vertices.push(vertex);
			++i;
		}
		// Calculate normals.
		loop = vertices.length;
		var p0:Vector3D, p1:Vector3D, p2:Vector3D, normal:Vector3D;
		_rawNormalsBuffer = new Vector<Float>();
		i = 0;
		while (i < loop)
		{
			p0 = vertices[i];
			p1 = vertices[i + 1];
			p2 = vertices[i + 2];
			normal = get3PointNormal(p0, p1, p2);
			_rawNormalsBuffer.push(normal.x);
			_rawNormalsBuffer.push(normal.y);
			_rawNormalsBuffer.push(normal.z);
			_rawNormalsBuffer.push(normal.x);
			_rawNormalsBuffer.push(normal.y);
			_rawNormalsBuffer.push(normal.z);
			_rawNormalsBuffer.push(normal.x);
			_rawNormalsBuffer.push(normal.y);
			_rawNormalsBuffer.push(normal.z);
			i += 3;
		}
	}

	// utility function that outputs all buffer data 
	// to the debug window - good for compiling OBJ to
	// pure as3 source code for faster inits
	public function dataDumpTrace():Void
	{
		trace(dataDumpString());
	}
	// turns all mesh data into AS3 source code
	public function dataDumpString():String
	{
		var str:String;
		str = "// Stage3d Model Data begins\n\n";

		str += "private var _Index:Vector.<uint> ";
		str += "= new Vector.<uint>([";
		str += _rawIndexBuffer.toString();
		str += "]);\n\n";
		
		str += "private var _Positions:Vector.<Number> ";
		str += "= new Vector.<Number>([";
		str += _rawPositionsBuffer.toString();
		str += "]);\n\n";

		str += "private var _UVs:Vector.<Number> = ";
		str += "new Vector.<Number>([";
		str += _rawUvBuffer.toString();
		str += "]);\n\n";

		str += "private var _Normals:Vector.<Number> = ";
		str += "new Vector.<Number>([";
		str += _rawNormalsBuffer.toString();
		str += "]);\n\n";

		str += "private var _Colors:Vector.<Number> = ";
		str += "new Vector.<Number>([";
		str += _rawColorsBuffer.toString();
		str += "]);\n\n";
		
		str += "// Stage3d Model Data ends\n";
		return str;
	}

}