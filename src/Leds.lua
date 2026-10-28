local Leds = {}

function Leds:update(device)
    if device.mmf == nil then
        return
    end

    if not device.mmf.SimHubConnected or device.mmf.LedsLastFilledBuffer == 0 then
        LedsConnected = false
        return
    end

    if device.lastLedsWriteCount == device.mmf.LedsWriteCount then
        return
    end

    LedsConnected = true
    device.lastLedsWriteCount = device.mmf.LedsWriteCount

    -- ダブルバッファ 書き込み完了しているバッファを見る
    local selectedBuffer = device.mmf.LedsLastFilledBuffer
    local ledsCount = device.mmf.WrittenLedsCount

    if device.mmf.LedsBufferCurrentlyWritten == selectedBuffer then
        device.syncFailures = device.syncFailures + 1
        return
    end

    local buf = (selectedBuffer == 1) 
        and device.mmf.LedsRenderBuffer1.Buffer
        or device.mmf.LedsRenderBuffer2.Buffer

    device.ledColors = {}
    for i = 0,ledsCount-1 do
        device.ledColors[i+1] = rgbm.from0255(buf[i*3+0],buf[i*3+1],buf[i*3+2],1)
        device.ledMeshes:filterMeshes('?.'..string.format( "%03d", i+1 ))
            :ensureUniqueMaterials()
            :setMaterialTexture("txDiffuse", rgbm(0.2,0.2,0.2,0))
            :setMaterialProperty("ksEmissive",vec3(
                device.ledColors[i+1].r*1000
                ,device.ledColors[i+1].g*1000
                ,device.ledColors[i+1].b*1000
            ))
    end

    device.mmf.ReadCount = device.mmf.ReadCount + 1
end

return Leds