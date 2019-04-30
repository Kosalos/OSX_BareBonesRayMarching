import Cocoa
import MetalKit

var vc3D:Win3DViewController! = nil
let view3D = View3D()
var camera:float3 = float3(0,0.2,-200)

var yScale3D:Float = 1
var ceiling3D:Float = 20
var floor3D:Float = 1

class Win3DViewController: NSViewController, NSWindowDelegate, WidgetDelegate {
    var isStereo:Bool = false
    var rendererL: Renderer!
    var rendererR: Renderer!
    var widget:Widget! = nil
    var viewCenter = CGPoint() // coordinate of middle of view
    var paceRotate = CGPoint() // amount to rotate image in timer call
    
    @IBOutlet var instructions: NSTextField!
    @IBOutlet var d3ViewL: MTKView!
    @IBOutlet var d3ViewR: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vc3D = self
        widget = Widget(1,self)
        
        d3ViewL.device = device
        d3ViewR.device = device

        guard let newRenderer = Renderer(metalKitView: d3ViewL, 0) else { fatalError("Renderer cannot be initialized") }
        rendererL = newRenderer
        rendererL.mtkView(d3ViewL, drawableSizeWillChange: d3ViewL.drawableSize)
        d3ViewL.delegate = rendererL
        
        guard let newRenderer2 = Renderer(metalKitView: d3ViewR, 1) else { fatalError("Renderer cannot be initialized") }
        rendererR = newRenderer2
        rendererR.mtkView(d3ViewR, drawableSizeWillChange: d3ViewR.drawableSize)
        d3ViewR.delegate = rendererR
        
        light.base = float3(20,1,0)
        light.radius = 50
        light.deltaAngle = 0.002
        light.power = 1
        light.ambient = 0.3
        light.height = -15
        
