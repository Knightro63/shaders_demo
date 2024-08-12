import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:shaders_demo/factory/gl_program.dart';
import 'package:shaders_demo/factory/model/render_texture_fromat.dart';
import 'package:shaders_demo/factory/rendering_context_factory.dart';
import 'package:shaders_demo/frame_buffer_factory.dart';
import 'package:shaders_demo/model/double_frame_buffer_object.dart';
import 'package:shaders_demo/model/frame_buffer_object.dart';
import 'package:shaders_demo/model/pointer_color.dart';
import 'package:shaders_demo/model/pointer_prototype.dart';
import 'package:shaders_demo/model/shader_config.dart';
import 'package:shaders_demo/model/shader_fragment_type.dart';
import 'package:shaders_demo/shader_fragment_source.dart';
import 'package:shaders_demo/utils/shader_utils.dart';

class ShaderHandler {
  ShaderHandler(
    this.textureWidth,
    this.textureHeight,
    this.defaultAspectRatio,
    this.onSetupDone
  );
  final config = const ShaderConfig();

  /// Constants
  final int textureWidth;
  final int textureHeight;
  final double defaultAspectRatio;
  final Function onSetupDone;

  /// Buffers
  late DoubleFrameBufferObject density;
  late DoubleFrameBufferObject velocity;
  late FrameBufferObject divergence;
  late FrameBufferObject curl;
  late DoubleFrameBufferObject pressure;

  /// Varyings
  double hue = 0;

  /// Formats
  RenderTextureFormat? _formatRGBA;
  RenderTextureFormat? _formatRG;
  RenderTextureFormat? _formatR;
  static const texType = WebGL.HALF_FLOAT;
  static const supportLinearFiltering = WebGL.LINEAR;

  final textures = <FlutterAngleTexture>[];

  /// Pointers
  List<PointerPrototype> pointers = [];
  List<PointerColor> pointersColours = [];
  List<PointerPrototype> automatedPointers = [];
  List<PointerColor> automatedPointersColours = [];

  /// shaders
  dynamic baseVertexShader;
  dynamic clearShader;
  dynamic displayShader;
  dynamic splatShader;
  dynamic advectionManualFilteringShader;
  dynamic advectionShader;
  dynamic divergenceShader;
  dynamic curlShader;
  dynamic vorticityShader;
  dynamic pressureShader;
  dynamic gradientSubtractShader;

  /// programs
  late GLProgram clearProgram;
  late GLProgram displayProgram;
  late GLProgram splatProgram;
  late GLProgram advectionManualFilteringProgram;
  late GLProgram advectionProgram;
  late GLProgram divergenceProgram;
  late GLProgram curlProgram;
  late GLProgram vorticityProgram;
  late GLProgram pressureProgram;
  late GLProgram gradientSubtractProgram;

  late RenderingContext _rc;

  void setup(BuildContext context) async {
    await FlutterAngle.initOpenGL(true);
    _createPointers();

    final options = AngleOptions(
      width: textureWidth,
      height: textureHeight,
      dpr: defaultAspectRatio,
      antialias: true
    );

    try {
      textures.add(await FlutterAngle.createTexture(options));
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Exception occurred while creating textures -> $e');
      }
      return;
    }
    final shaderRC = RenderingContextFactory.create(textures[0]);

    _rc = shaderRC.rc;
    _formatRGBA = shaderRC.formatRGBA;
    _formatRG = shaderRC.formatRG;
    _formatR = shaderRC.formatR;

    onSetupDone();

