import Foundation
import AVFoundation
import Cocoa

// https://stackoverflow.com/questions/43838089/capture-metal-mtkview-as-movie-in-realtime

var vr:VideoRecorderViewController! = nil

class VideoRecorderViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var isRecording = false
    var frameCount:Int = 0
    var keyFrames:[Control] = []
    var keyFramesIndex:Int = 0
    var keyFramesRatio:Float = 0
    var framesPerKeyFrame:Int = 49
    var sFactor:Float = 2
    var filename:String = ""
    var easeInOutFlag:Bool = true
    
    @IBOutlet var keyFrameList: NSScrollView!
    @IBOutlet var framesPerKeyframe: NSSegmentedControl!
    @IBOutlet var smoothingFactor: NSSegmentedControl!
    @IBOutlet var statusField: NSTextField!
    
    var tv:NSTableView! = nil
    
    func addKeyFrame() {
        vc.control.skip = 1
        keyFrames.append(vc.control)
        refresh()
    }
    
    @IBAction func addKeyframePressed(_ sender: NSButton) { addKeyFrame() }
    
    @IBAction func insertKeyframePressed(_ sender: NSButton) {
        let row = tv.selectedRow
        if row >= 0 {
            keyFrames.insert(vc.control, at:row)
            tv.reloadData()
        }
    }
    
    @IBAction func updateKeyframePressed(_ sender: NSButton) {
        let row = tv.selectedRow
        if row >= 0 {
            keyFrames[row] = vc.control
        }
    }
    
    @IBAction func deleteKeyframePressed(_ sender: NSButton) {
        var row = tv.selectedRow
        if row >= 0 {
            keyFrames.remove(at:row)
            tv.reloadData()
            
            if keyFrames.count > 0 {    // reestablish selected row highlight
                row = min(row,keyFrames.count-1) // they had just deleted the last entry in the list?
                tv.selectRowIndexes(IndexSet(integer:row), byExtendingSelection:false)
                vc.control = loadKeyframe(row)
                vc.flagViewToRecalcFractal()
            }
        }
    }
    
    @IBAction func createVideoPressed(_ sender: NSButton) {
        if keyFrames.count < 2 { return }
        
        let t = Date.init(timeIntervalSinceNow: 0)
        filename = t.toTimeStampedFilename("Video","m4v")
        
        let fileURL:URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(filename)
        
        deleteFile(fileURL.path)
        
        startRecording(outputURL:fileURL, size: vc.metalView.bounds.size)
        vc.control.skip = 1
    }
    
    @IBAction func easeInOutChanged(_ sender: NSButton) {
        easeInOutFlag = sender.state == .on
    }
    
    func presentPopover(_ name:String) {
        let mvc = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let vc = mvc.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(name)) as! NSViewController
        self.present(vc, asPopoverRelativeTo: view.bounds, of: view, preferredEdge: .minX, behavior: .transient)
    }
    
    @IBAction func helpPressed(_ sender: NSButton) {
        helpIndex = 2
        presentPopover("HelpVC")
    }
    
    @IBAction func resetPressed(_ sender: NSButton) { reset() }
    
    @IBAction func framesPerKeyframeChanged(_ sender: NSSegmentedControl) {
        let fpkf:[Int] = [ 19,49,99 ]
        framesPerKeyFrame = fpkf[sender.selectedSegment]
    }
    
    @IBAction func smoothingFactorChanged(_ sender: NSSegmentedControl) {
        let sf:[Float] = [ 0,2,5,10,20 ]
        sFactor = sf[sender.selectedSegment]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vr = self
        tv = keyFrameList.documentView as? NSTableView
        tv.dataSource = self
        tv.delegate = self
    }
    
    override func viewDidAppear() {
        reset()
    }
    
    func reset() {
        keyFrames.removeAll()
        refresh()
    }
    
    func refresh() {
        tv.reloadData()
    }
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        
        switch event.charactersIgnoringModifiers!.uppercased() {
        case " " : if isRecording { stopRecording() }
        default : break
        }
    }
    
    //=======================================================================
    
    func numberOfSections(in tableView: NSTableView) -> Int { return 1 }
    func numberOfRows(in tableView: NSTableView) -> Int { return keyFrames.count }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { return CGFloat(20) }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let str = Int(row + 1).description
        let view = NSTextField(string:str)
        view.isEditable = false
        view.isBordered = false
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        vc.control = loadKeyframe(row)
        vc.flagViewToRecalcFractal()
        return true
    }
    
    //=======================================================================
    
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
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        assetWriter.add(assetWriterVideoInput)
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        isRecording = true
        frameCount = 0
        keyFramesIndex = 0
        keyFramesRatio = 0

        vc.control = loadKeyframe(0)
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
    
    func finishRecording() {
        if keyFrames.count < 2 { return } // 'Cancelled'
        
        keyFrames.append(vc.control) // stopping recording adds terminating keyframe
        
        let fileURL:URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(filename)
        
        deleteFile(fileURL.path)
        
        vc.control.skip = 1
        startRecording(outputURL:fileURL, size: vc.metalView.bounds.size)
    }
    
    func saveVideoFrame(_ texture:MTLTexture) { // false = finished session, repaint instructions
        if isRecording {
            writeFrame(forTexture:texture)
            updateRecordingStatusDisplay()
            interpolateParameters()
        }
    }
    
    func loadKeyframe(_ index:Int) -> Control {
        var temp = keyFrames[index]
        temp.bright = vc.control.bright
        temp.contrast = vc.control.contrast
        temp.specular = vc.control.specular
        temp.colorScheme = vc.control.colorScheme
        temp.isStereo = vc.control.isStereo
        temp.xSize = vc.control.xSize
        temp.ySize = vc.control.ySize
        return temp
    }

    func interpolateParameters() {
        if !isRecording { return }
        
        func parametricBlend(_ t:Float) -> Float { return powf(sin(Float.pi * t / 2),2) } // ease-in/out 0..1 -> 0..1
        let ratio = easeInOutFlag ? parametricBlend(keyFramesRatio) : keyFramesRatio
        
        func interpolate(_ v1:Float, _ v2:Float) -> Float { return v1 + (v2-v1) * ratio }
        
        func smoothed(_ oldV:Float, _ newV:Float) -> Float {
            if sFactor == 0 { return newV }         // 0 == no smoothing
            return (oldV * (sFactor-1) + newV) / sFactor
        }
        
        let c1:Control = loadKeyframe(keyFramesIndex)
        let c2:Control = loadKeyframe(keyFramesIndex+1)
        
        vc.control.camera = mix(c1.camera,c2.camera,t:ratio)
        vc.control.viewVector = normalize(mix(c1.viewVector,c2.viewVector,t:ratio))
        vc.control.sideVector = normalize(mix(c1.sideVector,c2.sideVector,t:ratio))
        vc.control.topVector = normalize(mix(c1.topVector,c2.topVector,t:ratio))
        
        vc.control.cx = smoothed(vc.control.cx,interpolate(c1.cx, c2.cx))
        vc.control.cy = smoothed(vc.control.cy,interpolate(c1.cy, c2.cy))
        vc.control.cz = smoothed(vc.control.cz,interpolate(c1.cz, c2.cz))
        vc.control.cw = smoothed(vc.control.cw,interpolate(c1.cw, c2.cw))
        vc.control.dx = smoothed(vc.control.dx,interpolate(c1.dx, c2.dx))
        vc.control.dy = smoothed(vc.control.dy,interpolate(c1.dy, c2.dy))
        vc.control.dz = smoothed(vc.control.dz,interpolate(c1.dz, c2.dz))
        vc.control.dw = smoothed(vc.control.dw,interpolate(c1.dw, c2.dw))
        vc.control.ex = smoothed(vc.control.ex,interpolate(c1.ex, c2.ex))
        vc.control.ey = smoothed(vc.control.ey,interpolate(c1.ey, c2.ey))
        vc.control.ez = smoothed(vc.control.ez,interpolate(c1.ez, c2.ez))
        vc.control.ew = smoothed(vc.control.ew,interpolate(c1.ew, c2.ew))
        vc.control.fx = smoothed(vc.control.fx,interpolate(c1.fx, c2.fx))
        vc.control.fy = smoothed(vc.control.fy,interpolate(c1.fy, c2.fy))
        vc.control.fz = smoothed(vc.control.fz,interpolate(c1.fz, c2.fz))
        vc.control.fw = smoothed(vc.control.fw,interpolate(c1.fw, c2.fw))
        vc.control.multiplier = smoothed(vc.control.multiplier,interpolate(c1.multiplier, c2.multiplier))
        vc.control.foam = smoothed(vc.control.foam,interpolate(c1.foam, c2.foam))
        vc.control.foam2 = smoothed(vc.control.foam2,interpolate(c1.foam2, c2.foam2))
        vc.control.bend = smoothed(vc.control.bend,interpolate(c1.bend, c2.bend))
        vc.control.power = smoothed(vc.control.power,interpolate(c1.power, c2.power))
        vc.control.Clamp_y = smoothed(vc.control.Clamp_y,interpolate(c1.Clamp_y, c2.Clamp_y))
        vc.control.Clamp_DF = smoothed(vc.control.Clamp_DF,interpolate(c1.Clamp_DF, c2.Clamp_DF))
        vc.control.box_size_z = smoothed(vc.control.box_size_z,interpolate(c1.box_size_z, c2.box_size_z))
        vc.control.box_size_x = smoothed(vc.control.box_size_z,interpolate(c1.box_size_x, c2.box_size_x))
        vc.control.KleinR = smoothed(vc.control.KleinR,interpolate(c1.KleinR, c2.KleinR))
        vc.control.KleinI = smoothed(vc.control.KleinI,interpolate(c1.KleinI, c2.KleinI))
        vc.control.InvCx = smoothed(vc.control.InvCx,interpolate(c1.InvCx, c2.InvCx))
        vc.control.InvCy = smoothed(vc.control.InvCy,interpolate(c1.InvCy, c2.InvCy))
        vc.control.InvCz = smoothed(vc.control.InvCz,interpolate(c1.InvCz, c2.InvCz))
        vc.control.DeltaAngle = smoothed(vc.control.DeltaAngle,interpolate(c1.DeltaAngle, c2.DeltaAngle))
        vc.control.InvRadius = smoothed(vc.control.InvRadius,interpolate(c1.InvRadius, c2.InvRadius))
        vc.control.juliaX = smoothed(vc.control.juliaX,interpolate(c1.juliaX, c2.juliaX))
        vc.control.juliaY = smoothed(vc.control.juliaY,interpolate(c1.juliaY, c2.juliaY))
        vc.control.juliaZ = smoothed(vc.control.juliaZ,interpolate(c1.juliaZ, c2.juliaZ))
        vc.control.InvCenter.x = smoothed(vc.control.InvCenter.x,interpolate(c1.InvCenter.x, c2.InvCenter.x))
        vc.control.InvCenter.y = smoothed(vc.control.InvCenter.y,interpolate(c1.InvCenter.y, c2.InvCenter.y))
        vc.control.InvCenter.z = smoothed(vc.control.InvCenter.z,interpolate(c1.InvCenter.z, c2.InvCenter.z))
        vc.control.julia.x = smoothed(vc.control.julia.x,interpolate(c1.julia.x, c2.julia.x))
        vc.control.julia.y = smoothed(vc.control.julia.y,interpolate(c1.julia.y, c2.julia.y))
        vc.control.julia.z = smoothed(vc.control.julia.z,interpolate(c1.julia.z, c2.julia.z))
        vc.control.angle1 = smoothed(vc.control.angle1,interpolate(c1.angle1, c2.angle1))
        vc.control.angle2 = smoothed(vc.control.angle2,interpolate(c1.angle2, c2.angle2))
        vc.control.tCenterX = smoothed(vc.control.tCenterX,interpolate(c1.tCenterX, c2.tCenterX))
        vc.control.tCenterY = smoothed(vc.control.tCenterY,interpolate(c1.tCenterY, c2.tCenterY))
        vc.control.tScale = smoothed(vc.control.tScale,interpolate(c1.tScale, c2.tScale))
        
        keyFramesRatio += 1.0 / Float(framesPerKeyFrame)
        if keyFramesRatio >= 1.0 {
            keyFramesRatio = 0
            keyFramesIndex += 1
            
            if keyFramesIndex == keyFrames.count - 1 { stopRecording() }
        }
    }
    
    func stopRecording()  {
        isRecording = false
        endRecording({ () in })
        statusField.stringValue = ""
    }
    
    func updateRecordingStatusDisplay() {
        let fs:String = String(format:"Building Video: %@\nStandby.\nFrame %3d of %3d",
                               filename,
                               frameCount+1,
                               (framesPerKeyFrame+1) * (keyFrames.count - 1))
        statusField.attributedStringValue = NSMutableAttributedString(string:fs)
    }
}

class BackgroundView: NSView {
    override func draw(_ rect: NSRect) {
        NSColor(red:0.6, green:0.6, blue:0.8, alpha:1).set()
        NSBezierPath(rect:bounds).fill()
    }
}
