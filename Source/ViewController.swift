import Cocoa
import Foundation
import MetalKit

var vc:ViewController! = nil
var win3D:NSWindowController! = nil
var controlBuffer:MTLBuffer! = nil
var coloringTexture:MTLTexture! = nil

var device: MTLDevice! = nil
var mvr:MetalVideoRecorder! = nil

class ViewController: NSViewController, NSWindowDelegate, MetalViewDelegate, WidgetDelegate {
    var control = Control()
    var widget:Widget! = nil
    var commandQueue: MTLCommandQueue?
    var pipeline:[MTLComputePipelineState] = []
    var threadsPerGroup:[MTLSize] = []
    var threadsPerGrid:[MTLSize] = []
    var isStereo:Bool = false
    var isFullScreen:Bool = false
    var isChangingViewVector:Bool = false
    var parallax:Float = 0.003
    var lightAngle:Float = 0
    var tCenterX:Float = 0
    var tCenterY:Float = 0
    var tScale:Float = 0

    @IBOutlet var instructions: NSTextField!
    @IBOutlet var metalViewL: MetalView!
    @IBOutlet var metalViewR: MetalView!
    
    let PIPELINE_FRACTAL = 0
    let PIPELINE_NORMAL  = 1
    let shaderNames = [ "rayMarchShader","normalShader" ]
    
