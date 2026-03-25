import 'package:flutter/foundation.dart';

abstract class ViewModel<T> extends ChangeNotifier {
  T _state;
  bool _loading = false;
  String? _errorMessage;

  ViewModel(T initialState) : _state = initialState;

  T get state => _state;
  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;

  @protected
  void emit(T newState) {
    _state = newState;
    _errorMessage = null;
    _loading = false;
    notifyListeners();
  }

  @protected
  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @protected
  void setError(String message) {
    _errorMessage = message;
    _loading = false;
    notifyListeners();
  }
}
