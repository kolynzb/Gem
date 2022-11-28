// ignore_for_file: avoid_escaping_inner_quotes, avoid_redundant_argument_values

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gem/CustomWidgets/add_playlist.dart';
import 'package:gem/CustomWidgets/data_search.dart';
import 'package:gem/CustomWidgets/gradient_containers.dart';
import 'package:gem/CustomWidgets/miniplayer.dart';
import 'package:gem/CustomWidgets/playlist_head.dart';
import 'package:gem/CustomWidgets/snackbar.dart';
import 'package:gem/Helpers/local_music_functions.dart';
import 'package:gem/Screens/LocalMusic/localplaylists.dart';
import 'package:gem/Screens/LocalMusic/pages/albums_page.dart';
import 'package:gem/Screens/LocalMusic/pages/local_artists.dart';
import 'package:gem/Screens/LocalMusic/pages/local_genres.dart';
import 'package:gem/Screens/Player/music_player.dart';
import 'package:gem/animations/custom_physics.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import '../Library/downloads.dart';

class DownloadedSongs extends StatefulWidget {
  final List<SongModel>? cachedSongs;
  final String? title;
  final int? playlistId;
  final bool showPlaylists;
  const DownloadedSongs({
    super.key,
    this.cachedSongs,
    this.title,
    this.playlistId,
    this.showPlaylists = false,
  });
  @override
  _DownloadedSongsState createState() => _DownloadedSongsState();
}

