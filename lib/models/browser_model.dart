import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_browser/models/web_archive_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_browser/models/favorite_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'search_engine_model.dart';
import 'package:collection/collection.dart';

class BrowserSettings {
  SearchEngineModel searchEngine;
  bool homePageEnabled;
  String customUrlHomePage;
  bool debuggingEnabled;

  BrowserSettings(
      {this.searchEngine = GoogleSearchEngine,
      this.homePageEnabled = false,
      this.customUrlHomePage = "",
      this.debuggingEnabled = false});

  BrowserSettings copy() {
    return BrowserSettings(
        searchEngine: searchEngine,
        homePageEnabled: homePageEnabled,
        customUrlHomePage: customUrlHomePage,
        debuggingEnabled: debuggingEnabled);
  }

  static BrowserSettings? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? BrowserSettings(
            searchEngine: SearchEngines[map["searchEngineIndex"]],
            homePageEnabled: map["homePageEnabled"],
            customUrlHomePage: map["customUrlHomePage"],
            debuggingEnabled: map["debuggingEnabled"])
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "searchEngineIndex": SearchEngines.indexOf(searchEngine),
      "homePageEnabled": homePageEnabled,
      "customUrlHomePage": customUrlHomePage,
      "debuggingEnabled": debuggingEnabled
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

class WebViewSettings {
  int? minimumFontSize;
  String? standardFontFamily;
  bool? mediaPlaybackRequiresUserGesture;
  bool? supportZoom;
  bool? blockNetworkImage;

  WebViewSettings(
      {this.minimumFontSize = 8,
      this.supportZoom = true,
      this.standardFontFamily = "sans-serif",
      this.mediaPlaybackRequiresUserGesture = true,
      this.blockNetworkImage = false});

  WebViewSettings copy() {
    return WebViewSettings(
        minimumFontSize: minimumFontSize,
        supportZoom: supportZoom,
        standardFontFamily: standardFontFamily,
        mediaPlaybackRequiresUserGesture: mediaPlaybackRequiresUserGesture,
        blockNetworkImage: blockNetworkImage);
  }

  static WebViewSettings? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? WebViewSettings(
            minimumFontSize: map["minimumFontSize"],
            supportZoom: map["supportZoom"],
            standardFontFamily: map["standardFontFamily"],
            mediaPlaybackRequiresUserGesture:
                map["mediaPlaybackRequiresUserGesture"],
            blockNetworkImage: map["blockNetworkImage"])
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "minimumFontSize": minimumFontSize,
      "supportZoom": supportZoom,
      "standardFontFamily": standardFontFamily,
      "mediaPlaybackRequiresUserGesture": mediaPlaybackRequiresUserGesture,
      "blockNetworkImage": blockNetworkImage
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

class BrowserModel extends ChangeNotifier {
  final List<FavoriteModel> _favorites = [];
  final List<WebViewTab> _webViewTabs = [];
  final Map<String, WebArchiveModel> _webArchives = {};
  int _currentTabIndex = -1;
  BrowserSettings _settings = BrowserSettings();
  WebViewSettings _webViewSettings = WebViewSettings();
  late WebViewModel _currentWebViewModel;
  WebViewModel? _defaultTabSettings;

  bool _showTabScroller = false;

