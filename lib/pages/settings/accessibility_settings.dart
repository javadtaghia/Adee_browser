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

  Widget _buildDropdownOption_old(var settings, var browserModel) {
    return Card(
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Icon(Icons.public),
      Text('Search Engine'),
      ListTile(
        trailing: DropdownButton<SearchEngineModel>(
          underline: Container(),
          onChanged: (SearchEngineModel? value) {
            setState(() {
              if (value != null) {
                settings.searchEngine = value;
                browserModel.updateSettings(settings);
              }
            });
          },
          value: settings.searchEngine,
          items: SearchEngines.map((searchEngine) {
            return DropdownMenuItem(
              value: searchEngine,
              child: Text(searchEngine.name),
            );
          }).toList(),
        ),
      ),
    ])));
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
    return Scaffold(
      body: GridView.count(
        crossAxisCount: 2,
        children: <Widget>[
          _buildSliderOption('Bigger Text', Icons.text_fields, textSize,
              (value) {
            setState(() {
              textSize = value;
            });
          }),
          _buildDropdownOption(settings, browserModel),
          _buildSwitchOption(
              'Hide Images', Icons.image_not_supported, hideImages, (value) {
            setState(() {
              hideImages = value;
            });
          }),
          _buildSwitchOption('Enable Zooming', Icons.zoom_in, enableZoom,
              (value) {
            setState(() {
              enableZoom = value;
            });
          }),
          _buildSwitchOption(
              'Pause AutoPlay', Icons.pause_circle_filled, mediaAutoPlay,
              (value) {
            setState(() {
              mediaAutoPlay = value;
            });
          }),
        ],
      ),
    );
  }

  List<Widget> _buildBaseSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    var widgets = <Widget>[
      const ListTile(
        title: Text("General Settings"),
        enabled: false,
      ),
      ListTile(
        title: const Text("Search Engine"),
        subtitle: Text(settings.searchEngine.name),
        trailing: DropdownButton<SearchEngineModel>(
          hint: const Text("Search Engine"),
          onChanged: (value) {
            setState(() {
              if (value != null) {
                settings.searchEngine = value;
              }
              browserModel.updateSettings(settings);
            });
          },
          value: settings.searchEngine,
          items: SearchEngines.map((searchEngine) {
            return DropdownMenuItem(
              value: searchEngine,
              child: Text(searchEngine.name),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Home page"),
        subtitle: Text(settings.homePageEnabled
            ? (settings.customUrlHomePage.isEmpty
                ? "ON"
                : settings.customUrlHomePage)
            : "OFF"),
        onTap: () {
          _customHomePageController.text = settings.customUrlHomePage;

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                contentPadding: const EdgeInsets.all(0.0),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    StatefulBuilder(
                      builder: (context, setState) {
                        return SwitchListTile(
                          title: Text(settings.homePageEnabled ? "ON" : "OFF"),
                          value: settings.homePageEnabled,
                          onChanged: (value) {
                            setState(() {
                              settings.homePageEnabled = value;
                              browserModel.updateSettings(settings);
                            });
                          },
                        );
                      },
                    ),
                    StatefulBuilder(builder: (context, setState) {
                      return ListTile(
                        enabled: settings.homePageEnabled,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                onSubmitted: (value) {
                                  setState(() {
                                    settings.customUrlHomePage = value;
                                    browserModel.updateSettings(settings);
                                    Navigator.pop(context);
                                  });
                                },
                                keyboardType: TextInputType.url,
                                decoration: const InputDecoration(
                                    hintText: 'Custom URL Home Page'),
                                controller: _customHomePageController,
                              ),
                            )
                          ],
                        ),
                      );
                    })
                  ],
                ),
              );
            },
          );
        },
      )
    ];

    return widgets;
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
