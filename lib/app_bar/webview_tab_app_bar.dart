// import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/app_bar/url_info_popup.dart';
import 'package:flutter_browser/custom_image.dart';
import 'package:flutter_browser/main.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/favorite_model.dart';
import 'package:flutter_browser/models/web_archive_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/pages/developers/main.dart';
import 'package:flutter_browser/pages/settings/main.dart';
import 'package:flutter_browser/tab_popup_menu_actions.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_extend/share_extend.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import '../animated_flutter_browser_logo.dart';
import '../custom_popup_dialog.dart';
import '../custom_popup_menu_item.dart';
import '../popup_menu_actions.dart';
import '../project_info_popup.dart';
import '../webview_tab.dart';

String formatUrl(String url) {
  if (kDebugMode) {
    print('*****************$url');
  }
  // Regular expression pattern to check for a domain-like structure
  var domainPattern = RegExp(r'^(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}$');

  // Check if the URL starts with http:// or https://
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  } else if (domainPattern.hasMatch(url)) {
    // If the URL is a domain but doesn't start with http:// or https://, prepend 'https://'
    if (kDebugMode) {
      print('https://$url');
    }
    return 'https://$url';
  } else {
    // If the URL is not a domain-like string, return it as is
    return url;
  }
}

TextEditingController? _searchController = TextEditingController();

class WebViewTabAppBar extends StatefulWidget {
  final void Function()? showFindOnPage;

  const WebViewTabAppBar({Key? key, this.showFindOnPage}) : super(key: key);

  @override
  State<WebViewTabAppBar> createState() => _WebViewTabAppBarState();
}