  // setAdblocker() async {
  //   final adUrlFilters = [
  //     ".*.cdn-test.mouseflow.com/.*",
  //     ".*.identify.hotjar.com/.*",
  //     ".*.static.media media.net/.*",
  //     ".*.claritybt.freshmarketer.com/.*",
  //     ".*.mediavisor.doubleclick.net/.*",
  //     ".*.events3alt.adcolony.com/.*",
  //     ".*.analytics.google.com/.*",
  //     ".*.stats.g.doubleclick.net/.*",
  //     ".*.adtago.s3.amazonaws.com/.*",
  //     ".*.w1.luckyorange.com/.*",
  //     ".*.careers.hotjar.com/.*",
  //     ".*.adbrite.com/.*",
  //     ".*.m.doubleclick.net/.*",
  //     ".*.analytics.pointdrive.linkedin.com/.*",
  //     ".*.googlesyndication.com/.*",
  //     ".*.exponential.com/.*",
  //     ".*.log.pinterest.com/.*",
  //     ".*.o2.mouseflow.com/.*",
  //     ".*.adc3-launch.adcolony.com/.*",
  //     ".*.gtm.mouseflow.com/.*",
  //     ".*.analytics.s3.amazonaws.com/.*",
  //     ".*.mouseflow.com/.*",
  //     ".*.insights.hotjar.com/.*",
  //     ".*.zedo.com/.*",
  //     ".*.static.doubleclick.net/.*",
  //     ".*.adm.hotjar.com/.*",
  //     ".*.events.hotjar.io/.*",
  //     ".*.events.reddit.com/.*",
  //     ".*.adservetx.media.net/.*",
  //     ".*.widgets.pinterest.com/.*",
  //     ".*.scorecardresearch.com/.*",
  //     ".*.cdn.mouseflow.com/.*",
  //     ".*.cdn.luckyorange.com/.*",
  //     ".*.click.googleanalytics.com/.*",
  //     ".*.settings.luckyorange.net/.*",
  //     ".*.realtime.luckyorange.com/.*",
  //     ".*.doubleclick.net/.*",
  //     ".*.api.mouseflow.com/.*",
  //     ".*.tools.mouseflow.com/.*",
  //     ".*.ssl.google-analytics.com/.*",
  //     ".*.api.luckyorange.com/.*",
  //     ".*.analyticsengine.s3.amazonaws.com/.*",
  //     ".*.adsymptotic.com/.*",
  //     ".*.adservice.google.com/.*",
  //     ".*.ads.pubmatic.com/.*",
  //     ".*.afs.googlesyndication.com/.*",
  //     ".*.pagead2.googleadservices.com/.*",
  //     ".*.ads.linkedin.com/.*",
  //     ".*.analytics.pinterest.com/.*",
  //     ".*.events.redditmedia.com/.*",
  //     ".*.script.hotjar.com/.*",
  //     ".*.cs.luckyorange.net/.*",
  //     ".*.fwtracks.freshmarketer.com/.*",
  //     ".*.ads.pinterest.com/.*",
  //     ".*.quantserve.com/.*",
  //     ".*.google-analytics.com/.*",
  //     ".*.advertising-api-eu.amazon.com/.*",
  //     ".*.surveys.hotjar.com/.*",
  //     ".*.advice-ads.s3.amazonaws.com/.*",
  //     ".*.ad.doubleclick.net/.*",
  //     ".*.stats.wp.com/.*",
  //     ".*.trk.pinterest.com/.*",
  //     ".*.freshmarketer.com/.*",
  //     ".*.upload.luckyorange.net/.*",
  //     ".*.adservice.google.*/.*",
  //     ".*.app-measurement.com/.*",
  //     ".*.pagead2.googlesyndication.com/.*",
  //     ".*.ads30.adcolony.com/.*",
  //     ".*.wd.adcolony.com/.*",
  //     ".*.events.reddit.com/.*",
  //     ".*.static.ads-twitter.com/.*",
  //     ".*.ads-api.twitter.com/.*",
  //     ".*.ads.pinterest.com/.*",
  //     ".*.log.pinterest.com/.*",
  //     ".*.analytics.pinterest.com/.*",
  //     ".*.widgets.pinterest.com/.*",
  //     ".*.media.net/.*",
  //     ".*static.media.net/.*",
  //     ".*.luckyorange.com/.*",
  //     ".*.pixel.facebook.com/.*",
  //     ".*.an.facebook.com/.*",
  //     ".*.notify.bugsnag.com/.*",
  //     ".*.sessions.bugsnag.com/.*",
  //     ".*.api.bugsnag.com/.*",
  //     ".*.app.bugsnag.com/.*",
  //     ".*.browser.sentry-cdn.com/.*"
  //   ];

  //   // Initialize content blockers list with CSS display none for common ad-related CSS classes.
  //   final List<ContentBlocker> contentBlockers =
  //       adUrlFilters.map((adUrlFilter) {
  //     return ContentBlocker(
  //       trigger: ContentBlockerTrigger(urlFilter: adUrlFilter),
  //       action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
  //     );
  //   }).toList()
  //         ..add(ContentBlocker(
  //           trigger: ContentBlockerTrigger(urlFilter: ".*"),
  //           action: ContentBlockerAction(
  //               type: ContentBlockerActionType.CSS_DISPLAY_NONE,
  //               selector: ".banner, .banners, .ads, .ad, .advert"),
  //         ));

