MMFHeader = {}

---@alias MMFHeader.Action
---| `MMFHeader.Action.Unset`
---| `MMFHeader.Action.PreviousScreen`
---| `MMFHeader.Action.NextScreen`
---| `MMFHeader.Action.FirstScreen`
---| `MMFHeader.Action.ActionA`
---| `MMFHeader.Action.ActionB`
---| `MMFHeader.Action.ActionC`
---| `MMFHeader.Action.ActionD`
MMFHeader.Action = {
    Unset = 0, ---@type MMFHeader.Action
    PreviousScreen = 6, ---@type MMFHeader.Action
    NextScreen = 7, ---@type MMFHeader.Action
    FirstScreen = 8, ---@type MMFHeader.Action
    ActionA = 1, ---@type MMFHeader.Action
    ActionB = 2, ---@type MMFHeader.Action
    ActionC = 4, ---@type MMFHeader.Action
    ActionD = 5, ---@type MMFHeader.Action
}

---@alias MMFHeader.TouchMode
---| `MMFHeader.TouchMode.Unchanged`
---| `MMFHeader.TouchMode.ForceLeftRight`
---| `MMFHeader.TouchMode.ForceAdvanced`
MMFHeader.TouchMode = {
    Unchanged = 0, ---@type MMFHeader.TouchMode
    ForceLeftRight = 1, ---@type MMFHeader.TouchMode
    ForceAdvanced = 2 ---@type MMFHeader.TouchMode
}
ffi.cdef(const('\
    #pragma pack(1)\
    typedef struct {\
        unsigned char DeviceID[64];\
        uint32_t MMFIdentifier1;\
        uint32_t MMFIdentifier2;\
        unsigned char DeviceInfo[256];\
        uint8_t Expansion[256];\
        bool Available;\
        unsigned char Expansion2[256];\
    } DeviceEntry;\
    #pragma pack(pop)\
\
    #pragma pack(1)\
    typedef struct {\
        bool CursorPressed;\
        uint32_t CursorCoordinatesX;\
        uint32_t CursorCoordinatesY;\
    } MMFTouchPoint;\
    #pragma pack(pop)\
\
    typedef struct {\
        bool RequestActive;\
        unsigned char padding[3];\
        uint32_t RequestId;\
        uint32_t Action;\
        unsigned char ActionCommandExpansion[32];\
    } ActionCommand;\
\
    #pragma pack(1)\
    typedef struct {\
        uint8_t Buffer[ 1920 * 1080 * 4 ];\
        uint32_t UpdateCount;\
        unsigned char RenderBufferExpansion[128];\
    } RenderBuffer;\
    #pragma pack(pop)\
\
    #pragma pack(1)\
    typedef struct {\
        uint8_t Buffer[ 2048 * 3 ];\
        uint32_t UpdateCount;\
        unsigned char RenderBufferExpansion[128];\
    } LedsRenderBuffer;\
    #pragma pack(pop)\
\
    #pragma pack(1)\
    typedef struct {\
        uint32_t StructVersion;\
        uint32_t RequestedRenderWidthPixels;\
        uint32_t RequestedRenderHeightPixels;\
        bool RequestDoubleBuffer;\
        unsigned char StartupDashboard[128];\
        uint32_t RequestedTouchMode;\
        bool EnableTouchTraces;\
        uint32_t ReadTimeout;\
        unsigned char Requester[128];\
        uint32_t ReadCount;\
        bool RequestActive;\
        unsigned char RequestHeaderExpansion[229];\
        MMFTouchPoint Cursor1;\
        MMFTouchPoint Cursor2;\
        MMFTouchPoint Cursor3;\
        MMFTouchPoint Cursor4;\
        ActionCommand DisplayActionCommand1;\
        ActionCommand DisplayActionCommand2;\
        ActionCommand DisplayActionCommand3;\
        ActionCommand DisplayActionCommand4;\
        bool SimHubConnected;\
        unsigned char ExternalLedsHardwareID[512];\
        uint32_t GlobalWriteCount;\
        uint32_t DisplayBufferCurrentlyWritten;\
        uint32_t DisplayLastFilledBuffer;\
        uint32_t DisplayWriteCount;\
        uint32_t DisplayRenderedDataSize;\
        uint32_t DisplayRenderedWidthPixels;\
        uint32_t DisplayRenderedHeightPixels;\
        uint32_t DisplayBytesPerRow;\
        uint32_t DisplayBrightness;\
        unsigned char DisplayRenderingHeaderExpansion[128];\
        RenderBuffer DisplayRenderBuffer1;\
        RenderBuffer DisplayRenderBuffer2;\
        uint32_t LedsBufferCurrentlyWritten;\
        uint32_t LedsLastFilledBuffer;\
        uint32_t LedsWriteCount;\
        uint32_t WrittenLedsCount;\
        unsigned char LedsRenderingHeaderExpansion[128];\
        LedsRenderBuffer LedsRenderBuffer1;\
        LedsRenderBuffer LedsRenderBuffer2;\
    } MMFHeaderV3;\
    #pragma pack(pop)\
'))

-- RenderBuffer = {
--     _explicit = ac.StructItem.explicit(0, 1),
--     Buffer = ac.StructItem.array(ac.StructItem.byte(), 1920 * 1080 * 4),
--     UpdateCount = ac.StructItem.int32(),
--     RenderBufferExpansion = ac.StructItem.array(ac.StructItem.byte(), 128)
-- }
-- 
-- LedsRenderBuffer = {
--     _explicit = ac.StructItem.explicit(0, 1),
--     Buffer = ac.StructItem.array(ac.StructItem.byte(), 2048 * 3),
--     UpdateCount = ac.StructItem.int32(),
--     RenderBufferExpansion = ac.StructItem.array(ac.StructItem.byte(), 128)
-- }


