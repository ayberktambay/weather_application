import 'package:flutter/widgets.dart';

TextStyle tStyle(FontWeight fw ,double size,Color color) {
  return TextStyle(
  fontSize: size,
  fontWeight: fw,
  color: color
 );
}
TextStyle w400TS(double size,Color color) {
  return TextStyle(
  fontSize: size,
  fontWeight: FontWeight.w400,
  color: color
);
}
TextStyle w500TS(double size,Color color) {
  return TextStyle(
  fontSize: size,
  fontWeight: FontWeight.w500,
  color: color
);
}
TextStyle w600TS(double size,Color color) {
  return TextStyle(
  fontSize: size,
  fontWeight: FontWeight.w600,
  color: color
);
}