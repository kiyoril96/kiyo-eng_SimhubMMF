MMF = {}

---@alias MMF.Action
---| `MMF.Action.Unset`
---| `MMF.Action.PreviousScreen`
---| `MMF.Action.NextScreen`
---| `MMF.Action.FirstScreen`
---| `MMF.Action.ActionA`
---| `MMF.Action.ActionB`
---| `MMF.Action.ActionC`
---| `MMF.Action.ActionD`
MMF.Action = {
    Unset = 0, ---@type MMF.Action
    PreviousScreen = 6, ---@type MMF.Action
    NextScreen = 7, ---@type MMF.Action
    FirstScreen = 8, ---@type MMF.Action
    ActionA = 1, ---@type MMF.Action
    ActionB = 2, ---@type MMF.Action
    ActionC = 4, ---@type MMF.Action
    ActionD = 5, ---@type MMF.Action
}

---@alias MMF.TouchMode
---| `MMF.TouchMode.Unchanged`
---| `MMF.TouchMode.ForceLeftRight`
---| `MMF.TouchMode.ForceAdvanced`
MMF.TouchMode = {
    Unchanged = 0, ---@type MMF.TouchMode
    ForceLeftRight = 1, ---@type MMF.TouchMode
    ForceAdvanced = 2 ---@type MMF.TouchMode
}

ffi.cdef [[
    typedef struct {
        bool RequestActive;
        unsigned char padding[3];
        uint32_t RequestId;
        uint32_t Action;
        unsigned char ActionCommandExpansion[32];
    } ActionCommand;
    #pragma pack(1)
    typedef struct {
        unsigned char DeviceID[64];
        uint32_t MMFIdentifier1;
        uint32_t MMFIdentifier2;
        unsigned char DeviceInfo[256];
        uint8_t Expansion[256];
        bool Available;
        unsigned char Expansion2[256];
    } DeviceEntry;
    typedef struct {
        bool CursorPressed;
        uint32_t CursorCoordinatesX;
        uint32_t CursorCoordinatesY;
    } MMFTouchPoint;
    typedef struct {
        uint8_t Buffer[ 1920 * 1080 * 4 ];
        uint32_t UpdateCount;
        unsigned char RenderBufferExpansion[128];
    } RenderBuffer;
    typedef struct {
        uint8_t Buffer[ 2048 * 3 ];
        uint32_t UpdateCount;
        unsigned char RenderBufferExpansion[128];
    } LedsRenderBuffer;
    typedef struct {
        DeviceEntry Device[10];
    } MMFDeviceIndex;
    typedef struct {
        uint32_t StructVersion;
        uint32_t RequestedRenderWidthPixels;
        uint32_t RequestedRenderHeightPixels;
        bool RequestDoubleBuffer;
        unsigned char StartupDashboard[128];
        uint32_t RequestedTouchMode;
        bool EnableTouchTraces;
        uint32_t ReadTimeout;
        unsigned char Requester[128];
        uint32_t ReadCount;
        bool RequestActive;
        unsigned char RequestHeaderExpansion[229];
        MMFTouchPoint Cursor1;
        MMFTouchPoint Cursor2;
        MMFTouchPoint Cursor3;
        MMFTouchPoint Cursor4;
        ActionCommand DisplayActionCommand1;
        ActionCommand DisplayActionCommand2;
        ActionCommand DisplayActionCommand3;
        ActionCommand DisplayActionCommand4;
        bool SimHubConnected;
        unsigned char ExternalLedsHardwareID[512];
        uint32_t GlobalWriteCount;
        uint32_t DisplayBufferCurrentlyWritten;
        uint32_t DisplayLastFilledBuffer;
        uint32_t DisplayWriteCount;
        uint32_t DisplayRenderedDataSize;
        uint32_t DisplayRenderedWidthPixels;
        uint32_t DisplayRenderedHeightPixels;
        uint32_t DisplayBytesPerRow;
        uint32_t DisplayBrightness;
        unsigned char DisplayRenderingHeaderExpansion[128];
        RenderBuffer DisplayRenderBuffer1;
        RenderBuffer DisplayRenderBuffer2;
        uint32_t LedsBufferCurrentlyWritten;
        uint32_t LedsLastFilledBuffer;
        uint32_t LedsWriteCount;
        uint32_t WrittenLedsCount;
        unsigned char LedsRenderingHeaderExpansion[128];
        LedsRenderBuffer LedsRenderBuffer1;
        LedsRenderBuffer LedsRenderBuffer2;
    } MMFHeaderV3;
    #pragma pack(pop)
]]

MMF.DeviceIndex = const(
'MMFDeviceIndex deviceIndex;'
)

MMF.Header = const(
'MMFHeaderV3 device;'
)