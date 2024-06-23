import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Displays an [AlertDialog] to select the app language
/// and returns the [Locale]
Future<Locale?> showLanguageDialog(BuildContext prevContext) {
  return showDialog<Locale?>(
    context: prevContext,
    builder: (diagContext) {
      // final delegate = LocalizedApp.of(context).delegate;
      // final langs = delegate.supportedLocales;
      return AlertDialog(
        title: Text(
          tr(
            'language.selected_message',
            namedArgs: {
              'language': tr(
                '''
language.name.${prevContext.locale.languageCode}''',
              ),
            },
          ),
        ),
        content: SizedBox(
          height: 400,
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: prevContext.supportedLocales.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        tr(
                          '''
language.name.${context.supportedLocales[index].languageCode}''',
                        ),
                      ),
                      onTap: () => Navigator.pop(
                        diagContext,
                        context.supportedLocales[index],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