class _WebViewTabAppBarState extends State<WebViewTabAppBar>
    with SingleTickerProviderStateMixin {
  FocusNode? _focusNode;

  GlobalKey tabInkWellKey = GlobalKey();

  Duration customPopupDialogTransitionDuration =
      const Duration(milliseconds: 300);
  CustomPopupDialogPageRoute? route;

  OutlineInputBorder outlineBorder = const OutlineInputBorder(
    borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    borderRadius: BorderRadius.all(
      Radius.circular(50.0),
    ),
  );

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode?.addListener(() async {
      _searchController!.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController!.text.length,
      );

      if (_focusNode != null &&
          !_focusNode!.hasFocus &&
          _searchController != null &&
          _searchController!.text.isEmpty) {
        var browserModel = Provider.of<BrowserModel>(context, listen: true);
        var webViewModel = browserModel.getCurrentTab()?.webViewModel;
        var webViewController = webViewModel?.webViewController;
        _searchController!.text =
            (await webViewController?.getUrl())?.toString() ?? "";
      }
    });
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    _focusNode = null;
    _searchController?.dispose();
    _searchController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<WebViewModel, WebUri?>(
        selector: (context, webViewModel) => webViewModel.url,
        builder: (context, url, child) {
          if (url == null) {
            _searchController?.text = "";
          }
          if (url != null && _focusNode != null && !_focusNode!.hasFocus) {
            _searchController?.text = url.toString();
          }

          Widget? leading = _buildAppBarHomePageWidget();

          return Selector<WebViewModel, bool>(
              selector: (context, webViewModel) => webViewModel.isIncognitoMode,
              builder: (context, isIncognitoMode, child) {
                return leading != null
                    ? AppBar(
                        backgroundColor:
                            isIncognitoMode ? Colors.black87 : Colors.black87,
                        leading: _buildAppBarHomePageWidget(),
                        titleSpacing: 0.0,
                        title: _buildSearchTextField(),
                        actions: _buildActionsMenu(),
                      )
                    : AppBar(
                        backgroundColor:
                            isIncognitoMode ? Colors.black87 : Colors.black87,
                        titleSpacing: 10.0,
                        title: _buildSearchTextField(),
                        actions: _buildActionsMenu(),
                      );
              });
        });
  }

  Widget? _buildAppBarHomePageWidget() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    var webViewModel = Provider.of<WebViewModel>(context, listen: true);

    if (!settings.homePageEnabled) {
      return null;
    }

    return IconButton(
      icon: const Icon(Icons.home),
      onPressed: () {
        if (webViewModel.webViewController != null) {
          var url =
              settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
                  ? WebUri(settings.customUrlHomePage)
                  : WebUri(settings.searchEngine.url);
          webViewModel.webViewController!
              .loadUrl(urlRequest: URLRequest(url: url));
        } else {
          addNewTab();
        }
      },
    );
  }

  Widget _buildSearchTextField() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    var webViewModel = Provider.of<WebViewModel>(context, listen: true);

    return SizedBox(
      height: 40.0,
      child: Stack(
        children: <Widget>[
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.length < 5) {
                return const Iterable<String>.empty();
              }
              if (kDebugMode) {
                print('### text to AI is:${textEditingValue.text}');
              }
              return getOpenAIAutocomplete(
                  textEditingValue.text); // Replace with
            },
            onSelected: (String selection) {
              _searchController!.text = selection.replaceAll('"', '');
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController? searchController,
                FocusNode? focusNode,
                VoidCallback onFieldSubmitted) {
              return TextField(
                controller: searchController,
                focusNode: focusNode,
                onTap: () {
                  _searchController!.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _searchController!.text.length,
                  );
                  _searchController = searchController;
                  _focusNode = focusNode;
                },
                keyboardType: TextInputType.url,
                autofocus: false,
                textInputAction: TextInputAction.go,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.only(
                      left: 45.0, top: 10.0, right: 10.0, bottom: 10.0),
                  filled: true,
                  fillColor: Colors.white,
                  border:
                      OutlineInputBorder(), // Replace with your outlineBorder
                  focusedBorder:
                      OutlineInputBorder(), // Replace with your outlineBorder
                  enabledBorder:
                      OutlineInputBorder(), // Replace with your outlineBorder
                  hintText: "Search for or type a web address",
                  hintStyle: TextStyle(color: Colors.black54, fontSize: 16.0),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 16.0),
                onSubmitted: (value) {
                  var url = WebUri(formatUrl(value.trim()));
                  if (!url.scheme.startsWith("http") &&
                      !Util.isLocalizedContent(url)) {
                    url = WebUri(settings.searchEngine.searchUrl + value);
                  }

                  if (webViewModel.webViewController != null) {
                    var webViewController = webViewModel.webViewController;
                    webViewController!
                        .loadUrl(urlRequest: URLRequest(url: url));
                  } else {
                    addNewTab(url: url);
                    webViewModel.url = url;
                  }
                },
              );
            },
          ),
          IconButton(
            icon: Selector<WebViewModel, bool>(
              selector: (context, webViewModel) => webViewModel.isSecure,
              builder: (context, isSecure, child) {
                var icon = Icons.info_outline;
                if (webViewModel.isIncognitoMode) {
                  icon = MaterialCommunityIcons.incognito;
                } else if (isSecure) {
                  if (webViewModel.url != null &&
                      webViewModel.url!.scheme == "file") {
                    icon = Icons.offline_pin;
                  } else {
                    icon = Icons.lock;
                  }
                }

                return Icon(
                  icon,
                  color: isSecure ? Colors.green : Colors.grey,
                );
              },
            ),
            onPressed: () {
              showUrlInfo();
            },
          ),
        ],
      ),
    );
  }

  Future<List<String>> getOpenAIAutocomplete(String input) async {
    // Use the endpoint for ChatGPT-3.5-turbo
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer sk-', // Replace with your actual API key
    };

    final data = {
      'model': 'gpt-3.5-turbo', // Specify the model
      'messages': [
        {
          'role': 'user',
          'content':
              " based on '$input' create a propser search suggestion to be asked from google; provide only one suggestion"
        }
      ],
      'max_tokens': 20,
      'temperature': 0.0,
      // Include any other parameters as per the latest API documentation
    };

    final response = await http.post(Uri.parse(endpoint),
        headers: headers, body: json.encode(data));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final List<dynamic> completions = responseBody['choices'];
      // Process and return suggestions as needed, assuming first choice text is the completion
      final List<String> suggestions = completions.isNotEmpty
          ? [completions[0]['message']['content'].toString().trim()]
          : [];
      return suggestions;
    } else {
      throw Exception('Failed to get autocomplete suggestions');
    }
  }

  Future<List<String>> getOpenAIAutocomplete0(String input) async {
    const endpoint =
        'https://api.openai.com/v1/engines/text-davinci-002/completions';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer sk-API',
    };

    final data = {
      'prompt': 'Complete the following user search query: $input',
      'max_tokens': 20,
      'temperature':
          0.3, // Adjust based on how deterministic you want the results to be
    };

    final response = await http.post(Uri.parse(endpoint),
        headers: headers, body: json.encode(data));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final List<dynamic> completions = responseBody['choices'];
      // Cast each element to String explicitly and return
      final List<String> suggestions =
          completions.map((c) => c['text'].toString().trim()).toList();
      return suggestions;
    } else {
      throw Exception('Failed to get autocomplete suggestions');
    }
  }

  List<Widget> _buildActionsMenu() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    return <Widget>[
      settings.homePageEnabled
          ? const SizedBox(
              width: 10.0,
            )
          : Container(),
      InkWell(
        key: tabInkWellKey,
        onLongPress: () {
          final RenderBox? box =
              tabInkWellKey.currentContext!.findRenderObject() as RenderBox?;
          if (box == null) {
            return;
          }

          Offset position = box.localToGlobal(Offset.zero);

          showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(position.dx,
                      position.dy + box.size.height, box.size.width, 0),
                  items: TabPopupMenuActions.choices.map((tabPopupMenuAction) {
                    IconData? iconData;
                    switch (tabPopupMenuAction) {
                      case TabPopupMenuActions.CLOSE_TABS:
                        iconData = Icons.cancel;
                        break;
                      case TabPopupMenuActions.NEW_TAB:
                        iconData = Icons.add;
                        break;
                      case TabPopupMenuActions.NEW_INCOGNITO_TAB:
                        iconData = MaterialCommunityIcons.incognito;
                        break;
                    }

                    return PopupMenuItem<String>(
                      value: tabPopupMenuAction,
                      child: Row(children: [
                        Icon(
                          iconData,
                          color: Colors.black,
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(tabPopupMenuAction),
                        )
                      ]),
                    );
                  }).toList())
              .then((value) {
            switch (value) {
              case TabPopupMenuActions.CLOSE_TABS:
                browserModel.closeAllTabs();
                break;
              case TabPopupMenuActions.NEW_TAB:
                addNewTab();
                break;
              case TabPopupMenuActions.NEW_INCOGNITO_TAB:
                addNewIncognitoTab();
                break;
            }
          });
        },
        onTap: () async {
          if (browserModel.webViewTabs.isNotEmpty) {
            var webViewModel = browserModel.getCurrentTab()?.webViewModel;
            var webViewController = webViewModel?.webViewController;
            var widgetsBingind = WidgetsBinding.instance;

            if (widgetsBingind.window.viewInsets.bottom > 0.0) {
              SystemChannels.textInput.invokeMethod('TextInput.hide');
              if (FocusManager.instance.primaryFocus != null) {
                FocusManager.instance.primaryFocus!.unfocus();
              }
              if (webViewController != null) {
                await webViewController.evaluateJavascript(
                    source: "document.activeElement.blur();");
              }
              await Future.delayed(const Duration(milliseconds: 300));
            }

            if (webViewModel != null && webViewController != null) {
              webViewModel.screenshot = await webViewController
                  .takeScreenshot(
                      screenshotConfiguration: ScreenshotConfiguration(
                          compressFormat: CompressFormat.JPEG, quality: 20))
                  .timeout(
                    const Duration(milliseconds: 1500),
                    onTimeout: () => null,
                  );
            }

            browserModel.showTabScroller = true;
          }
        },
        child: Container(
          margin: const EdgeInsets.only(
              left: 10.0, top: 15.0, right: 10.0, bottom: 15.0),
          decoration: BoxDecoration(
              border: Border.all(width: 2.0, color: Colors.white),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(5.0)),
          constraints: const BoxConstraints(minWidth: 25.0),
          child: Center(
              child: Text(
            browserModel.webViewTabs.length.toString(),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.0),
          )),
        ),
      ),
      PopupMenuButton<String>(
        onSelected: _popupMenuChoiceAction,
        itemBuilder: (popupMenuContext) {
          var items = [
            CustomPopupMenuItem<String>(
              enabled: true,
              isIconButtonRow: true,
              child: StatefulBuilder(
                builder: (statefulContext, setState) {
                  var browserModel =
                      Provider.of<BrowserModel>(statefulContext, listen: true);
                  var webViewModel =
                      Provider.of<WebViewModel>(statefulContext, listen: true);
                  var webViewController = webViewModel.webViewController;

                  var isFavorite = false;
                  FavoriteModel? favorite;

                  if (webViewModel.url != null &&
                      webViewModel.url!.toString().isNotEmpty) {
                    favorite = FavoriteModel(
                        url: webViewModel.url,
                        title: webViewModel.title ?? "",
                        favicon: webViewModel.favicon);
                    isFavorite = browserModel.containsFavorite(favorite);
                  }

                  var children = <Widget>[];

                  // if (Util.isIOS()) {
                  //   children.add(
                  //     SizedBox(
                  //         width: 35.0,
                  //         child: IconButton(
                  //             padding: const EdgeInsets.all(0.0),
                  //             icon: const Icon(
                  //               Icons.arrow_back,
                  //               color: Colors.black,
                  //             ),
                  //             onPressed: () {
                  //               webViewController?.goBack();
                  //               Navigator.pop(popupMenuContext);
                  //             })),
                  //   );
                  // }

                  children.addAll([
                    SizedBox(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              webViewController?.goBack();
                              Navigator.pop(popupMenuContext);
                            })),
                    SizedBox(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                if (favorite != null) {
                                  if (!browserModel
                                      .containsFavorite(favorite)) {
                                    browserModel.addFavorite(favorite);
                                  } else if (browserModel
                                      .containsFavorite(favorite)) {
                                    browserModel.removeFavorite(favorite);
                                  }
                                }
                              });
                            })),
                    // SizedBox(
                    //     width: 35.0,
                    //     child: IconButton(
                    //         padding: const EdgeInsets.all(0.0),
                    //         icon: const Icon(
                    //           Icons.file_download,
                    //           color: Colors.black,
                    //         ),
                    //         onPressed: () async {
                    //           Navigator.pop(popupMenuContext);
                    //           if (webViewModel.url != null &&
                    //               webViewModel.url!.scheme.startsWith("http")) {
                    //             var url = webViewModel.url;
                    //             if (url == null) {
                    //               return;
                    //             }

                    //             String webArchivePath =
                    //                 "$WEB_ARCHIVE_DIR${Platform.pathSeparator}${url.scheme}-${url.host}${url.path.replaceAll("/", "-")}${DateTime.now().microsecondsSinceEpoch}.${Util.isAndroid() ? WebArchiveFormat.MHT.toValue() : WebArchiveFormat.WEBARCHIVE.toValue()}";

                    //             String? savedPath =
                    //                 (await webViewController?.saveWebArchive(
                    //                     filePath: webArchivePath,
                    //                     autoname: false));

                    //             var webArchiveModel = WebArchiveModel(
                    //                 url: url,
                    //                 path: savedPath,
                    //                 title: webViewModel.title,
                    //                 favicon: webViewModel.favicon,
                    //                 timestamp: DateTime.now());

                    //             if (savedPath != null) {
                    //               browserModel.addWebArchive(
                    //                   url.toString(), webArchiveModel);
                    //               if (mounted) {
                    //                 ScaffoldMessenger.of(context)
                    //                     .showSnackBar(SnackBar(
                    //                   content: Text(
                    //                       "${webViewModel.url} saved offline!"),
                    //                 ));
                    //               }
                    //               browserModel.save();
                    //             } else {
                    //               if (mounted) {
                    //                 ScaffoldMessenger.of(context)
                    //                     .showSnackBar(const SnackBar(
                    //                   content: Text("Unable to save!"),
                    //                 ));
                    //               }
                    //             }
                    //           }
                    //         })),
                    SizedBox(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: const Icon(
                              Icons.settings_applications_rounded,
                              color: Colors.black,
                            ),
                            onPressed: () async {
                              Navigator.pop(popupMenuContext);

                              await route?.completed;
                              showUrlInfo();
                            })),
                    SizedBox(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: const Icon(
                              MaterialCommunityIcons.cellphone_screenshot,
                              color: Colors.black,
                            ),
                            onPressed: () async {
                              Navigator.pop(popupMenuContext);

                              await route?.completed;

                              takeScreenshotAndShow();
                            })),
                    SizedBox(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              webViewController?.reload();
                              Navigator.pop(popupMenuContext);
                            })),
                    SizedBox(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              webViewController?.goForward();
                              Navigator.pop(popupMenuContext);
                            })),
                  ]);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: children,
                  );
                },
              ),
            )
          ];

          items.addAll(PopupMenuActions.choices.map((choice) {
            switch (choice) {
              case PopupMenuActions.NEW_TAB:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.add,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.NEW_INCOGNITO_TAB:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          MaterialCommunityIcons.incognito,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.TRIM_READER:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.book_online_rounded,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.FAVORITES:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.star,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.WEB_ARCHIVES:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.offline_pin,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.DESKTOP_MODE:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Selector<WebViewModel, bool>(
                          selector: (context, webViewModel) =>
                              webViewModel.isDesktopMode,
                          builder: (context, value, child) {
                            return Icon(
                              value
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: Colors.black,
                            );
                          },
                        )
                      ]),
                );
              case PopupMenuActions.HISTORY:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.history,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.SHARE:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Ionicons.share,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.SETTINGS:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.settings,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.DEVELOPERS:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.developer_mode,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.FIND_ON_PAGE:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.search,
                          color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.INAPPWEBVIEW_PROJECT:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Container(
                          padding: const EdgeInsets.only(right: 6),
                          child: const AnimatedFlutterBrowserLogo(
                            size: 12.5,
                          ),
                        )
                      ]),
                );
              case PopupMenuActions.EXIT_APP:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.exit_to_app,
                          color: Colors.black,
                        )
                      ]),
                );

              case PopupMenuActions.REVIEW:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.reviews,
                          color: Colors.black,
                        )
                      ]),
                );

              case PopupMenuActions.DONATE:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.paypal_outlined,
                          color: Colors.black,
                        )
                      ]),
                );

              case PopupMenuActions.COPY_CURRENT_URL:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
                          Icons.copy,
                          color: Colors.black,
                        )
                      ]),
                );
              default:
                return CustomPopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
            }
          }).toList());

          return items;
        },
      )
    ];
  }

  void _popupMenuChoiceAction(String choice) async {
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: false);

    switch (choice) {
      case PopupMenuActions.NEW_TAB:
        addNewTab();
        break;
      case PopupMenuActions.NEW_INCOGNITO_TAB:
        addNewIncognitoTab();
        break;
      case PopupMenuActions.FAVORITES:
        showFavorites();
        break;
      case PopupMenuActions.HISTORY:
        showHistory();
        break;
      case PopupMenuActions.TRIM_READER:
        showTrimReader();
        break;
      case PopupMenuActions.WEB_ARCHIVES:
        showWebArchives();
        break;
      case PopupMenuActions.FIND_ON_PAGE:
        var isFindInteractionEnabled =
            currentWebViewModel.settings?.isFindInteractionEnabled ?? false;
        var findInteractionController =
            currentWebViewModel.findInteractionController;
        if (Util.isIOS() &&
            isFindInteractionEnabled &&
            findInteractionController != null) {
          await findInteractionController.presentFindNavigator();
        } else if (widget.showFindOnPage != null) {
          widget.showFindOnPage!();
        }
        break;
      case PopupMenuActions.SHARE:
        share();
        break;
      case PopupMenuActions.DESKTOP_MODE:
        toggleDesktopMode();
        break;
      case PopupMenuActions.DEVELOPERS:
        Future.delayed(const Duration(milliseconds: 300), () {
          goToDevelopersPage();
        });
        break;
      case PopupMenuActions.SETTINGS:
        Future.delayed(const Duration(milliseconds: 300), () {
          goToSettingsPage();
        });
        break;
      case PopupMenuActions.INAPPWEBVIEW_PROJECT:
        Future.delayed(const Duration(milliseconds: 300), () {
          openProjectPopup();
        });
        break;
      case PopupMenuActions.EXIT_APP:
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Util.isIOS()) {
            exit(0);
          } else {
            SystemNavigator.pop();
          }
        });
        break;
      case PopupMenuActions.REVIEW:
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Util.isIOS()) {
            addNewTab(url: WebUri('https://adee.co/contact-us'));
          } else {
            addNewTab(url: WebUri('https://adee.co/contact-us'));
          }
        });
        break;

      case PopupMenuActions.DONATE:
        Future.delayed(const Duration(milliseconds: 300), () {
          addNewTab(url: WebUri('https://www.paypal.com/paypalme/adeeteam'));
        });
        break;
      case PopupMenuActions.COPY_CURRENT_URL:
        Future.delayed(const Duration(milliseconds: 300), () {
          copyUrl();
        });
        break;
    }
  }

  void addNewTab({WebUri? url}) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    var settings = browserModel.getSettings();
    var tabSettings = browserModel.getCurrentTab()?.webViewModel.settings;
    if (kDebugMode) {
      print(
          "########## setting2${browserModel.getDefaultTabSettings()!.minimumFontSize}");
    }

    url ??= settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
        ? WebUri(settings.customUrlHomePage)
        : WebUri(settings.searchEngine.url);

    browserModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel: WebViewModel(
          url: url, settings: browserModel.getDefaultTabSettings()),
    ));
  }

  void addNewIncognitoTab({WebUri? url}) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    url ??= settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
        ? WebUri(settings.customUrlHomePage)
        : WebUri(settings.searchEngine.url);

    browserModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel: WebViewModel(
          url: url,
          isIncognitoMode: true,
          settings: browserModel.getDefaultTabSettings()),
    ));
  }

  void showFavorites_old() {
    showDialog(
        context: context,
        builder: (context) {
          var browserModel = Provider.of<BrowserModel>(context, listen: true);

          return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    children: browserModel.favorites.map((favorite) {
                      var url = favorite.url;
                      var faviconUrl = favorite.favicon != null
                          ? favorite.favicon!.url
                          : WebUri("${url?.origin ?? ""}/favicon.ico");

                      return ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // CachedNetworkImage(
                            //   placeholder: (context, url) =>
                            //       CircularProgressIndicator(),
                            //   imageUrl: faviconUrl,
                            //   height: 30,
                            // )
                            CustomImage(
                              url: faviconUrl,
                              maxWidth: 30.0,
                              height: 30.0,
                            )
                          ],
                        ),
                        title: Text(
                            favorite.title ?? favorite.url?.toString() ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(favorite.url?.toString() ?? "",
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        onTap: () {
                          setState(() {
                            addNewTab(url: favorite.url);
                            Navigator.pop(context);
                          });
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.close, size: 20.0),
                              onPressed: () {
                                setState(() {
                                  browserModel.removeFavorite(favorite);
                                  if (browserModel.favorites.isEmpty) {
                                    Navigator.pop(context);
                                  }
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  )));
        });
  }

  void showFavorites_v1() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    double screenWidth = MediaQuery.of(context).size.width;
    double drawerWidth = screenWidth * 0.75;

    var drawerContent = Container(
      width: drawerWidth,
      child: Drawer(
        child: Column(
          children: [
            AppBar(
              // leading: IconButton(
              //   icon: const Icon(Icons.arrow_back),
              //   onPressed: () => Navigator.of(context).pop(),
              // ),
              title: const Text('Favorites'),
            ),
            Expanded(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return ListView(
                    children: browserModel.favorites.map((favorite) {
                      var url = favorite.url;
                      Uri? faviconUrl;
                      if (favorite.favicon != null) {
                        faviconUrl = favorite.favicon!.url;
                      } else if (url != null && url.origin.isNotEmpty) {
                        faviconUrl = Uri.parse("${url.origin}/favicon.ico");
                      } else {
                        faviconUrl = null;
                      }

                      return ListTile(
                        leading: CustomImage(
                          url: faviconUrl,
                          maxWidth: 30.0,
                          height: 30.0,
                        ),
                        title: Text(
                            favorite.title ?? favorite.url?.toString() ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(favorite.url?.toString() ?? "",
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          addNewTab(url: favorite.url);
                          Navigator.of(context).pop();
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20.0),
                          onPressed: () {
                            setState(() {
                              browserModel.removeFavorite(favorite);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    Scaffold.of(context).showBottomSheet((context) => drawerContent);
  }

  void showFavorites() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    double screenWidth = MediaQuery.of(context).size.width;
    double drawerWidth = screenWidth * 0.75;

    var drawerContent = Container(
      width: drawerWidth,
      child: Column(
        children: [
          AppBar(
            title: const Text('Favorites'),
          ),
          Expanded(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return ListView(
                  children: browserModel.favorites.map((favorite) {
                    var url = favorite.url;
                    Uri? faviconUrl;
                    if (favorite.favicon != null) {
                      faviconUrl = favorite.favicon!.url;
                    } else if (url != null && url.origin.isNotEmpty) {
                      faviconUrl = Uri.parse("${url.origin}/favicon.ico");
                    } else {
                      faviconUrl = null;
                    }

                    return ListTile(
                      leading: CustomImage(
                        url: faviconUrl,
                        maxWidth: 30.0,
                        height: 30.0,
                      ),
                      title: Text(
                          favorite.title ?? favorite.url?.toString() ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(favorite.url?.toString() ?? "",
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        addNewTab(url: favorite.url);
                        Navigator.of(context).pop();
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 20.0),
                        onPressed: () {
                          setState(() {
                            browserModel.removeFavorite(favorite);
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return drawerContent;
      },
      isScrollControlled:
          false, // Set to true if you want the sheet to take the full screen height
    );
  }

  // Function to limit text to 1000 words
  String limitTo1000Words(String text) {
    var words = text.split(' ');
    if (words.length > 1000) {
      return words.take(1000).join(' ');
    }
    return text;
  }

// Function to get summary from OpenAI
  Future<String> getSummary(String text) async {
    var apiKey = 'sk-api'; // Replace with your API key
    var url = Uri.parse(
        'https://api.openai.com/v1/engines/gpt-3.5-turbo/completions');
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'prompt': 'Summarize the following text:\n\n$text',
        'max_tokens': 100, // Adjust based on your needs
      }),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['choices'][0]['text'].trim();
    } else {
      throw Exception('Failed to get summary');
    }
  }

  void _speak(String text, FlutterTts flutterTts) async {
    bool isSpeaking = false;

    // Set up a completion handler
    flutterTts.setCompletionHandler(() {
      isSpeaking = false;
    });

    int start = 0;
    while (start < text.length) {
      // Wait if still speaking the previous chunk
      while (isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 1));
      }

      int end = findNextChunkEnd(text, start, 20);
      String chunk = text.substring(start, end);
      start = end + 1; // Update start for next chunk

      // Start speaking the next chunk
      isSpeaking = true;
      await flutterTts.speak(chunk);
    }
  }

  int findNextChunkEnd(String text, int start, int maxWords) {
    int end = start;
    int words = 0;

    while (end < text.length && words < maxWords) {
      if (text[end] == ' ') {
        words++;
      }

      if (".;?!,:\n".contains(text[end]) || words >= maxWords) {
        break;
      }

      end++;
    }

    // Handle case where end of text is reached without punctuation or word limit
    if (end >= text.length) {
      return text.length;
    }

    // Find the next space after punctuation or word limit
    int spaceIndex = text.indexOf(' ', end);
    return (spaceIndex != -1) ? spaceIndex : end;
  }

  void _stopSpeak(var flutterTts) async {
    await flutterTts.stop();
  }

  void showTrimReader() async {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var url = webViewModel?.url;
    var fontSize = webViewModel?.settings?.minimumFontSize ?? 16;
    var fontFamily = webViewModel?.settings?.standardFontFamily ??
        'sans-serif'; // Corrected line
    if (fontSize <= 8) {
      fontSize = 16;
    }

    FlutterTts? flutterTts = FlutterTts();

    if (url != null) {
      try {
        // Fetch the webpage content
        final response = await http.get(Uri.parse(url.toString()));
        if (response.statusCode == 200) {
          // Parse the HTML content and extract elements
          var document = parser.parse(response.body);
          List<dom.Element> elements = document.querySelectorAll(
              'title, h1, h2, h3, h4, h5, h6, h7, p, texarea');

          var text = elements.map((e) => e.text).join("\n");

          //summary
          //  var limitedText = limitTo1000Words(text);
          //var summary = await getSummary("hello ");
          // var summary = limitedText;
          if (kDebugMode) {
            //  print("### SUMMARY ###\n$summary\n");
            print("### TEXT ###\n$text");
          }
//
          //  text = "SUMMARY \n$summary\nORIGINAL TEXT$text";

          // Convert the elements to a list of widgets
          List<Widget> elementWidgets = elements.map((element) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 2.0), // 2px padding on left and right
              child: Text(
                element.text,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: fontSize * 1.05,
                  letterSpacing: 1.05,
                  fontFamily: fontFamily,
                ),
              ),
            );
          }).toList();

          // Show a custom dialog simulating a drawer from the right
          // ignore: use_build_context_synchronously
          showGeneralDialog(
            context: context,
            pageBuilder: (context, animation, secondaryAnimation) {
              return SafeArea(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Material(
                      child: Column(
                        children: [
                          AppBar(
                            title: const Text('Reading mode'),
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.volume_up),
                                onPressed: () async {
                                  _speak(text,
                                      flutterTts!); // Ensure this method is correctly implemented
                                },
                              ),
                            ],
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(children: elementWidgets),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            barrierDismissible: true,
            barrierLabel: "Dismiss",
            transitionDuration: const Duration(milliseconds: 300),
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          ).then((value) async {
            // This code runs after the dialog is dismissed
            _speak('', flutterTts!);
            _stopSpeak(flutterTts);
            flutterTts = null; // Stop speaking when the dialog is closed
          });
        } else {
          // Handle HTTP request error
        }
      } catch (e) {
        // Handle errors
      }
    } else {
      // Handle case where URL is null
    }
  }

  void showTrimReader_bottom() async {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var url = webViewModel?.url;
    var fontSize = webViewModel?.settings?.minimumFontSize ?? 16;

    if (url != null) {
      try {
        // Fetch the webpage content
        final response = await http.get(Uri.parse(url.toString()));
        if (response.statusCode == 200) {
          // Parse the HTML content and extract headings
          var document = parser.parse(response.body);
          List<dom.Element> headings =
              document.querySelectorAll('h1, h2, h3, h4, h5, h6, p');

          // Convert the headings to a list of widgets
          List<Widget> headingWidgets = headings.map((heading) {
            return Text(heading.text,
                style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: fontSize * 1.05,
                    letterSpacing: 1.05));
          }).toList();

          // Show the modal bottom sheet with the extracted headings
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Container(
                child: Column(
                  children: [
                    AppBar(title: const Text('Reading mode')),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(children: headingWidgets),
                      ),
                    ),
                  ],
                ),
              );
            },
            isScrollControlled: false,
          );
        } else {
          // Handle HTTP request error
        }
      } catch (e) {
        // Handle general errors
      }
    } else {
      // Handle case where URL is null
    }
  }

  void showHistory_old() {
    showDialog(
        context: context,
        builder: (context) {
          var webViewModel = Provider.of<WebViewModel>(context, listen: true);

          return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              content: FutureBuilder(
                future:
                    webViewModel.webViewController?.getCopyBackForwardList(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }

                  WebHistory history = snapshot.data as WebHistory;
                  return SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        children: history.list?.reversed.map((historyItem) {
                              var url = historyItem.url;

                              return ListTile(
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    // CachedNetworkImage(
                                    //   placeholder: (context, url) =>
                                    //       CircularProgressIndicator(),
                                    //   imageUrl: (url?.origin ?? "") + "/favicon.ico",
                                    //   height: 30,
                                    // )
                                    CustomImage(
                                        url: WebUri(
                                            "${url?.origin ?? ""}/favicon.ico"),
                                        maxWidth: 30.0,
                                        height: 30.0)
                                  ],
                                ),
                                title: Text(historyItem.title ?? url.toString(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(url?.toString() ?? "",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                isThreeLine: true,
                                onTap: () {
                                  webViewModel.webViewController
                                      ?.goTo(historyItem: historyItem);
                                  Navigator.pop(context);
                                },
                              );
                            }).toList() ??
                            <Widget>[],
                      ));
                },
              ));
        });
  }

  void showHistory() {
    var webViewModel = Provider.of<WebViewModel>(context, listen: false);

    double screenWidth = MediaQuery.of(context).size.width;
    double drawerWidth = screenWidth * 0.75;

    var drawerContent = Container(
      width: drawerWidth,
      child: Drawer(
        child: Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('History'),
            ),
            Expanded(
              child: FutureBuilder(
                future:
                    webViewModel.webViewController?.getCopyBackForwardList(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  WebHistory history = snapshot.data as WebHistory;
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return ListView(
                        children: history.list?.reversed.map((historyItem) {
                              var url = historyItem.url;
                              Uri? faviconUrl =
                                  (url != null && url.origin.isNotEmpty)
                                      ? Uri.parse("${url.origin}/favicon.ico")
                                      : null;

                              return ListTile(
                                leading: CustomImage(
                                  url: faviconUrl,
                                  maxWidth: 30.0,
                                  height: 30.0,
                                ),
                                title: Text(
                                  historyItem.title ?? url.toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  url?.toString() ?? "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  webViewModel.webViewController
                                      ?.goTo(historyItem: historyItem);
                                  Navigator.of(context).pop();
                                },
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, size: 20.0),
                                  onPressed: () {
                                    setState(() {
                                      // Assuming you have a method `moveHistoryItem` in the `WebViewModel`
                                      history.list!.remove(historyItem);
                                    });
                                  },
                                ),
                              );
                            }).toList() ??
                            <Widget>[],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return drawerContent;
      },
      isScrollControlled:
          false, // Set to true if you want the sheet to take the full screen height
    );
  }

  void showWebArchives() async {
    showDialog(
        context: context,
        builder: (context) {
          var browserModel = Provider.of<BrowserModel>(context, listen: true);
          var webArchives = browserModel.webArchives;

          var listViewChildren = <Widget>[];
          webArchives.forEach((key, webArchive) {
            var path = webArchive.path;
            // String fileName = path.substring(path.lastIndexOf('/') + 1);

            var url = webArchive.url;

            listViewChildren.add(ListTile(
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // CachedNetworkImage(
                  //   placeholder: (context, url) => CircularProgressIndicator(),
                  //   imageUrl: (url?.origin ?? "") + "/favicon.ico",
                  //   height: 30,
                  // )
                  CustomImage(
                      url: WebUri("${url?.origin ?? ""}/favicon.ico"),
                      maxWidth: 30.0,
                      height: 30.0)
                ],
              ),
              title: Text(webArchive.title ?? url?.toString() ?? "",
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(url?.toString() ?? "",
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  setState(() {
                    browserModel.removeWebArchive(webArchive);
                    browserModel.save();
                  });
                },
              ),
              isThreeLine: true,
              onTap: () {
                if (path != null) {
                  var browserModel =
                      Provider.of<BrowserModel>(context, listen: false);
                  browserModel.addTab(WebViewTab(
                    key: GlobalKey(),
                    webViewModel: WebViewModel(url: WebUri("file://$path")),
                  ));
                }
                Navigator.pop(context);
              },
            ));
          });

          return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              content: Builder(
                builder: (context) {
                  return SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        children: listViewChildren,
                      ));
                },
              ));
        });
  }

  void share() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var url = webViewModel?.url;
    if (url != null) {
      Share.share(url.toString(), subject: webViewModel?.title);
    }
  }

  void copyUrl() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var url = webViewModel?.url;

    if (url != null) {
      Clipboard.setData(ClipboardData(text: url.toString()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL copied to clipboard'),
        ),
      );
    }
  }

  void toggleDesktopMode() async {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var webViewController = webViewModel?.webViewController;

    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: false);

    if (webViewController != null) {
      webViewModel?.isDesktopMode = !webViewModel.isDesktopMode;
      currentWebViewModel.isDesktopMode = webViewModel?.isDesktopMode ?? false;

      var currentSettings = await webViewController.getSettings();
      if (currentSettings != null) {
        currentSettings.preferredContentMode =
            webViewModel?.isDesktopMode ?? false
                ? UserPreferredContentMode.DESKTOP
                : UserPreferredContentMode.RECOMMENDED;
        await webViewController.setSettings(settings: currentSettings);
      }
      await webViewController.reload();
    }
  }

  void showUrlInfo() {
    var webViewModel = Provider.of<WebViewModel>(context, listen: false);
    var url = webViewModel.url;
    if (url == null || url.toString().isEmpty) {
      return;
    }

    route = CustomPopupDialog.show(
      context: context,
      transitionDuration: customPopupDialogTransitionDuration,
      builder: (context) {
        return UrlInfoPopup(
          route: route!,
          transitionDuration: customPopupDialogTransitionDuration,
          onWebViewTabSettingsClicked: () {
            goToSettingsPage();
          },
        );
      },
    );
  }

  void goToDevelopersPage() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const DevelopersPage()));
  }

  void goToSettingsPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const SettingsPage()));
  }

  void openProjectPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const ProjectInfoPopup();
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void takeScreenshotAndShow() async {
    var webViewModel = Provider.of<WebViewModel>(context, listen: false);
    var screenshot = await webViewModel.webViewController?.takeScreenshot();

    if (screenshot != null) {
      var dir = await getApplicationDocumentsDirectory();
      File file = File(
          "${dir.path}/screenshot_${DateTime.now().microsecondsSinceEpoch}.png");
      await file.writeAsBytes(screenshot);

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Image.memory(screenshot),
            actions: <Widget>[
              ElevatedButton(
                child: const Text("Share"),
                onPressed: () async {
                  await ShareExtend.share(file.path, "image");
                },
              )
            ],
          );
        },
      );

      file.delete();
    }
  }
}
