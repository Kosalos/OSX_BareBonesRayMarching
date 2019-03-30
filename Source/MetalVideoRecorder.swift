import Foundation
import AVFoundation
import Cocoa

// https://stackoverflow.com/questions/43838089/capture-metal-mtkview-as-movie-in-realtime

class MetalVideoRecorder {
    var isRecording = false
    var frameCount:Int = 0
    var isCollectingVideoKeyFrames:Bool = false
    var videoKeyFrames:[Control] = []
    var videoKeyFramesIndex:Int = 0
    var videoKeyFramesRatio:Float = 0
    let framesPerKeyFrame:Int = 100
    var filename:String = ""
    
    private var assetWriter:AVAssetWriter! = nil
    private var assetWriterVideoInput:AVAssetWriterInput! = nil
    private var assetWriterPixelBufferInput:AVAssetWriterInputPixelBufferAdaptor! = nil
    
    func startRecording(outputURL url:URL, size:CGSize) {
        var size = size
        size.width *= 2     // why * 2? this app requies *2 size so that shader calcs all texture pixels
        size.height *= 2
        
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: AVFileType.m4v)
        } catch {
            return
        }
        
        let outputSettings: [String: Any] = [ AVVideoCodecKey : AVVideoCodecType.h264,
                                              AVVideoWidthKey : size.width,
                                              AVVideoHeightKey : size.height ]
        
        assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = false
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String : size.width,
            kCVPixelBufferHeightKey as String : size.height ]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                                                           sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        assetWriter.add(assetWriterVideoInput)

        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        isRecording = true
        frameCount = 0
        videoKeyFramesIndex = 0
        videoKeyFramesRatio = 0
    }
    
    func endRecording(_ completionHandler: @escaping () -> ()) {
        isRecording = false
        assetWriterVideoInput.markAsFinished()
        assetWriter.finishWriting(completionHandler: completionHandler)
    }
    
    func writeFrame(forTexture texture: MTLTexture) {
        if !isRecording {
            return
        }
        
        while !assetWriterVideoInput.isReadyForMoreMediaData {}
        
        guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
            print("Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
            return
        }
        
        var maybePixelBuffer: CVPixelBuffer? = nil
        let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybePixelBuffer)
        if status != kCVReturnSuccess {
            print("Could not get pixel buffer from asset writer input; dropping frame...")
            return
        }
        
        guard let pixelBuffer = maybePixelBuffer else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer)!
        
        // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        
        texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let frameTime:Double = Double(frameCount) * 0.1 // CACurrentMediaTime() - recordingStartTime
        let presentationTime = CMTimeMakeWithSeconds(frameTime, preferredTimescale: 240)
        assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        frameCount += 1
    }
    
    func deleteFile(_ filename:String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filename) {
            do {
                try fileManager.removeItem(atPath: filename)
            } catch {
                print(error)
            }
        }
    }
    
    func addKeyFrame() {
        if isRecording { return }  // busy
        
        if !isCollectingVideoKeyFrames {
            isCollectingVideoKeyFrames = true
            videoKeyFrames.removeAll()

            let t = Date.init(timeIntervalSinceNow: 0)
            filename = t.toTimeStampedFilename("Video","m4v")
            
            let str:String = String(format:"Beginning Video recording: %@\nPress '[' for each keyframe,\nPress ']' to end recording.",filename)
            alertPopup(str)
        }
        
        videoKeyFrames.append(vc.control)
    }
    
    func finishRecording() {
        if videoKeyFrames.count > 1 {
            isCollectingVideoKeyFrames = false

            let fileURL:URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(filename)
            
            deleteFile(fileURL.path)
            
            startRecording(outputURL:fileURL, size: vc.metalView.bounds.size)
            vc.control.skip = 1
        }
        else {
            alertPopup("Cannot continue.\nYou must save at least two keyframes to\ndefine a video.")
        }
    }
    
    func saveVideoFrame(_ texture:MTLTexture) -> Bool { // false = finished session, repaint instructions
        if !isRecording { return true } // true == do NOT repaint instructions
        
        writeFrame(forTexture:texture)

        let fs:String = String(format:"Building Video: %@\nStandby.\nFrame %3d of %3d",
                               filename,
                               frameCount+1,
                               (framesPerKeyFrame+1) * (videoKeyFrames.count - 1))
        let str = NSMutableAttributedString(string:fs)
        vc.instructions.attributedStringValue = str
        
        // determine parameters for next interpolated frame
        if videoKeyFramesIndex < videoKeyFrames.count - 1 {
            func interpolate(_ v1:Float, _ v2:Float) -> Float { return v1 + (v2-v1) * videoKeyFramesRatio }

            let c1 = videoKeyFrames[videoKeyFramesIndex]
            let c2 = videoKeyFrames[videoKeyFramesIndex + 1]
            
            vc.control.camera.x = interpolate(c1.camera.x, c2.camera.x)
            vc.control.camera.y = interpolate(c1.camera.y, c2.camera.y)
            vc.control.camera.z = interpolate(c1.camera.z, c2.camera.z)
            vc.control.cx = interpolate(c1.cx, c2.cx)
            vc.control.cy = interpolate(c1.cy, c2.cy)
            vc.control.cz = interpolate(c1.cz, c2.cz)
            vc.control.cw = interpolate(c1.cw, c2.cw)
            vc.control.dx = interpolate(c1.dx, c2.dx)
            vc.control.dy = interpolate(c1.dy, c2.dy)
            vc.control.dz = interpolate(c1.dz, c2.dz)
            vc.control.dw = interpolate(c1.dw, c2.dw)
            vc.control.ex = interpolate(c1.ex, c2.ex)
            vc.control.ey = interpolate(c1.ey, c2.ey)
            vc.control.ez = interpolate(c1.ez, c2.ez)
            vc.control.ew = interpolate(c1.ew, c2.ew)
            vc.control.fx = interpolate(c1.fx, c2.fx)
            vc.control.fy = interpolate(c1.fy, c2.fy)
            vc.control.fz = interpolate(c1.fz, c2.fz)
            vc.control.fw = interpolate(c1.fw, c2.fw)            
            vc.control.multiplier = interpolate(c1.multiplier, c2.multiplier)
            vc.control.foam = interpolate(c1.foam, c2.foam)
            vc.control.foam2 = interpolate(c1.foam2, c2.foam2)
            vc.control.bend = interpolate(c1.bend, c2.bend)
            vc.control.power = interpolate(c1.power, c2.power)
            vc.control.contrast = interpolate(c1.contrast, c2.contrast)
            vc.control.specular = interpolate(c1.specular, c2.specular)
            vc.control.Clamp_y = interpolate(c1.Clamp_y, c2.Clamp_y)
            vc.control.Clamp_DF = interpolate(c1.Clamp_DF, c2.Clamp_DF)
            vc.control.box_size_z = interpolate(c1.box_size_z, c2.box_size_z)
            vc.control.box_size_x = interpolate(c1.box_size_x, c2.box_size_x)
            vc.control.KleinR = interpolate(c1.KleinR, c2.KleinR)
            vc.control.KleinI = interpolate(c1.KleinI, c2.KleinI)
            vc.control.InvCx = interpolate(c1.InvCx, c2.InvCx)
            vc.control.InvCy = interpolate(c1.InvCy, c2.InvCy)
            vc.control.InvCz = interpolate(c1.InvCz, c2.InvCz)
            vc.control.DeltaAngle = interpolate(c1.DeltaAngle, c2.DeltaAngle)
            vc.control.InvRadius = interpolate(c1.InvRadius, c2.InvRadius)
            vc.control.juliaX = interpolate(c1.juliaX, c2.juliaX)
            vc.control.juliaY = interpolate(c1.juliaY, c2.juliaY)
            vc.control.juliaZ = interpolate(c1.juliaZ, c2.juliaZ)
            vc.control.InvCenter.x = interpolate(c1.InvCenter.x, c2.InvCenter.x)
            vc.control.InvCenter.y = interpolate(c1.InvCenter.y, c2.InvCenter.y)
            vc.control.InvCenter.z = interpolate(c1.InvCenter.z, c2.InvCenter.z)
            vc.control.julia.x = interpolate(c1.julia.x, c2.julia.x)
            vc.control.julia.y = interpolate(c1.julia.y, c2.julia.y)
            vc.control.julia.z = interpolate(c1.julia.z, c2.julia.z)
            vc.control.angle1 = interpolate(c1.angle1, c2.angle1)
            vc.control.angle2 = interpolate(c1.angle2, c2.angle2)
            vc.control.tCenterX = interpolate(c1.tCenterX, c2.tCenterX)
            vc.control.tCenterY = interpolate(c1.tCenterY, c2.tCenterY)
            vc.control.tScale = interpolate(c1.tScale, c2.tScale)

            videoKeyFramesRatio += 1.0 / Float(framesPerKeyFrame)
            if videoKeyFramesRatio >= 1.0 {
                videoKeyFramesRatio = 0
                videoKeyFramesIndex += 1
                
                if videoKeyFramesIndex == videoKeyFrames.count - 1 {
                    isRecording = false
                    endRecording({ () in })
                    return false
                }
            }
        }
        
        return true
    }
}

func alertPopup(_ str:String) {
    let alert = NSAlert()
    alert.messageText = str
    alert.beginSheetModal(for: vc.view.window!)
}
//
//    {( returnCode: NSApplication.ModalResponse) -> Void in
//        if returnCode.rawValue == 1001 {
//            do {
//                self.determineURL(index)
//                vc.control.version = versionNumber
//                let data:NSData = NSData(bytes:&vc.control, length:self.sz)
//                try data.write(to: self.fileURL, options: .atomic)
//            } catch {
//                print(error)
//            }
//        }
//    }
//}
