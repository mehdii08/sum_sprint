import 'package:flutter/material.dart';

const kBgDark = Color(0xFF0D0F16);
const kSurfaceDark = Color(0xFF151823);
const kAccentPurple = Color(0xFF8B5CF6);
const kAccentCyan = Color(0xFF22D3EE);
const kAccentGold = Color(0xFFF59E0B);
const kTextPrimary = Colors.white;
const kTextSecondary = Color(0xFF9CA3AF);
const kTextMuted = Color(0xFF6B7280);

const kBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF1A1030), Color(0xFF0D0F16)],
);

const kCardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kSurfaceDark, Color(0xFF1C1F2E)],
);