    //MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vc = self
        mvr = MetalVideoRecorder()
    }
    
    override func viewDidAppear() {
        super.viewWillAppear()
        widget = Widget(0,self)
        
        metalViewL.ident = 0
        metalViewR.ident = 1
        metalViewL.window?.delegate = self;  (metalViewL).delegate2 = self
        metalViewR.window?.delegate = self;  (metalViewR).delegate2 = self
        
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        view3D.initializeBuffers()
        
        //------------------------------
        let defaultLibrary:MTLLibrary! = device.makeDefaultLibrary()
        
        func loadShader(_ name:String) -> MTLComputePipelineState {
            do {
                guard let fn = defaultLibrary.makeFunction(name: name)  else { print("shader not found: " + name); exit(0) }
                return try device.makeComputePipelineState(function: fn)
            }
            catch { print("pipeline failure for : " + name); exit(0) }
        }
        
        for i in 0 ..< shaderNames.count {
            pipeline.append(loadShader(shaderNames[i]))
            threadsPerGroup.append(MTLSize()) // determined in updateThreadGroupsAccordingToWindowSize()
            threadsPerGrid.append(MTLSize())
        }
        //------------------------------
        
        controlBuffer = device.makeBuffer(length:MemoryLayout<Control>.stride, options:MTLResourceOptions.storageModeShared)
        
        control.equation = Int32(EQU_01_MANDELBULB)
        control.txtOnOff = false    // 'no texture'
        control.skip = 1            // "fast render" defaults to 'not active'
        
        reset()
        ensureWindowSizeIsNotTooSmall()
        
        Timer.scheduledTimer(withTimeInterval:0.033, repeats:true) { timer in self.timerHandler() }
        presentPopover("HelpVC")
    }
    
    var fastRenderEnabled:Bool = true
    var slowRenderCountDown:Int = 0
    
    /// direct shader to sparsely calculate, and copy results to neighboring pixels, for faster fractal rendering
    func setShaderToFastRender() {
        if fastRenderEnabled {
            control.skip = max(control.xSize / 250, 6)
            if isStereo { control.skip *= 2 }
            slowRenderCountDown = 20 // 30 = 1 second
        }
    }
    
    /// direct 2D fractals views to re-calculate image on next draw call
    func flagViewsToRecalcFractal() {
        metalViewL.viewIsDirty = true
        if isStereo {
            metalViewR.viewIsDirty = true
        }
    }
    
    /// ensure companion 3D window is also closed
    func windowWillClose(_ aNotification: Notification) {
        if let w = win3D { w.close() }
    }
    
    // 3D window just closed. reset window handle, reset "3D window active flag", repaint 2D to remove ROI box
    func win3DClosed() {
        win3D = nil
        control.win3DFlag = 0
        flagViewsToRecalcFractal() // to erase bounding box
    }
    
    //MARK: -
    
    @objc func timerHandler() {
        var isDirty:Bool = mvr.isRecording
        
        if control.skip > 1 && slowRenderCountDown > 0 {
            slowRenderCountDown -= 1
            if slowRenderCountDown == 0 {
                control.skip = 1
                isDirty = true
            }
        }
        
        if isDirty {
            flagViewsToRecalcFractal()
        }
    }
    
    //MARK: -
    
    func toRectangular(_ sph:float3) -> float3 { let ss = sph.x * sin(sph.z); return float3( ss * cos(sph.y), ss * sin(sph.y), sph.x * cos(sph.z)) }
    func toSpherical(_ rec:float3) -> float3 { return float3(length(rec), atan2(rec.y,rec.x), atan2(sqrt(rec.x*rec.x+rec.y*rec.y), rec.z)) }
    
    func updateShaderDirectionVector(_ v:float3) {
        control.viewVector = v
        control.topVector = toSpherical(control.viewVector)
        control.topVector.z += 1.5708
        control.topVector = toRectangular(control.topVector)
        control.sideVector = cross(control.viewVector,control.topVector)
        control.sideVector = normalize(control.sideVector) * length(control.topVector)
    }
    
    /// window title displays fractal name and number, and name of focused widget
    let titleString:[String] =
        [ "MandelBulb","Apollonian","Apollonian2","Jos Leys Kleinian",
          "MandelBox","Quaternion Julia","Monster","Kali Tower","Polyhedral Menger",
          "Gold","Spider","Knighty's Kleinian","EvilRyu's KIFS",
          "IFS Tetrahedron","IFS Octahedron","IFS Dodecahedron","IFS Menger",
          "Sierpinski Tetrahedron","Half Tetrahedron","Full Tetrahedron","Cubic",
          "Half Octahedron","Full Octahedron","Kaleidoscopic",
          "Knighty Polychora","QuadRay","3Dickulus FragM",
          "3Dickulus Quaternion Julia","3Dickulus Quaternion Mandelbrot",
          "Kali's MandelBox","Spudsville","Menger Smooth Polyhedra",
          "Menger Helix","Flower Hive","Jungle","Prisoner","Pupukuusikkos Spiralbox",
          "Aleksandrov MandelBulb","SurfBox","TwistBox","Kali Rontgen","Vertebrae",
          "DarkBeam Surfbox","Buffalo Bulb","Ancient Temple","Kali 3D",
          "Klienian Sponge","Floral Hybrid","Torus Knot","Donuts" ]
    
    func updateWindowTitle() {
        let index = Int(control.equation)
        view.window?.title = Int(index + 1).description + ": " + titleString[index] + " : " + widget.focusString()
    }
    
    /// reset widget focus index, update window title, recalc fractal.  Called after Load and LoadNext
    func controlJustLoaded() {
        reset()
        widget.focus = 0
        updateWindowTitle()
        flagViewsToRecalcFractal()
    }
    
    /// load initial parameter values and view vectors for the current fractal (control.equation holds index)
    func reset() {
        updateShaderDirectionVector(float3(0,0.1,1))
        control.bright = 1
        control.contrast = 0.5
        control.specular = 0
        control.angle1 = 0
        control.angle2 = 0
        
        switch Int(control.equation) {
        case EQU_01_MANDELBULB :
            updateShaderDirectionVector(float3(0.010000015, 0.41950363, 0.64503753))
            control.camera = float3(0.038563743, -1.1381346, -1.8405379)
            control.multiplier = 80
            control.power = 8
            control.fMaxSteps = 10
        case EQU_02_APOLLONIAN, EQU_03_APOLLONIAN2 :
            control.camera = float3(0.42461035, 10.847559, 2.5749633)
            control.foam = 1.05265248
            control.foam2 = 1.06572711
            control.bend = 0.0202780124
            control.multiplier = 25
            control.fMaxSteps = 8
        case EQU_04_KLEINIAN :
            control.camera = float3(0.5586236, 1.1723881, -1.8257363)
            control.fMaxSteps = 70
            control.fFinal_Iterations = 21
            control.fBox_Iterations = 17
            control.showBalls = true
            control.doInversion = true
            control.fourGen = false
            control.Clamp_y = 0.221299887
            control.Clamp_DF = 0.00999999977
            control.box_size_x = 0.6318979
            control.box_size_z = 1.3839532
            control.KleinR = 1.9324
            control.KleinI = 0.04583
            control.InvCenter = float3(1.0517285, 0.7155759, 0.9883028)
            control.DeltaAngle = 5.5392437
            control.InvRadius = 2.06132293
        case EQU_05_MANDELBOX :
            control.camera = float3(-1.3771019, 0.9999971, -5.037427)
            control.cx = 1.42
            control.cy = 2.997
            control.cz = 1.0099998
            control.cw = 0.02
            control.dx = 4.3978653
            control.fMaxSteps = 17.0
            control.juliaX =  0.0
            control.juliaY =  -6.0
            control.juliaZ =  -8.0
            control.bright = 1.01
            control.contrast = 0.5
            control.power = 2.42
            control.juliaboxMode = true
        case EQU_06_QUATJULIA :
            control.camera = float3(-0.010578117, -0.49170083, -2.4)
            control.cx = -1.74999952
            control.cy = -0.349999964
            control.cz = -0.0499999635
            control.cw = -0.0999999642
            control.fMaxSteps = 7
            control.contrast = 0.28
            control.specular = 0.9
        case EQU_07_MONSTER :
            control.camera = float3(0.0012031387, -0.106357165, -1.1865364)
            control.cx = 120
            control.cy = 4
            control.cz = 1
            control.cw = 1.3
            control.fMaxSteps = 10
        case EQU_08_KALI_TOWER :
            control.camera = float3(-0.051097937, 5.059899, -4.0350704)
            control.cx = 8.65
            control.cy = 1
            control.cz = 2.3
            control.cw = 0.13
            control.fMaxSteps = 2
        case EQU_09_POLY_MENGER :
            control.camera = float3(-0.20046826, -0.51177955, -5.087464)
            control.cx = 4.7799964
            control.cy = 2.1500008
            control.cz = 2.899998
            control.cw = 3.0999982
            control.dx = 5;
        case EQU_10_GOLD :
            updateShaderDirectionVector(float3(0.010000015, 0.41950363, 0.64503753))
            control.camera = float3(0.038563743, -1.1381346, -1.8405379)
            control.cx = -0.09001912
            control.cy = 0.43999988
            control.cz = 1.0499994
        case EQU_11_SPIDER :
            control.camera = float3(0.04676684, -0.50068825, -3.4419205)
            control.cx = 0.13099998
            control.cy = 0.21100003
            control.cz = 0.041
        case EQU_12_KLEINIAN2 :
            control.camera = float3(4.1487565, 2.6955016, 1.3862593)
            control.cx = -0.7821867
            control.cy = -0.5424057
            control.cz = -0.4748369
            control.cw = 0.7999992
            control.dx = 0.5
            control.dy = 1.3
            control.dz = 1.5499997
            control.dw = 0.9000002
            control.power = 1
        case EQU_13_KIFS :
            control.camera = float3(-0.033257294, -0.58263075, -5.087464)
            control.cx = 2.7499976
            control.cy = 2.6499977
            control.cz = 4.049997
        case EQU_14_IFS_TETRA :
            control.camera = float3(-0.034722134, -0.45799592, -3.3590596)
            control.cx = 1.4900005
        case EQU_15_IFS_OCTA :
            control.camera = float3(0.00014548551, -0.20753044, -1.7193593)
            control.cx = 1.65
        case EQU_16_IFS_DODEC :
            control.camera = float3(-0.09438618, -0.52536994, -4.1138387)
            control.cx = 1.8
            control.cy = 1.5999994
        case EQU_17_IFS_MENGER :
            control.camera = float3(0.017836891, -0.40871215, -3.3820548)
            control.cx = 3.0099978
            control.cy = -0.53999937
            control.fMaxSteps = 3
        case EQU_18_SIERPINSKI :
            control.camera = float3(0.03816485, -0.08283869, -0.63742965)
            control.cx = 1.3240005
            control.cy = 1.5160003
            control.angle1 = 3.1415962
            control.angle2 = 1.5610005
            control.fMaxSteps = 27
        case EQU_19_HALF_TETRA :
            control.camera = float3(-0.023862544, -0.113349974, -0.90810966)
            control.cx = 1.2040006
            control.cy = 9.236022
            control.angle1 = -3.9415956
            control.angle2 = 0.79159856
            control.fMaxSteps = 53
        case EQU_20_FULL_TETRA :
            control.camera = float3(-0.018542236, -0.08817809, -0.90810966)
            control.cx = 1.1280007
            control.cy = 8.099955
            control.angle1 = -1.2150029
            control.angle2 = -0.018401254
            control.fMaxSteps = 71.0
        case EQU_21_CUBIC :
            control.camera = float3(-0.0011281949, -0.21761245, -0.97539556)
            control.cx = 1.1000057
            control.cy = 1.6714587
            control.angle1 = -1.8599923
            control.angle2 = 1.1640991
            control.fMaxSteps = 73.0
        case EQU_22_HALF_OCTA :
            control.camera = float3(-0.015249629, -0.14036252, -0.8621065)
            control.cx = 1.1399999
            control.cy = 0.61145973
            control.angle1 = 2.8750083
            control.angle2 = 1.264099
            control.fMaxSteps = 50.0
        case EQU_23_FULL_OCTA :
            control.camera = float3(0.0028324036, -0.05510863, -0.47697017)
            control.cx = 1.132
            control.cy = 0.6034597
            control.angle1 = 2.8500082
            control.angle2 = 1.264099
            control.fMaxSteps = 34.0
        case EQU_24_KALEIDO :
            control.camera = float3(-0.00100744, -0.1640267, -1.7581517)
            control.cx = 1.1259973
            control.cy = 0.8359996
            control.cz = -0.016000029
            control.angle1 = 1.7849922
            control.angle2 = -1.2375059
            control.fMaxSteps = 35.0
        case EQU_25_POLYCHORA :
            control.camera = float3(-0.00100744, -0.16238609, -1.7581517)
            control.cx = 5.0
            control.cy = 1.3159994
            control.cz = 2.5439987
            control.cw = 4.5200005
            control.dx = 0.08000006
            control.dy = 0.008000016
            control.dz = -1.5999997
        case EQU_26_QUADRAY :
            control.camera = float3(0.017425783, -0.03216796, -3.7908385)
            control.cx = -0.8950321
            control.cy = -0.22100903
            control.cz = 0.10000001
            control.cw = 2
            control.fMaxSteps = 10.0
        case EQU_27_FRAGM :
            control.camera = float3(-0.010637887, -0.27700076, -2.4429061)
            control.cx = 0.6
            control.cy = 0.13899112
            control.cz = -0.66499984
            control.cw = 1.3500009
            control.angle1 = 0.40500003
            control.angle2 = 0.0
            control.fMaxSteps = 4.0
            control.juliaX =  -1.4901161e-08
            control.juliaY =  -0.3
            control.juliaZ =  -0.8000001
            control.bright = 0.25
            control.power = 8
        case EQU_28_QUATJULIA2 :
            control.camera = float3(-0.010578117, -0.49170083, -2.4)
            control.cx = -1.7499995
            control.fMaxSteps = 7.0
            control.bright = 0.5
            control.juliaX =  0.0
            control.juliaY =  0.0
            control.juliaZ =  0.0
        case EQU_29_MBROT :
            control.camera = float3(-0.23955467, -0.3426069, -2.4)
            control.cx = -9.685755e-08
            control.angle1 = 0.0
            control.fMaxSteps = 10.0
            control.juliaX =  0.39999992
            control.juliaY =  5.399997
            control.juliaZ =  -2.3
            control.bright = 0.5
        case EQU_30_KALIBOX :
            control.camera = float3(0.32916373, -0.42756003, -3.6908724)
            control.cx = 1.6500008
            control.cy = 0.35499972
            control.cz = 0.0
            control.cw = 0.0
            control.dx = -0.7600006
            control.dy = -0.25000006
            control.dz = -0.8000002
            control.dw = 0.0
            control.angle1 = 3.5800009
            control.angle2 = 0.0
            control.fMaxSteps = 11.0
            control.juliaX =  0.0
            control.juliaY =  0.0
            control.juliaZ =  0.0
            control.bright = 0.5
        case EQU_31_SPUDS :
            control.camera = float3(0.98336715, -1.2565054, -3.960955)
            control.cx = 3.7524672
            control.cy = 1.0099992
            control.cz = -1.0059854
            control.cw = -1.0534152
            control.dx = 1.1883448
            control.dz = -4.100001
            control.dw = -3.2119942
            control.fMaxSteps = 8.0
            control.bright = 0.3199999
            control.power = 3.2999988
        case EQU_32_MPOLY :
            control.camera = float3(0.0047654044, -0.4972743, -3.960955)
            control.cx = 4.712923
            control.cy = 4.1999984
            control.cz = -4.0846615
            control.cw = -1.2505636
            control.dx = 0.080002524
            control.angle1 = -1.1579993
            control.fMaxSteps = 8.0
            control.bright = 1.0799999
            control.HoleSphere = true
        case EQU_33_MHELIX :
            control.camera = float3(0.45329404, -1.7558048, -21.308537)
            control.cx = 1.0140339
            control.cy = 2.1570902
            control.angle1 = 0
            control.fMaxSteps = 5.0
            control.juliaX =  1.8000009
            control.juliaY =  -8.0
            control.juliaZ =  -10.0
            control.bright = 1.12
            control.gravity = true // 'moebius'
        case EQU_34_FLOWER :
            control.camera = float3(-0.16991696, -2.5964863, -12.54011)
            control.cx = 1.6740334
            control.cy = 2.1570902
            control.fMaxSteps = 10.0
            control.juliaX =  6.0999966
            control.juliaY =  13.999996
            control.juliaZ =  3.0999992
            control.bright = 1.5000001
        case EQU_35_JUNGLE :
            control.camera = float3(-1.8932692, -10.888095, -12.339884)
            control.cx = 1.8540331
            control.cy = 0.16000009
            control.cz = 3.1000001
            control.cw = 2.1499999
            control.fMaxSteps = 1.0
        case EQU_36_PRISONER :
            control.camera = float3(-0.002694401, -0.36424443, -3.5887358)
            control.cx = 1.0799996
            control.cy = 1.06
            control.angle1 = 1.0759996
            control.fMaxSteps = 3.0
            control.bright = 1.5000001
            control.contrast = 0.15999986
            control.power = 4.8999977
        case EQU_37_SPIRALBOX :
            control.camera = float3(0.047575176, -0.122939646, 1.5686907)
            control.cx = 0.8810008
            control.juliaX =  1.9000009
            control.juliaY =  1.0999998
            control.juliaZ =  0.19999993
            control.fMaxSteps = 9
        case EQU_38_ALEK_BULB :
            control.camera = float3(-0.07642456, -0.23929897, -2.1205378)
            control.fMaxSteps = 10.0
            control.juliaX =  0.6000004
            control.juliaY =  0.29999986
            control.juliaZ =  0.29999968
            control.bright = 1.4000001
            control.contrast = 0.5
            control.power = 3.4599924
        case EQU_39_SURFBOX :
            control.camera = float3(-0.37710285, 0.4399976, -5.937426)
            control.cx = 1.4199952
            control.cy = 4.1000023
            control.cz = 1.2099996
            control.cw = 0.0
            control.dx = 4.3978653
            control.fMaxSteps = 17.0
            control.juliaX =  -0.6800002
            control.juliaY =  -4.779989
            control.juliaZ =  -7.2700005
            control.bright = 1.01
            control.contrast = 0.5
            control.power = 2.5600004
            control.juliaboxMode = true
        case EQU_40_TWISTBOX :
            control.camera = float3(0.24289839, -2.1800025, -9.257425)
            control.cx = 1.5611011
            control.fMaxSteps = 24.0
            control.juliaX =  3.2779012
            control.juliaY =  -3.0104024
            control.juliaZ =  -3.2913034
            control.bright = 1.4100001
            control.contrast = 0.3399999
            control.power = 8.21999
        case EQU_41_KALI_RONTGEN :
            control.camera = float3(-0.16709971, -0.020002633, -0.9474212)
            control.cx = 0.88783956
            control.cy = 1.3439986
            control.cz = 0.56685466
            control.fMaxSteps = 7.0
        case EQU_42_VERTEBRAE :
            control.camera = float3(0.5029001, -1.3100017, -9.947422)
            control.cx = 5.599995
            control.cy = 8.699999
            control.cz = -3.6499987
            control.cw = 0.089999855
            control.dx = 1.0324188
            control.dy = 9.1799965
            control.dz = -0.68002427
            control.dw = 1.439993
            control.ex = -0.6299968
            control.ey = 2.0999985
            control.ez = -4.026443
            control.ew = -4.6699996
            control.fx = -9.259983
            control.fy = 0.8925451
            control.fz = -0.0112106
            control.fw = 2.666039
            control.fMaxSteps = 2.0
            control.bright = 0.41
            control.contrast = 0.28000006
            control.specular = 2.0
        case EQU_43_DARKSURF :
            control.camera = float3(-0.4870995, -1.9200011, -1.7574148)
            control.cx = 7.1999893
            control.cy = 0.34999707
            control.cz = -4.549979
            control.dx = -10.0
            control.dy = 0.549999
            control.dz = 0.88503367
            control.ex = 0.99998015
            control.ey = 1.8999794
            control.ez = 3.3499994
            control.fMaxSteps = 10.0
            control.angle1 = -1.5399991
            control.bright = 1.0
            control.contrast = 0.5
            control.specular = 0.0
        case EQU_44_BUFFALO :
            control.preabsx = true
            control.preabsy = true
            control.preabsz = false
            control.absx = true
            control.absy = false
            control.absz = true
            control.UseDeltaDE = false
            control.juliaboxMode = true
            control.camera = float3(0.008563751, -2.8381326, -0.2005394)
            control.cx = -1.2459466
            control.cy = 2.6300106
            control.fMaxSteps = 4.0
            control.angle1 = 0.009998376
            control.juliaX =  0.6382017
            control.juliaY =  -0.4336
            control.juliaZ =  -0.9396994
            control.bright = 1.2100002
            control.contrast = 0.17999999
            control.specular = 1.1999998
            updateShaderDirectionVector( float3(-0.0045253364, 0.73382026, 0.091496624) )
        case EQU_45_TEMPLE :
            control.camera = float3(1.4945942, -0.47837746, -8.777346)
            control.cx = 1.9772799
            control.cy = 0.3100043
            control.cz = -0.5800003
            control.cw = -0.12
            control.dx = 0.6599997
            control.dy = 1.1499994
            control.fMaxSteps = 16.0
            control.angle1 = -3.139998
            control.angle2 = 2.6600018
            control.bright = 1.1100001
            control.contrast = 0.53999996
            control.specular = 1.4000002
        case EQU_46_KALI3 :
            control.juliaboxMode = true
            control.camera = float3(-0.025405688, -0.418378, -3.017353)
            control.cx = -0.5659971
            control.fMaxSteps = 8.0
            control.juliaX =  -0.97769934
            control.juliaY =  -0.8630977
            control.juliaZ =  -0.58009946
            control.bright = 1.6100001
            control.contrast = 0.1
            control.specular = 2.0
        case EQU_47_SPONGE :
            control.camera = float3(0.7610872, -0.7994865, -3.8773263)
            control.cx = -0.8064072
            control.cy = -0.74000216
            control.cz = -1.0899884
            control.cw = 1.2787694
            control.dx = 0.26409245
            control.dy = -0.76119435
            control.dz = 0.2899983
            control.dw = 0.27301705
            control.ex = 6
            control.ey = -6
            control.fMaxSteps = 3.0
            control.bright = 2.31
            control.contrast = 0.17999999
            control.specular = 0.3
        case EQU_48_FLORAL :
            control.camera = float3(-24.393913, -13.7295, -34.877304)
            control.cx = 3.1049967
            control.cy = -5.800398
            control.cz = 2.8034544
            control.cw = -1.7025113
            control.dx = -10.5
            control.dy = -7.4109964
            control.dz = -3.487999
            control.dw = 3.0838223
            control.ex = -2.7218008
            control.ey = 1.2499981
            control.ez = 2.9939957
            control.ew = -2.3987765
            control.fx = 1.1306266
            control.fy = 7.76505
            control.fz = 0.8100605
            control.fw = 1.3926225
            control.fMaxSteps = 2.0
            control.bright = 2.0100002
            control.contrast = 0.1
            control.specular = 1.9
        case EQU_49_KNOT :
            control.camera = float3(0.22108716, -4.869475, -3.187327)
            control.cx = 6.28
            control.cy = 7.0
            control.cz = 1.5
            control.fMaxSteps = 30.0
            control.bright = 1.0100001
            control.contrast = 0.36000004
            control.specular = 1.2000002
            updateShaderDirectionVector( float3(-0.05346525, 1.0684087, 0.78181773) )
        case EQU_50_DONUTS :
            control.camera = float3(-0.2254057, -7.728364, -19.269318)
            control.cx = 7.9931593
            control.cy = 0.35945648
            control.cz = 2.8700645
            control.cw = -2.713223
            control.fMaxSteps = 4.0
            control.bright = 1.0100001
            control.contrast = 0.36000004
            control.specular = 1.2000002
            updateShaderDirectionVector( float3(-2.0272768e-08, 0.46378687, 0.89157283) )
        default : break // zorro
        }
        
        defineWidgetsForCurrentEquation()
        updateWindowTitle()
    }
    
    //MARK: -
    
    var timeInterval:Double = 0.1
    
    /// call shader to update 2D fractal window(s), and 3D vertex data
    func computeTexture(_ drawable:CAMetalDrawable, _ ident:Int) {
        
        // this appears to stop beachball delays if I cause key roll-over?
        Thread.sleep(forTimeInterval: timeInterval)
        
        var c = control
        if isStereo {
            let offset:float3 = c.sideVector * parallax
            c.camera += ident == 0 ? offset : -offset
        }
        
        if control.txtOnOff {
            c.txtCenter.x = tCenterX
            c.txtCenter.y = tCenterY
            c.txtCenter.z = tScale
        }
        
        c.win3DDirty = 0     // assume 3D window is inactive
        if vc3D != nil && ident == 0 { // 3D window is active, & we are drawing left fractal window
            c.win3DDirty = 1
            c.xSize3D = c.xmax3D - c.xmin3D
            c.ySize3D = c.ymax3D - c.ymin3D
        }
        
        func prepareJulia() { c.julia = float3(control.juliaX,control.juliaY,control.juliaZ) }
        
        c.light = c.camera + float3(sin(lightAngle)*100,cos(lightAngle)*100,-100)
        c.nlight = normalize(c.light)
        c.maxSteps = Int32(control.fMaxSteps);
        c.Box_Iterations = Int32(control.fBox_Iterations)
        
        switch Int(control.equation) {
        case EQU_04_KLEINIAN :
            c.Final_Iterations = Int32(control.fFinal_Iterations)
            c.InvCenter = float3(c.InvCx, c.InvCy, c.InvCz)
        case EQU_07_MONSTER :
            c.mm[0][0] = 99   // mark as needing calculation in shader
        case EQU_09_POLY_MENGER :
            let dihedDodec:Float = 0.5 * atan(c.dx)
            c.csD = float2(cos(dihedDodec), -sin(dihedDodec))
            c.csD2 = float2(cos(2 * dihedDodec), -sin(2 * dihedDodec))
        case EQU_12_KLEINIAN2, EQU_47_SPONGE :
            c.mins = float4(control.cx,control.cy,control.cz,control.cw);
            c.maxs = float4(control.dx,control.dy,control.dz,control.dw);
        case EQU_16_IFS_DODEC :
            c.n1 = normalize(float3(-1.0,control.cy-1.0,1.0/(control.cy-1.0)))
            c.n2 = normalize(float3(control.cy-1.0,1.0/(control.cy-1.0),-1.0))
            c.n3 = normalize(float3(1.0/(control.cy-1.0),-1.0,control.cy-1.0))
        case EQU_18_SIERPINSKI, EQU_19_HALF_TETRA, EQU_20_FULL_TETRA,
             EQU_21_CUBIC, EQU_22_HALF_OCTA, EQU_23_FULL_OCTA, EQU_24_KALEIDO :
            c.n1 = normalize(float3(-1.0,control.cy-1.0,1.0/control.cy-1.0))
        case EQU_25_POLYCHORA :
            let pabc:float4 = float4(0,0,0,1)
            let pbdc:float4 = 1.0/sqrt(2) * float4(1,0,0,1)
            let pcda:float4 = 1.0/sqrt(2) * float4(0,1,0,1)
            let pdba:float4 = 1.0/sqrt(2) * float4(0,0,1,1)
            let aa = c.cx * pabc
            let bb = c.cy * pbdc
            let cc = c.cz * pcda
            let dd = c.cw * pdba
            c.p = normalize(aa + bb + cc + dd)
            c.cVR = cos(c.dx)
            c.sVR = sin(c.dx)
            c.cSR = cos(c.dy)
            c.sSR = sin(c.dy)
            c.cRA = cos(c.dz)
            c.sRA = sin(c.dz)
            c.nd = float4(-0.5,-0.5,-0.5,0.5)
        case EQU_27_FRAGM :
            prepareJulia()
            
            c.msIterations = Int32(c.fmsIterations)
            c.mbIterations = Int32(c.fmbIterations)
            c.msScale = 2.57144
            c.msOffset = float3(1,1.00008,1.28204)
            c.mbMinRad2 = 0.17778
            c.mbScale = 2.4
            
            let o:float3 = abs(c.msOffset)
            c.sc = max(o.x,max(o.y,o.z))
            c.sr = sqrt(dot(o,o)+1)
            
            c.absScalem1 = abs(c.mbScale - 1.0)
            c.AbsScaleRaisedTo1mIters = pow(abs(c.mbScale), Float(1 - c.mbIterations))
        case EQU_30_KALIBOX :
            c.absScalem1 = abs(c.cx - 1.0)
            c.AbsScaleRaisedTo1mIters = pow(abs(c.cx), Float(1 - c.maxSteps))
            c.n1 = float3(c.dx,c.dy,c.dz)
            c.mins = float4(c.cx, c.cx, c.cx, abs(c.cx)) / c.cy
            prepareJulia()
        case EQU_33_MHELIX, EQU_34_FLOWER, EQU_05_MANDELBOX, EQU_28_QUATJULIA2, EQU_29_MBROT, EQU_34_FLOWER,
             EQU_37_SPIRALBOX, EQU_38_ALEK_BULB, EQU_40_TWISTBOX, EQU_44_BUFFALO, EQU_46_KALI3 :
            prepareJulia()
        case EQU_39_SURFBOX :
            prepareJulia()
            c.dx = c.cx * c.cy  // foldMod
        case EQU_43_DARKSURF, EQU_48_FLORAL :
            c.n1 = float3(c.dx,c.dy,c.dz)
            c.n2 = float3(c.ex,c.ey,c.ez)
            c.n3 = float3(c.fx,c.fy,c.fz)
        default : break
        }
        
        controlBuffer.contents().copyMemory(from:&c, byteCount:MemoryLayout<Control>.stride)
        
        let start = NSDate()
        
        let commandBuffer = commandQueue?.makeCommandBuffer()!
        let renderEncoder = commandBuffer!.makeComputeCommandEncoder()!
        renderEncoder.setComputePipelineState(pipeline[PIPELINE_FRACTAL])
        renderEncoder.setTexture(drawable.texture, index: 0)
        renderEncoder.setTexture(coloringTexture,  index: 1)
        renderEncoder.setBuffer(controlBuffer, offset: 0, index: 0)
        renderEncoder.setBuffer(vBuffer,       offset: 0, index: 1)
        renderEncoder.dispatchThreads(threadsPerGrid[PIPELINE_FRACTAL], threadsPerThreadgroup:threadsPerGroup[PIPELINE_FRACTAL])
        renderEncoder.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        if control.skip > 1 {   // 'fast' renders will have ~50% utilization
            timeInterval = NSDate().timeIntervalSince(start as Date)
        }
        
        // -------------------------------------
        if vc3D != nil {  // 3D window is active. calc vertex normals for newly updated vertices
            let commandBuffer = commandQueue?.makeCommandBuffer()!
            let commandEncoder = commandBuffer!.makeComputeCommandEncoder()!
            commandEncoder.setComputePipelineState(pipeline[PIPELINE_NORMAL])
            
            commandEncoder.setBuffer(vBuffer, offset: 0, index: 0)
            commandEncoder.dispatchThreads(threadsPerGrid[PIPELINE_NORMAL], threadsPerThreadgroup:threadsPerGroup[PIPELINE_NORMAL])
            commandEncoder.endEncoding()
            commandBuffer?.commit()
            commandBuffer?.waitUntilCompleted()
        }
        
        if !mvr.saveVideoFrame(drawable.texture) { displayWidgets() } // false = finished session. repaint instructions
    }
    
    //MARK: -
    
    var pt1 = NSPoint()
    var pt2 = NSPoint()
    
    override func mouseDown     (with event: NSEvent) { pt1 = event.locationInWindow }
    override func mouseDragged  (with event: NSEvent) { pt2 = event.locationInWindow }
    
    // if 3D window is active: users has dragged a 3D region of interest (ROI) with left mouse button
    override func mouseUp(with event: NSEvent) {
        if vc3D != nil {
            control.xmin3D = uint(min(pt1.x,pt2.x) * 2)
            control.xmax3D = uint(max(pt1.x,pt2.x) * 2)
            control.ymax3D = uint(control.ySize - Int32(min(pt1.y,pt2.y) * 2))
            control.ymin3D = uint(control.ySize - Int32(max(pt1.y,pt2.y) * 2))
            
            func ensureSizeAndBounds(_ v1:inout uint, _ v2:inout uint, _ sz:Int32) {
                if v2 - v1 < SIZE3D {
                    v2 = v1 + uint(SIZE3D)
                    if v2 >= sz {
                        v1 = uint(sz - Int32(SIZE3D + 1))
                        v2 = v1 + uint(SIZE3D)
                    }
                }
            }
            
            ensureSizeAndBounds(&control.xmin3D,&control.xmax3D,control.xSize)
            ensureSizeAndBounds(&control.ymin3D,&control.ymax3D,control.ySize)
            flagViewsToRecalcFractal()
        }
    }
    
    //MARK: -
    
    func presentPopover(_ name:String) {
        let mvc = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let vc = mvc.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(name)) as! NSViewController
        self.present(vc, asPopoverRelativeTo: view.bounds, of: view, preferredEdge: .minX, behavior: .transient)
    }
    
    override func keyDown(with event: NSEvent) {
        func toggle(_ v:inout Bool) { v = !v;    defineWidgetsForCurrentEquation(); flagViewsToRecalcFractal() }
        
        super.keyDown(with: event)
        widget.updateAlterationSpeed(event)
        
        switch event.keyCode {
        case 115 : // home
            presentPopover("SaveLoadVC")
            return
        case 116 : // page up
            helpIndex = 0
            presentPopover("HelpVC")
            return
        case 119 : // end
            let s = SaveLoadViewController()
            s.loadNext()
            controlJustLoaded()
            return
        case 121 : // page down
            toggleDisplayOfCompanion3DView()
            return
        default : break
        }
        
        switch event.charactersIgnoringModifiers!.uppercased() {
        case "O" :
            presentPopover("EquationPickerVC")
            return
        case "\\" : // set focus to 3D window
            if vc3D != nil {
                vc3D.view.window?.makeMain()
                vc3D.view.window?.makeKey()
            }
        case "0" :
            view.window?.toggleFullScreen(self)
            isFullScreen = !isFullScreen
            updateLayoutOfChildViews()
        case "1" : changeEquationIndex(-1)
        case "2" : changeEquationIndex(+1)
        case "3" :
            isStereo = !isStereo
            adjustWindowSizeForStereo()
            defineWidgetsForCurrentEquation()
            flagViewsToRecalcFractal()
        case "4","$" : jogCameraPosition(float3(-1,0,0))
        case "5","%" : jogCameraPosition(float3(+1,0,0))
        case "6","^" : jogCameraPosition(float3(0,-1,0))
        case "7","&" : jogCameraPosition(float3(0,+1,0))
        case "8","*" : jogCameraPosition(float3(0,0,-1))
        case "9","(" : jogCameraPosition(float3(0,0,+1))
        case "?","/" : fastRenderEnabled = !fastRenderEnabled
            
        case "B" : toggle(&control.showBalls)
        case "F" : toggle(&control.fourGen)
        case "I" : toggle(&control.doInversion)
        case "J" : toggle(&control.juliaboxMode)
        case "K" : toggle(&control.AlternateVersion)
        case "P" :
            if control.txtOnOff {
                control.txtOnOff = false
                defineWidgetsForCurrentEquation()
                flagViewsToRecalcFractal()
            }
            else {
                loadImageFile()
            }
            
        case " " : instructions.isHidden = !instructions.isHidden
        case "X" : isChangingViewVector = !isChangingViewVector
        case "H" : setControlParametersToRandomValues(); flagViewsToRecalcFractal()
        case "V" : displayControlParametersInConsoleWindow()
        case "Q" :
            toggle(&control.polygonate)
            toggle(&control.preabsx)
        case "W" :
            toggle(&control.polyhedronate)
            toggle(&control.preabsy)
        case "E" :
            toggle(&control.TotallyTubular)
            toggle(&control.preabsz)
        case "R" :
            toggle(&control.Sphere)
            toggle(&control.absx)
        case "T" :
            toggle(&control.HoleSphere)
            toggle(&control.absy)
        case "Y" :
            toggle(&control.unSphere)
            toggle(&control.absz)
        case "U" :
            toggle(&control.gravity)
            toggle(&control.UseDeltaDE)
        case "G" :
            control.colorScheme += 1
            if control.colorScheme > 4 { control.colorScheme = 0 }
            flagViewsToRecalcFractal()
        case ",","<" : adjustWindowSize(-1)
        case ".",">" : adjustWindowSize(+1)
        case "[" : mvr.addKeyFrame()
        case "]" : mvr.finishRecording()
        default : break
        }
        
        if widget.keyPress(event) { setShaderToFastRender() }
    }
    
    /// update 2D fractal camera position
    func jogCameraPosition(_ direction:float3) {
        let amount:float3 = direction * alterationSpeed * 0.01
        
        if isChangingViewVector {
            let s = toSpherical(control.viewVector) + amount
            updateShaderDirectionVector(toRectangular(s))
        }
        else {
            control.camera += amount
        }
        
        setShaderToFastRender()
        flagViewsToRecalcFractal()
    }
    
    /// toggle display of companion 3D window
    func toggleDisplayOfCompanion3DView() {
        control.win3DFlag = control.win3DFlag > 0 ? 0 : 1
        
        if control.win3DFlag > 0 {
            if win3D == nil {
                let mainStoryboard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
                win3D = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Win3D")) as? NSWindowController
            }
            
            control.xmin3D = uint(control.xSize * 3 / 8) // default 3D window region of interest
            control.xmax3D = uint(control.xSize * 5 / 8)
            control.ymin3D = uint(control.ySize * 3 / 8)
            control.ymax3D = uint(control.ySize * 5 / 8)
            win3D.showWindow(self)
        }
        else {
            win3D.close()
        }
        
        flagViewsToRecalcFractal() // redraw 2D so that ROI rectangle is drawn (or erased)
    }
    
    /// press 'V' to display control parameter values in console window
    func displayControlParametersInConsoleWindow() {
        print("control.camera =",control.camera.debugDescription)
        print("control.cx =",control.cx)
        print("control.cy =",control.cy)
        print("control.cz =",control.cz)
        print("control.cw =",control.cw)
        print("control.dx =",control.dx)
        print("control.dy =",control.dy)
        print("control.dz =",control.dz)
        print("control.dw =",control.dw)
        print("control.ex =",control.ex)
        print("control.ey =",control.ey)
        print("control.ez =",control.ez)
        print("control.ew =",control.ew)
        print("control.fx =",control.fx)
        print("control.fy =",control.fy)
        print("control.fz =",control.fz)
        print("control.fw =",control.fw)
        
        print("control.fMaxSteps =",control.fMaxSteps)
        
        print("control.angle1 =",control.angle1)
        print("control.angle2 =",control.angle2)
        print("control.juliaX = ",control.juliaX)
        print("control.juliaY = ",control.juliaY)
        print("control.juliaZ = ",control.juliaZ)
        print("control.power =",control.power)
        
        print("control.bright =",control.bright)
        print("control.contrast =",control.contrast)
        print("control.specular =",control.specular)
        
        print("updateShaderDirectionVector(",control.viewVector.debugDescription,")")
    }
    
    /// press 'H" to set control parameters to random values
    func setControlParametersToRandomValues() {
        func fRandom() -> Float { return Float.random(in: -1 ..< 0) }
        func fRandom2() -> Float { return Float.random(in: 0 ..< 1) }
        func fRandom3() -> Float { return Float.random(in: -5 ..< 5) }
        
        //control.camera.x = Float.random(in: -2 ..< 2)
        //control.camera.y = Float.random(in: -2 ..< 2)
        //control.camera.z = Float.random(in: -2 ..< 2)
        control.cx = fRandom3()
        control.cy = fRandom3()
        control.cz = fRandom3()
        control.cw = fRandom3()
        control.dx = fRandom3()
        control.dy = fRandom3()
        control.dz = fRandom3()
        control.dw = fRandom3()
        control.ex = fRandom3()
        control.ey = fRandom3()
        control.ez = fRandom3()
        control.ew = fRandom3()
        control.fx = fRandom3()
        control.fy = fRandom3()
        control.fz = fRandom3()
        control.fw = fRandom3()
    }
    
    //MARK: -
    
    /// alter equation selection, reset it's parameters, display it's widgets, calculate fractal
    func changeEquationIndex(_ dir:Int) {
        control.equation += Int32(dir)
        if control.equation >= EQU_MAX { control.equation = 0 } else
            if control.equation < 0 { control.equation = Int32(EQU_MAX - 1) }
        reset()
        defineWidgetsForCurrentEquation()
        flagViewsToRecalcFractal()
    }
    
    /// define widget entries for current equation
    func defineWidgetsForCurrentEquation() {
        func juliaGroup(_ range:Float = 10, _ delta:Float = 1) {
            if control.juliaboxMode {
                widget.addEntry("Julia X",&control.juliaX,-range,range, delta)
                widget.addEntry("Julia Y",&control.juliaY,-range,range, delta)
                widget.addEntry("Julia Z",&control.juliaZ,-range,range, delta)
            }
        }
        
        widget.reset()
        
        if isStereo { widget.addEntry("Parallax",&parallax,0.001,1,0.01) }
        widget.addEntry("Bright",&control.bright,0.01,10,0.1)
        widget.addEntry("Contrast",&control.contrast,0.1,0.7,0.02)
        widget.addEntry("Specular",&control.specular,0,2,0.1)
        widget.addEntry("Light Position",&lightAngle,-3,3,0.3)
        
        if control.txtOnOff {
            widget.addEntry("Texture Center X",&tCenterX,0.01,1,0.02)
            widget.addEntry("Texture Center Y",&tCenterY,0.01,1,0.02)
            widget.addEntry("Texture Scale",&tScale,0.01,1,0.02)
        }
        
        switch Int(control.equation) {
        case EQU_01_MANDELBULB :
            widget.addEntry("Iterations",&control.fMaxSteps,3,30,1)
            widget.addEntry("Power",&control.power,1.5,12,0.02)
            juliaGroup()
            control.juliaboxMode = true
        case EQU_02_APOLLONIAN, EQU_03_APOLLONIAN2 :
            widget.addEntry("Iterations",&control.fMaxSteps,2,10,1)
            widget.addEntry("Multiplier",&control.multiplier,10,300,0.2)
            widget.addEntry("Foam",&control.foam,0.1,3,0.02)
            widget.addEntry("Foam2",&control.foam2,0.1,3,0.02)
            widget.addEntry("Bend",&control.bend,0.01,0.03,0.0001)
        case EQU_04_KLEINIAN :
            widget.addEntry("Final Iterations",&control.fFinal_Iterations, 1,39,1)
            widget.addEntry("Box Iterations",&control.fBox_Iterations,1,10,1)
            widget.addEntry("Box Size X",&control.box_size_x, 0.01,2,0.006)
            widget.addEntry("Box Size Z",&control.box_size_z, 0.01,2,0.006)
            widget.addEntry("Klein R",&control.KleinR, 0.01,2.5,0.005)
            widget.addEntry("Klein I",&control.KleinI, 0.01,2.5,0.005)
            
            if control.doInversion {
                widget.addEntry("InvCenter X",&control.InvCx,0,1.5,0.02)
                widget.addEntry("InvCenter Y",&control.InvCy,0,1.5,0.02)
                widget.addEntry("InvCenter Z",&control.InvCz,0,1.5,0.02)
                widget.addEntry("Inv Radius",&control.InvRadius, 0.01,4,0.01)
            }
            
            widget.addEntry("Delta Angle",&control.DeltaAngle, 0.1,10,0.004)
            widget.addEntry("Clamp Y",&control.Clamp_y, 0.001,2,0.01)
            widget.addEntry("Clamp DF",&control.Clamp_DF, 0.001,2,0.03)
        case EQU_05_MANDELBOX :
            widget.addEntry("Iterations",&control.fMaxSteps,3,60,1)
            widget.addEntry("Scale Factor",&control.power,0.6,10,0.02)
            widget.addEntry("Box",&control.cx, 0,10,0.001)
            widget.addEntry("Sphere 1",&control.cz, 0,4,0.01)
            widget.addEntry("Sphere 2",&control.cw, 0,4,0.01)
            juliaGroup(10,0.01)
        case EQU_06_QUATJULIA :
            widget.addEntry("Iterations",&control.fMaxSteps,3,10,1)
            widget.addEntry("X",&control.cx,-5,5,0.05)
            widget.addEntry("Y",&control.cy,-5,5,0.05)
            widget.addEntry("Z",&control.cz,-5,5,0.05)
            widget.addEntry("W",&control.cw,-5,5,0.05)
        case EQU_07_MONSTER :
            widget.addEntry("Iterations",&control.fMaxSteps,3,30,1)
            widget.addEntry("X",&control.cx,-500,500,0.5)
            widget.addEntry("Y",&control.cy,3.5,7,0.03)
            widget.addEntry("Z",&control.cz,0.45,2.8,0.01)
            widget.addEntry("Scale",&control.cw,1,1.6,0.003)
        case EQU_08_KALI_TOWER :
            widget.addEntry("Iterations",&control.fMaxSteps,2,7,1)
            widget.addEntry("X",&control.cx,0.01,10,0.05)
            widget.addEntry("Y",&control.cy,0,30,0.1)
            widget.addEntry("Twist",&control.cz,0,5,0.1)
            widget.addEntry("Waves",&control.cw,0.1,0.34,0.01)
        case EQU_09_POLY_MENGER :
            widget.addEntry("Menger",&control.cy,1.1,2.9,0.05)
            widget.addEntry("Stretch",&control.cz,0,10,0.05)
            widget.addEntry("Spin",&control.cw,0.1,5,0.05)
            widget.addEntry("Twist",&control.cx, 0.5,7,0.05)
            widget.addEntry("Shape",&control.dx, 0.1,50,0.2)
        case EQU_10_GOLD :
            widget.addEntry("X",&control.cx,-5,5,0.01)
            widget.addEntry("Y",&control.cy,-5,5,0.01)
            widget.addEntry("Z",&control.cz,-5,5,0.01)
        case EQU_11_SPIDER :
            widget.addEntry("X",&control.cx,0.001,5,0.01)
            widget.addEntry("Y",&control.cy,0.001,5,0.01)
            widget.addEntry("Z",&control.cz,0.001,5,0.01)
        case EQU_12_KLEINIAN2 :
            widget.addEntry("Shape",&control.power,0.01,2,0.005)
            widget.addEntry("minX",&control.cx,-5,5,0.01)
            widget.addEntry("minY",&control.cy,-5,5,0.01)
            widget.addEntry("minZ",&control.cz,-5,5,0.01)
            widget.addEntry("minW",&control.cw,-5,5,0.01)
            widget.addEntry("maxX",&control.dx,-5,5,0.01)
            widget.addEntry("maxY",&control.dy,-5,5,0.01)
            widget.addEntry("maxZ",&control.dz,-5,5,0.01)
            widget.addEntry("maxW",&control.dw,-5,5,0.01)
        case EQU_13_KIFS :
            widget.addEntry("Iterations",&control.fMaxSteps,2,8,1)
            widget.addEntry("X",&control.cx,0.44,7,0.05)
            widget.addEntry("Y",&control.cy,0.9,7,0.05)
            widget.addEntry("Z",&control.cz,0.9,5.75,0.1)
        case EQU_14_IFS_TETRA :
            widget.addEntry("Scale",&control.cx,1.45,2.5,0.01)
            widget.addEntry("Angle1",&control.angle1,-2,2,0.02)
            widget.addEntry("Angle2",&control.angle2,-2,2,0.02)
        case EQU_15_IFS_OCTA :
            widget.addEntry("Scale",&control.cx,1.45,2.5,0.01)
            widget.addEntry("Angle1",&control.angle1,-2,2,0.02)
            widget.addEntry("Angle2",&control.angle2,-2,2,0.02)
        case EQU_16_IFS_DODEC :
            widget.addEntry("Scale",&control.cx,1.8,3.6,0.02)
            widget.addEntry("Normal",&control.cy,1.03,4,0.02)
            widget.addEntry("Angle1",&control.angle1,-2,2,0.1)
            widget.addEntry("Angle2",&control.angle2,-2,2,0.1)
        case EQU_17_IFS_MENGER :
            widget.addEntry("Iterations",&control.fMaxSteps,3,7,1)
            widget.addEntry("Scale",&control.cx,0.04,8.86,0.02)
            widget.addEntry("Y",&control.cy,-0.6,0.75,0.01)
            widget.addEntry("Angle",&control.angle1,-2,2,0.1)
        case EQU_18_SIERPINSKI :
            widget.addEntry("Iterations",&control.fMaxSteps,11,40,1)
            widget.addEntry("Scale",&control.cx,1.18,1.8,0.02)
            widget.addEntry("Y",&control.cy,0.5,3,0.02)
            widget.addEntry("Angle1",&control.angle1,-4,4,0.01)
            widget.addEntry("Angle2",&control.angle2,-4,4,0.01)
        case EQU_19_HALF_TETRA :
            widget.addEntry("Iterations",&control.fMaxSteps,9,50,1)
            widget.addEntry("Scale",&control.cx,1.12,1.5,0.02)
            widget.addEntry("Y",&control.cy,2,10,0.1)
            widget.addEntry("Angle1",&control.angle1,-4,4,0.01)
            widget.addEntry("Angle2",&control.angle2,-4,4,0.01)
        case EQU_20_FULL_TETRA :
            widget.addEntry("Iterations",&control.fMaxSteps,21,70,1)
            widget.addEntry("Scale",&control.cx,1.06,1.16,0.005)
            widget.addEntry("Y",&control.cy,4.6,20,0.1)
            widget.addEntry("Angle1",&control.angle1,-4,4,0.025)
            widget.addEntry("Angle2",&control.angle2,-4,4,0.025)
        case EQU_21_CUBIC :
            widget.addEntry("Iterations",&control.fMaxSteps,13,80,1)
            widget.addEntry("Scale",&control.cx,1,2,0.01)
            widget.addEntry("Y",&control.cy,0.5,4,0.02)
            widget.addEntry("Angle1",&control.angle1,-4,4,0.025)
            widget.addEntry("Angle2",&control.angle2,-4,4,0.025)
        case EQU_22_HALF_OCTA :
            widget.addEntry("Iterations",&control.fMaxSteps,13,80,1)
            widget.addEntry("Scale",&control.cx,1,1.6,0.004)
            widget.addEntry("Y",&control.cy,0.4,1,0.004)
            widget.addEntry("Angle1",&control.angle1,-4,4,0.025)
            widget.addEntry("Angle2",&control.angle2,-4,4,0.025)
        case EQU_23_FULL_OCTA :
            widget.addEntry("Iterations",&control.fMaxSteps,13,80,1)
            widget.addEntry("Scale",&control.cx,1,1.6,0.004)
            widget.addEntry("Y",&control.cy,0.4,1,0.004)
            widget.addEntry("Angle1",&control.angle1,-4,4,0.025)
            widget.addEntry("Angle2",&control.angle2,-4,4,0.025)
        case EQU_24_KALEIDO :
            widget.addEntry("Iterations",&control.fMaxSteps,10,200,1)
            widget.addEntry("Scale",&control.cx,0.5,2,0.0005)
            widget.addEntry("Y",&control.cy,-5,5,0.004)
            widget.addEntry("Z",&control.cz,-5,5,0.004)
            widget.addEntry("Angle1",&control.angle1,-4,4,0.005)
            widget.addEntry("Angle2",&control.angle2,-4,4,0.005)
        case EQU_25_POLYCHORA :
            widget.addEntry("Distance 1",&control.cx,-2,10,0.1)
            widget.addEntry("Distance 2",&control.cy,-2,10,0.1)
            widget.addEntry("Distance 3",&control.cz,-2,10,0.1)
            widget.addEntry("Distance 4",&control.cw,-2,10,0.1)
            widget.addEntry("Ball",&control.dx,0,0.35,0.02)
            widget.addEntry("Stick",&control.dy,0,0.35,0.02)
            widget.addEntry("Spin",&control.dz,-15,15,0.05)
        case EQU_26_QUADRAY :
            widget.addEntry("Iterations",&control.fMaxSteps,1,20,1)
            widget.addEntry("X",&control.cx,-15,15,0.05)
            widget.addEntry("Y",&control.cy,-15,15,0.05)
        case EQU_27_FRAGM :
            widget.addDash("MandelBulb")
            widget.addEntry("Iterations",&control.fMaxSteps,0,20,1,.integer,true)
            widget.addEntry("Power",&control.power,1,12,0.1)
            juliaGroup(10,0.005)
            widget.addDash("Sphere Menger")
            widget.addEntry("Iterations",&control.fmsIterations,0,20,1,.integer,true)
            widget.addEntry("Shape",&control.cx,-0.6,2.5,0.003)
            widget.addEntry("Angle",&control.angle2,-4,4,0.006)
            widget.addDash("MandelBox")
            widget.addEntry("Iterations",&control.fmbIterations,0,20,1,.integer,true)
            widget.addEntry("Angle",&control.angle1,-4,4,0.002)
        case EQU_28_QUATJULIA2 :
            widget.addEntry("Iterations",&control.fMaxSteps,3,10,1)
            widget.addEntry("Mul",&control.cx,-5,5,0.05)
            widget.addEntry("Offset X",&control.juliaX,-15,15,0.1)
            widget.addEntry("Offset Y",&control.juliaY,-15,15,0.1)
            widget.addEntry("Offset Z",&control.juliaZ,-15,15,0.1)
        case EQU_29_MBROT :
            widget.addEntry("Iterations",&control.fMaxSteps,3,10,1)
            widget.addEntry("Offset",&control.cx,-5,5,0.05)
            widget.addEntry("Rotate X",&control.juliaX,-15,15,0.1)
            widget.addEntry("Rotate Y",&control.juliaY,-15,15,0.1)
            widget.addEntry("Rotate Z",&control.juliaZ,-15,15,0.1)
        case EQU_30_KALIBOX :
            widget.addEntry("Iterations",&control.fMaxSteps,3,30,1)
            widget.addEntry("Scale",&control.cx,-5,5,0.05)
            widget.addEntry("MinRad2",&control.cy,-5,5,0.05)
            widget.addEntry("Trans X",&control.dx,-15,15,0.01)
            widget.addEntry("Trans Y",&control.dy,-15,15,0.01)
            widget.addEntry("Trans Z",&control.dz,-1,5,0.01)
            widget.addEntry("Angle",&control.angle1,-4,4,0.02)
            juliaGroup()
        case EQU_31_SPUDS :
            widget.addEntry("Iterations",&control.fMaxSteps,3,30,1)
            widget.addEntry("Power",&control.power,1.5,12,0.1)
            widget.addEntry("MinRad",&control.cx,-5,5,0.1)
            widget.addEntry("FixedRad",&control.cy,-5,5,0.02)
            widget.addEntry("Fold Limit",&control.cz,-5,5,0.02)
            widget.addEntry("Fold Limit2",&control.cw,-5,5,0.02)
            widget.addEntry("ZMUL",&control.dx,-5,5,0.1)
            widget.addEntry("Scale",&control.dz,-5,5,0.1)
            widget.addEntry("Scale2",&control.dw,-5,5,0.1)
        case EQU_32_MPOLY :
            if control.polygonate { widget.addEntry("# Sides",&control.cx,0,15,0.1) }
            if control.polyhedronate { widget.addEntry("# Sides2",&control.cy,0,15,0.1) }
            if control.gravity { widget.addEntry("Gravity",&control.cw,-5,5,0.02) }
            widget.addEntry("Scale",&control.cz,-5,5,0.02)
            widget.addEntry("Offset",&control.dx,-5,5,0.01)
            widget.addEntry("Angle",&control.angle1,-4,4,0.02)
        case EQU_33_MHELIX :
            widget.addEntry("Iterations",&control.fMaxSteps,2,30,1)
            widget.addEntry("Scale",&control.cx,0.89,1.1,0.001)
            widget.addEntry("Angle",&control.angle1,-4,4,0.1)
            widget.addEntry("scaleX",&control.juliaX,-50,50, 2)
            widget.addEntry("scaleY",&control.juliaY,-50,50, 2)
            widget.addEntry("scaleZ",&control.juliaZ,-50,50, 2)
        case EQU_34_FLOWER :
            widget.addEntry("Iterations",&control.fMaxSteps,2,30,1)
            widget.addEntry("Scale",&control.cx,0.5,3,0.01)
            widget.addEntry("Offset X",&control.juliaX,-15,15,0.1)
            widget.addEntry("Offset Y",&control.juliaY,-15,15,0.1)
            widget.addEntry("Offset Z",&control.juliaZ,-15,15,0.1)
        case EQU_35_JUNGLE :
            widget.addEntry("Iterations",&control.fMaxSteps,1,12,1)
            widget.addEntry("X",&control.cx,0.1,5,0.01)
            widget.addEntry("Y",&control.cy,0.01,2,0.005)
            widget.addEntry("Pattern",&control.cz,1,20,0.7)
            widget.addEntry("Sabs",&control.cw,2,6,0.03)
        case EQU_36_PRISONER :
            widget.addEntry("Iterations",&control.fMaxSteps,1,12,1)
            widget.addEntry("Power",&control.power,1.5,12,0.1)
            widget.addEntry("Angle",&control.angle1,-4,4,0.02)
            widget.addEntry("Cage",&control.cx,0.6,2.8,0.01)
            widget.addEntry("Thickness",&control.cy,1,10,0.02)
        case EQU_37_SPIRALBOX :
            widget.addEntry("Iterations",&control.fMaxSteps,6,20,1)
            widget.addEntry("Fold",&control.cx,0.5,1,0.003)
            if control.juliaboxMode {
                widget.addEntry("Julia X",&control.juliaX,-2,2, 0.1)
                widget.addEntry("Julia Y",&control.juliaY,-2,2, 0.1)
                widget.addEntry("Julia Z",&control.juliaZ,-2,2, 0.1)
            }
        case EQU_38_ALEK_BULB :
            control.juliaboxMode = true
            widget.addEntry("Iterations",&control.fMaxSteps,3,30,1)
            widget.addEntry("Power",&control.power,1.5,12,0.02)
            juliaGroup(1.6,0.01)
        case EQU_39_SURFBOX :
            widget.addEntry("Iterations",&control.fMaxSteps,3,20,1)
            widget.addEntry("Scale Factor",&control.power,0.6,3,0.02)
            widget.addEntry("Box 1",&control.cx, 0,3,0.002)
            widget.addEntry("Box 2",&control.cy, 4,5.6,0.002)
            widget.addEntry("Sphere 1",&control.cz, 0,4,0.01)
            widget.addEntry("Sphere 2",&control.cw, 0,4,0.01)
            juliaGroup(10,0.01)
        case EQU_40_TWISTBOX :
            widget.addEntry("Iterations",&control.fMaxSteps,3,60,1)
            widget.addEntry("Scale Factor",&control.power,0.6,10,0.02)
            widget.addEntry("Box",&control.cx, 0,10,0.0001)
            juliaGroup(10,0.0001)
        case EQU_41_KALI_RONTGEN :
            widget.addEntry("Iterations",&control.fMaxSteps,1,30,1)
            widget.addEntry("X",&control.cx, -10,10,0.01)
            widget.addEntry("Y",&control.cy, -10,10,0.01)
            widget.addEntry("Z",&control.cz, -10,10,0.01)
            widget.addEntry("Angle",&control.angle1,-4,4,0.02)
        case EQU_42_VERTEBRAE :
            widget.addEntry("Iterations",&control.fMaxSteps,1,50,1)
            widget.addEntry("X",&control.cx,       -10,10,0.05)
            widget.addEntry("Y",&control.cy,       -10,10,0.05)
            widget.addEntry("Z",&control.cz,       -10,10,0.05)
            widget.addEntry("W",&control.cw,       -10,10,0.05)
            widget.addEntry("ScaleX",&control.dx,  -10,10,0.05)
            widget.addEntry("Sine X",&control.dw,  -10,10,0.05)
            widget.addEntry("Offset X",&control.ez,-10,10,0.05)
            widget.addEntry("Slope X",&control.fy, -10,10,0.05)
            widget.addEntry("ScaleY",&control.dy,  -10,10,0.05)
            widget.addEntry("Sine Y",&control.ex,  -10,10,0.05)
            widget.addEntry("Offset Y",&control.ew,-10,10,0.05)
            widget.addEntry("Slope Y",&control.fz, -10,10,0.05)
            widget.addEntry("ScaleZ",&control.dz,  -10,10,0.05)
            widget.addEntry("Sine Z",&control.ey,  -10,10,0.05)
            widget.addEntry("Offset Z",&control.fx,-10,10,0.05)
            widget.addEntry("Slope Z",&control.fw, -10,10,0.05)
        case EQU_43_DARKSURF :
            widget.addEntry("Iterations",&control.fMaxSteps,2,10,1)
            widget.addEntry("scale",&control.cx,    -10,10,0.002)
            widget.addEntry("MinRad",&control.cy,   -10,10,0.002)
            widget.addEntry("Scale",&control.cz,    -10,10,0.002)
            widget.addEntry("Fold X",&control.dx,   -10,10,0.002)
            widget.addEntry("Fold Y",&control.dy,   -10,10,0.002)
            widget.addEntry("Fold Z",&control.dz,   -10,10,0.002)
            widget.addEntry("FoldMod X",&control.ex,-10,10,0.002)
            widget.addEntry("FoldMod Y",&control.ey,-10,10,0.002)
            widget.addEntry("FoldMod Z",&control.ez,-10,10,0.002)
            widget.addEntry("Angle",&control.angle1,-4,4,0.002)
        case EQU_44_BUFFALO :
            widget.addEntry("Iterations",&control.fMaxSteps,2,60,1)
            widget.addEntry("Power",&control.cy,  0.1,30,0.01)
            widget.addEntry("Angle",&control.angle1,-4,4,0.01)
            
            if control.UseDeltaDE {
                widget.addEntry("DE Scale",&control.cx, 0,2,0.01)
            }
            juliaGroup(10,0.01)
        case EQU_45_TEMPLE :
            widget.addEntry("Iterations",&control.fMaxSteps,1,16,1)
            widget.addEntry("X",&control.cx,        -10,10,0.01)
            widget.addEntry("Y",&control.cy,        -10,10,0.01)
            widget.addEntry("Z",&control.dx,        -4,4,0.01)
            widget.addEntry("W",&control.dy,        -4,4,0.01)
            widget.addEntry("A1",&control.angle1,   -10,10,0.01)
            widget.addEntry("A2",&control.angle2,   -10,10,0.01)
            widget.addEntry("Ceiling",&control.cw,  -2,1,0.01)
            widget.addEntry("Floor",&control.cz,    -2,1,0.01)
        case EQU_46_KALI3 :
            widget.addEntry("Iterations",&control.fMaxSteps,3,60,1)
            widget.addEntry("Box",&control.cx, -10,10,0.001)
            juliaGroup(10,0.001)
        case EQU_47_SPONGE :
            widget.addEntry("Iterations",&control.fMaxSteps,1,16,1)
            widget.addEntry("minX",&control.cx,-5,5,0.01)
            widget.addEntry("minY",&control.cy,-5,5,0.01)
            widget.addEntry("minZ",&control.cz,-5,5,0.01)
            widget.addEntry("minW",&control.cw,-5,5,0.01)
            widget.addEntry("maxX",&control.dx,-5,5,0.01)
            widget.addEntry("maxY",&control.dy,-5,5,0.01)
            widget.addEntry("maxZ",&control.dz,-5,5,0.01)
            widget.addEntry("maxW",&control.dw,-5,5,0.01)
            widget.addEntry("Scale",&control.ex,1,20,1)
            widget.addEntry("Shape",&control.ey,-10,10,0.1)
        case EQU_48_FLORAL :
            widget.addEntry("Iterations",&control.fMaxSteps,2,20,1)
            widget.addEntry("X",&control.cx,        -20,20,0.005)
            widget.addEntry("Y",&control.cy,        -20,20,0.005)
            widget.addEntry("CSize X",&control.dx,  -20,20,0.005)
            widget.addEntry("CSize Y",&control.dy,  -20,20,0.005)
            widget.addEntry("CSize Z",&control.dz,  -20,20,0.005)
            widget.addEntry("C1    X",&control.ex,  -20,20,0.005)
            widget.addEntry("C1    Y",&control.ey,  -20,20,0.005)
            widget.addEntry("C1    Z",&control.ez,  -20,20,0.005)
            widget.addEntry("Offset X",&control.fx, -20,20,0.005)
            widget.addEntry("Offset Y",&control.fy, -20,20,0.005)
            widget.addEntry("Offset Z",&control.fz, -20,20,0.005)
        case EQU_49_KNOT :
            widget.addEntry("Iterations",&control.fMaxSteps,2,50,1)
            widget.addEntry("Length",&control.cx, 0.1,10,0.05)
            widget.addEntry("Twist",&control.cy,  -20,20,0.05)
            widget.addEntry("Size",&control.cz,   -20,20,0.05)
        case EQU_50_DONUTS :
            widget.addEntry("Iterations",&control.fMaxSteps,1,5,1)
            widget.addEntry("X",&control.cx, 0.01,20,0.05)
            widget.addEntry("Y",&control.cy, 0.01,20,0.05)
            widget.addEntry("Z",&control.cz, 0.01,20,0.05)
            widget.addEntry("Spread",&control.dx, 0.01,2,0.01)
            widget.addEntry("Mult",&control.dy, 0.01,2,0.01)
        default : break  // zorro
        }
        
        displayWidgets()
        updateWindowTitle()
    }
    
    func displayWidgets() {
        let str = NSMutableAttributedString()
        
        func booleanEntry(_ onoff:Bool, _ legend:String) { str.normal(legend + (onoff ? " = true" : " = false")) }
        func juliaEntry() {
            booleanEntry(control.juliaboxMode,"J: Julia Mode")
            str.normal("")
        }
        
        switch Int(control.equation) {
        case EQU_04_KLEINIAN :
            booleanEntry(control.showBalls,"B: ShowBalls")
            booleanEntry(control.fourGen,"F: FourGen")
            booleanEntry(control.doInversion,"I: Do Inversion")
            str.normal("")
        case EQU_30_KALIBOX, EQU_37_SPIRALBOX :
            juliaEntry()
        case EQU_27_FRAGM :
            booleanEntry(control.AlternateVersion,"K: Alternate Version")
            juliaEntry()
        case EQU_32_MPOLY :
            booleanEntry(control.polygonate,"Q: polygonate")
            booleanEntry(control.polyhedronate,"W: polyhedronate")
            booleanEntry(control.TotallyTubular,"E: TotallyTubular")
            booleanEntry(control.Sphere,"R: Sphere")
            booleanEntry(control.HoleSphere,"T: HoleSphere")
            booleanEntry(control.unSphere,"Y: unSphere")
            booleanEntry(control.gravity,"U: gravity")
        case EQU_33_MHELIX :
            booleanEntry(control.gravity,"U: Moebius")
            str.normal("")
        case EQU_05_MANDELBOX :
            booleanEntry(control.doInversion,"I: Box Fold both sides")
            juliaEntry()
        case EQU_44_BUFFALO :
            booleanEntry(control.preabsx,"Q: Pre Abs X")
            booleanEntry(control.preabsy,"W: Pre Abs Y")
            booleanEntry(control.preabsz,"E: Pre Abs Z")
            booleanEntry(control.absx,"R: Abs X")
            booleanEntry(control.absy,"T: Abs Y")
            booleanEntry(control.absz,"Y: Abs Z")
            booleanEntry(control.UseDeltaDE,"U: Delta DE")
            juliaEntry()
        default : break
        }
        
        widget.addinstructionEntries(str)
        
        instructions.attributedStringValue = str
    }
    
    //MARK: -
    
    /// detemine shader threading settings for 2D and 3D windows (varies according to window size)
    func updateThreadGroupsAccordingToWindowSize() {
        var w = pipeline[PIPELINE_FRACTAL].threadExecutionWidth
        var h = pipeline[PIPELINE_FRACTAL].maxTotalThreadsPerThreadgroup / w
        threadsPerGroup[PIPELINE_FRACTAL] = MTLSizeMake(w, h, 1)
        
        let wxs = Int(metalViewL.bounds.width) * 2     // why * 2 ??
        let wys = Int(metalViewL.bounds.height) * 2
        control.xSize = Int32(wxs)
        control.ySize = Int32(wys)
        threadsPerGrid[PIPELINE_FRACTAL] = MTLSizeMake(wxs,wys,1)
        
        //------------------------
        w = pipeline[PIPELINE_NORMAL].threadExecutionWidth
        h = pipeline[PIPELINE_NORMAL].maxTotalThreadsPerThreadgroup / w
        threadsPerGroup[PIPELINE_NORMAL] = MTLSizeMake(w, h, 1)
        
        let sz:Int = Int(SIZE3D)
        threadsPerGrid[PIPELINE_NORMAL] = MTLSizeMake(sz,sz,1)
    }
    
    /// ensure initial 2D window size is large enough to display all widget entries
    func ensureWindowSizeIsNotTooSmall() {
        var r:CGRect = (view.window?.frame)!
        if r.size.width < 700 { r.size.width = 700 }
        if r.size.height < 700 { r.size.height = 700 }
        view.window?.setFrame(r, display:true)
    }
    
    /// toggling stereo viewing automatically adjusts window size to accomodate (unless we are already full screen)
    func adjustWindowSizeForStereo() {
        if !isFullScreen {
            var r:CGRect = (view.window?.frame)!
            r.size.width *= CGFloat(isStereo ? 2.0 : 0.5)
            view.window?.setFrame(r, display:true)
        }
        else {
            updateLayoutOfChildViews()
        }
    }
    
    /// key commands direct 2D window to grow/shrink
    func adjustWindowSize(_ dir:Int) {
        if !isFullScreen {
            var r:CGRect = (view.window?.frame)!
            let ratio:CGFloat = 1.0 + CGFloat(dir) * 0.1
            r.size.width *= ratio
            r.size.height *= ratio
            view.window?.setFrame(r, display:true)
            
            updateLayoutOfChildViews()
        }
    }
    
    /// 2D window has resized. adjust child views to fit.
    func updateLayoutOfChildViews() {
        var r:CGRect = view.frame
        
        if isFullScreen {
            r = NSScreen.main!.frame
            
            if isStereo {
                metalViewR.isHidden = false
                let xc:CGFloat = r.size.width/2 + 1
                metalViewL.frame = CGRect(x:0, y:0, width:xc, height:r.size.height)
                metalViewR.frame = CGRect(x:xc-1, y:0, width:xc, height:r.size.height)
            }
            else {
                metalViewR.isHidden = true
                metalViewL.frame = CGRect(x:0, y:0, width:r.size.width, height:r.size.height)
            }
        }
        else {
            let minWinSize:CGSize = CGSize(width:300, height:300)
            var changed:Bool = false
            
            if r.size.width < minWinSize.width {
                r.size.width = minWinSize.width
                changed = true
            }
            if r.size.height < minWinSize.height {
                r.size.height = minWinSize.height
                changed = true
            }
            
            if changed {  view.window?.setFrame(r, display:true) }
            
            if isStereo {
                metalViewR.isHidden = false
                let xc:CGFloat = r.size.width/2 + 1
                metalViewL.frame = CGRect(x:0, y:0, width:xc, height:r.size.height)
                metalViewR.frame = CGRect(x:xc-1, y:0, width:xc, height:r.size.height)
            }
            else {
                metalViewR.isHidden = true
                metalViewL.frame = CGRect(x:1, y:1, width:r.size.width-2, height:r.size.height-2)
            }
        }
        
        instructions.frame = CGRect(x:5, y:30, width:500, height:700)
        instructions.textColor = .white
        instructions.backgroundColor = .black
        instructions.bringToFront()
        
        updateThreadGroupsAccordingToWindowSize()
        flagViewsToRecalcFractal()
    }
    
    func windowDidResize(_ notification: Notification) { updateLayoutOfChildViews() }
    
    //MARK: -
    
    /// store just loaded .png picture to texture
    func loadTexture(from image: NSImage) -> MTLTexture {
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        
        let textureLoader = MTKTextureLoader(device: device)
        do {
            let textureOut = try textureLoader.newTexture(cgImage:cgImage)
            
            control.txtSize.x = Float(cgImage.width)
            control.txtSize.y = Float(cgImage.height)
            control.txtCenter = float3(repeating: 0.5)
            return textureOut
        }
        catch {
            fatalError("Can't load texture")
        }
    }
    
    /// launch file open dialog for picking .png picture for texturing
    func loadImageFile() {
        control.txtOnOff = false
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Select Image for Texture"
        openPanel.allowedFileTypes = ["jpg","png"]
        
        openPanel.beginSheetModal(for:self.view.window!) { (response) in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let selectedPath = openPanel.url!.path
                
                if let image:NSImage = NSImage(contentsOfFile: selectedPath) {
                    coloringTexture = self.loadTexture(from: image)
                    self.control.txtOnOff = true
                }
            }
            
            openPanel.close()
            
            if self.control.txtOnOff { // just loaded a texture
                self.defineWidgetsForCurrentEquation()
                self.flagViewsToRecalcFractal()
            }
        }
    }
}

// ===============================================

class BaseNSView: NSView {
    override var isFlipped: Bool { return true }
    override var acceptsFirstResponder: Bool { return true }
}

extension NSView {
    public func bringToFront() {
        let superlayer = self.layer?.superlayer
        self.layer?.removeFromSuperlayer()
        superlayer?.addSublayer(self.layer!)
    }
}

extension NSMutableAttributedString {
    @discardableResult func colored(_ text: String , _ color:NSColor) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [ NSAttributedString.Key.foregroundColor: color]
        let cString = NSMutableAttributedString(string:text + "\n", attributes: attrs)
        append(cString)
        return self
    }
    
    @discardableResult func normal(_ text: String) -> NSMutableAttributedString {
        let normal = NSAttributedString(string: text + "\n")
        append(normal)
        return self
    }
}
