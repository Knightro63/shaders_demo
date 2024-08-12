enum ShaderFragmentType {
  clear,
  display,
  splat,
  advection,
  divergence,
  curl,
  vorticity,
  pressure,
  gradientSubtract;

  @override
  String toString() => '${name}Frag';
}
