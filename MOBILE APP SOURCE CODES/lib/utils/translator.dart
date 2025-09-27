// lib/utils/translator.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'translations.dart';



String translate(BuildContext context, String key) {
  final language = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
  return appTranslations[language]?[key] ?? key;
}
