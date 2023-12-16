import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/search_engine_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_adeeinappwebview/flutter_adeeinappwebview.dart';
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

    return Scaffold(
      body: GridView.count(
        crossAxisCount: 2,
        children: <Widget>[
          _buildSliderOption('Bigger Text', Icons.text_fields, textSize,
              (value) async {
            currentWebViewModel.settings?.minimumFontSize = value.round();
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.setDefaultTabSettings(currentWebViewModel);
            browserModel.save();
            setState(() {
              textSize = value;
            });
          }),
          _buildDropdownOption(settings, browserModel),
          _buildSwitchOption(
              'Hide Images', Icons.image_not_supported, hideImages,
              (value) async {
            currentWebViewModel.settings?.blockNetworkImage = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.setDefaultTabSettings(currentWebViewModel);
            browserModel.save();
            setState(() {
              hideImages = value;
            });
          }),
          _buildSwitchOption('Enable Zooming', Icons.zoom_in, enableZoom,
              (value) async {
            currentWebViewModel.settings?.supportZoom = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.setDefaultTabSettings(currentWebViewModel);
            browserModel.save();
            setState(() {
              enableZoom = value;
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
