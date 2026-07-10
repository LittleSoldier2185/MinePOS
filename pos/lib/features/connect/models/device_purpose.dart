/// What this device is being set up to do once it connects to a host.
/// Picked on [RoleSelectionScreen], threaded through [ConnectScreen] and
/// [LoginScreen] so each can route to the right landing screen afterward.
enum DevicePurpose { staffHub, kitchenOnly, customerDisplay }
