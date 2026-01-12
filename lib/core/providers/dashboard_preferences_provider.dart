import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/dashboard_widget_preferences.dart';

class DashboardPreferencesProvider extends ChangeNotifier {
  DashboardPreferences _preferences = DashboardPreferences.getDefault();
  bool _isLoading = false;
  bool _isEditMode = false;

  // Getters
  DashboardPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isEditMode => _isEditMode;

  List<DashboardWidget> get visibleWidgets =>
      _preferences.widgets.where((widget) => widget.isVisible).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<DashboardWidget> get allWidgets => _preferences.widgets;
  List<DashboardWidget> get hiddenWidgets =>
      _preferences.widgets.where((widget) => !widget.isVisible).toList();

  // Initialize and load preferences
  Future<void> loadPreferences() async {
    await initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString('dashboard_preferences');

      if (prefsJson != null) {
        final Map<String, dynamic> prefsMap = json.decode(prefsJson);
        _preferences = DashboardPreferences.fromMap(prefsMap);
      }
    } catch (e) {
      debugPrint('Error loading dashboard preferences: $e');
      // Use default preferences if loading fails
      _preferences = DashboardPreferences.getDefault();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = json.encode(_preferences.toMap());
      await prefs.setString('dashboard_preferences', prefsJson);
    } catch (e) {
      debugPrint('Error saving dashboard preferences: $e');
    }
  }

  // Toggle edit mode
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  // Reorder widgets
  void reorderWidgets(int oldIndex, int newIndex) {
    final widgets = List<DashboardWidget>.from(_preferences.widgets);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = widgets.removeAt(oldIndex);
    widgets.insert(newIndex, item);

    // Update order values
    for (int i = 0; i < widgets.length; i++) {
      widgets[i] = widgets[i].copyWith(order: i);
    }

    _preferences = _preferences.copyWith(widgets: widgets);
    _savePreferences();
    notifyListeners();
  }

  // Show/hide widget methods
  void showWidget(String widgetId) {
    final widgets = _preferences.widgets.map((widget) {
      if (widget.id == widgetId) {
        return widget.copyWith(isVisible: true);
      }
      return widget;
    }).toList();

    _preferences = _preferences.copyWith(widgets: widgets);
    _savePreferences();
    notifyListeners();
  }

  void hideWidget(String widgetId) {
    final widgets = _preferences.widgets.map((widget) {
      if (widget.id == widgetId) {
        return widget.copyWith(isVisible: false);
      }
      return widget;
    }).toList();

    _preferences = _preferences.copyWith(widgets: widgets);
    _savePreferences();
    notifyListeners();
  }

  // Update widget size by string
  void updateWidgetSize(String widgetId, String sizeName) {
    DashboardWidgetSize size;
    switch (sizeName.toLowerCase()) {
      case 'small':
        size = DashboardWidgetSize.small;
        break;
      case 'large':
        size = DashboardWidgetSize.large;
        break;
      default:
        size = DashboardWidgetSize.medium;
    }
    changeWidgetSize(widgetId, size);
  }

  // Toggle widget visibility
  void toggleWidgetVisibility(String widgetId) {
    final widgets = _preferences.widgets.map((widget) {
      if (widget.id == widgetId) {
        return widget.copyWith(isVisible: !widget.isVisible);
      }
      return widget;
    }).toList();

    _preferences = _preferences.copyWith(widgets: widgets);
    _savePreferences();
    notifyListeners();
  }

  // Change widget size
  void changeWidgetSize(String widgetId, DashboardWidgetSize newSize) {
    final widgets = _preferences.widgets.map((widget) {
      if (widget.id == widgetId) {
        return widget.copyWith(size: newSize);
      }
      return widget;
    }).toList();

    _preferences = _preferences.copyWith(widgets: widgets);
    _savePreferences();
    notifyListeners();
  }

  // Update greeting name
  void updateGreetingName(String name) {
    _preferences = _preferences.copyWith(greetingName: name);
    _savePreferences();
    notifyListeners();
  }

  // Toggle welcome message
  void toggleWelcomeMessage() {
    _preferences = _preferences.copyWith(
      showWelcomeMessage: !_preferences.showWelcomeMessage,
    );
    _savePreferences();
    notifyListeners();
  }

  // Reset to default
  void resetToDefault() {
    _preferences = DashboardPreferences.getDefault();
    _savePreferences();
    notifyListeners();
  }

  // Get widget by ID
  DashboardWidget? getWidgetById(String id) {
    try {
      return _preferences.widgets.firstWhere((widget) => widget.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if widget is visible
  bool isWidgetVisible(String id) {
    final widget = getWidgetById(id);
    return widget?.isVisible ?? false;
  }
}
