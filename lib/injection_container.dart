import 'vpn_engine/data/datasources/singbox_process_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/network/network_info.dart';
import 'core/constants/app_constants.dart';
import 'vpn_engine/data/datasources/singbox_api_datasource.dart';
import 'vpn_engine/data/datasources/singbox_process_manager.dart';
import 'vpn_engine/data/repositories/vpn_engine_repository_impl.dart';
import 'vpn_engine/domain/repositories/vpn_engine_repository.dart';
import 'vpn_engine/domain/usecases/connect_vpn.dart';
import 'features/servers/data/datasources/server_local_datasource.dart';
import 'features/servers/data/repositories/server_repository_impl.dart';
import 'features/servers/domain/repositories/server_repository.dart';
import 'features/servers/domain/usecases/get_best_server.dart';
import 'features/servers/domain/usecases/test_server.dart';
import 'features/servers/domain/usecases/search_servers.dart';
import 'features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'features/subscriptions/domain/repositories/subscription_repository.dart';
import 'features/subscriptions/domain/usecases/add_subscription.dart';
import 'features/subscriptions/domain/usecases/update_subscription.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._();
  factory ServiceLocator() => _instance;
  ServiceLocator._();
  final Map<Type, dynamic> _services = {};

  Future<void> init() async {
    final dio = Dio(BaseOptions(connectTimeout: AppConstants.defaultTimeout, receiveTimeout: AppConstants.defaultTimeout));
    register<Dio>(dio);
    const secureStorage = FlutterSecureStorage();
    register<FlutterSecureStorage>(secureStorage);
    final connectivity = Connectivity();
    register<Connectivity>(connectivity);
    register<NetworkInfo>(NetworkInfoImpl(connectivity: connectivity));
    
    register<SingBoxApiDataSource>(SingBoxApiDataSource(dio: dio));
    final processManager = SingBoxProcessManager();
    register<SingBoxProcessManager>(processManager);
    final vpnEngineRepo = VpnEngineRepositoryImpl(apiDataSource: get<SingBoxApiDataSource>(), processManager: get<SingBoxProcessManager>(), secureStorage: secureStorage);
    register<VpnEngineRepository>(vpnEngineRepo);
    register<ConnectVpn>(ConnectVpn(vpnEngineRepo));
    final serverLocalDs = ServerLocalDataSource();
    await serverLocalDs.init();
    register<ServerLocalDataSource>(serverLocalDs);
    final serverRepo = ServerRepositoryImpl(localDataSource: serverLocalDs);
    register<ServerRepository>(serverRepo);
    register<GetBestServer>(GetBestServer(serverRepo));
    register<TestServer>(TestServer(serverRepo));
    register<SearchServers>(SearchServers(serverRepo));
    final subLocalDs = SubscriptionLocalDataSource();
    await subLocalDs.init();
    register<SubscriptionLocalDataSource>(subLocalDs);
    final subRepo = SubscriptionRepositoryImpl(localDataSource: subLocalDs, dio: dio, serverRepository: serverRepo);
    register<SubscriptionRepository>(subRepo);
    register<AddSubscription>(AddSubscription(subRepo));
    register<UpdateSubscription>(UpdateSubscription(subRepo));
  }

  void register<T>(T service) => _services[T] = service;
  T get<T>() { final s = _services[T]; if (s == null) throw Exception('Not registered: $T'); return s as T; }
  void dispose() => get<VpnEngineRepository>().dispose();
}
final sl = ServiceLocator();