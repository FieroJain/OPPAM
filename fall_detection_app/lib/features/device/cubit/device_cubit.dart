import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/device_info.dart';
import '../../../core/utils/mock_data.dart';

class DeviceState {
  final DeviceInfo device;
  final bool isUpdating;

  const DeviceState({
    required this.device,
    this.isUpdating = false,
  });

  DeviceState copyWith({DeviceInfo? device, bool? isUpdating}) {
    return DeviceState(
      device: device ?? this.device,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

class DeviceCubit extends Cubit<DeviceState> {
  DeviceCubit() : super(DeviceState(device: MockData.device));

  /// Simulate connecting to device.
  Future<void> connectDevice() async {
    final updated = DeviceInfo(
      name: state.device.name,
      batteryPercent: state.device.batteryPercent,
      estimatedLife: state.device.estimatedLife,
      signalDbm: state.device.signalDbm,
      signalQuality: state.device.signalQuality,
      connectionState: DeviceConnectionState.searching,
    );
    emit(state.copyWith(device: updated));

    await Future.delayed(const Duration(seconds: 2));

    if (!isClosed) {
      final connected = DeviceInfo(
        name: state.device.name,
        batteryPercent: state.device.batteryPercent,
        estimatedLife: state.device.estimatedLife,
        signalDbm: state.device.signalDbm,
        signalQuality: state.device.signalQuality,
        connectionState: DeviceConnectionState.connected,
      );
      emit(state.copyWith(device: connected));
    }
  }

  /// Simulate firmware update.
  Future<void> updateFirmware() async {
    emit(state.copyWith(isUpdating: true));
    await Future.delayed(const Duration(seconds: 3));
    if (!isClosed) {
      emit(state.copyWith(isUpdating: false));
    }
  }
}
