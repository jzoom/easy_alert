import 'dart:async';

import 'package:easy_alert/src/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Supply text for alert, cancel and ok
/// 为Alert提供文字，一般为取消和确认
class AlertConfig {
  final String ok;
  final String cancel;
  final bool useIosStyle;
  final EdgeInsetsGeometry toastPadding;
  const AlertConfig(
      {this.ok: "OK",
      this.cancel: "CANCEL",
      this.useIosStyle: true,
      this.toastPadding: const EdgeInsets.all(30)});
}

class AlertProvider extends StatefulWidget {
  final Widget child;

  final AlertConfig config;

  final TextDirection textDirection;

  AlertProvider(
      {this.child,
      this.config: const AlertConfig(),
      this.textDirection = TextDirection.ltr});

  static AlertConfig getConfig(BuildContext context) {
    final _AlertScope scope =
        context.dependOnInheritedWidgetOfExactType(aspect: _AlertScope);
    return scope?.config;
  }

  static AlertConfig getToaster(BuildContext context) {
    final _AlertScope scope =
        context.dependOnInheritedWidgetOfExactType(aspect: _AlertScope);
    return scope?.config;
  }

  static ToastManager getManager(BuildContext context) {
    final _AlertScope scope =
        context.dependOnInheritedWidgetOfExactType(aspect: _AlertScope);

    return scope?.manager;
  }

  @override
  State<StatefulWidget> createState() {
    return new _AlertProviderState();
  }
}

class _AlertProviderState extends State<AlertProvider>
    with SingleTickerProviderStateMixin
    implements ToastManager {
  List<Toast> _queue = [];
  Toast _current;

  AnimationController _controller;
  Animation<double> _animation;

  @override
  void showToast(
    String message, {
    ToastPosition position,
    ToastDuration duration: ToastDuration.short,
  }) {
    Toast toast =
        new Toast(message: message, position: position, duration: duration);
    if (_current != null) {
      _queue.add(toast);
    } else {
      _show(toast);
    }
  }

  void _show(Toast toast) {
    _current = toast;
    _controller.animateTo(1.0,
        curve: Curves.ease, duration: new Duration(milliseconds: 300));
    new Future.delayed(new Duration(
            milliseconds:
                _current.duration == ToastDuration.long ? 3000 : 1000))
        .whenComplete(_hide);
    setState(() {});
  }

  void _hide() {
    _controller
        .animateTo(0.0,
            curve: Curves.ease, duration: new Duration(milliseconds: 300))
        .whenComplete(() {
      if (_queue.length > 0) {
        _show(_queue.removeAt(0));
        return;
      } else {
        _current = null;
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    _controller = new AnimationController(vsync: this);
    _controller.duration = new Duration(milliseconds: 300);
    _animation = new Tween(begin: 0.0, end: 1.0).animate(_controller);
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  AlignmentGeometry _getAlignment() {
    switch (_current.position) {
      case ToastPosition.center:
        return Alignment.center;
      case ToastPosition.bottom:
        return Alignment.bottomCenter;
      case ToastPosition.top:
        return Alignment.topCenter;
    }
    return Alignment.center;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      new _AlertScope(
        manager: this,
        config: widget.config,
        child: widget.child,
      )
    ];
    if (_current != null) {
      children.add(
        new Padding(
            padding: widget.config.toastPadding,
            child: new Align(
              child: new AnimatedBuilder(
                  animation: _animation,
                  builder: (BuildContext context, Widget w) {
                    return new Opacity(
                      opacity: _animation.value,
                      child: new IgnorePointer(
                        child: new ToastView(
                          text: _current.message,
                          textDirection: widget.textDirection,
                        ),
                      ),
                    );
                  }),
              alignment: _getAlignment(),
            )),
      );
    }

    return new Material(
        child: new Stack(
      textDirection: TextDirection.ltr,
      children: children,
    ));
  }
}

class _AlertScope extends InheritedWidget {
  const _AlertScope({Key key, this.config, this.manager, Widget child})
      : super(key: key, child: child);

  final AlertConfig config;
  final ToastManager manager;

  @override
  bool updateShouldNotify(_AlertScope old) {
    return config != old.config;
  }
}
