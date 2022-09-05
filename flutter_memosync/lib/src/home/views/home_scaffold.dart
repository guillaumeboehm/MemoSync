import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/app.dart' show App;
import 'package:flutter_memosync/src/authentication/authentication.dart';
import 'package:flutter_memosync/src/home/home.dart';
import 'package:flutter_memosync/src/home/repositories/memo.dart';
import 'package:flutter_memosync/src/home/widgets/about_dialog.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:flutter_memosync/src/settings/settings.dart';
import 'package:flutter_memosync/src/widgets/modal_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Widget returning the Scaffold for the home page
class HomeScaffold extends StatelessWidget {
  /// Default constructor
  HomeScaffold({
    super.key,
    required this.builder,
    this.canBack = false,
  }) {
    PackageInfo.fromPlatform();
  }

  /// Returns the home widget to build.
  final Widget Function(BoxConstraints constraints) builder;

  /// Dictates if the appBar should have a back arrow or not.
  final bool canBack;

  @override
  Widget build(BuildContext context) {
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    return BlocProvider(
      create: (context) => HomeBloc(
        context.read<AuthenticationBloc>(),
        context.read<MemoRepository>(),
        context,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          String? packageInfo;
          PackageInfo.fromPlatform().then((info) {
            packageInfo = '${info.version}-${info.buildNumber}';
          });
          return SafeArea(
            child: Scaffold(
              key: _scaffoldKey,
              drawer: (constraints.maxWidth < App.maxWidth)
                  ? Drawer(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          DrawerHeader(
                            child: Text(
                              tr('general.app_title'),
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                          if (kDebugMode)
                            ListTile(
                              title: Text(tr('debug.purge_local_db')),
                              onTap: Storage.removeAllMemos,
                            ),
                          ListTile(
                            title: Text(tr('menu.settings')),
                            onTap: () => Navigator.of(context)
                              ..pop()
                              ..push<void>(SettingsPage.route()),
                          ),
                          ListTile(
                            title: Text(tr('menu.logout')),
                            onTap: () => context
                                .read<AuthenticationBloc>()
                                .add(AuthLogoutRequested()),
                          ),
                          ListTile(
                            title: Text(tr('menu.about')),
                            onTap: () => showAbout(context),
                          ),
                        ],
                      ),
                    )
                  : null,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: BlocBuilder<HomeBloc, HomeState>(
                  buildWhen: (previous, current) =>
                      previous.viewPage != current.viewPage,
                  builder: (context, state) {
                    final canBack = state.viewPage.index > 0;
                    final backArrow = <Widget>[];

                    if (canBack) {
                      backArrow.add(
                        IconButton(
                          onPressed: () {
                            BlocProvider.of<HomeBloc>(context).add(
                              state.viewPage == ViewPage.memo
                                  ? const DeselectCurrentMemo()
                                  : const ChangeViewPage(
                                      viewPage: ViewPage.memo,
                                    ),
                            );
                          },
                          icon: Icon(Icons.adaptive.arrow_back),
                        ),
                      );
                    }

                    return Row(
                      children: [
                        ...(constraints.maxWidth < App.maxWidth)
                            ? <Widget>[
                                ...backArrow,
                                IconButton(
                                  onPressed: () =>
                                      _scaffoldKey.currentState?.openDrawer(),
                                  icon: const Icon(Icons.menu),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ]
                            : <Widget>[],
                        Flexible(
                          child: InkWell(
                            onTap: () {
                              // Go back to memo selection I guess
                              BlocProvider.of<HomeBloc>(context).add(
                                const DeselectCurrentMemo(),
                              );
                            },
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: SvgPicture.asset(
                                    'assets/resources/logos/svg/Full_logo.svg',
                                    height: 40,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                ),
                                Flexible(
                                  child: Text(
                                    tr('general.app_title'),
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                actions: (constraints.maxWidth < App.maxWidth)
                    ? null
                    : [
                        Row(
                          children: [
                            InkResponse(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.person),
                                  Icon(Icons.arrow_drop_down_rounded),
                                ],
                              ),
                              onTap: () {
                                ModalDrawer.show(context);
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ],
                        ),
                      ],
              ),
              body: builder(constraints),
            ),
          );
        },
      ),
    );
  }
}
