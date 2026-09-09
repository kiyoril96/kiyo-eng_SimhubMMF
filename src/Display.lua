local Display = {}

function Display:update(device) 
    if not device.mmf then
        return
    end

    if not device.mmf.SimHubConnected or device.mmf.DisplayLastFilledBuffer == 0 then
        DisplayConnected = false
        return
    end

    if device.lastDisplayWrite == device.mmf.DisplayWriteCount then
        return
    end

    DisplayConnected = true
    device.lastDisplayWrite = device.mmf.DisplayWriteCount

    
    -- ダブルバッファ 書き込み完了しているバッファを見る
    local selectedBuffer = device.mmf.DisplayLastFilledBuffer

    if device.mmf.DisplayBufferCurrentlyWritten == selectedBuffer then
        device.syncFailures = device.syncFailures + 1
        return
    end

    if device.frameTexture and device.displayCanvas then
        device.frameTexture:push( 
            ffi.string( (selectedBuffer == 1) 
                and device.mmf.DisplayRenderBuffer1.Buffer 
                or device.mmf.DisplayRenderBuffer2.Buffer 
                , device.mmf.DisplayRenderedDataSize)
            )
        device.displayCanvas:updateWithShader({
            textures = {txInput = device.frameTexture},
            shader = [[
                float4 main(PS_IN pin) {
                    float4 color = txInput.Sample(samLinear, pin.Tex);
                    return float4(color.b, color.g, color.r, color.a);
                }
            ]]
        })
        device.mmf.ReadCount = device.mmf.ReadCount + 1
        device.wasDisplayFilled = true -- レンダリングの状況確認用
    end
    ac.debug(device.id..' Display Write Count',device.mmf.DisplayWriteCount)
end

return Display