  //   // Apply content blockers to all relevant web view settings.
  //   applyContentBlockers(WebViewModel model) {
  //     model.settings?.contentBlockers = contentBlockers;
  //     try {
  //       model.webViewController
  //           ?.setSettings(settings: model.settings ?? InAppWebViewSettings());
  //     } catch (e) {
  //       if (kDebugMode) print("Error applying adblocker settings: $e");
  //     }
  //   }

  //   // Apply to current, default, and all web view tabs.
  //   applyContentBlockers(_currentWebViewModel);
  //   if (_defaultTabSettings != null) applyContentBlockers(_defaultTabSettings!);
  //   for (var webViewTab in _webViewTabs) {
  //     applyContentBlockers(webViewTab.webViewModel);
  //   }

  //   if (kDebugMode) {
  //     print("Adblocker settings applied.");
  //   }
  // }

  setAdblocker() async {
    final adUrlFilters = [
      ".*.cdn-test.mouseflow.com/.*",
      ".*.identify.hotjar.com/.*",
      ".*.static.media media.net/.*",
      ".*.claritybt.freshmarketer.com/.*",
      ".*.mediavisor.doubleclick.net/.*",
      ".*.events3alt.adcolony.com/.*",
      ".*.analytics.google.com/.*",
      ".*.stats.g.doubleclick.net/.*",
      ".*.adtago.s3.amazonaws.com/.*",
      ".*.w1.luckyorange.com/.*",
      ".*.careers.hotjar.com/.*",
      ".*.adbrite.com/.*",
      ".*.m.doubleclick.net/.*",
      ".*.analytics.pointdrive.linkedin.com/.*",
      ".*.googlesyndication.com/.*",
      ".*.exponential.com/.*",
      ".*.log.pinterest.com/.*",
      ".*.o2.mouseflow.com/.*",
      ".*.adc3-launch.adcolony.com/.*",
      ".*.gtm.mouseflow.com/.*",
      ".*.analytics.s3.amazonaws.com/.*",
      ".*.mouseflow.com/.*",
      ".*.insights.hotjar.com/.*",
      ".*.zedo.com/.*",
      ".*.static.doubleclick.net/.*",
      ".*.adm.hotjar.com/.*",
      ".*.events.hotjar.io/.*",
      ".*.events.reddit.com/.*",
      ".*.adservetx.media.net/.*",
      ".*.widgets.pinterest.com/.*",
      ".*.scorecardresearch.com/.*",
      ".*.cdn.mouseflow.com/.*",
      ".*.cdn.luckyorange.com/.*",
      ".*.click.googleanalytics.com/.*",
      ".*.settings.luckyorange.net/.*",
      ".*.realtime.luckyorange.com/.*",
      ".*.doubleclick.net/.*",
      ".*.api.mouseflow.com/.*",
      ".*.tools.mouseflow.com/.*",
      ".*.ssl.google-analytics.com/.*",
      ".*.api.luckyorange.com/.*",
      ".*.analyticsengine.s3.amazonaws.com/.*",
      ".*.adsymptotic.com/.*",
      ".*.adservice.google.com/.*",
      ".*.ads.pubmatic.com/.*",
      ".*.afs.googlesyndication.com/.*",
      ".*.pagead2.googleadservices.com/.*",
      ".*.ads.linkedin.com/.*",
      ".*.analytics.pinterest.com/.*",
      ".*.events.redditmedia.com/.*",
      ".*.script.hotjar.com/.*",
      ".*.cs.luckyorange.net/.*",
      ".*.fwtracks.freshmarketer.com/.*",
      ".*.ads.pinterest.com/.*",
      ".*.quantserve.com/.*",
      ".*.google-analytics.com/.*",
      ".*.advertising-api-eu.amazon.com/.*",
      ".*.surveys.hotjar.com/.*",
      ".*.advice-ads.s3.amazonaws.com/.*",
      ".*.ad.doubleclick.net/.*",
      ".*.stats.wp.com/.*",
      ".*.trk.pinterest.com/.*",
      ".*.freshmarketer.com/.*",
      ".*.upload.luckyorange.net/.*",
      ".*.adservice.google.*/.*",
      ".*.app-measurement.com/.*",
      ".*.pagead2.googlesyndication.com/.*",
      ".*.ads30.adcolony.com/.*",
      ".*.wd.adcolony.com/.*",
      ".*.events.reddit.com/.*",
      ".*.static.ads-twitter.com/.*",
      ".*.ads-api.twitter.com/.*",
      ".*.ads.pinterest.com/.*",
      ".*.log.pinterest.com/.*",
      ".*.analytics.pinterest.com/.*",
      ".*.widgets.pinterest.com/.*",
      ".*.media.net/.*",
      ".*static.media.net/.*",
      ".*.luckyorange.com/.*",
      ".*.pixel.facebook.com/.*",
      ".*.an.facebook.com/.*",
      ".*.notify.bugsnag.com/.*",
      ".*.sessions.bugsnag.com/.*",
      ".*.api.bugsnag.com/.*",
      ".*.app.bugsnag.com/.*",
      ".*.browser.sentry-cdn.com/.*"
    ];
    List<ContentBlocker>? contentBlockers = [];
    for (final adUrlFilter in adUrlFilters) {
      contentBlockers.add(ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: adUrlFilter,
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          )));
    }

