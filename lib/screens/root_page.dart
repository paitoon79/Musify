import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/update_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/custom_animated_bottom_bar.dart';
import 'package:on_audio_query/on_audio_query.dart' hide context;

class Musify extends StatefulWidget {
  @override
  _MusifyState createState() => _MusifyState();
}

final ValueNotifier<int> activeTabIndex = ValueNotifier<int>(-1);

final _navigatorKey = GlobalKey<NavigatorState>();

class _MusifyState extends State<Musify> {
  @override
  void initState() {
    super.initState();
    if (isAndroid) {
      if (!isFdroidBuild) {
        unawaited(checkAppUpdates(context));
      }

      unawaited(checkNecessaryPermissions(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return getBody();
  }

  Widget getMiniPlayer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<SequenceState?>(
          stream: audioPlayer.sequenceStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            if (state?.sequence.isEmpty ?? true) {
              return const SizedBox();
            }
            final metadata = state!.currentSource!.tag;
            return Container(
              height: 75,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 2),
                child: Row(
                  children: <Widget>[
                    if (isAndroid)
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        icon: Icon(
                          FluentIcons.arrow_up_24_filled,
                          size: 22,
                        color: colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NowPlayingPage(),
                            ),
                          );
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 7,
                        bottom: 7,
                        right: 15,
                      ),
                      child: metadata.extras['localSongId'] is int
                          ? QueryArtworkWidget(
                              id: metadata.extras['localSongId'] as int,
                              type: ArtworkType.AUDIO,
                              artworkBorder: BorderRadius.circular(8),
                              artworkWidth: 55,
                              artworkHeight: 55,
                              keepOldArtwork: true,
                              nullArtworkWidget: _buildNullArtworkWidget(),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: metadata!.artUri.toString(),
                                fit: BoxFit.cover,
                                width: 55,
                                height: 55,
                                errorWidget: (context, url, error) =>
                                    _buildNullArtworkWidget(),
                              ),
                            ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          metadata!.title.toString().length > 15
                              ? '${metadata!.title.toString().substring(0, 15)}...'
                              : metadata!.title.toString(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          metadata!.artist.toString().length > 15
                              ? '${metadata!.artist.toString().substring(0, 15)}...'
                              : metadata!.artist.toString(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 15,
                          ),
                        )
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: StreamBuilder<PlayerState>(
                        stream: audioPlayer.playerStateStream,
                        builder: (context, snapshot) {
                          final playerState = snapshot.data;
                          final processingState = playerState?.processingState;
                          final playing = playerState?.playing;

                          IconData icon;
                          VoidCallback? onPressed;

                          if (processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering) {
                            icon = FluentIcons.spinner_ios_16_filled;
                            onPressed = null;
                          } else if (playing != true) {
                            icon = FluentIcons.play_12_filled;
                            onPressed = audioPlayer.play;
                          } else if (processingState !=
                              ProcessingState.completed) {
                            icon = FluentIcons.pause_12_filled;
                            onPressed = audioPlayer.pause;
                          } else {
                            icon = FluentIcons.replay_20_filled;
                            onPressed = () => audioPlayer.seek(
                                  Duration.zero,
                                  index: audioPlayer.effectiveIndices!.first,
                                );
                          }

                          return IconButton(
                            icon: Icon(icon, color: colorScheme.primary),
                            iconSize: 45,
                            onPressed: onPressed,
                            splashColor: Colors.transparent,
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget getBody() {
    final items = List.generate(
      4,
      (index) {
        final iconData = [
          FluentIcons.home_24_regular,
          FluentIcons.search_24_regular,
          FluentIcons.book_24_regular,
          FluentIcons.more_horizontal_24_regular,
        ][index];

        final title = [
          context.l10n()!.home,
          context.l10n()!.search,
          context.l10n()!.userPlaylists,
          context.l10n()!.more,
        ][index];

        final routeName = destinations[index];

        return BottomNavBarItem(
          icon: Icon(iconData),
          title: Text(
            title,
            maxLines: 1,
          ),
          routeName: routeName,
          activeColor: colorScheme.primary,
          inactiveColor: Theme.of(context).hintColor,
        );
      },
    );

    return _getHomeContent(context, items);
  }

  Widget _buildNullArtworkWidget() => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: colorScheme.secondary,
          ),
          child: const Center(
            child: Icon(
              FluentIcons.music_note_1_24_regular,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      );

  Widget _getHomeContent(BuildContext context, List<BottomNavBarItem> items) {
    if (isAndroid) {
      return Scaffold(
        body: WillPopScope(
          onWillPop: () async {
            if (_navigatorKey.currentState?.canPop() == true) {
              _navigatorKey.currentState?.pop();
              return false;
            }
            return true;
          },
          child: Navigator(
            key: _navigatorKey,
            initialRoute: RoutePaths.home,
            onGenerateRoute: RouterService.generateRoute,
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            getMiniPlayer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 65,
              child: CustomAnimatedBottomBar(
                backgroundColor: Theme.of(context).bottomAppBarTheme.color,
                selectedIndex: activeTabIndex.value,
                onItemSelected: (index) => setState(() {
                  activeTabIndex.value = index;
                  _navigatorKey.currentState!.pushNamedAndRemoveUntil(
                    destinations[index],
                    ModalRoute.withName(destinations[index]),
                  );
                }),
                items: items,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ValueListenableBuilder<int>(
                    valueListenable: activeTabIndex,
                    builder: (_, value, __) {
                      if (value < 0 ||
                          value >= destinations.length ||
                          value == -1) {
                        activeTabIndex.value = 0;
                      }
                      return NavigationRail(
                        unselectedIconTheme:
                            const IconThemeData(color: Colors.white),
                        unselectedLabelTextStyle:
                            const TextStyle(color: Colors.white),
                        useIndicator: true,
                        selectedIndex: activeTabIndex.value,
                        onDestinationSelected: (int index) {
                          activeTabIndex.value = index;
                          _navigatorKey.currentState!.pushNamedAndRemoveUntil(
                            destinations[index],
                            ModalRoute.withName(destinations[index]),
                          );
                        },
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          NavigationRailDestination(
                            icon: const Icon(FluentIcons.home_24_regular),
                            selectedIcon:
                                const Icon(FluentIcons.home_24_filled),
                            label: Text(context.l10n()!.home),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(FluentIcons.search_24_regular),
                            selectedIcon:
                                const Icon(FluentIcons.search_24_filled),
                            label: Text(context.l10n()!.search),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(FluentIcons.book_24_regular),
                            selectedIcon:
                                const Icon(FluentIcons.book_24_filled),
                            label: Text(context.l10n()!.userPlaylists),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(
                              FluentIcons.more_horizontal_24_regular,
                            ),
                            selectedIcon: const Icon(
                              FluentIcons.more_horizontal_24_filled,
                            ),
                            label: Text(context.l10n()!.settings),
                          ),
                        ],
                      );
                    },
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: WillPopScope(
                      onWillPop: () async {
                        if (_navigatorKey.currentState?.canPop() == true) {
                          _navigatorKey.currentState?.pop();
                          return false;
                        }
                        return true;
                      },
                      child: Navigator(
                        key: _navigatorKey,
                        initialRoute: RoutePaths.home,
                        onGenerateRoute: RouterService.generateRoute,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: getMiniPlayer(),
      );
    }
  }
}
