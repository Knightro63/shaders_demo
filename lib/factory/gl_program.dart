import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_angle/flutter_angle.dart';

class GLProgram {
  Map<String, UniformLocation> uniforms = {};
  Map<String, UniformLocation> varyings = {};

  late String _name;
  late Program program;
  late RenderingContext _rc;

  GLProgram({
    required String name,
    required RenderingContext rc,
    required dynamic vertexShader,
    required dynamic fragmentShader,
  }) {
    log('Creating $name program...');

    _name = name;
    _rc = rc;
    program = rc.createProgram();

    rc.attachShader(program, vertexShader);
    rc.attachShader(program, fragmentShader);
    rc.linkProgram(program);

    rc.deleteShader(vertexShader);
    rc.deleteShader(fragmentShader);

    // TODO: check usage of id
    final uniformCount = rc.getProgramParameter(program, WebGL.ACTIVE_UNIFORMS).id;

    for (var i = 0; i < uniformCount; i++) {
      final uniformName = rc.getActiveUniform(program, i).name;

      if (uniformName.isEmpty) {
        continue;
      }
      uniforms[uniformName] = rc.getUniformLocation(program, uniformName);
    }
    // TODO: check usage of id
    final varyingCount =
        rc.getProgramParameter(program, WebGL.ACTIVE_ATTRIBUTES).id;

    for (var i = 0; i < varyingCount; i++) {
      final varyingName = rc.getActiveAttrib(program, i).name;

      if (varyingName.isEmpty) {
        continue;
      }
      varyings[varyingName] = rc.getAttribLocation(program, varyingName);
    }
  }

  void bind() {
    _rc.useProgram(program);
  }
  void dispose() {
    _rc.deleteProgram(program);
  }
  void logValues() {
    uniforms.forEach((key, value) {
      if (kDebugMode) {
        print('Program $_name key $key ${value.toString()}');
      }
    });

    varyings.forEach((key, value) {
      if (kDebugMode) {
        final attribute = _rc.getActiveAttrib(program, value.id);
        print(
            'Program $_name key $key ${value.toString()} -> ${attribute.name}');
      }
    });
  }

  UniformLocation get uVelocity => uniforms['uVelocity']!;

  UniformLocation get color => uniforms['color']!;

  UniformLocation get point => uniforms['point']!;

  UniformLocation get aspectRatio => uniforms['aspectRatio']!;

  UniformLocation get uTarget => uniforms['uTarget']!;

  UniformLocation get radius => uniforms['radius']!;

  UniformLocation get opacity => uniforms['opacity']!;

  UniformLocation get uSource => uniforms['uSource']!;

  UniformLocation get dissipation => uniforms['dissipation']!;

  UniformLocation get texelSize => uniforms['texelSize']!;

  UniformLocation get dt => uniforms['dt']!;

  UniformLocation get uTexture => uniforms['uTexture']!;

  UniformLocation get value => uniforms['value']!;

  UniformLocation get uDivergence => uniforms['uDivergence']!;

  UniformLocation get uPressure => uniforms['uPressure']!;

  UniformLocation get uCurl => uniforms['uCurl']!;

  UniformLocation get uAmount => uniforms['uAmount']!;
}
