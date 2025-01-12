// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gem/Helpers/extensions.dart';
import 'package:hive/hive.dart';
import '../../../APIs/api.dart';
import '../../../services/player_service.dart';
import '../../../widgets/collage.dart';
import '../../../widgets/horizontal_albumlist.dart';
import '../../../widgets/last_session_widget.dart';
import '../../../widgets/like_button.dart';
import '../../../widgets/on_hover.dart';
import '../../../widgets/song_tile_trailing_menu.dart';
import '../../../Helpers/format.dart';
import '../../../Helpers/image_cleaner.dart';
import '../../common/song_list.dart';
import '../../Library/favorites_section.dart';
import '../../Search/artists.dart';

bool fetched = false;
List preferredLanguage = Hive.box('settings')
    .get('preferredLanguage', defaultValue: ['English']) as List;
List likedRadio =
    Hive.box('settings').get('likedRadio', defaultValue: []) as List;
Map data = Hive.box('cache').get('homepage', defaultValue: {}) as Map;
List lists = ['recent', 'playlist', ...?data['collections']];

class OnlineMusic extends StatefulWidget {
  const OnlineMusic({super.key});

  @override
  _OnlineMusicState createState() => _OnlineMusicState();
}

class _OnlineMusicState extends State<OnlineMusic>
    with AutomaticKeepAliveClientMixin<OnlineMusic> {
  List recentList =
      Hive.box('cache').get('recentSongs', defaultValue: []) as List;
  Map likedArtists =
      Hive.box('settings').get('likedArtists', defaultValue: {}) as Map;
  List blacklistedHomeSections = Hive.box('settings')
      .get('blacklistedHomeSections', defaultValue: []) as List;
  List playlistNames =
      Hive.box('settings').get('playlistNames')?.toList() as List? ??
          ['Favorite Songs'];
  Map playlistDetails =
      Hive.box('settings').get('playlistDetails', defaultValue: {}) as Map;
  int recentIndex = 0;
  int playlistIndex = 1;

  Future<void> getHomePageData() async {
    Map recievedData = await SaavnAPI().fetchHomePageData();
    if (recievedData.isNotEmpty) {
      Hive.box('cache').put('homepage', recievedData);
      data = recievedData;
      lists = ['recent', 'playlist', ...?data['collections']];
      lists.insert((lists.length / 2).round(), 'likedArtists');
    }
    setState(() {});
    recievedData = await FormatResponse.formatPromoLists(data);
    if (recievedData.isNotEmpty) {
      Hive.box('cache').put('homepage', recievedData);
      data = recievedData;
      lists = ['recent', 'playlist', ...?data['collections']];
      lists.insert((lists.length / 2).round(), 'likedArtists');
    }
    setState(() {});
  }

  String getSubTitle(Map item) {
    final type = item['type'];
    switch (type) {
      case 'charts':
        return '';
      case 'radio_station':
        return 'Radio • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle']?.toString().unescape()}';
      case 'playlist':
        return 'Playlist • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'song':
        return 'Single • ${item['artist']?.toString().unescape()}';
      case 'mix':
        return 'Mix • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'show':
        return 'Podcast • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'album':
        final artists = item['more_info']?['artistMap']?['artists']
            .map((artist) => artist['name'])
            .toList();
        if (artists != null) {
          return 'Album • ${artists?.join(', ')?.toString().unescape()}';
        } else if (item['subtitle'] != null && item['subtitle'] != '') {
          return 'Album • ${item['subtitle']?.toString().unescape()}';
        }
        return 'Album';
      default:
        final artists = item['more_info']?['artistMap']?['artists']
            .map((artist) => artist['name'])
            .toList();
        return artists?.join(', ')?.toString().unescape() ?? '';
    }
  }

  int likedCount() {
    return Hive.box('Favorite Songs').length;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!fetched) {
      getHomePageData();
      fetched = true;
    }
    double boxSize =
        MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
            ? MediaQuery.of(context).size.width / 2
            : MediaQuery.of(context).size.height / 2.5;
    if (boxSize > 250) boxSize = 250;
    if (recentList.length < playlistNames.length) {
      recentIndex = 0;
      playlistIndex = 1;
    } else {
      recentIndex = 1;
      playlistIndex = 0;
    }
    return (data.isEmpty && recentList.isEmpty)
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            itemCount: data.isEmpty ? 2 : lists.length,
            itemBuilder: (context, idx) {
              if (idx == recentIndex) {
                return (recentList.isEmpty ||
                        !(Hive.box('settings')
                            .get('showRecent', defaultValue: true) as bool))
                    ? const SizedBox()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 0, 10),
                                child: Text(
                                  "last Played online".toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          HorizontalAlbumsListSeparated(
                            songsList: recentList,
                            onTap: (int idx) {
                              PlayerInvoke.init(
                                songsList: recentList,
                                index: idx,
                                isOffline: false,
                              );
                              Navigator.pushNamed(context, '/player');
                            },
                          ),
                        ],
                      );
              }
              if (idx == playlistIndex) {
                return (playlistNames.isEmpty ||
                        !(Hive.box('settings')
                            .get('showPlaylist', defaultValue: true) as bool) ||
                        likedCount() == 0)
                    ? const SizedBox()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 0, 10),
                                child: Text(
                                  "Online playlists".toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: boxSize + 15,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              itemCount: playlistNames.length,
                              itemBuilder: (context, index) {
                                final String name =
                                    playlistNames[index].toString();
                                final String showName =
                                    playlistDetails.containsKey(name)
                                        ? playlistDetails[name]['name']
                                                ?.toString() ??
                                            name
                                        : name;
                                final String? subtitle = playlistDetails[
                                                name] ==
                                            null ||
                                        playlistDetails[name]['count'] ==
                                            null ||
                                        playlistDetails[name]['count'] == 0
                                    ? null
                                    : '${playlistDetails[name]['count']} songs';
                                return GestureDetector(
                                  child: SizedBox(
                                    width: boxSize - 30,
                                    child: HoverBox(
                                      child: (playlistDetails[name] == null ||
                                              playlistDetails[name]
                                                      ['imagesList'] ==
                                                  null ||
                                              (playlistDetails[name]
                                                      ['imagesList'] as List)
                                                  .isEmpty)
                                          ? Card(
                                              elevation: 5,
                                              color: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  10.0,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: name == 'Favorite Songs'
                                                  ? const Image(
                                                      image: AssetImage(
                                                        'assets/cover.jpg',
                                                      ),
                                                    )
                                                  : const Image(
                                                      image: AssetImage(
                                                        'assets/album.png',
                                                      ),
                                                    ),
                                            )
                                          : Collage(
                                              borderRadius: 10.0,
                                              imageList: playlistDetails[name]
                                                  ['imagesList'] as List,
                                              showGrid: true,
                                              placeholderImage:
                                                  'assets/cover.jpg',
                                            ),
                                      builder: (
                                        BuildContext context,
                                        bool isHover,
                                        Widget? child,
                                      ) {
                                        return Card(
                                          color: isHover
                                              ? null
                                              : Colors.transparent,
                                          elevation: 0,
                                          margin: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.0,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Column(
                                            children: [
                                              SizedBox.square(
                                                dimension: isHover
                                                    ? boxSize - 25
                                                    : boxSize - 30,
                                                child: child,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10.0,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      showName,
                                                      textAlign:
                                                          TextAlign.center,
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (subtitle != null &&
                                                        subtitle.isNotEmpty)
                                                      Text(
                                                        subtitle,
                                                        textAlign:
                                                            TextAlign.center,
                                                        softWrap: false,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall!
                                                                  .color,
                                                        ),
                                                      )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  onTap: () async {
                                    await Hive.openBox(name);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LikedSongs(
                                          playlistName: name,
                                          showName: playlistDetails
                                                  .containsKey(name)
                                              ? playlistDetails[name]['name']
                                                      ?.toString() ??
                                                  name
                                              : name,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        ],
                      );
              }
              if (lists[idx] == 'likedArtists') {
                final List likedArtistsList = likedArtists.values.toList();
                return likedArtists.isEmpty
                    ? const SizedBox()
                    : Column(
                        children: [
                          const Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(10, 10, 0, 10),
                                child: Text(
                                  "LIKED ARTISTS",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          HorizontalAlbumsList(
                            songsList: likedArtistsList,
                            onTap: (int idx) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) => ArtistSearchPage(
                                    data: likedArtistsList[idx] as Map,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
              }

              //exclude premium categories
              if (data['modules'][lists[idx]]?['title'].toString() ==
                  "Radio Stations") {
                return const SizedBox();
              }

              if (data['modules'][lists[idx]]?['title'].toString() ==
                  "Top Charts") {
                return const SizedBox();
              }
              if (data['modules'][lists[idx]]?['title'].toString() ==
                  "Editorial Picks") {
                return const SizedBox();
              }

              return (data[lists[idx]] == null ||
                      blacklistedHomeSections.contains(
                        data['modules'][lists[idx]]?['title']
                            ?.toString()
                            .toLowerCase(),
                      ))
                  ? const SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                          child: Text(
                            data['modules'][lists[idx]]?['title']
                                    ?.toString()
                                    .toUpperCase()
                                    .unescape() ??
                                '',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: boxSize + 15,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: (data[lists[idx]] as List).length,
                            itemBuilder: (context, index) {
                              Map item;

                              item = data[lists[idx]][index] as Map;

                              final currentSongList = data[lists[idx]]
                                  .where((e) => e['type'] == 'song')
                                  .toList();
                              final subTitle = getSubTitle(item);
                              item['subTitle'] = subTitle;
                              if (item.isEmpty) return const SizedBox();
                              //TODO: Test whether item list at index is empty
                              if ((data[lists[idx]] as List).isEmpty) {
                                return const SizedBox();
                              }
                              return GestureDetector(
                                onLongPress: () {
                                  Feedback.forLongPress(context);
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return InteractiveViewer(
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  Navigator.pop(context),
                                            ),
                                            AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                              ),
                                              backgroundColor:
                                                  Colors.transparent,
                                              contentPadding: EdgeInsets.zero,
                                              content: Card(
                                                elevation: 5,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    15.0,
                                                  ),
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: CachedNetworkImage(
                                                  fit: BoxFit.cover,
                                                  errorWidget:
                                                      (context, _, __) =>
                                                          const Image(
                                                    fit: BoxFit.cover,
                                                    image: AssetImage(
                                                      'assets/cover.jpg',
                                                    ),
                                                  ),
                                                  imageUrl: getImageUrl(
                                                    item['image'].toString(),
                                                  ),
                                                  placeholder: (context, url) =>
                                                      Image(
                                                    fit: BoxFit.cover,
                                                    image: (item['type'] ==
                                                                'playlist' ||
                                                            item['type'] ==
                                                                'album')
                                                        ? const AssetImage(
                                                            'assets/album.png',
                                                          )
                                                        : item['type'] ==
                                                                'artist'
                                                            ? const AssetImage(
                                                                'assets/artist.png',
                                                              )
                                                            : const AssetImage(
                                                                'assets/cover.jpg',
                                                              ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                onTap: () {
                                  if (item['type'] == 'radio_station') {
                                    /* ShowSnackBar().showSnackBar(
                                      context,
                                      "Connecting to the station",
                                      duration: const Duration(seconds: 2),
                                    );
                                    SaavnAPI()
                                        .createRadio(
                                      names: item['more_info']
                                                      ['featured_station_type']
                                                  .toString() ==
                                              'artist'
                                          ? [
                                              item['more_info']['query']
                                                  .toString()
                                            ]
                                          : [item['id'].toString()],
                                      language: item['more_info']['language']
                                              ?.toString() ??
                                          'hindi',
                                      stationType: item['more_info']
                                              ['featured_station_type']
                                          .toString(),
                                    )
                                        .then((value) {
                                      if (value != null) {
                                        SaavnAPI()
                                            .getRadioSongs(stationId: value)
                                            .then((value) {
                                          PlayerInvoke.init(
                                            songsList: value,
                                            index: 0,
                                            isOffline: false,
                                            shuffle: true,
                                          );
                                          Navigator.pushNamed(
                                            context,
                                            '/player',
                                          );
                                        });
                                      }
                                    }); */
                                  } else {
                                    if (item['type'] == 'song') {
                                      PlayerInvoke.init(
                                        songsList: currentSongList as List,
                                        index: currentSongList.indexWhere(
                                          (e) => e['id'] == item['id'],
                                        ),
                                        isOffline: false,
                                      );
                                    }
                                    item['type'] == 'song'
                                        ? Navigator.pushNamed(
                                            context,
                                            '/player',
                                          )
                                        : Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              opaque: false,
                                              pageBuilder: (_, __, ___) =>
                                                  SongsListPage(
                                                listItem: item,
                                              ),
                                            ),
                                          );
                                  }
                                },
                                child: SizedBox(
                                  width: boxSize - 30,
                                  child: HoverBox(
                                    child: Card(
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          item['type'] == 'radio_station'
                                              ? 1000.0
                                              : 10.0,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        fit: BoxFit.cover,
                                        errorWidget: (context, _, __) =>
                                            const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage(
                                            'assets/cover.jpg',
                                          ),
                                        ),
                                        imageUrl: getImageUrl(
                                          item['image'].toString(),
                                        ),
                                        placeholder: (context, url) => Image(
                                          fit: BoxFit.cover,
                                          image: (item['type'] == 'playlist' ||
                                                  item['type'] == 'album')
                                              ? const AssetImage(
                                                  'assets/album.png',
                                                )
                                              : item['type'] == 'artist'
                                                  ? const AssetImage(
                                                      'assets/artist.png',
                                                    )
                                                  : const AssetImage(
                                                      'assets/cover.jpg',
                                                    ),
                                        ),
                                      ),
                                    ),
                                    builder: (
                                      BuildContext context,
                                      bool isHover,
                                      Widget? child,
                                    ) {
                                      return Card(
                                        color:
                                            isHover ? null : Colors.transparent,
                                        elevation: 0,
                                        margin: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                SizedBox.square(
                                                  dimension: isHover
                                                      ? boxSize - 25
                                                      : boxSize - 30,
                                                  child: child,
                                                ),
                                                if (isHover &&
                                                    (item['type'] == 'song' ||
                                                        item['type'] ==
                                                            'radio_station'))
                                                  Positioned.fill(
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                        4.0,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          item['type'] ==
                                                                  'radio_station'
                                                              ? 1000.0
                                                              : 10.0,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: DecoratedBox(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.black87,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              1000.0,
                                                            ),
                                                          ),
                                                          child: const Icon(
                                                            Icons
                                                                .play_arrow_rounded,
                                                            size: 50.0,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                /* if (item['type'] ==
                                                        'radio_station' &&
                                                    (Platform.isAndroid ||
                                                        Platform.isIOS ||
                                                        isHover))
                                                  Align(
                                                    alignment:
                                                        Alignment.topRight,
                                                    child: IconButton(
                                                      icon: likedRadio
                                                              .contains(item)
                                                          ? const Icon(
                                                              Icons
                                                                  .favorite_rounded,
                                                              color: Colors.red,
                                                            )
                                                          : const Icon(
                                                              Icons
                                                                  .favorite_border_rounded,
                                                            ),
                                                      tooltip: likedRadio
                                                              .contains(item)
                                                          ? "Unlike"
                                                          : "Like",
                                                      onPressed: () {
                                                        likedRadio
                                                                .contains(item)
                                                            ? likedRadio
                                                                .remove(item)
                                                            : likedRadio
                                                                .add(item);
                                                        Hive.box('settings')
                                                            .put(
                                                          'likedRadio',
                                                          likedRadio,
                                                        );
                                                        setState(() {});
                                                      },
                                                    ),
                                                  ), */
                                                if (item['type'] == 'song' ||
                                                    item['duration'] != null)
                                                  Align(
                                                    alignment:
                                                        Alignment.topRight,
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (isHover)
                                                          LikeButton(
                                                            mediaItem: null,
                                                            data: item,
                                                          ),
                                                        SongTileTrailingMenu(
                                                          data: item,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10.0,
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    item['title']
                                                            ?.toString()
                                                            .unescape() ??
                                                        '',
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  if (subTitle != '')
                                                    Text(
                                                      subTitle,
                                                      textAlign:
                                                          TextAlign.center,
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall!
                                                            .color,
                                                      ),
                                                    )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
            },
          );
  }
}