        Timer.scheduledTimer(withTimeInterval:0.0033, repeats:true) { timer in self.timerHandler() }
    }
    
    override func viewDidAppear() {
        view.window?.delegate = self    // so we received window size changed notifications
        updateLayoutOfChildViews()
        setInitialCameraPositionAndOrientation()
        defineWidgets()
        showHelpDialog()
    }
    
    func windowWillClose(_ aNotification: Notification) {
        vc.win3DClosed()
    }
    
    //MARK: -
    
    func updateLayoutOfChildViews() {
        // also ensure window isn't too small
        let minWinSize:CGSize = CGSize(width:700, height:500)
        var r:CGRect = (view.window?.frame)!
        var needSizing:Bool = false
        
        if r.size.width  < minWinSize.width  { r.size.width = minWinSize.width; needSizing = true }
        if r.size.height < minWinSize.height { r.size.height = minWinSize.height; needSizing = true }
        
        if needSizing {
            view.window?.setFrame(r, display: true)
        }

        // layout child views ---------------
        let xs = view.bounds.width
        let ys = view.bounds.height
        
        d3ViewL.frame = CGRect(x:1, y:1, width:xs-2, height:ys-2)
        
        if isStereo {
            d3ViewR.isHidden = false
            let xs2:CGFloat = xs/2
            d3ViewL.frame = CGRect(x:1,     y:1, width:xs2,     height:ys-2)
            d3ViewR.frame = CGRect(x:xs2+1, y:1, width:xs2-2,   height:ys-2)
        }
        else {
            d3ViewR.isHidden = true
            d3ViewL.frame = CGRect(x:+1, y:1, width:xs-2, height:ys-2)
        }
        
        viewCenter.x = d3ViewL.frame.width/2
        viewCenter.y = d3ViewL.frame.height/2
        arcBall.initialize(Float(d3ViewL.frame.width),Float(d3ViewL.frame.height))
        
        instructions.frame = CGRect(x:5, y:30, width:500, height:700)
        instructions.textColor = .white
        instructions.backgroundColor = .black
        instructions.bringToFront()
        
        setInitialCameraPositionAndOrientation()
    }
        
    func windowDidResize(_ notification: Notification) {
        updateLayoutOfChildViews()
    }
    
    //MARK: -
    
    func rotate(_ pt:CGPoint) {
        arcBall.mouseDown(viewCenter)
        arcBall.mouseMove(CGPoint(x:viewCenter.x + pt.x, y:viewCenter.y - pt.y))
    }

    @objc func timerHandler() {
        rotate(paceRotate)
    }
    
    //MARK: -
    
    func setInitialCameraPositionAndOrientation() {
        camera = float3(3.125000e-02, 3.514453e+01, -1.700000e+02)
        arcBall.endPosition = simd_float3x3([0.9165989, -0.12373819, 0.35284355], [-0.16035071, 0.7048163, 0.6751394], [-0.3287292, -0.6790984, 0.6267859])
        arcBall.transformMatrix = simd_float4x4([0.9165989, -0.12373819, 0.35284355, 0.0], [-0.16035071, 0.7048163, 0.6751394, 0.0], [-0.3287292, -0.6790984, 0.6267859, 0.0], [0.0, 0.0, 0.0, 1.0])
    }
    
    //MARK: -

    func defineWidgets() {
        widget.reset()
        widget.addEntry("Height",&yScale3D,-150,150,0.1)
        widget.addEntry("Ceiling",&ceiling3D,0.1,50,0.1)
        widget.addEntry("Floor",&floor3D,-50,50,0.1)
        widget.addDash("Light Controls")
        widget.addEntry("Spread",&light.power,0.1,2,0.1)
        widget.addEntry("Ambient",&light.ambient,0,1,0.01)
        widget.addEntry("Speed",&light.deltaAngle,0.001,0.05,0.001)
        widget.addEntry("Radius",&light.radius,5,150,4)
        widget.addEntry("Height",&light.height,-100,100,5)
        
        displayWidgets()
    }
    
    func displayWidgets() {
        let str = NSMutableAttributedString()
        widget.addinstructionEntries(str)
        instructions.attributedStringValue = str
    }
    
    /// toggling stereo viewing automatically adjusts window size to accomodate (unless we are already full screen)
    func adjustWindowSizeForStereo() {
        var r:CGRect = (view.window?.frame)!
        r.size.width *= CGFloat(isStereo ? 2.0 : 0.5)
        view.window?.setFrame(r, display:true)
    }
    
    //MARK: -
 
    var shiftKeyDown:Bool = false
    var optionKeyDown:Bool = false
    
    func updateModifierKeyFlags(_ ev:NSEvent) {
        let rv = ev.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        shiftKeyDown   = rv & (1 << 17) != 0
        optionKeyDown  = rv & (1 << 19) != 0
    }
    
    func showHelpDialog() {
        if !isHelpVisible {
            helpIndex = 1
            presentPopover("HelpVC")
        }
    }
    
    func presentPopover(_ name:String) {
        let mvc = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let vc = mvc.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(name)) as! NSViewController
        self.present(vc, asPopoverRelativeTo: view.bounds, of: view, preferredEdge: .minX, behavior: .transient)
    }
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        
        updateModifierKeyFlags(event)
        _ = widget.keyPress(event)
        
        switch event.keyCode {
        case 116 : // page up
            showHelpDialog()
            return
        case 121 : // page down close this window
            win3D.close()
            vc.flagViewToRecalcFractal()
            return
        default : break
        }

        switch event.charactersIgnoringModifiers!.uppercased() {
        case "\\" : // set focus to Fractal window
            vc.view.window?.makeMain()
            vc.view.window?.makeKey()
        case " " :
            instructions.isHidden = !instructions.isHidden
            updateLayoutOfChildViews()
        case "3" :
            isStereo = !isStereo
            adjustWindowSizeForStereo()
            updateLayoutOfChildViews()
        default : break
        }
    }
    
    override func keyUp(with event: NSEvent) {
        super.keyUp(with: event)
        updateModifierKeyFlags(event)
    }
    
    //MARK: -
    
    func flippedYCoord(_ pt:NSPoint) -> NSPoint {
        var npt = pt
        npt.y = view.bounds.size.height - pt.y
        return npt
    }
    
    var pt = NSPoint()
    
    override func mouseDown(with event: NSEvent) {
        pt = flippedYCoord(event.locationInWindow)
        
        if optionKeyDown {      // optionKey + mouse click = stop rotation
            paceRotate = CGPoint()
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        updateModifierKeyFlags(event)
        
        var npt = flippedYCoord(event.locationInWindow)
        npt.x -= pt.x
        npt.y -= pt.y
        
        if optionKeyDown {      // optionKey + mouse drag = set rotation speed & direction
            updateRotationSpeedAndDirection(npt)
            return
        }
        
        camera.x += Float(npt.x / 50)
        camera.y -= Float(npt.y / 50)
    }
    
    override func mouseUp(with event: NSEvent) {
        pt.x = 0
        pt.y = 0
    }
    
    override func scrollWheel(with event: NSEvent) {
        camera.z *= Float(1 - event.deltaY / 50.0)
    }

    //MARK: -
    
    func updateRotationSpeedAndDirection(_ pt:NSPoint) {
        let scale:Float = 0.01
        let rRange = float2(-3,3)
        
        func fClamp(_ v:Float, _ range:float2) -> Float {
            if v < range.x { return range.x }
            if v > range.y { return range.y }
            return v
        }
        
        paceRotate.x = +CGFloat(fClamp(Float(pt.x) * scale, rRange))
        paceRotate.y = -CGFloat(fClamp(Float(pt.y) * scale, rRange))
    }
}
