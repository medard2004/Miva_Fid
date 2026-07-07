import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // Plus Jakarta Sans — titres
  static TextStyle display() => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
      );

  static TextStyle h1() => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
      );

  static TextStyle h2() => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      );

  static TextStyle h3() => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      );

  static TextStyle labelBold() => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );

  // Manrope — corps
  static TextStyle body() => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle bodyMd() => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle caption() => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  // DM Mono — chiffres, FCFA, codes
  static TextStyle mono() => GoogleFonts.dmMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle monoLg() => GoogleFonts.dmMono(
        fontSize: 22,
        fontWeight: FontWeight.w500,
      );

  static TextStyle monoXl() => GoogleFonts.dmMono(
        fontSize: 36,
        fontWeight: FontWeight.w500,
      );

  static TextStyle monoHuge() => GoogleFonts.dmMono(
        fontSize: 48,
        fontWeight: FontWeight.w500,
      );
}
