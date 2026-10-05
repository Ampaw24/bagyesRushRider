import 'package:permission_handler/permission_handler.dart';

enum CameraAccess { granted, denied, permanentlyDenied, restricted }

/// Camera permission, asking the OS only when [request] is set and the
/// rider hasn't already refused for good — so returning to the app never
/// re-prompts on its own.
Future<CameraAccess> cameraAccess({required bool request}) async {
  var status = await Permission.camera.status;
  if (request && status.isDenied) status = await Permission.camera.request();
  return cameraAccessFrom(status);
}

CameraAccess cameraAccessFrom(PermissionStatus status) {
  if (status.isGranted || status.isLimited) return CameraAccess.granted;
  if (status.isPermanentlyDenied) return CameraAccess.permanentlyDenied;
  if (status.isRestricted) return CameraAccess.restricted;
  return CameraAccess.denied;
}
