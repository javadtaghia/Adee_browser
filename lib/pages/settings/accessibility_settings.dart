import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/search_engine_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../project_info_popup.dart';

class AccessibilitySettings extends StatefulWidget {
  const AccessibilitySettings({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettings> createState() => _AccessibilitySettingsState();
}

class _AccessibilitySettingsState extends State<AccessibilitySettings> {
  final TextEditingController _customHomePageController =
      TextEditingController();
  final TextEditingController _customUserAgentController =
      TextEditingController();

  bool enableZoom = true;
  bool mediaAutoPlay = false;
  bool hideImages = false;
  bool pauseAdBlock = false;
  double textSize = 8.0; // Default text size
  String selectSearchEngine = 'Google'; // Default selection
  final List<String> searchEngine = [
    'Google',
    'Bing',
    'DuckDuckGo',
    'Ecosia',
    'Yahoo',
    // Add more browser types if needed
  ];

  @override
  void dispose() {
    _customHomePageController.dispose();
    _customUserAgentController.dispose();
    super.dispose();
  }

  Widget _buildDropdownOption(var settings, var browserModel) {
    // Convert SearchEngineModel list to a list of Strings for DropdownButton<String>
    List<String> searchEngineNames = SearchEngines.map((e) => e.name).toList();

    // Find the currently selected search engine's name
    String selectSearchEngine = settings.searchEngine.name;

    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.public),
            Text('Search Engine'),
            ListTile(
              trailing: DropdownButton<String>(
                underline: Container(), // To remove the underline
                icon: Icon(Icons.arrow_downward), // Customized arrow icon
                value: selectSearchEngine,
                onChanged: (String? newValue) {
                  setState(() {
                    if (newValue != null) {
                      // Find the SearchEngineModel corresponding to the selected name
                      settings.searchEngine = SearchEngines.firstWhere(
                          (searchEngine) => searchEngine.name == newValue,
                          orElse: () => settings.searchEngine);
                      browserModel.updateSettings(settings);
                    }
                  });
                },
                items: searchEngineNames
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchOption(String title, IconData icon, bool currentValue,
      Function(bool) onChanged) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon),
            Text(title),
            Switch(
              value: currentValue,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderOption(String title, IconData icon, double currentValue,
      Function(double) onChanged) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon),
            Text(title),
            Slider(
              value: currentValue,
              min: 6.0,
              max: 42.0,
              divisions: 40,
              label: '${currentValue.round()}',
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var webViewController = currentWebViewModel.webViewController;
    textSize = currentWebViewModel.settings?.minimumFontSize?.toDouble() ?? 8.0;
    hideImages = currentWebViewModel.settings?.blockNetworkImage ?? false;
    enableZoom = currentWebViewModel.settings?.supportZoom ?? true;
    //mediaAutoPlay =
    // currentWebViewModel.settings?.mediaPlaybackRequiresUserGesture ?? true;
    var contentBlockers = currentWebViewModel.settings?.contentBlockers;
    if (contentBlockers != null && contentBlockers.isNotEmpty) {
      pauseAdBlock = false;
    } else {
      pauseAdBlock = true;
    }

    return Scaffold(
      body: GridView.count(
        crossAxisCount: 2,
        children: <Widget>[
          _buildSliderOption('Bigger Text', Icons.text_fields, textSize,
              (value) async {
            currentWebViewModel.settings?.minimumFontSize = value.round();
            try {
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              var webSet = await webViewController?.getSettings();
              currentWebViewModel.settings = webSet;
            } catch (e) {}

            setState(() {
              textSize = value;
              browserModel.setDefaultTabSettings(currentWebViewModel);
              browserModel.save();
            });
          }),
          _buildDropdownOption(settings, browserModel),
          _buildSwitchOption(
              'Hide Images', Icons.image_not_supported, hideImages,
              (value) async {
            currentWebViewModel.settings?.blockNetworkImage = value;
            try {
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              var webSet = await webViewController?.getSettings();
              currentWebViewModel.settings = webSet;
            } catch (e) {}

            setState(() {
              browserModel.setDefaultTabSettings(currentWebViewModel);
              browserModel.save();
              hideImages = value;
              browserModel.updateSettings(settings);
            });
          }),
          _buildSwitchOption('Enable Zooming', Icons.zoom_in, enableZoom,
              (value) async {
            currentWebViewModel.settings?.supportZoom = value;
            try {
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              var webSet = await webViewController?.getSettings();
              currentWebViewModel.settings = webSet;
            } catch (e) {}

            setState(() {
              browserModel.setDefaultTabSettings(currentWebViewModel);
              browserModel.save();
              enableZoom = value;
              browserModel.updateSettings(settings);
            });
          }),
          // _buildSwitchOption(
          //     'Pause AutoPlay', Icons.pause_circle_filled, mediaAutoPlay,
          //     (value) {
          //   //     async {
          //   // currentWebViewModel.settings?.mediaPlaybackRequiresUserGesture =
          //   //     value;
          //   // webViewController?.setSettings(
          //   //     settings:
          //   //         currentWebViewModel.settings ?? InAppWebViewSettings());
          //   // currentWebViewModel.settings =
          //   //     await webViewController?.getSettings();
          //   // browserModel.setDefaultTabSettings(currentWebViewModel);
          //   // browserModel.save();
          //   setState(() {
          //     mediaAutoPlay = value;
          //   });
          // }),

          _buildSwitchOption('Pause AdBlock', Icons.pause, pauseAdBlock,
              (value) async {
            if (!pauseAdBlock) {
              currentWebViewModel.settings?.contentBlockers = [];
            } else {
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

              currentWebViewModel.settings?.contentBlockers = contentBlockers;
            }
            try {
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              var webSet = await webViewController?.getSettings();
              currentWebViewModel.settings = webSet;
            } catch (e) {}

            setState(() {
              browserModel.setDefaultTabSettings(currentWebViewModel);
              browserModel.save();
              pauseAdBlock = value;
              browserModel.updateSettings(settings);
            });
          }),
        ],
      ),
    );
  }

  List<Widget> _buildWebViewTabSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var webViewController = currentWebViewModel.webViewController;

    var widgets = <Widget>[
      const ListTile(
        title: Text("Current WebView Settings"),
        enabled: false,
      ),
      ListTile(
        title: const Text("Minimum Font Size"),
        subtitle: const Text("Sets the minimum font size."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.settings?.minimumFontSize.toString(),
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.minimumFontSize = int.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.setDefaultTabSettings(currentWebViewModel);
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Block Network Image"),
        subtitle: const Text(
            "Sets whether the WebView should not load image resources from the network (resources accessed via http and https URI schemes)."),
        value: currentWebViewModel.settings?.blockNetworkImage ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.blockNetworkImage = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.setDefaultTabSettings(currentWebViewModel);
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Standard Font Family"),
        subtitle: const Text("Sets the standard font family name."),
        trailing: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.standardFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.standardFontFamily = value;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.setDefaultTabSettings(currentWebViewModel);
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Support Zoom"),
        subtitle: const Text(
            "Sets whether the WebView should not support zooming using its on-screen zoom controls and gestures."),
        value: currentWebViewModel.settings?.supportZoom ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.supportZoom = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.setDefaultTabSettings(currentWebViewModel);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Media Playback Requires User Gesture"),
        subtitle: const Text(
            "Sets whether the WebView should prevent HTML5 audio or video from autoplaying."),
        value: currentWebViewModel.settings?.mediaPlaybackRequiresUserGesture ??
            true,
        onChanged: (value) async {
          currentWebViewModel.settings?.mediaPlaybackRequiresUserGesture =
              value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.setDefaultTabSettings(currentWebViewModel);
          browserModel.save();
          setState(() {});
        },
      )
    ];

    return widgets;
  }
}
