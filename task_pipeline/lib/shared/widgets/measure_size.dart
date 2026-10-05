import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports its child's size after layout, and again whenever that size changes.
///
/// [onChange] runs after the frame, so it can safely call setState.
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderMeasureSize createRenderObject(BuildContext context) {
    return RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = size;
    if (newSize == _lastSize) return;
    _lastSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}