    // Apply the "display: none" style to some HTML elements
    contentBlockers.add(ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: ".*",
        ),
        action: ContentBlockerAction(
            type: ContentBlockerActionType.CSS_DISPLAY_NONE,
            selector: ".banner, .banners, .ads, .ad, .advert")));

    _currentWebViewModel.settings?.contentBlockers = contentBlockers;
    _defaultTabSettings?.settings?.contentBlockers = contentBlockers;
    for (var webViewTab in _webViewTabs) {
      webViewTab.webViewModel.settings?.contentBlockers = contentBlockers;
    }
    if (kDebugMode) {
      print(
          "@@@ I just did add the adblocks${_currentWebViewModel.settings!.contentBlockers}");
    }

    try {
      _currentWebViewModel.webViewController?.setSettings(
          settings: _currentWebViewModel.settings ?? InAppWebViewSettings());
    } catch (e) {}

    var webViewController = _currentWebViewModel.webViewController;

    webViewController?.setSettings(
        settings: _currentWebViewModel.settings ?? InAppWebViewSettings());
    var webSet = await webViewController?.getSettings();
    _currentWebViewModel.settings = webSet;
    if (kDebugMode) {
      print(
          "### ADBLOCKER SETTINGS: ${_currentWebViewModel.settings?.contentBlockers}");
    }
  }

  getDefaultTabSettings() {
    // _currentWebViewModel.settings?.minimumFontSize = 64; // javad
    //return _defaultTabSettings?.settings;
    return _defaultTabSettings?.settings;
  }

  castWebViewSettingsFrom(var model) {
    if (model != null) {
      _webViewSettings.minimumFontSize = model.settings?.minimumFontSize;
      _webViewSettings.supportZoom = model.settings?.supportZoom;
      _webViewSettings.standardFontFamily = model.settings?.standardFontFamily;
      _webViewSettings.mediaPlaybackRequiresUserGesture =
          model.settings?.mediaPlaybackRequiresUserGesture;
      _webViewSettings.blockNetworkImage = model.settings?.blockNetworkImage;
    }
  }

  castWebViewSettingsTo(var settings) {
    if (settings != null) {
      _currentWebViewModel.settings?.minimumFontSize = settings.minimumFontSize;
      _currentWebViewModel.settings?.supportZoom = settings.supportZoom;
      _currentWebViewModel.settings?.standardFontFamily =
          settings.standardFontFamily;
      _currentWebViewModel.settings?.mediaPlaybackRequiresUserGesture =
          settings.mediaPlaybackRequiresUserGesture;
      _currentWebViewModel.settings?.blockNetworkImage =
          settings.blockNetworkImage;
    }
    _defaultTabSettings = _currentWebViewModel;
  }

  setDefaultTabSettings(var settings) {
    castWebViewSettingsFrom(settings);
  }

  bool get showTabScroller => _showTabScroller;

  set showTabScroller(bool value) {
    if (value != _showTabScroller) {
      _showTabScroller = value;
      notifyListeners();
    }
  }

  BrowserModel() {
    _currentWebViewModel = WebViewModel();
    castWebViewSettingsTo(_webViewSettings);
    setAdblocker();
  }

  UnmodifiableListView<WebViewTab> get webViewTabs =>
      UnmodifiableListView(_webViewTabs);

  UnmodifiableListView<FavoriteModel> get favorites =>
      UnmodifiableListView(_favorites);

  UnmodifiableMapView<String, WebArchiveModel> get webArchives =>
      UnmodifiableMapView(_webArchives);

  void addTab(WebViewTab webViewTab) {
    _webViewTabs.add(webViewTab);
    _currentTabIndex = _webViewTabs.length - 1;
    webViewTab.webViewModel.tabIndex = _currentTabIndex;

    _currentWebViewModel.updateWithValue(webViewTab.webViewModel);

    notifyListeners();
  }

  void addTabs(List<WebViewTab> webViewTabs) {
    for (var webViewTab in webViewTabs) {
      webViewTab.webViewModel.needsToCompleteInitialLoad = true;
      _webViewTabs.add(webViewTab);
      webViewTab.webViewModel.tabIndex = _webViewTabs.length - 1;
    }
    _currentTabIndex = _webViewTabs.length - 1;
    if (_currentTabIndex >= 0) {
      _currentWebViewModel.updateWithValue(webViewTabs.last.webViewModel);
    }

    if (kDebugMode) {
      print(
          "######## LOADED STATUS OF THE FIRST ${_webViewTabs.first.webViewModel.needsToCompleteInitialLoad} #####");
    }

    notifyListeners();
  }

  void closeTab(int index) {
    _webViewTabs.removeAt(index);
    _currentTabIndex = _webViewTabs.length - 1;

    for (int i = index; i < _webViewTabs.length; i++) {
      _webViewTabs[i].webViewModel.tabIndex = i;
    }

    if (_currentTabIndex >= 0) {
      _currentWebViewModel
          .updateWithValue(_webViewTabs[_currentTabIndex].webViewModel);
    } else {
      _currentWebViewModel.updateWithValue(WebViewModel());
    }

    notifyListeners();
  }

  void showTab(int index) {
    if (kDebugMode) {
      print("**** NEEDS LOADING  1 *****");
      print(
          "**** NEEDS LOADING  ${_webViewTabs[index].webViewModel.needsToCompleteInitialLoad} *****");
    }
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      _currentWebViewModel
          .updateWithValue(_webViewTabs[_currentTabIndex].webViewModel);

      if (_webViewTabs[_currentTabIndex]
          .webViewModel
          .needsToCompleteInitialLoad) {
        _currentWebViewModel.webViewController?.reload();
        _currentWebViewModel.needsToCompleteInitialLoad = false;
      }
      setAdblocker();
      notifyListeners();
    }
  }

  void closeAllTabs() {
    _webViewTabs.clear();
    _currentTabIndex = -1;
    _currentWebViewModel.updateWithValue(WebViewModel());

    notifyListeners();
  }

  int getCurrentTabIndex() {
    return _currentTabIndex;
  }

  WebViewTab? getCurrentTab() {
    return _currentTabIndex >= 0 ? _webViewTabs[_currentTabIndex] : null;
  }

  bool containsFavorite(FavoriteModel favorite) {
    if (kDebugMode) {
      print("fav contains");
    }
    return _favorites.contains(favorite) ||
        _favorites
                .map((e) => e)
                .firstWhereOrNull((element) => element.url == favorite.url) !=
            null;
  }

  void addFavorite(FavoriteModel favorite) {
    _favorites.add(favorite);
    if (kDebugMode) {
      print("fav add");
    }
    notifyListeners();
  }

  void addFavorites(List<FavoriteModel> favorites) {
    _favorites.addAll(favorites);

    if (kDebugMode) {
      print("fav add all${_favorites.length}");
    }
    notifyListeners();
  }

  void clearFavorites() {
    if (kDebugMode) {
      print("fav cleardc");
    }
    _favorites.clear();
    notifyListeners();
  }

  void removeFavorite(FavoriteModel favorite) {
    if (kDebugMode) {
      print("fav removed");
    }
    if (!_favorites.remove(favorite)) {
      var favToRemove = _favorites
          .map((e) => e)
          .firstWhereOrNull((element) => element.url == favorite.url);
      _favorites.remove(favToRemove);
    }

    notifyListeners();
  }

  void addWebArchive(String url, WebArchiveModel webArchiveModel) {
    _webArchives.putIfAbsent(url, () => webArchiveModel);
    notifyListeners();
  }

  void addWebArchives(Map<String, WebArchiveModel> webArchives) {
    _webArchives.addAll(webArchives);
    notifyListeners();
  }

  void removeWebArchive(WebArchiveModel webArchive) {
    var path = webArchive.path;
    if (path != null) {
      final webArchiveFile = File(path);
      try {
        webArchiveFile.deleteSync();
      } finally {
        _webArchives.remove(webArchive.url.toString());
      }
      notifyListeners();
    }
  }

  void clearWebArchives() {
    _webArchives.forEach((key, webArchive) {
      var path = webArchive.path;
      if (path != null) {
        final webArchiveFile = File(path);
        try {
          webArchiveFile.deleteSync();
        } finally {
          _webArchives.remove(key);
        }
      }
    });

    notifyListeners();
  }

  BrowserSettings getSettings() {
    return _settings.copy();
  }

  void updateSettings(BrowserSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  WebViewSettings getWebViewSettings() {
    return _webViewSettings.copy();
  }

  void updateWebViewSettings(WebViewSettings settings) {
    _webViewSettings = settings;
    castWebViewSettingsTo(_webViewSettings);
    notifyListeners();
  }

  void setCurrentWebViewModel(WebViewModel webViewModel) {
    _currentWebViewModel = webViewModel;
  }

  DateTime _lastTrySave = DateTime.now();
  Timer? _timerSave;
  Future<void> save() async {
    _timerSave?.cancel();

    if (DateTime.now().difference(_lastTrySave) >=
        const Duration(milliseconds: 400)) {
      _lastTrySave = DateTime.now();
      await flush();
    } else {
      _lastTrySave = DateTime.now();
      _timerSave = Timer(const Duration(milliseconds: 500), () {
        save();
      });
    }
  }

  Future<void> flush() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString("browser", json.encode(toJson()));
  }

  Future<void> restore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> browserData;
    try {
      String? source = prefs.getString("browser");

      if (source != null) {
        browserData = await json.decode(source);
        if (kDebugMode) {
          if (browserData.containsKey("favorites")) {
            print(
                "********* RESTORE ********** Favorites: ${browserData["favorites"]}");
            print("Size of browserData: ${browserData.length}");
          } else {
            print("Favorites not found in browserData");
          }
        }
        clearFavorites();
        closeAllTabs();
        clearWebArchives();

        if (browserData.containsKey("favorites") &&
            browserData["favorites"] is List) {
          List favoritesData = browserData["favorites"];
          List<FavoriteModel> favoritesList = [];

          for (var favoriteMap in favoritesData) {
            FavoriteModel? favorite =
                FavoriteModel.fromMap(favoriteMap as Map<String, dynamic>?);
            if (favorite != null) {
              favoritesList.add(favorite);
            }
          }

          addFavorites(favoritesList);
        } else {
          if (kDebugMode) {
            print("No favorites data found in browserData");
          }
        }

        Map<String, dynamic> webArchivesMap =
            browserData["webArchives"]?.cast<String, dynamic>() ?? {};
        Map<String, WebArchiveModel> webArchives = webArchivesMap.map(
            (key, value) => MapEntry(
                key, WebArchiveModel.fromMap(value?.cast<String, dynamic>())!));

        BrowserSettings settings = BrowserSettings.fromMap(
                browserData["settings"]?.cast<String, dynamic>()) ??
            BrowserSettings();

        WebViewSettings webviewsettings = WebViewSettings.fromMap(
                browserData["webviewsettings"]?.cast<String, dynamic>()) ??
            WebViewSettings();

        List<Map<String, dynamic>> webViewTabList =
            browserData["webViewTabs"]?.cast<Map<String, dynamic>>() ?? [];
        List<WebViewTab> webViewTabs = webViewTabList
            .map((e) => WebViewTab(
                  key: GlobalKey(),
                  webViewModel: WebViewModel.fromMap(e)!,
                ))
            .toList();
        webViewTabs.sort((a, b) =>
            a.webViewModel.tabIndex!.compareTo(b.webViewModel.tabIndex!));

        addWebArchives(webArchives);
        updateSettings(settings);
        updateWebViewSettings(webviewsettings);
        addTabs(webViewTabs);

        int currentTabIndex =
            browserData["currentTabIndex"] ?? _currentTabIndex;
        currentTabIndex = min(currentTabIndex, _webViewTabs.length - 1);

        if (currentTabIndex >= 0) {
          showTab(currentTabIndex);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "favorites": _favorites.map((e) => e.toMap()).toList(),
      "webViewTabs": _webViewTabs.map((e) => e.webViewModel.toMap()).toList(),
      "webArchives":
          _webArchives.map((key, value) => MapEntry(key, value.toMap())),
      "currentTabIndex": _currentTabIndex,
      "settings": _settings.toMap(),
      "webviewsettings": _webViewSettings.toMap(),
      "currentWebViewModel": _currentWebViewModel.toMap(),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
