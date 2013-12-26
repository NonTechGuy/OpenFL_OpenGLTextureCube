package;

import flash.display.Sprite;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.geom.Rectangle;
import flash.Lib;
import openfl.display.OpenGLView;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.gl.GLProgram;
import openfl.gl.GLTexture;
import openfl.gl.GLUniformLocation;
import openfl.utils.Float32Array;
import openfl.utils.Int16Array;
import openfl.utils.UInt8Array;
import openfl.Assets;

/**
 *
 */
class Main extends Sprite {
  private var shaderProgram:GLProgram;

  private var mvMatrixUniform:GLUniformLocation;
  private var pMatrixUniform:GLUniformLocation;
  private var samplerUniform:GLUniformLocation;

  private var view:OpenGLView;
  private var vertexPositionAttribute:Int;

  private var textureCoordAttribute:Int;
  private var texture:GLTexture;

  private var cubeVertexPositionBuffer:GLBuffer;
  private var cubeVertexTextureCoordBuffer:GLBuffer;
  private var cubeVertexIndexBuffer:GLBuffer;

  private var pMatrix:Matrix3D;
  private var mvMatrix:Matrix3D;

  private var mvMatrixStack:Array<Matrix3D>;
  private var xRot:Float;
  private var yRot:Float;
  private var zRot:Float;
  private var lastTime:Float;

  /**
   *
   */
  public function new() {
    super();

    if (OpenGLView.isSupported) {
      view = new OpenGLView();

      GL.enable(GL.DEPTH_TEST);
      GL.depthFunc( GL.LEQUAL );
      GL.depthMask( true );

      mvMatrixStack = [];
      xRot = 0.0;
      yRot = 0.0;
      zRot = 0.0;
      lastTime = 0.0;

      mvMatrix = new Matrix3D();

      initializeShaders();
      initTexture();
      createBuffers();

      view.render = renderView;
      addChild(view);
		}
	}
	
  /**
   *
   */
  private function initializeShaders():Void {
    var vertexShaderSource = Assets.getText("assets/shader.vert");

    var vertexShader = GL.createShader(GL.VERTEX_SHADER);
    GL.shaderSource(vertexShader, vertexShaderSource);
    GL.compileShader(vertexShader);

    if (GL.getShaderParameter(vertexShader, GL.COMPILE_STATUS) == 0) {
      throw "Error compiling vertex shader";
    }

    #if desktop
      var fragmentShaderSource = "";
    #else
      var fragmentShaderSource = "precision mediump float;\n";
    #end

    fragmentShaderSource += Assets.getText("assets/shader.frag");

    var fragmentShader = GL.createShader(GL.FRAGMENT_SHADER);
    GL.shaderSource(fragmentShader, fragmentShaderSource);
    GL.compileShader(fragmentShader);

    if (GL.getShaderParameter (fragmentShader, GL.COMPILE_STATUS) == 0) {
      throw "Error compiling fragment shader";
    }

    shaderProgram = GL.createProgram();
    GL.attachShader(shaderProgram, vertexShader);
    GL.attachShader(shaderProgram, fragmentShader);
    GL.linkProgram(shaderProgram);

    if (GL.getProgramParameter(shaderProgram, GL.LINK_STATUS) == 0) {
      throw "Unable to initialize the shader program.";
    }

    //
    vertexPositionAttribute = GL.getAttribLocation(shaderProgram, "aVertexPosition");
    GL.enableVertexAttribArray(vertexPositionAttribute);

    textureCoordAttribute = GL.getAttribLocation(shaderProgram, "aTextureCoord");
    GL.enableVertexAttribArray(textureCoordAttribute);

    pMatrixUniform  = GL.getUniformLocation(shaderProgram, "uPMatrix");
    mvMatrixUniform = GL.getUniformLocation(shaderProgram, "uMVMatrix");
    samplerUniform  = GL.getUniformLocation(shaderProgram, "uSampler");
  }

