import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class ConnectionProvider extends ChangeNotifier {
  final SocketService _socketService;
  final DiscoveryService _discoveryService;
  final StorageService _storageService;

  List<PcServer> _discoveredServers = [];
  List<PcServer> _connectionHistory = [];
  PcServer? _selectedServer;
  String? _password;
  bool _isManualIpMode = false;

  ConnectionProvider({
    required SocketService socketService,
    required DiscoveryService discoveryService,
    required StorageService storageService,
  })  : _socketService = socketService,
        _discoveryService = discoveryService,
        _storageService = storageService {
    _socketService.addListener(_onSocketStatusChanged);
    _discoveryService.addListener(_onDiscoveryChanged);
  }

  List<PcServer> get discoveredServers => _discoveredServers;
  List<PcServer> get connectionHistory => _connectionHistory;
  PcServer? get selectedServer => _selectedServer;
  String? get password => _password;
  bool get isManualIpMode => _isManualIpMode;
  ConnectionStatus get status => _socketService.status;
  bool get isConnected => _socketService.isConnected;
  String? get errorMessage => _socketService.errorMessage;

  Future<void> init() async {
    _connectionHistory = await _storageService.getConnectionHistory();
    notifyListeners();
  }

  void _onSocketStatusChanged() {
    notifyListeners();
  }

  void _onDiscoveryChanged() {
    _discoveredServers = _discoveryService.discoveredServers;
    notifyListeners();
  }

  Future<void> startDiscovery() async {
    await _discoveryService.startDiscovery();
  }

  void stopDiscovery() {
    _discoveryService.stopDiscovery();
  }

  void selectServer(PcServer server) {
    _selectedServer = server;
    _isManualIpMode = false;
    _password = null;
    notifyListeners();
  }

  void setManualIp(String ip, {int port = 19876}) {
    _selectedServer = PcServer(ip: ip, port: port);
    _isManualIpMode = true;
    _password = null;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  Future<bool> connect() async {
    if (_selectedServer == null) return false;

    final result = await _socketService.connect(
      _selectedServer!,
      password: _password,
    );

    if (result) {
      await _storageService.addToConnectionHistory(_selectedServer!);
      _connectionHistory = await _storageService.getConnectionHistory();
    }

    notifyListeners();
    return result;
  }

  void disconnect() {
    _socketService.disconnect();
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.removeListener(_onSocketStatusChanged);
    _discoveryService.removeListener(_onDiscoveryChanged);
    super.dispose();
  }
}