class _DownloadedSongsState extends State<DownloadedSongs>
    with TickerProviderStateMixin {
  List<SongModel> _songs = [];
  String? tempPath = Hive.box('settings').get('tempDirPath')?.toString();

  bool added = false;
  int sortValue = Hive.box('settings').get('sortValue', defaultValue: 1) as int;
  int orderValue =
      Hive.box('settings').get('orderValue', defaultValue: 1) as int;
  int albumSortValue =
      Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;
  List dirPaths =
      Hive.box('settings').get('searchPaths', defaultValue: []) as List;
  int minDuration =
      Hive.box('settings').get('minDuration', defaultValue: 10) as int;
  bool includeOrExclude =
      Hive.box('settings').get('includeOrExclude', defaultValue: false) as bool;
  List includedExcludedPaths = Hive.box('settings')
      .get('includedExcludedPaths', defaultValue: []) as List;
  TabController? _tcontroller;
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  List<PlaylistModel> playlistDetails = [];

  final Map<int, SongSortType> songSortTypes = {
    0: SongSortType.DISPLAY_NAME,
    1: SongSortType.DATE_ADDED,
    2: SongSortType.ALBUM,
    3: SongSortType.ARTIST,
    4: SongSortType.DURATION,
    5: SongSortType.SIZE,
  };

  final Map<int, OrderType> songOrderTypes = {
    0: OrderType.ASC_OR_SMALLER,
    1: OrderType.DESC_OR_GREATER,
  };

  @override
  void initState() {
    _tcontroller =
        TabController(length: widget.showPlaylists ? 5 : 4, vsync: this);
    getData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tcontroller!.dispose();
  }

  bool checkIncludedOrExcluded(SongModel song) {
    for (final path in includedExcludedPaths) {
      if (song.data.contains(path.toString())) return true;
    }
    return false;
  }

  Future<void> getData() async {
    await offlineAudioQuery.requestPermission();
    tempPath ??= (await getTemporaryDirectory()).path;
    playlistDetails = await offlineAudioQuery.getPlaylists();
    if (widget.cachedSongs == null) {
      _songs = (await offlineAudioQuery.getSongs(
        sortType: songSortTypes[sortValue],
        orderType: songOrderTypes[orderValue],
      ))
          .where(
            (i) =>
                (i.duration ?? 60000) > 1000 * minDuration &&
                (i.isMusic! || i.isPodcast! || i.isAudioBook!) &&
                (includeOrExclude
                    ? checkIncludedOrExcluded(i)
                    : !checkIncludedOrExcluded(i)),
          )
          .toList();
    } else {
      _songs = widget.cachedSongs!;
    }
    added = true;
    setState(() {});
  }

  Future<void> sortSongs(int sortVal, int order) async {
    switch (sortVal) {
      case 0:
        _songs.sort(
          (a, b) => a.displayName.compareTo(b.displayName),
        );
        break;
      case 1:
        _songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
        break;
      case 2:
        _songs.sort(
          (a, b) => a.album.toString().compareTo(b.album.toString()),
        );
        break;
      case 3:
        _songs.sort(
          (a, b) => a.artist.toString().compareTo(b.artist.toString()),
        );
        break;
      case 4:
        _songs.sort(
          (a, b) => a.duration.toString().compareTo(b.duration.toString()),
        );
        break;
      case 5:
        _songs.sort(
          (a, b) => a.size.toString().compareTo(b.size.toString()),
        );
        break;
      default:
        _songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
        break;
    }

    if (order == 1) {
      _songs = _songs.reversed.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool rotated =
        MediaQuery.of(context).size.height < MediaQuery.of(context).size.width;

    double boxSize =
        MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
            ? MediaQuery.of(context).size.width / 2
            : MediaQuery.of(context).size.height / 2.5;

//get dorminant color from image rendered
    Future<Color> getdominantColor(ImageProvider imageProvider) async {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(imageProvider);
      return paletteGenerator.dominantColor!.color;
    }

    return FutureBuilder(
        future:
            getdominantColor(const AssetImage("assets/elements/online.png")),
        builder: (context, AsyncSnapshot<Color> snapshot) {
          return snapshot.connectionState == ConnectionState.waiting
              ? const Center(
                  child: SizedBox(),
                )
              : GradientContainer(
                  child: Column(
                    children: [
                      Expanded(
                        child: DefaultTabController(
                            length: widget.showPlaylists ? 5 : 4,
                            child: Stack(children: [
                              NestedScrollView(
                                //shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                headerSliverBuilder: (BuildContext context,
                                    bool innerBoxIsScrolled) {
                                  return [
                                    SliverAppBar(
                                      elevation: 0,

                                      stretch: true,
                                      pinned: true,
                                      centerTitle: true,
                                      expandedHeight:
                                          MediaQuery.of(context).size.height *
                                              0.3,
                                      bottom: TabBar(
                                        isScrollable: widget.showPlaylists,
                                        controller: _tcontroller,
                                        indicator: MaterialIndicator(
                                          horizontalPadding: 20,
                                          color: Theme.of(context).focusColor,
                                          height: 6,
                                        ),
                                        tabs: [
                                          const Tab(text: "Songs"),
                                          const Tab(text: "Albums"),
                                          const Tab(text: "Artists"),
                                          const Tab(text: "Genres"),
                                          if (widget.showPlaylists)
                                            const Tab(text: "Playlists"),
                                        ],
                                      ),
                                      actions: [
                                        IconButton(
                                          splashRadius: 24,
                                          icon:
                                              const Icon(CupertinoIcons.search),
                                          tooltip: 'Search',
                                          onPressed: () {
                                            showSearch(
                                              context: context,
                                              delegate: DataSearch(
                                                data: _songs,
                                                tempPath: tempPath!,
                                              ),
                                            );
                                          },
                                        ),
                                        PopupMenuButton(
                                          splashRadius: 24,
                                          icon: const Icon(
                                            Iconsax.filter,
                                          ),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(15.0)),
                                          ),
                                          onSelected: (int value) async {
                                            if (value < 6) {
                                              sortValue = value;
                                              Hive.box('settings')
                                                  .put('sortValue', value);
                                            } else {
                                              orderValue = value - 6;
                                              Hive.box('settings').put(
                                                  'orderValue', orderValue);
                                            }
                                            await sortSongs(
                                                sortValue, orderValue);
                                            setState(() {});
                                          },
                                          itemBuilder: (context) {
                                            final List<String> sortTypes = [
                                              'Display Name',
                                              'Date Added',
                                              'Album',
                                              'Artist',
                                              'Duration',
                                              'Size',
                                            ];
                                            final List<String> orderTypes = [
                                              'Increasing',
                                              'Decreasing',
                                            ];
                                            final menuList =
                                                <PopupMenuEntry<int>>[];
                                            menuList.addAll(
                                              sortTypes
                                                  .map(
                                                    (e) => PopupMenuItem(
                                                      value:
                                                          sortTypes.indexOf(e),
                                                      child: Row(
                                                        children: [
                                                          if (sortValue ==
                                                              sortTypes
                                                                  .indexOf(e))
                                                            Icon(
                                                              Icons
                                                                  .check_rounded,
                                                              size: 20,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors.white
                                                                  : Colors.grey[
                                                                      700],
                                                            )
                                                          else
                                                            const SizedBox(),
                                                          const SizedBox(
                                                              width: 10),
                                                          Text(e),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            );
                                            menuList.add(
                                              const PopupMenuDivider(
                                                height: 10,
                                              ),
                                            );
                                            menuList.addAll(
                                              orderTypes
                                                  .map(
                                                    (e) => PopupMenuItem(
                                                      value: sortTypes.length +
                                                          orderTypes.indexOf(e),
                                                      child: Row(
                                                        children: [
                                                          if (orderValue ==
                                                              orderTypes
                                                                  .indexOf(e))
                                                            Icon(
                                                              Icons
                                                                  .check_rounded,
                                                              size: 20,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors.white
                                                                  : Colors.grey[
                                                                      700],
                                                            )
                                                          else
                                                            const SizedBox(),
                                                          const SizedBox(
                                                              width: 10),
                                                          Text(e),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            );
                                            return menuList;
                                          },
                                        ),
                                      ],
                                      // title: Opacity(
                                      //   opacity: 1 - _opacity.value,
                                      //   child: Text(
                                      //     title.toUpperCase(),
                                      //     style: const TextStyle(
                                      //       fontSize: 17,
                                      //       fontWeight: FontWeight.w500,
                                      //     ),
                                      //   ),
                                      // ),
                                      flexibleSpace: LayoutBuilder(
                                        builder: (BuildContext context,
                                            BoxConstraints constraints) {
                                          double top =
                                              constraints.biggest.height;
                                          if (top >
                                              MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.45) {
                                            top = MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.45;
                                          }
                                          return FlexibleSpaceBar(
                                            // title: const Opacity(
                                            //   opacity: 0.5,
                                            //   child: Text(
                                            //     "All Music",
                                            //     style: TextStyle(
                                            //       fontSize: 15,
                                            //       fontWeight: FontWeight.w500,
                                            //     ),
                                            //     textAlign: TextAlign.center,
                                            //     overflow: TextOverflow.ellipsis,
                                            //   ),
                                            // ),
                                            centerTitle: true,
                                            background: GlassmorphicContainer(
                                              width: double.maxFinite,
                                              height: double.maxFinite,
                                              borderRadius: 0,
                                              blur: 20,
                                              alignment: Alignment.bottomCenter,
                                              border: 2,
                                              linearGradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    snapshot.data!
                                                        .withOpacity(0.9),
                                                    snapshot.data!
                                                        .withOpacity(0.05),
                                                  ],
                                                  stops: const [
                                                    0.1,
                                                    1,
                                                  ]),
                                              borderGradient:
                                                  const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.transparent
                                                ],
                                              ),
                                              child: Stack(
                                                children: [
                                                  if (!rotated)
                                                    Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        12.0),
                                                            child: SizedBox(
                                                              height:
                                                                  boxSize - 40,
                                                              child: Image.asset(
                                                                  "assets/cover.jpg"),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  if (rotated)
                                                    Align(
                                                      alignment:
                                                          const Alignment(
                                                              -0.85, 0.5),
                                                      child: Card(
                                                        elevation: 5,
                                                        color:
                                                            Colors.transparent,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      7.0),
                                                        ),
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        child: SizedBox(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.3,
                                                          child: Image.asset(
                                                              "assets/cover.jpg"),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ];
                                },
                                body: !added
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : TabBarView(
                                        physics: const CustomPhysics(),
                                        controller: _tcontroller,
                                        children: [
                                          SongsTab(
                                            songs: _songs,
                                            playlistId: widget.playlistId,
                                            playlistName: widget.title,
                                            tempPath: tempPath!,
                                          ),
                                          const LocalAlbumsPage(),
                                          const LocalArtistsPage(),
                                          const LocalGenresPage(),
                                          if (widget.showPlaylists)
                                            LocalPlaylists(
                                              playlistDetails: playlistDetails,
                                              offlineAudioQuery:
                                                  offlineAudioQuery,
                                            ),
                                        ],
                                      ),
                              ),
                            ])),
                      ),
                      const MiniPlayer(),
                    ],
                  ),
                );
        });
  }
}

class SongsTab extends StatefulWidget {
  final List<SongModel> songs;
  final int? playlistId;
  final String? playlistName;
  final String tempPath;
  const SongsTab({
    super.key,
    required this.songs,
    required this.tempPath,
    this.playlistId,
    this.playlistName,
  });

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    double boxSize =
        MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
            ? MediaQuery.of(context).size.width / 2
            : MediaQuery.of(context).size.height / 2.5;
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset("assets/svg/add_content.svg",
                      height: 140, width: 100),
                  const SizedBox(height: 20),
                  Text(
                    "No music\nhere",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                PlaylistHead(
                  songsList: widget.songs,
                  offline: true,
                  fromDownloads: false,
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: widget.songs.length,
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              //Test putting local songa
                              //addRecentlyPlayed(widget.songs);
                              setState(() {});
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) => PlayScreen(
                                    songsList: widget.songs,
                                    index: index,
                                    offline: true,
                                    fromDownloads: false,
                                    fromMiniplayer: false,
                                    recommend: false,
                                  ),
                                ),
                              );
                            },
                            child: SizedBox(
                              height: boxSize - 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OfflineAudioQuery.offlineArtworkWidget(
                                    id: widget.songs[index].id,
                                    type: ArtworkType.AUDIO,
                                    height: 70,
                                    width: 70,
                                    tempPath: widget.tempPath,
                                    fileName:
                                        widget.songs[index].displayNameWOExt,
                                  ),
                                  Expanded(
                                    child: ListTile(
                                      title: Text(
                                        widget.songs[index].title.trim() != ''
                                            ? widget.songs[index].title
                                            : widget
                                                .songs[index].displayNameWOExt,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(fontSize: 17),
                                      ),
                                      subtitle: Text(
                                        widget.songs[index].album?.replaceAll(
                                                '<unknown>', 'Unknown') ??
                                            'Unknown',
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 3.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        PopupMenuButton(
                                          splashRadius: 24,
                                          icon: const Icon(
                                            Icons.more_horiz_rounded,
                                            color: Colors.grey,
                                          ),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(15.0)),
                                          ),
                                          onSelected: (int? value) async {
                                            if (value == 0) {
                                              AddToOffPlaylist()
                                                  .addToOffPlaylist(
                                                context,
                                                widget.songs[index].id,
                                              );
                                            }
                                            if (value == 1) {
                                              await OfflineAudioQuery()
                                                  .removeFromPlaylist(
                                                playlistId: widget.playlistId!,
                                                audioId: widget.songs[index].id,
                                              );
                                              ShowSnackBar().showSnackBar(
                                                context,
                                                '${'Removed from'} ${widget.playlistName}',
                                              );
                                            }
                                            if (value == 2) {
                                              widget.songs[index] =
                                                  (await editTags(
                                                widget.songs[index] as Map,
                                                context,
                                              )) as SongModel;
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 0,
                                              child: Row(
                                                children: const [
                                                  Icon(Icons
                                                      .playlist_add_rounded),
                                                  SizedBox(width: 10.0),
                                                  Text(
                                                    'Add to Playlist',
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (widget.playlistId != null)
                                              PopupMenuItem(
                                                value: 1,
                                                child: Row(
                                                  children: const [
                                                    Icon(Iconsax.trash),
                                                    SizedBox(width: 10.0),
                                                    Text('Remove'),
                                                  ],
                                                ),
                                              ),
                                            PopupMenuItem(
                                              value: 2,
                                              child: Row(
                                                children: const [
                                                  Icon(Iconsax.edit),
                                                  SizedBox(width: 10.0),
                                                  Text(
                                                    'Edit Tag',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          splashRadius: 24,
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              PageRouteBuilder(
                                                opaque: false,
                                                pageBuilder: (_, __, ___) =>
                                                    PlayScreen(
                                                  songsList: widget.songs,
                                                  index: index,
                                                  offline: true,
                                                  fromDownloads: false,
                                                  fromMiniplayer: false,
                                                  recommend: false,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                              MdiIcons.playCircleOutline),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