  /**
   *
   */
  private function initTexture() {
    var bitmapData = Assets.getBitmapData("assets/openfl.png");
    
    texture = GL.createTexture();
    GL.bindTexture(GL.TEXTURE_2D, texture);

    #if js
      var data = rearrangeColorComponents( bitmapData.getPixels(bitmapData.rect).byteView, bitmapData.width, bitmapData.height );
    #else
      var data = new UInt8Array(bitmapData.getPixels (bitmapData.rect));
    #end

    GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, bitmapData.width, bitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, data);
    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
    GL.bindTexture(GL.TEXTURE_2D, null);
  }

  /**
   *
   */
   private function createBuffers():Void {
    var vertices = [
      // Front face
      -1.0, -1.0,  1.0,
       1.0, -1.0,  1.0,
       1.0,  1.0,  1.0,
      -1.0,  1.0,  1.0,

      // Back face
      -1.0, -1.0, -1.0,
      -1.0,  1.0, -1.0,
       1.0,  1.0, -1.0,
       1.0, -1.0, -1.0,

      // Top face
      -1.0,  1.0, -1.0,
      -1.0,  1.0,  1.0,
       1.0,  1.0,  1.0,
       1.0,  1.0, -1.0,

      // Bottom face
      -1.0, -1.0, -1.0,
       1.0, -1.0, -1.0,
       1.0, -1.0,  1.0,
      -1.0, -1.0,  1.0,

      // Right face
       1.0, -1.0, -1.0,
       1.0,  1.0, -1.0,
       1.0,  1.0,  1.0,
       1.0, -1.0,  1.0,

      // Left face
      -1.0, -1.0, -1.0,
      -1.0, -1.0,  1.0,
      -1.0,  1.0,  1.0,
      -1.0,  1.0, -1.0
    ];
    cubeVertexPositionBuffer = GL.createBuffer();
    GL.bindBuffer(GL.ARRAY_BUFFER, cubeVertexPositionBuffer);
    GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(vertices), GL.STATIC_DRAW);
    GL.bindBuffer(GL.ARRAY_BUFFER, null);

    var textureCoords = [
      // Front face
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,

      // Back face
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,
      0.0, 0.0,

      // Top face
      0.0, 1.0,
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,

      // Bottom face
      1.0, 1.0,
      0.0, 1.0,
      0.0, 0.0,
      1.0, 0.0,

      // Right face
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,
      0.0, 0.0,

      // Left face
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,
    ];
    cubeVertexTextureCoordBuffer = GL.createBuffer();
    GL.bindBuffer(GL.ARRAY_BUFFER, cubeVertexTextureCoordBuffer);
    GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(cast textureCoords), GL.STATIC_DRAW);

    var cubeVertexIndices = [
        0, 1, 2,      0, 2, 3,    // Front face
        4, 5, 6,      4, 6, 7,    // Back face
        8, 9, 10,     8, 10, 11,  // Top face
        12, 13, 14,   12, 14, 15, // Bottom face
        16, 17, 18,   16, 18, 19, // Right face
        20, 21, 22,   20, 22, 23  // Left face
    ];
    cubeVertexIndexBuffer = GL.createBuffer();
    GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer);
    GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, new Int16Array(cubeVertexIndices), GL.STATIC_DRAW);
  }

  /**
   *
   */
   private function setMatrixUniforms() {
    GL.uniformMatrix3D( pMatrixUniform,  false, pMatrix  );
    GL.uniformMatrix3D( mvMatrixUniform, false, mvMatrix );
  }

  /**
   *
   */
   private function renderView(rect:Rectangle):Void {
    update();

    GL.viewport(Std.int(rect.x), Std.int(rect.y), Std.int(rect.width), Std.int(rect.height));

    GL.clearColor(0.0, 0.0, 0.0, 1.0);
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

    GL.useProgram(shaderProgram);

    pMatrix = perspective(45, Std.int(rect.width)/Std.int(rect.height), 0.1, 100.0);

    mvMatrix.identity();
    mvMatrix.appendTranslation(0.0, 0.0, -5.0);

    mvMatrix.prependRotation(xRot, new Vector3D(1, 0, 0));
    mvMatrix.prependRotation(yRot, new Vector3D(0, 1, 0));
    mvMatrix.prependRotation(zRot, new Vector3D(0, 0, 1));

    GL.bindBuffer(GL.ARRAY_BUFFER, cubeVertexPositionBuffer);
    GL.vertexAttribPointer(vertexPositionAttribute, 3, GL.FLOAT, false, 0, 0);

    GL.bindBuffer(GL.ARRAY_BUFFER, cubeVertexTextureCoordBuffer);
    GL.vertexAttribPointer(textureCoordAttribute, 2, GL.FLOAT, false, 0, 0);

    GL.activeTexture(GL.TEXTURE0);
    GL.bindTexture(GL.TEXTURE_2D, texture);
    GL.uniform1i(samplerUniform, 0);

    GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer);

    setMatrixUniforms();

    GL.drawElements(GL.TRIANGLES, 36, GL.UNSIGNED_SHORT, 0);

    //
    GL.bindBuffer(GL.ARRAY_BUFFER, null);
    GL.useProgram(null);
  }

  /**
   *
   */
  private function update() {
    var timeNow = Lib.getTimer();

    if (lastTime != 0) {
      var elapsed = timeNow - lastTime;
      xRot += (90 * elapsed) / 1000.0;
      yRot += (90 * elapsed) / 1000.0;
      zRot += (90 * elapsed) / 1000.0;
    }

    lastTime = timeNow;
  }

  /**
   *
   */
  private function mvPushMatrix() {
    mvMatrixStack.push( mvMatrix.clone() );
  }

  /**
   *
   */
  private function mvPopMatrix() {
    if (mvMatrixStack.length > 0) {
      mvMatrix = mvMatrixStack.pop();
    }
  }

  /**
   *
   */
  public static function perspective(fovy:Float, aspect:Float, near:Float, far:Float) {
    var top = near*Math.tan(fovy*Math.PI/360.0);
    var bottom = -top;
    
    var right = top*aspect;
    var left = -right;

    var rl = (right - left);
    var tb = (top - bottom);
    var fn = (far - near);

    return new Matrix3D(
      [ 
        (near*2)/rl,      0,                 0,                 0,
        0,                (near*2)/tb,       0,                 0,
        (right+left)/rl,  (top+bottom)/tb,  -(far+near)/fn,    -1,
        0,                0,                -(far*near*2)/fn,   0
      ]
    );
  }

  /**
   *
   */
  private function rearrangeColorComponents(values:UInt8Array, w:Int, h:Int) {
    var result = new UInt8Array(w*h*4);

    for (i in 0...w*h) {
      result[i*4]    = values[i*4 +3];
      result[i*4 +1] = values[i*4];
      result[i*4 +2] = values[i*4 +1];
      result[i*4 +3] = values[i*4 +2];
    }

    return result;
  }


}