--ActionCommand = {
--    --_explicit = ac.StructItem.explicit(0, 1),
--    RequestActive = ac.StructItem.boolean(),
--    padding1 = ac.StructItem.array(ac.StructItem.byte(), 3),
--    RequestId = ac.StructItem.int32(),
--    Action = ac.StructItem.int32(),
--    ActionCommandExpansion = ac.StructItem.array(ac.StructItem.byte(), 32)
--}
--
--ActionCommandPadding = {
--    Padding = ac.StructItem.array(ac.StructItem.byte(), 48)
--}

--MMFTouchPoint = {
--    _explicit = ac.StructItem.explicit(0, 1),
--    CursorPressed = ac.StructItem.boolean(),
--    padding1 = ac.StructItem.array(ac.StructItem.byte(), 3),
--    CursorCoordinatesX = ac.StructItem.int32(),
--    CursorCoordinatesY = ac.StructItem.int32()
--}

--DeviceEntry = 
--{
--    _explicit = ac.StructItem.explicit(0, 1),
--    DeviceID = ac.StructItem.array(ac.StructItem.byte(), 64),
--    MMFIdentifier1 = ac.StructItem.int32(),
--    MMFIdentifier2 = ac.StructItem.int32(),
--    DeviceInfo = ac.StructItem.array(ac.StructItem.byte(), 256),
--    Expansion = ac.StructItem.array(ac.StructItem.byte(), 256), -- C#のCharは2バイトらしい
--    Available = ac.StructItem.boolean(),
--    Expansion2 = ac.StructItem.array(ac.StructItem.byte(), 256) -- C#のCharは2バイトらしい
--}

MMFDeviceIndex = const(
'\
DeviceEntry AvailableDevice01;\
DeviceEntry AvailableDevice02;\
DeviceEntry AvailableDevice03;\
DeviceEntry AvailableDevice04;\
DeviceEntry AvailableDevice05;\
DeviceEntry AvailableDevice06;\
DeviceEntry AvailableDevice07;\
DeviceEntry AvailableDevice08;\
DeviceEntry AvailableDevice09;\
DeviceEntry AvailableDevice10;\
'
)

MMFHeaderV3 = const(
'MMFHeaderV3 mmfHeaderV3;'
)

--ac.StructItem.combine(
--{
--    _explicit = ac.StructItem.explicit(0, 1),
--    StructVersion = ac.StructItem.int32(),
--    RequestedRenderWidthPixels = ac.StructItem.int32(),
--    RequestedRenderHeightPixels = ac.StructItem.int32(),
--    RequestDoubleBuffer = ac.StructItem.boolean(),
--    StartupDashboard = ac.StructItem.array(ac.StructItem.byte(), 128),
--    RequestedTouchMode = ac.StructItem.int32(),
--    EnableTouchTraces = ac.StructItem.boolean(),
--    ReadTimeout = ac.StructItem.int32(),
--    Requester = ac.StructItem.array(ac.StructItem.int16(), 64),
--    ReadCount = ac.StructItem.int32(),
--    RequestActive = ac.StructItem.boolean(),
--    RequestHeaderExpansion = ac.StructItem.array(ac.StructItem.byte(), 229),
--    Cursor1 = ac.StructItem.struct(MMFTouchPoint),
--    Cursor2 = ac.StructItem.struct(MMFTouchPoint),
--    Cursor3 = ac.StructItem.struct(MMFTouchPoint),
--    Cursor4 = ac.StructItem.struct(MMFTouchPoint),
--    DisplayActionCommand1 = ac.StructItem.struct(ActionCommandPadding),
--    DisplayActionCommand2 = ac.StructItem.struct(ActionCommandPadding),
--    DisplayActionCommand3 = ac.StructItem.struct(ActionCommandPadding),
--    DisplayActionCommand4 = ac.StructItem.struct(ActionCommandPadding),
--    SimHubConnected = ac.StructItem.boolean(),
--    ExternalLedsHardwareID = ac.StructItem.array(ac.StructItem.byte(), 512),
--    GlobalWriteCount = ac.StructItem.int32(),
--    DisplayBufferCurrentlyWritten = ac.StructItem.int32(),
--    DisplayLastFilledBuffer = ac.StructItem.int32(),
--    DisplayWriteCount = ac.StructItem.int32(),
--    DisplayRenderedDataSize = ac.StructItem.int32(),
--    DisplayRenderedWidthPixels = ac.StructItem.int32(),
--    DisplayRenderedHeightPixels = ac.StructItem.int32(),
--    DisplayBytesPerRow = ac.StructItem.int32(),
--    DisplayBrightness = ac.StructItem.int32(),
--    DisplayRenderingHeaderExpansion = ac.StructItem.array(ac.StructItem.byte(), 128),
--    DisplayRenderBuffer1 = ac.StructItem.struct(RenderBuffer),
--    DisplayRenderBuffer2 = ac.StructItem.struct(RenderBuffer),
--    LedsBufferCurrentlyWritten = ac.StructItem.int32(),
--    LedsLastFilledBuffer = ac.StructItem.int32(),
--    LedsWriteCount = ac.StructItem.int32(),
--    WrittenLedsCount = ac.StructItem.int32(),
--    LedsRenderingHeaderExpansion = ac.StructItem.array(ac.StructItem.byte(), 128),
--    LedsRenderBuffer1 = ac.StructItem.struct(LedsRenderBuffer),
--    LedsRenderBuffer2 = ac.StructItem.struct(LedsRenderBuffer)
--},true)