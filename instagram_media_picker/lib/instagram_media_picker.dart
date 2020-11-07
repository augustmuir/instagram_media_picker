library instagram_media_picker;

import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InstagramMediaPicker extends StatefulWidget {
  final String appID;
  final String appSecret;
  InstagramMediaPicker({@required this.appID, @required this.appSecret})
      : assert(appID != null),
        assert(appSecret != null);

  @override
  _InstagramMediaPickerState createState() => _InstagramMediaPickerState();
}

class _InstagramMediaPickerState extends State<InstagramMediaPicker> {
  final webViewPlugin = FlutterWebviewPlugin();
  StreamSubscription<String> _onUrlChanged;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String accessToken;
  String accessCode;
  String igUserID;

  var mediaUrls = [];
  var mediaTimestamps = [];
  var mediaIDs = [];
  var mediaTypes = [];
  var mediaCaptions = [];

  var mediaSelected = [];

  int stage = 0;

  @override
  void initState() {
    super.initState();
    _onUrlChanged = webViewPlugin.onUrlChanged.listen((String url) {
      if (mounted) {
        if (url.contains("code=")) {
          setState(() {
            accessCode = (url.split("code=")[1]).replaceAll("#_", "");
            stage = 1;
          });
          var map = new Map<String, dynamic>();
          map['client_id'] = widget.appID;
          map['client_secret'] = widget.appSecret;
          map['grant_type'] = 'authorization_code';
          map['redirect_uri'] = 'https://httpstat.us/200';
          map['code'] = accessCode;
          _getShortLivedToken(map);
        }
      }
    });
  }

  @override
  void dispose() {
    _onUrlChanged.cancel();
    webViewPlugin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String urlOne =
        "https://instagram.com/oauth/authorize/?client_id=${widget.appID}&redirect_uri=https://httpstat.us/200&&scope=user_profile,user_media&response_type=code&hl=en";

    return Scaffold(
        appBar: AppBar(
          title: Text('Instagram Media'),
          centerTitle: true,
        ),
        body: StreamBuilder(
            stream: Stream.value(stage),
            builder: (context, stageSnap) {
              if (stageSnap.data == 0) {
                return WebviewScaffold(
                  key: scaffoldKey,
                  url: urlOne,
                );
              } else if (stageSnap.data == 1) {
                return Container(
                  color: Colors.transparent,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: Text('Fetching Media...'),
                  ),
                );
              } else if (stageSnap.data == 2) {
                return LayoutBuilder(builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        color: Colors.grey[100],
                        child: StreamBuilder(
                          stream: Stream.value(mediaCaptions),
                          builder: (context, mediaSnap) {
                            if (mediaCaptions.length == 0) {
                              return Center(child: Text('No Media to Display'));
                            } else {
                              return Padding(
                                padding: EdgeInsets.all(5),
                                child: GridView.count(
                                    crossAxisCount: 3,
                                    childAspectRatio: 1,
                                    children: List.generate(
                                        mediaCaptions.length, (index) {
                                      return InkWell(
                                        onTap: () {
                                          if (mediaSelected[index] == false) {
                                            setState(() {
                                              mediaSelected[index] = true;
                                            });
                                          } else {
                                            setState(() {
                                              mediaSelected[index] = false;
                                            });
                                          }
                                        },
                                        child: Stack(
                                          children: [
                                            Container(
                                              width:
                                                  constraints.maxWidth * 0.32,
                                              height:
                                                  constraints.maxWidth * 0.32,
                                              decoration: BoxDecoration(
                                                  color: Colors.grey,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(15)),
                                                  image: DecorationImage(
                                                      image: NetworkImage(
                                                          mediaUrls[index]))),
                                            ),
                                            Center(
                                                child: Icon(Icons.check,
                                                    color: _determineIconColor(
                                                        index),
                                                    size:
                                                        (constraints.maxWidth *
                                                            0.20)))
                                          ],
                                        ),
                                      );
                                    })),
                              );
                            }
                          },
                        ),
                      ),
                      Positioned(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 3,
                        left: constraints.maxWidth * 0.1,
                        right: constraints.maxWidth * 0.1,
                        child: InkWell(
                          onTap: () {
                            _determineAndReturn();
                          },
                          child: Container(
                            width: constraints.maxWidth * 0.80,
                            height: 55,
                            decoration: BoxDecoration(
                                color: Colors.blue[400].withOpacity(0.95),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: Center(
                              child: Text('Continue'),
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                });
              }
              return Container(
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Center(
                  child: Text('Fetching Media...'),
                ),
              );
            }));
  }

  _getShortLivedToken(map) async {
    String urlTwo = 'https://api.instagram.com/oauth/access_token';
    http.Response response = await http.post(urlTwo, body: map);
    var respData = json.decode(response.body);
    setState(() {
      accessToken = respData['access_token'];
      igUserID = (respData['user_id']).toString();
    });
    _getMedia(context);
  }

  _getMedia(context) async {
    var respData;
    String urlThree = 'https://graph.instagram.com/' +
        igUserID +
        '/media?access_token=' +
        accessToken +
        '&fields=timestamp,media_url,media_type,caption';
    http.Response response = await http.get(urlThree);
    respData = (json.decode(response.body))['data'];
    for (var i = 0; i < respData.length; i++) {
      if ((respData[i])['media_type'] == 'IMAGE') {
        mediaUrls.add((respData[i])['media_url']);
        mediaTimestamps.add((respData[i])['timestamp']);
        mediaIDs.add((respData[i])['id']);
        mediaTypes.add((respData[i])['media_type']);
        mediaCaptions.add((respData[i])['caption']);
        mediaSelected.add(false);
      }
    }
    setState(() {
      stage = 2;
    });
  }

  _determineIconColor(index) {
    if (mediaSelected[index] == false) {
      return Colors.transparent;
    } else {
      return Colors.greenAccent[700];
    }
  }

  _determineAndReturn() {
    var selectedPhotoUrls = [];
    var selectedPhotoCaptions = [];
    var selectedPhotoTimestamps = [];
    var selectedPhotoIDs = [];

    for (var i = 0; i < mediaSelected.length; i++) {
      if (mediaSelected[i] == true) {
        selectedPhotoUrls.add(mediaUrls[i]);
        selectedPhotoCaptions.add(mediaCaptions[i]);
        selectedPhotoTimestamps.add(mediaTimestamps[i]);
        selectedPhotoIDs.add(mediaIDs[i]);
      }
    }

    var returnData = [
      selectedPhotoUrls,
      selectedPhotoIDs,
      selectedPhotoCaptions,
      selectedPhotoTimestamps
    ];
    Navigator.of(context).pop(returnData);
  }
}
