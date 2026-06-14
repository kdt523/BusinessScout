import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget createWebIframe(String htmlContent) {
  final viewType = 'iframe-${htmlContent.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..srcdoc = htmlContent;
    return iframe;
  });
  return HtmlElementView(viewType: viewType);
}

Widget createWebPdfIframe(String pdfUrl) {
  final viewType = 'pdf-iframe-${pdfUrl.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..src = pdfUrl;
    return iframe;
  });
  return HtmlElementView(viewType: viewType);
}
