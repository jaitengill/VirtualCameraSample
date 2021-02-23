import Foundation
import CoreMediaIO
import DeepAR

@_cdecl("VirtualCameraSampleMain")
func VirtualCameraSampleMain(allocator: CFAllocator, requestedTypeUUID: CFUUID) -> CMIOHardwarePlugInRef {
    return pluginRef
}