    /// Create shaders
    _createShaders();
    _initFrameBuffers();
    _createPrograms();
  }

  void _createPointers() {
    pointers.add(PointerPrototype());
    pointers.add(PointerPrototype());

    pointersColours.add(PointerColor('#8a3ffc'));
    pointersColours.add(PointerColor('#0f62fe'));

    automatedPointers.add(PointerPrototype());
    automatedPointers.add(PointerPrototype());
    automatedPointers.add(PointerPrototype());

    automatedPointersColours.add(PointerColor('#8a3ffc'));
    automatedPointersColours.add(PointerColor('#0f62fe'));
    automatedPointersColours.add(PointerColor('#da3ffc'));
  }

  WebGLShader _createShader({
    required String shaderSource,
    int type = WebGL.FRAGMENT_SHADER,
  }) {
    WebGLShader newShader = _rc.createShader(type);
    _rc.shaderSource(newShader, shaderSource);
    _rc.compileShader(newShader);
    return newShader;
  }

  void _createShaders() {
    baseVertexShader = _createShader(
      shaderSource: ShaderFragmentSource.baseVertexFrag,
      type: WebGL.VERTEX_SHADER,
    );

    clearShader = _createShader(
      shaderSource: ShaderFragmentSource.clearFrag,
    );

    displayShader = _createShader(
      shaderSource: ShaderFragmentSource.displayFrag,
    );

    splatShader = _createShader(
      shaderSource: ShaderFragmentSource.splatFrag,
    );

    advectionManualFilteringShader = _createShader(
      shaderSource: ShaderFragmentSource.advectionManualFiltering,
    );

    advectionShader = _createShader(
      shaderSource: ShaderFragmentSource.advectionFrag,
    );

    divergenceShader = _createShader(
      shaderSource: ShaderFragmentSource.divergenceFrag,
    );

    curlShader = _createShader(
      shaderSource: ShaderFragmentSource.curlFrag,
    );

    vorticityShader = _createShader(
      shaderSource: ShaderFragmentSource.vorticityFrag,
    );

    pressureShader = _createShader(
      shaderSource: ShaderFragmentSource.pressureFrag,
    );

    gradientSubtractShader = _createShader(
      shaderSource: ShaderFragmentSource.gradientSubtractFrag,
    );
  }

  void _createPrograms() {
    /// Create programs
    clearProgram = GLProgram(
      name: ShaderFragmentType.clear.toString(),
      rc: _rc,
      vertexShader: baseVertexShader,
      fragmentShader: clearShader,
    );

    displayProgram = GLProgram(
      name: ShaderFragmentType.display.toString(),
      rc: _rc,
      vertexShader: baseVertexShader,
      fragmentShader: displayShader,
    );

    splatProgram = GLProgram(
      name: ShaderFragmentType.splat.toString(),
      rc: _rc,
      vertexShader: baseVertexShader,
      fragmentShader: splatShader,
    );

    advectionProgram = GLProgram(
      name: ShaderFragmentType.advection.toString(),
      rc: _rc,
      vertexShader: baseVertexShader,
      fragmentShader: advectionShader,
    );

    divergenceProgram = GLProgram(
      name: ShaderFragmentType.divergence.toString(),
      rc: _rc,
      vertexShader: baseVertexShader,
      fragmentShader: divergenceShader,
    );

    curlProgram = GLProgram(
      name: ShaderFragmentType.curl.toString(),
      rc: _rc,
      vertexShader: baseVertexShader,
      fragmentShader: curlShader,
    );

    vorticityProgram = GLProgram(
      name: ShaderFragmentType.vorticity.toString(),
      rc: _rc,
      vertexShader: baseVertexShader,
      fragmentShader: vorticityShader,
    );

    pressureProgram = GLProgram(
      name: ShaderFragmentType.pressure.toString(),
      rc: _rc,
      vertexShader: baseVertexShader,
      fragmentShader: pressureShader,
    );

    gradientSubtractProgram = GLProgram(
      name: ShaderFragmentType.gradientSubtract.toString(),
      rc: _rc,
      vertexShader: baseVertexShader,
      fragmentShader: gradientSubtractShader,
    );
  }

  void _initFrameBuffers() {
    density = FrameBufferFactory.createDoubleFBO(
      _rc,
      texId: 2,
      width: textureWidth,
      height: textureHeight,
      internalFormat: _formatRGBA?.internalFormat ?? 0,
      format: _formatRGBA?.format ?? 0,
      type: texType,
      param: supportLinearFiltering,
    );
    velocity = FrameBufferFactory.createDoubleFBO(
      _rc,
      texId: 0,
      width: textureWidth,
      height: textureHeight,
      internalFormat: _formatRG?.internalFormat ?? 0,
      format: _formatRG?.format ?? 0,
      type: texType,
      param: supportLinearFiltering,
    );
    divergence = FrameBufferFactory.createFBO(
      _rc,
      texId: 4,
      width: textureWidth,
      height: textureHeight,
      internalFormat: _formatR?.internalFormat ?? 0,
      format: _formatR?.format ?? 0,
      type: texType,
      param: WebGL.LINEAR,
    );
    curl = FrameBufferFactory.createFBO(
      _rc,
      texId: 5,
      width: textureWidth,
      height: textureHeight,
      internalFormat: _formatR?.internalFormat ?? 0,
      format: _formatR?.format ?? 0,
      type: texType,
      param: WebGL.LINEAR,
    );
    pressure = FrameBufferFactory.createDoubleFBO(
      _rc,
      texId: 6,
      width: textureWidth,
      height: textureHeight,
      internalFormat: _formatR?.internalFormat ?? 0,
      format: _formatR?.format ?? 0,
      type: texType,
      param: WebGL.LINEAR,
    );
  }

  void blit(dynamic destination) {
    textures[0].activate();

    final Buffer vertexBuffer = _rc.createBuffer();
    _rc.bindBuffer(WebGL.ARRAY_BUFFER, vertexBuffer);
    _rc.bufferData(WebGL.ARRAY_BUFFER,Float32Array.fromList([-1, -1, -1, 1, 1, 1, 1, -1]), WebGL.STATIC_DRAW);

    final Buffer vertexBuffer4FBO = _rc.createBuffer();
    _rc.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, vertexBuffer4FBO);
    _rc.bufferData(WebGL.ELEMENT_ARRAY_BUFFER,Uint16Array.fromList([0, 1, 2, 0, 2, 3]), WebGL.STATIC_DRAW);
    _rc.vertexAttribPointer(0, 2, WebGL.FLOAT, false, 0, 0);
    _rc.enableVertexAttribArray(0);

    textures[0].signalNewFrameAvailable();

    //return (dynamic destination) {
      _rc.bindFramebuffer(WebGL.FRAMEBUFFER, destination);
      _rc.drawElements(WebGL.TRIANGLES, 6, WebGL.UNSIGNED_SHORT, 0);
    //};

    _rc.deleteBuffer(vertexBuffer);
    _rc.deleteBuffer(vertexBuffer4FBO);
  }

  void splat(
    double x,
    double y,
    double dx,
    double dy,
    List<double> color,
    double radius,
    double opacity,
  ) {
    splatProgram.bind();
    _rc.uniform1i(splatProgram.uTarget, velocity.read.texId);
    // TODO: check if it works with textureWidth / textureHeight
    _rc.uniform1f(splatProgram.aspectRatio, textureWidth / textureHeight);
    _rc.uniform2f(splatProgram.point, x / textureWidth, 1.0 - y / textureHeight);
    _rc.uniform3f(splatProgram.color, dx, -dy, 1.0);
    _rc.uniform1f(splatProgram.radius, radius);
    _rc.uniform1f(splatProgram.opacity, opacity);
    blit(velocity.write.fbo);
    velocity.swap();

    _rc.uniform1i(splatProgram.uTarget, density.read.texId);
    _rc.uniform3f(splatProgram.color, color[0] * 0.3, color[1] * 0.3, color[2] * 0.3);
    blit(density.write.fbo);
    density.swap();
  }

  void update() {
    const dt = 0.005;
    //_rc.viewport(0, 0, textureWidth, textureHeight);

    /// Bind velocity uniforms
    advectionProgram.bind();
    _rc.uniform2f(
      advectionProgram.texelSize,
      (1.0 / textureWidth) * config.speed,
      (1.0 / textureHeight) * config.speed
    );
    _rc.uniform1i(advectionProgram.uVelocity, velocity.read.texId);
    _rc.uniform1i(advectionProgram.uSource, velocity.read.texId);
    _rc.uniform1f(advectionProgram.dt, dt);
    _rc.uniform1f(advectionProgram.dissipation, config.velocityDissipation);
    blit(velocity.write.fbo);
    velocity.swap();

    /// Bind density uniforms
    _rc.uniform1i(advectionProgram.uVelocity, velocity.read.texId);
    _rc.uniform1i(advectionProgram.uSource, density.read.texId);
    _rc.uniform1f(advectionProgram.dissipation, config.densityDissipation);
    blit(density.write.fbo);
    density.swap();
    
    /// Create pointer splats
    for (int i = 0; i < pointers.length; i++) {
      final pointer = pointers[i];

      if (pointer.moved) {
        List<double> colour = ShaderUtils.hexToColourArray(pointersColours[i].base);
        double opacity;
        double radius;
        switch (i) {
          case 0:
            opacity = config.opacity * 0.8;
            radius = config.radius * 0.5;
            break;
          case 1:
            opacity = config.opacity * 0.7;
            radius = config.radius * 0.05;
            break;
          default:
            opacity = config.opacity * 0.8;
            radius = config.radius * 0.05;
            break;
        }

        if (config.rainbow) {
          if (hue > 360) {
            hue = 0;
          }
          hue += config.rainbowSpeed;
          final colourHex = ShaderUtils.hslToHex(HSLColor.fromAHSL(1, hue, 1, 0.5));
          colour = ShaderUtils.hexToColourArray(colourHex);
        }

        splat(
          pointer.x,
          pointer.y,
          pointer.dx * 0.4,
          pointer.dy * 0.4,
          colour,
          radius * 0.5,
          opacity * 2,
        );
        pointer.moved = false;
      }
    }

    /// Create automated pointer splats
    for (int i = 0; i < automatedPointers.length; i++) {
      final pointer = automatedPointers[i];
      if (config.movement) {
        final noiseX = Random().nextDouble();
        final noiseY = Random().nextDouble();

        // TODO: check inner width/height
        final x = noiseX * textureWidth;
        final y = noiseY * textureHeight;
        pointer.dx = (x - pointer.x) * 10.0;
        pointer.dy = (y - pointer.y) * 10.0;
        pointer.x = x;
        pointer.y = y;
        pointer.moved = true;
        pointer.down = true;
      }

      if (pointer.moved) {
        List<double> colour = ShaderUtils.hexToColourArray(automatedPointersColours[i].base);
        double opacity;
        double radius;
        switch (i) {
          case 0:
            opacity = config.opacity * 0.8;
            radius = config.radius * 0.5;
            break;
          case 1:
            opacity = config.opacity * 0.7;
            radius = config.radius * 0.05;
            break;
          case 2:
            opacity = config.opacity * 0.5;
            radius = config.radius * 0.02;
            break;
          default:
            opacity = config.opacity * 0.8;
            radius = config.radius * 0.05;
            break;
        }

        if (config.rainbow) {
          if (hue > 360) {
            hue = 0;
          }
          if (hue < 0) {
            hue = 360;
          }
          hue += config.rainbowSpeed;
          final colourHex = ShaderUtils.hslToHex(HSLColor.fromAHSL(1, hue, 1, 0.5));
          colour = ShaderUtils.hexToColourArray(colourHex);
        }

        splat(
          pointer.x,
          pointer.y,
          pointer.dx,
          pointer.dy,
          colour,
          radius,
          opacity,
        );
        pointer.moved = false;
      }
    }

    /// Bind vorticity uniforms
    curlProgram.bind();
    _rc.uniform2f(curlProgram.texelSize, 1.0 / textureWidth, 1.0 / textureHeight);
    _rc.uniform1i(curlProgram.uVelocity, velocity.read.texId);
    blit(curl.fbo);

    /// Bind velocity uniforms
    vorticityProgram.bind();
    _rc.uniform2f(vorticityProgram.texelSize, 1.0 / textureWidth, 1.0 / textureHeight);
    _rc.uniform1i(vorticityProgram.uVelocity, velocity.read.texId);
    _rc.uniform1i(vorticityProgram.uCurl, curl.texId);
    // _rc.uniform1f(vorticityProgram.curl, config.vorticity);
    _rc.uniform1f(vorticityProgram.dt, dt);
    blit(velocity.write.fbo);
    velocity.swap();

    /// Bind divergence uniforms
    divergenceProgram.bind();
    _rc.uniform2f(divergenceProgram.texelSize, 1.0 / textureWidth, 1.0 / textureHeight);
    _rc.uniform1i(divergenceProgram.uVelocity, velocity.read.texId);
    blit(divergence.fbo);

    /// Bind pressure uniforms
    clearProgram.bind();
    int pressureTexId = pressure.read.texId;
    _rc.activeTexture(WebGL.TEXTURE0 + pressureTexId);
    _rc.bindTexture(WebGL.TEXTURE_2D, pressure.read.texture);
    _rc.uniform1i(clearProgram.uTexture, pressureTexId);
    _rc.uniform1f(clearProgram.value, config.pressureDissipation);
    blit(pressure.write.fbo);
    pressure.swap();

    /// Bind pressure iterations uniforms
    pressureProgram.bind();
    _rc.uniform2f(pressureProgram.texelSize, 1.0 / textureWidth, 1.0 / textureHeight);
    _rc.uniform1i(pressureProgram.uDivergence, divergence.texId);
    pressureTexId = pressure.read.texId;
    _rc.uniform1i(pressureProgram.uPressure, pressureTexId);
    _rc.activeTexture(WebGL.TEXTURE0 + pressureTexId);
    for (int i = 0; i < config.pressureIterations; i++) {
      _rc.bindTexture(WebGL.TEXTURE_2D, pressure.read.texture);
      blit(pressure.write.fbo);
      pressure.swap();
    }

    /// Bind gradient subtract uniforms
    gradientSubtractProgram.bind();
    _rc.uniform2f(gradientSubtractProgram.texelSize, 1.0 / textureWidth, 1.0 / textureHeight);
    _rc.uniform1i(gradientSubtractProgram.uPressure, pressure.read.texId);
    _rc.uniform1i(gradientSubtractProgram.uVelocity, velocity.read.texId);
    blit(velocity.write.fbo);
    
    velocity.swap();

    /// Bind display uniforms
    // TODO: check if width/height is the same as drawing buffer width/height
    //_rc.viewport(0, 0, _rc.width, _rc.height);
    displayProgram.bind();
    _rc.uniform1i(displayProgram.uTexture, density.read.texId);
    _rc.uniform1f(displayProgram.uAmount, config.grain);
    blit(null);

    _rc.finish();
    FlutterAngle.updateTexture(textures.first);
  }

  void dispose(){
    advectionProgram.dispose();
    curlProgram.dispose();
    vorticityProgram.dispose();
    divergenceProgram.dispose();
    clearProgram.dispose();
    pressureProgram.dispose();
    gradientSubtractProgram.dispose();
    displayProgram.dispose();

    _rc.deleteFramebuffer(pressure.write.fbo);
    _rc.deleteFramebuffer(divergence.fbo);
    _rc.deleteFramebuffer(velocity.write.fbo);
    _rc.deleteFramebuffer(curl.fbo);
    _rc.deleteFramebuffer(density.write.fbo);

    _rc.deleteTexture(pressure.read.texture);
  }
}
