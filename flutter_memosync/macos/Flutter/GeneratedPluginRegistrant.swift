//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import device_info_plus_macos
import objectbox_flutter_libs
import package_info_plus_macos
import path_provider_macos
import quick_notify
import screen_retriever
import system_tray
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  ObjectboxFlutterLibsPlugin.register(with: registry.registrar(forPlugin: "ObjectboxFlutterLibsPlugin"))
  FLTPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FLTPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  QuickNotifyPlugin.register(with: registry.registrar(forPlugin: "QuickNotifyPlugin"))
  ScreenRetrieverPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverPlugin"))
  SystemTrayPlugin.register(with: registry.registrar(forPlugin: "SystemTrayPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
