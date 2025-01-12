// ignore_for_file: use_super_parameters, avoid_redundant_argument_values

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:gem/APIs/api.dart';
import 'package:gem/widgets/artist_like_button.dart';
import 'package:gem/widgets/bouncy_sliver_scroll_view.dart';
import 'package:gem/widgets/copy_clipboard.dart';
import 'package:gem/widgets/download_button.dart';
import 'package:gem/widgets/empty_screen.dart';
import 'package:gem/widgets/gradient_containers.dart';
import 'package:gem/widgets/horizontal_albumlist.dart';
import 'package:gem/widgets/miniplayer.dart';
import 'package:gem/widgets/playlist_popupmenu.dart';
import 'package:gem/widgets/song_tile_trailing_menu.dart';
import 'package:gem/Screens/Common/song_list.dart';
import 'package:gem/Screens/Player/music_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../Helpers/local_music_functions.dart';

class ArtistSearchPage extends StatefulWidget {
  final Map data;

  const ArtistSearchPage({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  _ArtistSearchPageState createState() => _ArtistSearchPageState();
}

class _ArtistSearchPageState extends State<ArtistSearchPage> {
  bool status = false;
  String category = '';
  String sortOrder = '';
  Map<String, List> data = {};
  bool fetched = false;
  String? tempPath = Hive.box('settings').get('tempDirPath')?.toString();
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  List<SongModel> artistSongs = [];
  bool loading = false;

  Future<void> fetchSongs() async {
    await offlineAudioQuery.requestPermission();
    tempPath ??= (await getTemporaryDirectory()).path;
    artistSongs = await offlineAudioQuery.getSongs();

    setState(() {
      loading = true;
    });
  }

  @override
  void initState() {
    fetchSongs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double boxSize =
        MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
            ? MediaQuery.of(context).size.width / 2
            : MediaQuery.of(context).size.height / 2.5;
    if (!status) {
      status = true;
      SaavnAPI()
          .fetchArtistSongs(
        artistToken: widget.data['artistToken'].toString(),
        category: category,
        sortOrder: sortOrder,
      )
          .then((value) {
        setState(() {
          data = value;
          fetched = true;
        });
      });
    }
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: !fetched
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : data.isEmpty
                      ? emptyScreen(
                          context,
                          0,
                          'ಠ_ಠ',
                          100,
                          'Yikes!',
                          60,
                          'Something unexpected\nhappened',
                          20,
                        )
                      : BouncyImageSliverScrollView(
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.share_rounded),
                              tooltip: 'Share',
                              onPressed: () {
                                Share.share(
                                  widget.data['perma_url'].toString(),
                                );
                              },
                            ),
                            if (data['Top Songs'] != null)
                              PlaylistPopupMenu(
                                data: data['Top Songs']!,
                                title:
                                    widget.data['title']?.toString() ?? 'Songs',
                              ),
                          ],
                          title: widget.data['title']?.toString() ?? 'Songs',
                          placeholderImage: 'assets/artist.png',
                          imageUrl: widget.data['image']
                              .toString()
                              .replaceAll('http:', 'https:')
                              .replaceAll('50x50', '500x500')
                              .replaceAll('150x150', '500x500'),
                          sliverList: SliverList(
                            delegate: SliverChildListDelegate(
                              [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                opaque: false,
                                                pageBuilder: (_, __, ___) =>
                                                    PlayScreen(
                                                  songsList: data['Top Songs']!,
                                                  index: 0,
                                                  offline: false,
                                                  fromMiniplayer: false,
                                                  fromDownloads: false,
                                                  recommend: true,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(100.0),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10.0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    EvaIcons.musicOutline,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                                    size: 26.0,
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Text(
                                                    'Shuffle Top Songs',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18.0,
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Container(
                                        margin: const EdgeInsets.only(
                                          top: 10,
                                          bottom: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(100.0),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: ArtistLikeButton(
                                            data: widget.data,
                                            size: 27.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                //! view local songs for the artist
                                Column(
                                    children: List.generate(artistSongs.length,
                                        (index) {
                                  return SizedBox(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        index == 0 &&
                                                artistSongs[index].artist ==
                                                    widget.data['title']
                                                        ?.toString()
                                            ? Row(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                            .fromLTRB(
                                                        20, 10, 0, 20),
                                                    child: Text(
                                                      "LOCAL SONGS by ${widget.data['title']?.toString()}",
                                                      style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                ],
                                              )
                                            : const SizedBox(),
                                        artistSongs[index].artist ==
                                                widget.data['title']?.toString()
                                            ? GestureDetector(
                                                onTap: () {
                                                  //Test putting local songa
                                                  //addRecentlyPlayed(widget.songs);
                                                  setState(() {});
                                                  Navigator.of(context).push(
                                                    PageRouteBuilder(
                                                      opaque: false,
                                                      pageBuilder:
                                                          (_, __, ___) =>
                                                              PlayScreen(
                                                        songsList: artistSongs,
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
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      OfflineAudioQuery
                                                          .offlineArtworkWidget(
                                                        id: artistSongs[index]
                                                            .id,
                                                        type: ArtworkType.AUDIO,
                                                        height: 70,
                                                        width: 70,
                                                        tempPath: tempPath!,
                                                        fileName: artistSongs[
                                                                index]
                                                            .displayNameWOExt,
                                                      ),
                                                      Expanded(
                                                        child: ListTile(
                                                          title: Text(
                                                            artistSongs[index]
                                                                        .title
                                                                        .trim() !=
                                                                    ''
                                                                ? artistSongs[
                                                                        index]
                                                                    .title
                                                                : artistSongs[
                                                                        index]
                                                                    .displayNameWOExt,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: GoogleFonts
                                                                .roboto(
                                                                    fontSize:
                                                                        17),
                                                          ),
                                                          subtitle: Text(
                                                            artistSongs[index]
                                                                    .album
                                                                    ?.replaceAll(
                                                                        '<unknown>',
                                                                        'Unknown') ??
                                                                'Unknown',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            textAlign:
                                                                TextAlign.start,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 3.0),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            /* IconButton(
                                                              splashRadius: 24,
                                                              onPressed:
                                                                  () async {},
                                                              icon: const Icon(
                                                                  EvaIcons
                                                                      .moreHorizontalOutline),
                                                            ), */
                                                            IconButton(
                                                              splashRadius: 24,
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .push(
                                                                  PageRouteBuilder(
                                                                    opaque:
                                                                        false,
                                                                    pageBuilder: (_,
                                                                            __,
                                                                            ___) =>
                                                                        PlayScreen(
                                                                      songsList:
                                                                          artistSongs,
                                                                      index:
                                                                          index,
                                                                      offline:
                                                                          true,
                                                                      fromDownloads:
                                                                          false,
                                                                      fromMiniplayer:
                                                                          false,
                                                                      recommend:
                                                                          false,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              icon: const Icon(
                                                                  MdiIcons
                                                                      .playCircleOutline),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : const SizedBox()
                                      ],
                                    ),
                                  );
                                })),
                                ...data.entries.map(
                                  (entry) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 25,
                                            top: 15,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        0, 10, 0, 10),
                                                child: Text(
                                                  entry.key.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              if (entry.key ==
                                                  'Top Songs') ...<Widget>[
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: <Widget>[
                                                    ChoiceChip(
                                                      label: const Text(
                                                        'Popularity',
                                                      ),
                                                      selectedColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                              .withOpacity(0.5),
                                                      labelStyle: TextStyle(
                                                        fontWeight: category ==
                                                                ''
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                      selected: category == '',
                                                      onSelected:
                                                          (bool selected) {
                                                        if (selected) {
                                                          category = '';
                                                          sortOrder = '';
                                                          status = false;
                                                          setState(() {});
                                                        }
                                                      },
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    ChoiceChip(
                                                      label: const Text(
                                                        'Date',
                                                      ),
                                                      selectedColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                              .withOpacity(0.2),
                                                      labelStyle: TextStyle(
                                                        color: category ==
                                                                'latest'
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .secondary
                                                            : Theme.of(context)
                                                                .textTheme
                                                                .bodyLarge!
                                                                .color,
                                                        fontWeight: category ==
                                                                'latest'
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                      selected:
                                                          category == 'latest',
                                                      onSelected:
                                                          (bool selected) {
                                                        if (selected) {
                                                          category = 'latest';
                                                          sortOrder = 'desc';
                                                          status = false;
                                                          setState(() {});
                                                        }
                                                      },
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    ChoiceChip(
                                                      label: const Text(
                                                        'Alphabetical',
                                                      ),
                                                      selectedColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                              .withOpacity(0.2),
                                                      labelStyle: TextStyle(
                                                        color: category ==
                                                                'alphabetical'
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .secondary
                                                            : Theme.of(context)
                                                                .textTheme
                                                                .bodyLarge!
                                                                .color,
                                                        fontWeight: category ==
                                                                'alphabetical'
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                      selected: category ==
                                                          'alphabetical',
                                                      onSelected:
                                                          (bool selected) {
                                                        if (selected) {
                                                          category =
                                                              'alphabetical';
                                                          sortOrder = 'asc';
                                                          status = false;
                                                          setState(() {});
                                                        }
                                                      },
                                                    ),
                                                    const Spacer(),
                                                    if (data['Top Songs'] !=
                                                        null)
                                                      MultiDownloadButton(
                                                        data:
                                                            data['Top Songs']!,
                                                        playlistName: widget
                                                                .data['title']
                                                                ?.toString() ??
                                                            'Songs',
                                                      ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (entry.key != 'Top Songs')
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                5, 10, 5, 0),
                                            child: HorizontalAlbumsList(
                                              songsList: entry.value,
                                              onTap: (int idx) {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    pageBuilder: (
                                                      _,
                                                      __,
                                                      ___,
                                                    ) =>
                                                        entry.key ==
                                                                'Related Artists'
                                                            ? ArtistSearchPage(
                                                                data: entry
                                                                        .value[
                                                                    idx] as Map,
                                                              )
                                                            : SongsListPage(
                                                                listItem: entry
                                                                        .value[
                                                                    idx] as Map,
                                                              ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        else
                                          ListView.builder(
                                            itemCount: entry.value.length,
                                            padding: const EdgeInsets.fromLTRB(
                                              5,
                                              5,
                                              5,
                                              0,
                                            ),
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemBuilder: (context, index) {
                                              return ListTile(
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                  left: 15.0,
                                                ),
                                                title: Text(
                                                  '${entry.value[index]["title"]}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                onLongPress: () {
                                                  copyToClipboard(
                                                    context: context,
                                                    text:
                                                        '${entry.value[index]["title"]}',
                                                  );
                                                },
                                                subtitle: Text(
                                                  '${entry.value[index]["subtitle"]}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                leading: Card(
                                                  elevation: 8,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      7.0,
                                                    ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: CachedNetworkImage(
                                                    fit: BoxFit.cover,
                                                    errorWidget:
                                                        (context, _, __) =>
                                                            Image(
                                                      fit: BoxFit.cover,
                                                      image: AssetImage(
                                                        (entry.key ==
                                                                    'Top Songs' ||
                                                                entry.key ==
                                                                    'Latest Release')
                                                            ? 'assets/cover.jpg'
                                                            : 'assets/album.png',
                                                      ),
                                                    ),
                                                    imageUrl:
                                                        '${entry.value[index]["image"].replaceAll('http:', 'https:')}',
                                                    placeholder:
                                                        (context, url) => Image(
                                                      fit: BoxFit.cover,
                                                      image: AssetImage(
                                                        (entry.key ==
                                                                    'Top Songs' ||
                                                                entry.key ==
                                                                    'Latest Release' ||
                                                                entry.key ==
                                                                    'Singles')
                                                            ? 'assets/cover.jpg'
                                                            : 'assets/album.png',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                trailing: (entry.key ==
                                                            'Top Songs' ||
                                                        entry.key ==
                                                            'Latest Release' ||
                                                        entry.key == 'Singles')
                                                    ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          DownloadButton(
                                                            data: entry.value[
                                                                index] as Map,
                                                            icon: 'download',
                                                          ),
                                                          /*   LikeButton(
                                                            data: entry.value[
                                                                index] as Map,
                                                            mediaItem: null,
                                                          ), */
                                                          SongTileTrailingMenu(
                                                            data: entry.value[
                                                                index] as Map,
                                                          ),
                                                        ],
                                                      )
                                                    : null,
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      opaque: false,
                                                      pageBuilder: (
                                                        _,
                                                        __,
                                                        ___,
                                                      ) =>
                                                          (entry.key ==
                                                                      'Top Songs' ||
                                                                  entry.key ==
                                                                      'Latest Release' ||
                                                                  entry.key ==
                                                                      'Singles')
                                                              ? PlayScreen(
                                                                  songsList:
                                                                      entry
                                                                          .value,
                                                                  index: index,
                                                                  offline:
                                                                      false,
                                                                  fromMiniplayer:
                                                                      false,
                                                                  fromDownloads:
                                                                      false,
                                                                  recommend:
                                                                      true,
                                                                )
                                                              : SongsListPage(
                                                                  listItem: entry
                                                                          .value[
                                                                      index] as Map,
                                                                ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                      ],
                                    );
                                  },
                                ).toList(),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
