import Cocoa
import Foundation
import MetalKit

var vc:ViewController! = nil
var win3D:NSWindowController! = nil
var winLight:NSWindowController! = nil
var videoRecorderWindow:NSWindowController! = nil
var controlBuffer:MTLBuffer! = nil
var coloringTexture:MTLTexture! = nil

var device: MTLDevice! = nil

class ViewController: NSViewController, NSWindowDelegate, MetalViewDelegate, WidgetDelegate {
    var control = Control()
    var widget:Widget! = nil
    var commandQueue: MTLCommandQueue?
    var pipeline:[MTLComputePipelineState] = []
    var threadsPerGroup:[MTLSize] = []
    var threadsPerGrid:[MTLSize] = []
    var isFullScreen:Bool = false
    var lightAngle:Float = 0
    var palletteIndex:Int = 0
    
    @IBOutlet var instructions: NSTextField!
    @IBOutlet var instructionsG: InstructionsG!
    @IBOutlet var metalView: MetalView!
    
    let PIPELINE_FRACTAL = 0
    let PIPELINE_NORMAL  = 1
    let shaderNames = [ "rayMarchShader","normalShader" ]
    
    //MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vc = self
        setControlPointer(&control)
    }
    
    override func viewDidAppear() {
        super.viewWillAppear()
        widget = Widget(0,self)
        instructionsG.initialize(widget)
        
        metalView.window?.delegate = self
        (metalView).delegate2 = self
        
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
        control.isStereo = false
        control.parallax = 0.003
        control.colorParam = 1
        
        reset()
        ensureWindowSizeIsNotTooSmall()
        
        flightReset()
        showLightWindow(true)
        vc.view.window!.makeKeyAndOrderFront(nil)  // bring focus back to main window

        Timer.scheduledTimer(withTimeInterval:0.033, repeats:true) { timer in self.timerHandler() }
        
        helpIndex = 0
        presentPopover("HelpVC")
    }
    
    func showLightWindow(_ onoff:Bool) {
        if onoff {
            if winLight == nil {
                let mainStoryboard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
                winLight = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Lights")) as? NSWindowController
            }
            winLight.showWindow(self)
        }
        else {
            if winLight != nil {
                winLight.close()
                winLight = nil
            }
        }
    }
    
    var fastRenderEnabled:Bool = true
    var slowRenderCountDown:Int = 0
    
    /// direct shader to sparsely calculate, and copy results to neighboring pixels, for faster fractal rendering
    func setShaderToFastRender() {
        if fastRenderEnabled {
            control.skip = max(control.xSize / 150, 8)
            slowRenderCountDown = 20 // 30 = 1 second
        }
    }
    
    /// direct 2D fractal view to re-calculate image on next draw call
    func flagViewToRecalcFractal() {
        metalView.viewIsDirty = true
    }
    
    /// ensure companion 3D window is also closed
    func windowWillClose(_ aNotification: Notification) {
        if let w = win3D { w.close() }
        if let l = winLight { l.close() }
        if let v = videoRecorderWindow { v.close() }
    }
    
    // 3D window just closed. reset window handle, reset "3D window active flag", repaint 2D to remove ROI box
    func win3DClosed() {
        win3D = nil
        control.win3DFlag = 0
        flagViewToRecalcFractal() // to erase bounding box
    }
        
    //MARK: -
    
    @objc func timerHandler() {
        var isDirty:Bool = (vr != nil) && vr.isRecording
        
        if performJog() { isDirty = true }
        
        if control.skip > 1 && slowRenderCountDown > 0 {
            slowRenderCountDown -= 1
            if slowRenderCountDown == 0 {
                control.skip = 1
                isDirty = true
            }
        }
        
        if isDirty {
            flagViewToRecalcFractal()
        }
    }
    
    //MARK: -
    
    func toRectangular(_ sph:simd_float3) -> simd_float3 {
        let ss = sph.x * sin(sph.z);
        return simd_float3( ss * cos(sph.y), ss * sin(sph.y), sph.x * cos(sph.z))
    }
    
    func toSpherical(_ rec:simd_float3) -> simd_float3 { return simd_float3(length(rec), atan2(rec.y,rec.x), atan2(sqrt(rec.x*rec.x+rec.y*rec.y), rec.z)) }
    
    func updateShaderDirectionVector(_ v:simd_float3) {
        control.viewVector = normalize(v)
        control.topVector = toSpherical(control.viewVector)
        control.topVector.z += 1.5708
        control.topVector = normalize(toRectangular(control.topVector))
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
        defineWidgetsForCurrentEquation()
        widget.focus = 0
        updateWindowTitle()
        flagViewToRecalcFractal()
    }
    
    /// load initial parameter values and view vectors for the current fractal (control.equation holds index)
    func reset() {
        updateShaderDirectionVector(simd_float3(0,0.1,1))
        control.bright = 1
        control.contrast = 0.5
        control.specular = 0
        control.angle1 = 0
        control.angle2 = 0
        control.colorParam = 25000
        control.radialAngle = 0
        control.InvCx = 0.1
        control.InvCy = 0.1
        control.InvCz = 0.1
        control.InvRadius = 0.3
        control.InvAngle = 0.1
        control.secondSurface = 0
        control.OrbitStrength = 0
        control.Cycles = 0
        control.orbitStyle = 0
        control.fog = 0
        
        switch Int(control.equation) {
        case EQU_01_MANDELBULB :
            updateShaderDirectionVector(simd_float3(0.010000015, 0.41950363, 0.64503753))
            control.camera = simd_float3(0.038563743, -1.1381346, -1.8405379)
            control.multiplier = 80
            control.power = 8
            control.fMaxSteps = 10
            
            if control.doInversion {
                control.camera = simd_float3( -0.138822 , -1.4459486 , -1.9716375 )
                updateShaderDirectionVector(simd_float3( 0.012995179 , 0.54515165 , 0.8382366 ))
                control.InvCenter = simd_float3( -0.10600001 , -0.74200004 , -1.3880001 )
                control.InvRadius =  2.14
                control.InvAngle =  0.9100002
            }
            
        case EQU_02_APOLLONIAN, EQU_03_APOLLONIAN2 :
            control.camera = simd_float3(0.42461035, 10.847559, 2.5749633)
            control.foam = 1.05265248
            control.foam2 = 1.06572711
            control.bend = 0.0202780124
            control.multiplier = 25
            control.fMaxSteps = 8
            
            if control.doInversion {
                control.camera = simd_float3(-4.4953876, -6.3138175, -29.144863)
                updateShaderDirectionVector(simd_float3(0.0, 0.09950372, 0.9950372))
                control.foam =  1.0326525
                control.foam2 =  0.9399999
                control.bend =  0.01
                control.InvCx = 0.56
                control.InvCy = 0.34
                control.InvCz = 0.46000004
                control.InvRadius = 2.7199993
            }
        case EQU_04_KLEINIAN :
            control.camera = simd_float3(0.5586236, 1.1723881, -1.8257363)
            control.fMaxSteps = 70
            control.fFinal_Iterations = 21
            control.fBox_Iterations = 17
            control.showBalls = true
            control.fourGen = false
            control.Clamp_y = 0.221299887
            control.Clamp_DF = 0.00999999977
            control.box_size_x = 0.6318979
            control.box_size_z = 1.3839532
            control.KleinR = 1.9324
            control.KleinI = 0.04583
            control.InvCenter = simd_float3(1.0517285, 0.7155759, 0.9883028)
            control.InvAngle = 5.5392437
            control.InvRadius = 2.06132293
            
            if control.doInversion {
                control.camera = simd_float3(-1.5613757, -0.61350304, 0.41508165)
                updateShaderDirectionVector(simd_float3(0.0, 0.09950372, 0.9950372))
                control.InvCx = -1.67399943
                control.InvCy = -0.494000345
                control.InvCz = 0.721998572
                control.InvAngle = 4.15921211
                control.InvRadius = 0.639999986
                control.box_size_z = 0.38800019
                control.box_size_x = 0.6880005
                control.KleinR = 1.97239995
                control.KleinI = 0.00999999977
                control.Clamp_y = 0.201299876
                control.Clamp_DF = 0.00999999977
            }
        case EQU_05_MANDELBOX :
            control.camera = simd_float3(-1.3771019, 0.9999971, -5.037427)
            control.cx = 1.42
            control.cy = 2.997
            control.cz = 1.0099998
            control.cw = 0.02
            control.dx = 4.3978653
            control.fMaxSteps = 17.0
            control.juliaX =  0.0
            control.juliaY =  -6.0
            control.juliaZ =  -8.0
            control.bright = 1.3299997
            control.contrast = 0.3199999
            control.power = 2.42
            control.juliaboxMode = true
            
            if control.doInversion {
                control.camera = simd_float3( -1.4471021 , 0.23879418 , -4.3080645 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950371 , 0.99503714 ))
                control.InvCenter = simd_float3( -0.13600002 , 0.30600032 , 0.011999967 )
                control.InvRadius =  0.62999976
                control.InvAngle =  0.37999997
            }
        case EQU_06_QUATJULIA :
            control.camera = simd_float3(-0.010578117, -0.49170083, -2.4)
            control.cx = -1.74999952
            control.cy = -0.349999964
            control.cz = -0.0499999635
            control.cw = -0.0999999642
            control.fMaxSteps = 7
            control.contrast = 0.28
            control.specular = 0.9
            
            if control.doInversion {
                control.camera = simd_float3( -0.010578117 , -0.49170083 , -2.4 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950371 , 0.99503714 ))
                control.InvCx =  0.098000005
                control.InvCy =  0.19999999
                control.InvCz =  -1.0519996
                control.InvRadius =  1.5200003
                control.InvAngle =  -0.29999992
            }
        case EQU_07_MONSTER :
            control.camera = simd_float3(0.0012031387, -0.106357165, -1.1865364)
            control.cx = 120
            control.cy = 4
            control.cz = 1
            control.cw = 1.3
            control.fMaxSteps = 10
            
            if control.doInversion {
                control.camera = simd_float3( 0.0012031387 , -0.106357165 , -1.1865364 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.025999993
                control.InvCy =  -0.062000014
                control.InvCz =  -0.74199986
                control.InvRadius =  0.40999997
                control.InvAngle =  -0.8200002
            }
        case EQU_08_KALI_TOWER :
            control.camera = simd_float3(-0.051097937, 5.059899, -4.0350704)
            control.cx = 8.65
            control.cy = 1
            control.cz = 2.3
            control.cw = 0.13
            control.fMaxSteps = 2
            
            if control.doInversion {
                control.camera = simd_float3( 0.06890213 , 4.266852 , -1.0111475 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.29999992
                control.InvCy =  3.6779976
                control.InvCz =  0.15800123
                control.InvRadius =  1.2900001
                control.InvAngle =  0.089999974
            }
        case EQU_09_POLY_MENGER :
            control.camera = simd_float3(-0.20046826, -0.51177955, -5.087464)
            control.cx = 4.7799964
            control.cy = 2.1500008
            control.cz = 2.899998
            control.cw = 3.0999982
            control.dx = 5
            
            if control.doInversion {
                control.camera = simd_float3( 0.62953156 , 0.51310825 , -5.1899557 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.242
                control.InvCy =  0.15800002
                control.InvCz =  0.074000046
                control.InvRadius =  0.31
                control.InvAngle =  -0.009999985
            }
        case EQU_10_GOLD :
            updateShaderDirectionVector(simd_float3(0.010000015, 0.41950363, 0.64503753))
            control.camera = simd_float3(0.038563743, -1.1381346, -1.8405379)
            control.cx = -0.09001912
            control.cy = 0.43999988
            control.cz = 1.0499994
            control.cw = 1
            control.dx = 0
            control.dy = 0.6
            control.dz = 0
            control.fMaxSteps = 15
            
            if control.doInversion {
                control.camera = simd_float3( 0.042072453 , -0.99094355 , -1.6142143 )
                updateShaderDirectionVector(simd_float3( 0.012995181 , 0.54515177 , 0.83823675 ))
                control.InvCx =  0.036
                control.InvCy =  0.092000015
                control.InvCz =  -0.15200002
                control.InvRadius =  0.17999996
                control.InvAngle =  -0.25999996
            }
        case EQU_11_SPIDER :
            control.camera = simd_float3(0.04676684, -0.50068825, -3.4419205)
            control.cx = 0.13099998
            control.cy = 0.21100003
            control.cz = 0.041
            
            if control.doInversion {
                control.camera = simd_float3( 0.04676684 , -0.46387178 , -3.0737557 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.28600028
                control.InvCy =  0.18000007
                control.InvCz =  -0.07799993
                control.InvRadius =  0.13
                control.InvAngle =  -0.079999976
            }
        case EQU_12_KLEINIAN2 :
            control.camera = simd_float3(4.1487565, 2.6955016, 1.3862593)
            control.cx = -0.7821867
            control.cy = -0.5424057
            control.cz = -0.4748369
            control.cw = 0.7999992
            control.dx = 0.5
            control.dy = 1.3
            control.dz = 1.5499997
            control.dw = 0.9000002
            control.power = 1
            
            if control.doInversion {
                control.camera = simd_float3( 4.1487565 , 2.6955016 , 1.3862593 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  -0.092
                control.InvCy =  0.01999999
                control.InvCz =  -0.47600016
                control.InvRadius =  4.2999983
                control.InvAngle =  0.13000003
            }
        case EQU_13_KIFS :
            control.camera = simd_float3(-0.033257294, -0.58263075, -5.087464)
            control.cx = 2.7499976
            control.cy = 2.6499977
            control.cz = 4.049997
            
            if control.doInversion {
                control.camera = simd_float3( -0.033257294 , -0.42640972 , -3.5252607 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.0040000193
                control.InvCy =  0.028000021
                control.InvCz =  -0.378
                control.InvRadius =  0.9499994
                control.InvAngle =  -0.05999998
            }
        case EQU_14_IFS_TETRA :
            control.camera = simd_float3(-0.034722134, -0.45799592, -3.3590596)
            control.cx = 1.4900005
            
            if control.doInversion {
                control.camera = simd_float3( 0.05527785 , 0.018626798 , -1.2057981 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.0019999929
                control.InvCy =  0.05600003
                control.InvCz =  0.08400006
                control.InvRadius =  0.28000003
                control.InvAngle =  -3.6399987
            }
        case EQU_15_IFS_OCTA :
            control.camera = simd_float3(0.00014548551, -0.20753044, -1.7193593)
            control.cx = 1.65
            
            if control.doInversion {
                control.camera = simd_float3( 0.00014548551 , -0.20753044 , -1.7193593 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  -1.1175871e-08
                control.InvCy =  0.1
                control.InvCz =  -2.0020003
                control.InvRadius =  1.9000001
                control.InvAngle =  0.1
            }
        case EQU_16_IFS_DODEC :
            control.camera = simd_float3(-0.09438618, -0.52536994, -4.1138387)
            control.cx = 1.8
            control.cy = 1.5999994
            
            if control.doInversion {
                control.camera = simd_float3( -0.09438618 , -0.52536994 , -4.1138387 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  -0.14200002
                control.InvCy =  -0.442
                control.InvCz =  -2.9619994
                control.InvRadius =  3.01
                control.InvAngle =  0.0
            }
        case EQU_17_IFS_MENGER :
            control.camera = simd_float3(0.017836891, -0.40871215, -3.3820548)
            control.cx = 3.0099978
            control.cy = -0.53999937
            control.fMaxSteps = 3
            
            if control.doInversion {
                control.camera = simd_float3( 0.017836891 , -0.40871215 , -3.3820548 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  -0.020000013
                control.InvCy =  -0.222
                control.InvCz =  -3.1019993
                control.InvRadius =  2.31
                control.InvAngle =  0.1
            }
        case EQU_18_SIERPINSKI :
            control.camera = simd_float3(0.03816485, -0.08283869, -0.63742965)
            control.cx = 1.3240005
            control.cy = 1.5160003
            control.angle1 = 3.1415962
            control.angle2 = 1.5610005
            control.fMaxSteps = 27
            
            if control.doInversion {
                control.camera = simd_float3( 0.03816485 , -0.12562533 , -1.0652959 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.11600001
                control.InvCy =  0.07200002
                control.InvCz =  -0.00799999
                control.InvRadius =  0.20999998
                control.InvAngle =  0.110000014
            }
        case EQU_19_HALF_TETRA :
            control.camera = simd_float3(-0.023862544, -0.113349974, -0.90810966)
            control.cx = 1.2040006
            control.cy = 9.236022
            control.angle1 = -3.9415956
            control.angle2 = 0.79159856
            control.fMaxSteps = 53
            
            if control.doInversion {
                control.camera = simd_float3( 0.13613744 , 0.07272194 , -0.85636866 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.07199999
                control.InvCy =  0.070000015
                control.InvCz =  0.037999995
                control.InvRadius =  0.33999994
                control.InvAngle =  0.44
            }
        case EQU_20_FULL_TETRA :
            control.camera = simd_float3(-0.018542236, -0.08817809, -0.90810966)
            control.cx = 1.1280007
            control.cy = 8.099955
            control.angle1 = -1.2150029
            control.angle2 = -0.018401254
            control.fMaxSteps = 71.0
            
            if control.doInversion {
                control.camera = simd_float3( -0.018542236 , -0.08817809 , -0.90810966 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.0069999956
                control.InvCy =  0.03999999
                control.InvCz =  0.22400002
                control.InvRadius =  0.3
                control.InvAngle =  0.4399999
            }
        case EQU_21_CUBIC :
            control.camera = simd_float3(-0.0011281949, -0.21761245, -0.97539556)
            control.cx = 1.1000057
            control.cy = 1.6714587
            control.angle1 = -1.8599923
            control.angle2 = 1.1640991
            control.fMaxSteps = 73.0
            
            if control.doInversion {
                control.camera = simd_float3( -0.0011282 , -0.09223774 , -0.8271352 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  -0.0020000078
                control.InvCy =  -0.026000004
                control.InvCz =  -0.602
                control.InvRadius =  0.51
                control.InvAngle =  0.27600044
            }
        case EQU_22_HALF_OCTA :
            control.camera = simd_float3(-0.015249629, -0.14036252, -0.8621065)
            control.cx = 1.1399999
            control.cy = 0.61145973
            control.angle1 = 2.8750083
            control.angle2 = 1.264099
            control.fMaxSteps = 50.0
            
            if control.doInversion {
                control.camera = simd_float3( 0.004750366 , -0.07966529 , -0.9586258 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.017999994
                control.InvCy =  -0.062000014
                control.InvCz =  -1.0059996
                control.InvRadius =  0.61
                control.InvAngle =  0.06000001
            }
        case EQU_23_FULL_OCTA :
            control.camera = simd_float3(0.0028324036, -0.05510863, -0.47697017)
            control.cx = 1.132
            control.cy = 0.6034597
            control.angle1 = 2.8500082
            control.angle2 = 1.264099
            control.fMaxSteps = 34.0
            
            if control.doInversion {
                control.camera = simd_float3( 0.0028324036 , -0.05510863 , -0.47697017 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.07400001
                control.InvCy =  0.0059999917
                control.InvCz =  0.006000004
                control.InvRadius =  0.10999999
                control.InvAngle =  -1.3100002
            }
        case EQU_24_KALEIDO :
            control.camera = simd_float3(-0.00100744, -0.1640267, -1.7581517)
            control.cx = 1.1259973
            control.cy = 0.8359996
            control.cz = -0.016000029
            control.angle1 = 1.7849922
            control.angle2 = -1.2375059
            control.fMaxSteps = 35.0
            
            if control.doInversion {
                control.camera = simd_float3( -0.00100744 , -0.1640267 , -1.7581517 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.034000028
                control.InvCy =  -0.026000002
                control.InvCz =  -1.082
                control.InvRadius =  0.97000015
                control.InvAngle =  -0.17
            }
        case EQU_25_POLYCHORA :
            control.camera = simd_float3(-0.00100744, -0.16238609, -1.7581517)
            control.cx = 5.0
            control.cy = 1.3159994
            control.cz = 2.5439987
            control.cw = 4.5200005
            control.dx = 0.08000006
            control.dy = 0.008000016
            control.dz = -1.5999997
            
            if control.doInversion {
                control.camera = simd_float3( 0.54899234 , -0.03701113 , -0.7053995 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.5320001
                control.InvCy =  0.012000054
                control.InvCz =  -0.023999948
                control.InvRadius =  0.36999995
                control.InvAngle =  0.15
            }
        case EQU_26_QUADRAY :
            control.camera = simd_float3(0.017425783, -0.03216796, -3.7908385)
            control.cx = -0.8950321
            control.cy = -0.22100903
            control.cz = 0.10000001
            control.cw = 2
            control.fMaxSteps = 10.0
            
            if control.doInversion {
                control.camera = simd_float3( 0.107425764 , -0.3406294 , -3.7599885 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.1
                control.InvCy =  0.1
                control.InvCz =  0.1
                control.InvRadius =  3.0999992
                control.InvAngle =  0.1
            }
        case EQU_27_FRAGM :
            control.camera = simd_float3(-0.010637887, -0.27700076, -2.4429061)
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
            control.bright = 1.05
            control.power = 8
            
            if control.doInversion {
                control.camera = simd_float3( -0.010637887 , -0.29889002 , -2.661827 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950371 , 0.99503714 ))
                control.InvCx =  0.012000011
                control.InvCy =  0.027999992
                control.InvCz =  -0.19200002
                control.InvRadius =  0.81000006
                control.InvAngle =  0.099999994
            }
        case EQU_28_QUATJULIA2 :
            control.camera = simd_float3(-0.010578117, -0.49170083, -2.4)
            control.cx = -1.7499995
            control.fMaxSteps = 7.0
            control.bright = 0.5
            control.juliaX =  0.0
            control.juliaY =  0.0
            control.juliaZ =  0.0
            control.bright = 0.9000001
            
            if control.doInversion {
                control.camera = simd_float3( -0.010578117 , -0.49170083 , -2.4 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.1
                control.InvCy =  0.006000016
                control.InvCz =  -0.072
                control.InvRadius =  0.51
                control.InvAngle =  0.1
            }
        case EQU_29_MBROT :
            control.camera = simd_float3(-0.23955467, -0.3426069, -2.4)
            control.cx = -9.685755e-08
            control.angle1 = 0.0
            control.fMaxSteps = 10.0
            control.juliaX =  0.39999992
            control.juliaY =  5.399997
            control.juliaZ =  -2.3
            control.bright = 1.3000002
            control.contrast = 0.19999999
            
            if control.doInversion {
                control.camera = simd_float3( 0.39044535 , -0.1694704 , -0.16614081 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.4520001
                control.InvCy =  -0.148
                control.InvCz =  0.626
                control.InvRadius =  0.16999993
                control.InvAngle =  0.07000001
            }
        case EQU_30_KALIBOX :
            control.camera = simd_float3(0.32916373, -0.42756003, -3.6908724)
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
            control.bright = 0.9000001
            
            if control.doInversion {
                control.camera = simd_float3( 0.32916373 , -0.42756003 , -3.6908724 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.16800001
                control.InvCy =  -0.080000006
                control.InvCz =  -0.39400005
                control.InvRadius =  0.96000016
                control.InvAngle =  0.1
            }
        case EQU_31_SPUDS :
            control.camera = simd_float3(0.98336715, -1.2565054, -3.960955)
            control.cx = 3.7524672
            control.cy = 1.0099992
            control.cz = -1.0059854
            control.cw = -1.0534152
            control.dx = 1.1883448
            control.dz = -4.100001
            control.dw = -3.2119942
            control.fMaxSteps = 8.0
            control.bright = 0.92
            control.power = 3.2999988
            
            if control.doInversion {
                control.camera = simd_float3( 0.18336754 , -0.29131955 , -4.057477 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  -0.544
                control.InvCy =  -0.18200001
                control.InvCz =  -0.44799998
                control.InvRadius =  1.3700002
                control.InvAngle =  0.1
            }
        case EQU_32_MPOLY :
            control.camera = simd_float3(0.0047654044, -0.4972743, -3.960955)
            control.cx = 4.712923
            control.cy = 4.1999984
            control.cz = -4.0846615
            control.cw = -1.2505636
            control.dx = 0.080002524
            control.angle1 = -1.1579993
            control.fMaxSteps = 8.0
            control.bright = 1.0799999
            control.HoleSphere = true
            
            if control.doInversion {
                control.camera = simd_float3( -0.13523462 , -0.29229668 , -1.9111774 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950371 , 0.99503714 ))
                control.InvCx =  -0.18800002
                control.InvCy =  -0.084000014
                control.InvCz =  -0.57400006
                control.InvRadius =  0.51
                control.InvAngle =  -0.42999998
            }
        case EQU_33_MHELIX :
            control.camera = simd_float3(0.45329404, -1.7558048, -21.308537)
            control.cx = 1.0140339
            control.cy = 2.1570902
            control.angle1 = 0
            control.fMaxSteps = 5.0
            control.juliaX =  1.8000009
            control.juliaY =  -8.0
            control.juliaZ =  -10.0
            control.bright = 1.12
            control.gravity = true // 'moebius'
            
            if control.doInversion {
                control.camera = simd_float3( 0.45329404 , -1.7558048 , -21.308537 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.1
                control.InvCy =  0.1
                control.InvCz =  0.68999994
                control.InvRadius =  7.0999956
                control.InvAngle =  0.1
            }
        case EQU_34_FLOWER :
            control.camera = simd_float3(-0.16991696, -2.5964863, -12.54011)
            control.cx = 1.6740334
            control.cy = 2.1570902
            control.fMaxSteps = 10.0
            control.juliaX =  6.0999966
            control.juliaY =  13.999996
            control.juliaZ =  3.0999992
            control.bright = 1.5000001
            
            if control.doInversion {
                control.camera = simd_float3( -0.16991696 , -2.5964863 , -12.54011 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.03800006
                control.InvCy =  0.162
                control.InvCz =  0.11799997
                control.InvRadius =  0.7099998
                control.InvAngle =  0.18000002
            }
        case EQU_35_JUNGLE :
            control.camera = simd_float3(-1.8932692, -10.888095, -12.339884)
            control.cx = 1.8540331
            control.cy = 0.16000009
            control.cz = 3.1000001
            control.cw = 2.1499999
            control.fMaxSteps = 1.0
            
            if control.doInversion {
                control.camera = simd_float3( -0.44326913 , -1.5447038 , -13.274241 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.2000001
                control.InvCy =  0.18000007
                control.InvCz =  -0.10799984
                control.InvRadius =  1.3000002
                control.InvAngle =  0.1
            }
        case EQU_36_PRISONER :
            control.camera = simd_float3(-0.002694401, -0.36424443, -3.5887358)
            control.cx = 1.0799996
            control.cy = 1.06
            control.angle1 = 1.0759996
            control.fMaxSteps = 3.0
            control.bright = 1.5000001
            control.contrast = 0.15999986
            control.power = 4.8999977
            
            if control.doInversion {
                control.camera = simd_float3( -0.002694401 , -0.36424443 , -3.5887358 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.058
                control.InvCy =  0.12200004
                control.InvCz =  -2.3920004
                control.InvRadius =  2.22
                control.InvAngle =  -0.00999994
            }
        case EQU_37_SPIRALBOX :
            control.camera = simd_float3(0.047575176, -0.122939646, 1.5686907)
            control.cx = 0.8810008
            control.juliaX =  1.9000009
            control.juliaY =  1.0999998
            control.juliaZ =  0.19999993
            control.fMaxSteps = 9
            
            if control.doInversion {
                control.camera = simd_float3( 0.047575176 , -0.122939646 , 1.5686907 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.1
                control.InvCy =  0.07600006
                control.InvCz =  -0.46800002
                control.InvRadius =  2.31
                control.InvAngle =  0.1
            }
        case EQU_38_ALEK_BULB :
            control.camera = simd_float3(-0.07642456, -0.23929897, -2.1205378)
            control.fMaxSteps = 10.0
            control.juliaX =  0.6000004
            control.juliaY =  0.29999986
            control.juliaZ =  0.29999968
            control.bright = 1.4000001
            control.contrast = 0.5
            control.power = 3.4599924
            
            if control.doInversion {
                control.camera = simd_float3( -0.07642456 , -0.23929897 , -2.1205378 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.076
                control.InvCy =  0.029999996
                control.InvCz =  0.015999988
                control.InvRadius =  2.01
                control.InvAngle =  0.06000001
            }
        case EQU_39_SURFBOX :
            control.camera = simd_float3(-0.37710285, 0.4399976, -5.937426)
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
            
            if control.doInversion {
                control.camera = simd_float3( -0.37710285 , 0.4399976 , -5.937426 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.10799999
                control.InvCy =  0.19999999
                control.InvCz =  0.1
                control.InvRadius =  0.47000003
                control.InvAngle =  -0.15999997
            }
        case EQU_40_TWISTBOX :
            control.camera = simd_float3(0.24289839, -2.1800025, -9.257425)
            control.cx = 1.5611011
            control.fMaxSteps = 24.0
            control.juliaX =  3.2779012
            control.juliaY =  -3.0104024
            control.juliaZ =  -3.2913034
            control.bright = 1.4100001
            control.contrast = 0.3399999
            control.power = 8.21999
            
            if control.doInversion {
                control.camera = simd_float3( 0.23289838 , 0.048880175 , -1.2394277 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.068000056
                control.InvCy =  0.1
                control.InvCz =  0.029999983
                control.InvRadius =  0.24000005
                control.InvAngle =  -0.7099997
            }
        case EQU_41_KALI_RONTGEN :
            control.camera = simd_float3(-0.16709971, -0.020002633, -0.9474212)
            control.cx = 0.88783956
            control.cy = 1.3439986
            control.cz = 0.56685466
            control.fMaxSteps = 7.0
            
            if control.doInversion {
                control.camera = simd_float3( 0.4029004 , -0.036918215 , -0.6140825 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.23400004
                control.InvCy =  0.04200006
                control.InvCz =  0.07000005
                control.InvRadius =  0.22000004
                control.InvAngle =  1.4000001
            }
        case EQU_42_VERTEBRAE :
            control.camera = simd_float3(0.5029001, -1.3100017, -9.947422)
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
            control.bright = 1.47
            control.contrast = 0.22000006
            control.specular = 2.0
            
            if control.doInversion {
                control.camera = simd_float3( 1.0229 , -1.1866168 , -8.713577 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  -0.9600001
                control.InvCy =  -0.5200006
                control.InvCz =  -3.583999
                control.InvRadius =  4.01
                control.InvAngle =  3.1000001
            }
        case EQU_43_DARKSURF :
            control.camera = simd_float3(-0.4870995, -1.9200011, -1.7574148)
            control.cx = 7.1999893
            control.cy = 0.34999707
            control.cz = -4.549979
            control.dx = 0
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
            
            if control.doInversion {
                control.camera = simd_float3( -0.10709968 , -0.06923248 , -1.9424983 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.068000056
                control.InvCy =  0.10799999
                control.InvCz =  0.09400001
                control.InvRadius =  0.13999999
                control.InvAngle =  -0.95000005
            }
        case EQU_44_BUFFALO :
            control.preabsx = true
            control.preabsy = true
            control.preabsz = false
            control.absx = true
            control.absy = false
            control.absz = true
            control.UseDeltaDE = false
            control.juliaboxMode = true
            control.camera = simd_float3(0.008563751, -2.8381326, -0.2005394)
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
            updateShaderDirectionVector( simd_float3(-0.0045253364, 0.73382026, 0.091496624) )
            
            if control.doInversion {
                control.camera = simd_float3( 0.033746917 , -0.4353387 , -0.07229346 )
                updateShaderDirectionVector(simd_float3( -0.0061193192 , 0.9922976 , 0.12372495 ))
                control.InvCx =  0.016000055
                control.InvCy =  0.08400003
                control.InvCz =  5.2619725e-08
                control.InvRadius =  0.3
                control.InvAngle =  -2.0000002
            }
        case EQU_45_TEMPLE :
            control.camera = simd_float3(1.4945942, -0.47837746, -8.777346)
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
            
            if control.doInversion {
                control.camera = simd_float3( 0.15459429 , 0.04401703 , -0.33744603 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950371 , 0.99503714 ))
                control.InvCx =  -0.07599993
                control.InvCy =  0.07000005
                control.InvCz =  0.2139999
                control.InvRadius =  2.29
                control.InvAngle =  -0.029999984
            }
        case EQU_46_KALI3 :
            control.juliaboxMode = true
            control.camera = simd_float3(-0.025405688, -0.418378, -3.017353)
            control.cx = -0.5659971
            control.fMaxSteps = 8.0
            control.juliaX =  -0.97769934
            control.juliaY =  -0.8630977
            control.juliaZ =  -0.58009946
            control.bright = 2.2299995
            control.contrast = 0.1
            control.specular = 2.0
            
            if control.doInversion {
                control.camera = simd_float3( -0.025405688 , -0.12185693 , -0.8561316 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.0020000527
                control.InvCy =  -0.009999948
                control.InvCz =  -0.158
                control.InvRadius =  0.29000002
                control.InvAngle =  -0.82000005
            }
        case EQU_47_SPONGE :
            control.camera = simd_float3(0.7610872, -0.7994865, -3.8773263)
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
            
            if control.doInversion {
                control.camera = simd_float3( 0.25108737 , -0.9736173 , -2.603676 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
                control.InvCx =  0.35200006
                control.InvCy =  0.009999977
                control.InvCz =  -0.092
                control.InvRadius =  1.0600003
                control.InvAngle =  -0.019999992
            }
        case EQU_48_FLORAL :
            control.camera = simd_float3( -12.573917 , -3.4179301 , -53.867744 )
            updateShaderDirectionVector(simd_float3( 0.0 , 0.09950372 , 0.9950372 ))
            control.cx = 17.0
            control.cy = -1.390399
            control.cz = 2.8034544
            control.cw = -1.7025113
            control.dx = -1.6000023
            control.dy = -5.0514984
            control.dz = -4.858
            control.dw = 3.0838223
            control.ex = 11.0
            control.ey = 2.3699985
            control.ez = 3.8739958
            control.ew = -2.3987765
            control.fx = 14.65563
            control.fy = -5.989952
            control.fz = -3.6949396
            control.fw = 1.3926225
            control.fMaxSteps = 3.0
            control.bright = 0.47000006
            control.contrast = 0.7
            control.specular = 1.9
            
            if control.doInversion {
                control.camera = simd_float3( 1.1760863 , -10.455813 , -38.119076 )
                updateShaderDirectionVector(simd_float3( 0.0 , 0.09950371 , 0.99503714 ))
                control.InvCx =  -2.0440004
                control.InvCy =  -0.021997645
                control.InvCz =  -0.63200307
                control.InvRadius =  9.269997
                control.InvAngle =  -0.81999993
            }
        case EQU_49_KNOT :
            control.camera = simd_float3(0.22108716, -4.869475, -3.187327)
            control.cx = 6.28
            control.cy = 7.0
            control.cz = 1.5
            control.fMaxSteps = 30.0
            control.bright = 1.0100001
            control.contrast = 0.36000004
            control.specular = 1.2000002
            updateShaderDirectionVector( simd_float3(-0.05346525, 1.0684087, 0.78181773) )
            
            if control.doInversion {
                control.camera = simd_float3( 0.042541288 , -0.7013039 , -0.15071231 )
                updateShaderDirectionVector(simd_float3( -0.04035148 , 0.80635315 , 0.5900562 ))
                control.InvCx =  0.017999994
                control.InvCy =  -0.30200002
                control.InvCz =  0.15799986
                control.InvRadius =  0.48999983
                control.InvAngle =  -3.0499992
            }
        case EQU_50_DONUTS :
            control.camera = simd_float3(-0.2254057, -7.728364, -19.269318)
            control.cx = 7.9931593
            control.cy = 0.35945648
            control.cz = 2.8700645
            control.dx = 0.0
            control.dy = 0.0
            control.fMaxSteps = 4.0
            control.bright = 1.0100001
            control.contrast = 0.36000004
            control.specular = 1.2000002
            updateShaderDirectionVector( simd_float3(-2.0272768e-08, 0.46378687, 0.89157283) )
            
            if control.doInversion {
                control.camera = simd_float3( -0.2254057 , -7.728364 , -19.269318 )
                updateShaderDirectionVector(simd_float3( -2.0172154e-08 , 0.4614851 , 0.8871479 ))
                control.InvCx =  -1.8719988
                control.InvCy =  -4.1039987
                control.InvCz =  -1.367999
                control.InvRadius =  7.589995
                control.InvAngle =  -2.7999995
            }
        default : break // zorro
        }
        
        defineWidgetsForCurrentEquation()
        updateWindowTitle()
    }
    
    var timeInterval:Double = 0.1
    
    //MARK: -
    //MARK: -
    //MARK: -
    
    /// call shader to update 2D fractal window(s), and 3D vertex data
    func computeTexture(_ drawable:CAMetalDrawable) {
        // this appears to stop beachball delays if I cause key roll-over?
        Thread.sleep(forTimeInterval: timeInterval)
        
        var c = control
        
        c.win3DDirty = 0     // assume 3D window is inactive
        if vc3D != nil {     // 3D window is active
            c.win3DDirty = 1
            c.xSize3D = c.xmax3D - c.xmin3D
            c.ySize3D = c.ymax3D - c.ymin3D
        }
        
        func prepareJulia() { c.julia = simd_float3(control.juliaX,control.juliaY,control.juliaZ) }
        
        c.light = c.camera + simd_float3(sin(lightAngle)*100,cos(lightAngle)*100,-100)
        c.nlight = normalize(c.light)
        c.maxSteps = Int32(control.fMaxSteps);
        c.Box_Iterations = Int32(control.fBox_Iterations)
        
        c.InvCenter = simd_float3(c.InvCx, c.InvCy, c.InvCz)
        flightEncode()
        
        //-----------------------------------------------
        let colMap = [ colorMap1,colorMap2,colorMap3,colorMap4 ]
        
        func getColor(_ fIndex:Float, _ weight:Float) -> simd_float4 {
            let cm = colMap[palletteIndex]
            let index = max(Int(fIndex),4)  // 1st 4 entries are black
            let cc = cm[index]
            
            return simd_float4(cc.x,cc.y,cc.z,weight)
        }
        
        c.X = getColor(control.xIndex,control.xWeight)
        c.Y = getColor(control.yIndex,control.yWeight)
        c.Z = getColor(control.zIndex,control.zWeight)
        c.R = getColor(control.rIndex,control.rWeight)
        //-----------------------------------------------
        
        prepareJulia()
        control.otFixed = simd_float3(control.otFixedX,control.otFixedY,control.otFixedZ)
        
        switch Int(control.equation) {
        case EQU_04_KLEINIAN, EQU_02_APOLLONIAN, EQU_03_APOLLONIAN2 :
            c.Final_Iterations = Int32(control.fFinal_Iterations)
        case EQU_07_MONSTER :
            c.mm[0][0] = 99   // mark as needing calculation in shader
        case EQU_09_POLY_MENGER :
            let dihedDodec:Float = 0.5 * atan(c.dx)
            c.csD = simd_float2(cos(dihedDodec), -sin(dihedDodec))
            c.csD2 = simd_float2(cos(2 * dihedDodec), -sin(2 * dihedDodec))
        case EQU_12_KLEINIAN2, EQU_47_SPONGE :
            c.mins = simd_float4(control.cx,control.cy,control.cz,control.cw);
            c.maxs = simd_float4(control.dx,control.dy,control.dz,control.dw);
        case EQU_16_IFS_DODEC :
            c.n1 = normalize(simd_float3(-1.0,control.cy-1.0,1.0/(control.cy-1.0)))
            c.n2 = normalize(simd_float3(control.cy-1.0,1.0/(control.cy-1.0),-1.0))
            c.n3 = normalize(simd_float3(1.0/(control.cy-1.0),-1.0,control.cy-1.0))
        case EQU_18_SIERPINSKI, EQU_19_HALF_TETRA, EQU_20_FULL_TETRA,
             EQU_21_CUBIC, EQU_22_HALF_OCTA, EQU_23_FULL_OCTA, EQU_24_KALEIDO :
            c.n1 = normalize(simd_float3(-1.0,control.cy-1.0,1.0/control.cy-1.0))
        case EQU_25_POLYCHORA :
            let pabc:simd_float4 = simd_float4(0,0,0,1)
            let pbdc:simd_float4 = 1.0/sqrt(2) * simd_float4(1,0,0,1)
            let pcda:simd_float4 = 1.0/sqrt(2) * simd_float4(0,1,0,1)
            let pdba:simd_float4 = 1.0/sqrt(2) * simd_float4(0,0,1,1)
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
            c.nd = simd_float4(-0.5,-0.5,-0.5,0.5)
        case EQU_27_FRAGM :
            prepareJulia()
            
            c.msIterations = Int32(c.fmsIterations)
            c.mbIterations = Int32(c.fmbIterations)
            c.msScale = 2.57144
            c.msOffset = simd_float3(1,1.00008,1.28204)
            c.mbMinRad2 = 0.17778
            c.mbScale = 2.4
            
            let o:simd_float3 = abs(c.msOffset)
            c.sc = max(o.x,max(o.y,o.z))
            c.sr = sqrt(dot(o,o)+1)
            
            c.absScalem1 = abs(c.mbScale - 1.0)
            c.AbsScaleRaisedTo1mIters = pow(abs(c.mbScale), Float(1 - c.mbIterations))
        case EQU_30_KALIBOX :
            c.absScalem1 = abs(c.cx - 1.0)
            c.AbsScaleRaisedTo1mIters = pow(abs(c.cx), Float(1 - c.maxSteps))
            c.n1 = simd_float3(c.dx,c.dy,c.dz)
            c.mins = simd_float4(c.cx, c.cx, c.cx, abs(c.cx)) / c.cy
            prepareJulia()
        case EQU_33_MHELIX, EQU_34_FLOWER, EQU_05_MANDELBOX, EQU_28_QUATJULIA2, EQU_29_MBROT, EQU_34_FLOWER,
             EQU_37_SPIRALBOX, EQU_38_ALEK_BULB, EQU_40_TWISTBOX, EQU_44_BUFFALO, EQU_46_KALI3 :
            prepareJulia()
        case EQU_39_SURFBOX :
            prepareJulia()
            c.dx = c.cx * c.cy  // foldMod
        case EQU_43_DARKSURF, EQU_48_FLORAL :
            c.n1 = simd_float3(c.dx,c.dy,c.dz)
            c.n2 = simd_float3(c.ex,c.ey,c.ez)
            c.n3 = simd_float3(c.fx,c.fy,c.fz)
        default : break
        }
        
        if let vr = vr { if vr.isRecording { c.skip = 1 }}  // editing params while recording was causing 'blocky fast renders' to be recorded
        
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
        
        if let vr = vr { vr.saveVideoFrame(drawable.texture) }
        instructionsG.refresh()
    }
    
    //MARK: -
    //MARK: -
    //MARK: -
    
    func toggleInversion() {
        control.doInversion = !control.doInversion
        defineWidgetsForCurrentEquation()
        reset()
        flagViewToRecalcFractal()
    }
    
    //MARK: -
    
    var pt1 = NSPoint()
    var pt2 = NSPoint()
    
    override func mouseDown(with event: NSEvent) { pt1 = event.locationInWindow }
    override func rightMouseDown(with event: NSEvent) { pt1 = event.locationInWindow }
    
    func mouseDrag2DImage(_ rightMouse:Bool) {
        if control.win3DFlag == 0 { // no 3D window active = mouse dragging pans 2D image
            var dx:Int = 0
            var dy:Int = 0
            let px = pt2.x - pt1.x
            let py = pt2.y - pt1.y
            if abs(px) > 4 { if px > 0 { dx = 1 } else if px < 0 { dx = -1 }}
            if abs(py) > 4 { if py > 0 { dy = 1 } else if py < 0 { dy = -1 }}
            alterationSpeed = -3
            
            if !rightMouse {
                if instructionsG.isHidden || pt1.x > 75 { // not if over the instructions panel
                    jogCameraAndFocusPosition(dx,dy,0)
                }
            }
            else {
                jogCameraAndFocusPosition(dx,0,dy)
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        pt2 = event.locationInWindow
        mouseDrag2DImage(false)
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        pt2 = event.locationInWindow
        mouseDrag2DImage(true)
    }
    
    var control2 = Control()
    
    // if 3D window is active: user has dragged a 3D region of interest (ROI) with left mouse button
    override func mouseUp(with event: NSEvent) {
        if control.win3DFlag != 0 {
            control.xmin3D = uint(min(pt1.x,pt2.x) * 2)
            control.xmax3D = uint(max(pt1.x,pt2.x) * 2)
            control.ymax3D = uint(control.ySize - Int32(min(pt1.y,pt2.y) * 2))
            control.ymin3D = uint(control.ySize - Int32(max(pt1.y,pt2.y) * 2))
            
            func ensureSizeAndBounds(_ v1:uint, _ v2:uint, _ sz:Int32) -> (min:uint, max:uint) {
                var v1 = v1
                var v2 = v2
                if v2 - v1 < SIZE3D {
                    v2 = v1 + uint(SIZE3D)
                    if v2 >= sz {
                        v1 = uint(sz - Int32(SIZE3D + 1))
                        v2 = v1 + uint(SIZE3D)
                    }
                }
                
                return (v1,v2)
            }
            
            let x = ensureSizeAndBounds(control.xmin3D,control.xmax3D,control.xSize)
            control.xmin3D = x.min
            control.xmax3D = x.max
            let y = ensureSizeAndBounds(control.ymin3D,control.ymax3D,control.ySize)
            control.ymin3D = y.min
            control.ymax3D = y.max
            
            flagViewToRecalcFractal()
        }
        else {
            jogRelease(1,1,1)
        }
    }
    
    override func rightMouseUp(with event: NSEvent) {
        if control.win3DFlag == 0 {
            jogRelease(1,1,1)
        }
    }
    
    //MARK: -
    
     func presentPopover(_ name:String) {
        let mvc = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let vc = mvc.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(name)) as! NSViewController
        self.present(vc, asPopoverRelativeTo: view.bounds, of: view, preferredEdge: .minX, behavior: .semitransient) 
    }
    
    var ctrlKeyDown:Bool = false
    
    func updateModifierKeyFlags(_ ev:NSEvent) {
        let rv = ev.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        ctrlKeyDown   = rv & (1 << 18) != 0
    }
    
    override func keyDown(with event: NSEvent) {
        func toggle2() {
            defineWidgetsForCurrentEquation()
            
            switch Int(control.equation) {
            case EQU_02_APOLLONIAN, EQU_03_APOLLONIAN2 :
                reset()
            default : break
            }
            
            flagViewToRecalcFractal()
        }
        
        updateModifierKeyFlags(event)
        
//      super.keyDown(with: event)   // comment out to prevent dull tone for every press, auto repeat
        widget.updateAlterationSpeed(event)
     
        if widget.keyPress(event) {
            setShaderToFastRender()
            return
        }

        switch Int32(event.keyCode) {
        case HOME_KEY :
            presentPopover("SaveLoadVC")
            return
        case PAGE_UP :
            if !isHelpVisible {
                helpIndex = 0
                presentPopover("HelpVC")
            }
            return
        case END_KEY :
            let s = SaveLoadViewController()
            s.loadNext()
            controlJustLoaded()
            return
        case PAGE_DOWN :
            toggleDisplayOfCompanion3DView()
            return
        default : break
        }
        
        switch event.charactersIgnoringModifiers!.uppercased() {
        case "O" :
            presentPopover("EquationPickerVC")
            return
        case "\\" : // set focus to child window
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
            control.isStereo = !control.isStereo
            adjustWindowSizeForStereo()
            defineWidgetsForCurrentEquation()
            flagViewToRecalcFractal()
        case "4","$" : jogCameraAndFocusPosition(-1,0,0)
        case "5","%" : jogCameraAndFocusPosition(+1,0,0)
        case "6","^" : jogCameraAndFocusPosition(0,-1,0)
        case "7","&" : jogCameraAndFocusPosition(0,+1,0)
        case "8","*" : jogCameraAndFocusPosition(0,0,-1)
        case "9","(" : jogCameraAndFocusPosition(0,0,+1)
        case "?","/" : fastRenderEnabled = !fastRenderEnabled
            
        case "C" :
            palletteIndex += 1
            if(palletteIndex > 3) { palletteIndex = 0 }
            flagViewToRecalcFractal()
            
        case "B" : control.showBalls = !control.showBalls; toggle2()
        case "F" : control.fourGen = !control.fourGen; toggle2()
        case "I" : toggleInversion()
        case "J" : control.juliaboxMode = !control.juliaboxMode; toggle2()
        case "K" : control.AlternateVersion = !control.AlternateVersion; toggle2()
        case "P" :
            if control.txtOnOff {
                control.txtOnOff = false
                defineWidgetsForCurrentEquation()
                flagViewToRecalcFractal()
            }
            else {
                loadImageFile()
            }
            
        case " " :
            instructions.isHidden = !instructions.isHidden
            instructionsG.isHidden = !instructionsG.isHidden
        case "H" : setControlParametersToRandomValues(); flagViewToRecalcFractal()
        case "V" : displayControlParametersInConsoleWindow()
        case "Q" :
            control.polygonate = !control.polygonate
            control.preabsx = !control.preabsx
            toggle2()
        case "W" :
            control.polyhedronate = !control.polyhedronate
            control.preabsy = !control.preabsy
            toggle2()
        case "E" :
            control.TotallyTubular = !control.TotallyTubular
            control.preabsz = !control.preabsz
            toggle2()
        case "R" :
            control.Sphere = !control.Sphere
            control.absx = !control.absx
            toggle2()
        case "T" :
            control.HoleSphere = !control.HoleSphere
            control.absy = !control.absy
            toggle2()
        case "Y" :
            control.unSphere = !control.unSphere
            control.absz = !control.absz
            toggle2()
        case "U" :
            control.gravity = !control.gravity
            control.UseDeltaDE = !control.UseDeltaDE
            toggle2()
        case "G" :
            control.colorScheme += 1
            if control.colorScheme > 7 { control.colorScheme = 0 }
            defineWidgetsForCurrentEquation()
            flagViewToRecalcFractal()
        case "L" :
            winLight.window!.makeKeyAndOrderFront(nil)
        case ",","<" : adjustWindowSize(-1)
        case ".",">" : adjustWindowSize(+1)
        case "[" : launchVideoRecorder()
        case "]" : if let vr = vr { vr.addKeyFrame() }
        default : break
        }
    }
    
    override func keyUp(with event: NSEvent) {
        super.keyUp(with: event)
        
        switch event.charactersIgnoringModifiers!.uppercased() {
        case "4","$","5","%" : jogRelease(1,0,0)
        case "6","^","7","&" : jogRelease(0,1,0)
        case "8","*","9","(" : jogRelease(0,0,1)
        default : break
        }
    }
    
    /// update 2D fractal camera position
    
    var jogAmount:simd_float3 = simd_float3()
    
    func jogCameraAndFocusPosition(_ dx:Int, _ dy:Int, _ dz:Int) {
        if dx != 0 { jogAmount.x = Float(dx) * alterationSpeed * 0.01 }
        if dy != 0 { jogAmount.y = Float(dy) * alterationSpeed * 0.01 }
        if dz != 0 { jogAmount.z = Float(dz) * alterationSpeed * 0.01 }
    }
    
    func jogRelease(_ dx:Int, _ dy:Int, _ dz:Int) {
        if dx != 0 { jogAmount.x = 0 }
        if dy != 0 { jogAmount.y = 0 }
        if dz != 0 { jogAmount.z = 0 }
    }
    
    func performJog() -> Bool {
        if jogAmount.x == 0 && jogAmount.y == 0 && jogAmount.z == 0 { return false}
        
        if ctrlKeyDown {
            updateShaderDirectionVector(control.viewVector + jogAmount)
        }
        else {
            control.camera += jogAmount.x * control.sideVector
            control.camera += jogAmount.y * control.topVector
            control.camera += jogAmount.z * control.viewVector
        }
        
        setShaderToFastRender()
        return true
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
            win3D?.close()
        }
        
        flagViewToRecalcFractal() // redraw 2D so that ROI rectangle is drawn (or erased)
    }
    
    /// toggle display of video recorder window
    func launchVideoRecorder() {
        if videoRecorderWindow == nil {
            let mainStoryboard = NSStoryboard.init(name: NSStoryboard.Name("Main"), bundle: nil)
            videoRecorderWindow = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("VideoRecorder")) as? NSWindowController
            videoRecorderWindow.showWindow(self)
        }
        
        videoRecorderWindow.showWindow(self)
    }
    
    /// press 'V' to display control parameter values in console window
    func displayControlParametersInConsoleWindow() {
        print("camera =",control.camera.debugDescription)
        print("viewVector = ",control.viewVector.debugDescription)
        print("topVector = ",control.topVector.debugDescription)
        print("sideVector = ",control.sideVector.debugDescription)
        print("multiplier = ",control.multiplier)
        print("foam = ",control.foam)
        print("foam2 = ",control.foam2)
        print("bend = ",control.bend)
        print("InvCenter = ",control.InvCx,",",control.InvCy,",",control.InvCz)
        print("InvRadius = ",control.InvRadius)
        print(" ")
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
        print("control.colorParam =",control.colorParam)
        
        print("updateShaderDirectionVector(",control.viewVector.debugDescription,")")
        
        //----------------------------------
        print(" ")
        print("if control.doInversion {")
        print("    control.camera = simd_float3(",control.camera.x,",",control.camera.y,",",control.camera.z,")")
        print("    updateShaderDirectionVector(simd_float3(",control.viewVector.x,",",control.viewVector.y,",",control.viewVector.z,"))")
        print("    control.InvCx = ",control.InvCx)
        print("    control.InvCy = ",control.InvCy)
        print("    control.InvCz = ",control.InvCz)
        print("    control.InvRadius = ",control.InvRadius)
        print("    control.InvAngle = ",control.InvAngle)
        print("}")
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
        flagViewToRecalcFractal()
    }
    
    /// define widget entries for current equation
    func defineWidgetsForCurrentEquation() {
        func juliaGroup(_ range:Float = 10, _ delta:Float = 1) {
            widget.addLegend("")
            widget.addBoolean("J: Julia Mode",&control.juliaboxMode)
            
            if control.juliaboxMode {
                widget.addEntry("  X",&control.juliaX,-range,range, delta)
                widget.addEntry("  Y",&control.juliaY,-range,range, delta)
                widget.addEntry("  Z",&control.juliaZ,-range,range, delta)
            }
        }
        
        widget.reset()
        
        if control.isStereo { widget.addEntry("Parallax",&control.parallax,0.001,1,0.01) }
        widget.addEntry("Bright",&control.bright,0.01,10,0.02)
        
        if control.colorScheme == 6 || control.colorScheme == 7 {
            widget.addEntry("Color Boost",&control.colorParam,1,1200000,200)
        }
        
        widget.addEntry("Enhance",&control.enhance,0,30,0.03)
        widget.addEntry("Contrast",&control.contrast,0.1,0.7,0.02)
        widget.addEntry("Specular",&control.specular,0,2,0.1)
        widget.addEntry("Light Position",&lightAngle,-3,3,0.3)
        
        widget.addEntry("Second Surface",&control.secondSurface,0,2,0.0003)
        widget.addEntry("Radial Symmetry",&control.radialAngle,0,Float.pi,0.03)
        
        switch Int(control.equation) {
        case EQU_01_MANDELBULB :
            widget.addEntry("Iterations",&control.fMaxSteps,3,30,1)
            widget.addEntry("Power",&control.power,1.5,12,0.02)
        case EQU_02_APOLLONIAN, EQU_03_APOLLONIAN2 :
            widget.addEntry("Iterations",&control.fMaxSteps,2,10,1)
            widget.addEntry("Multiplier",&control.multiplier,10,300,0.2)
            widget.addEntry("Foam",&control.foam,0.1,3,0.02)
            widget.addEntry("Foam2",&control.foam2,0.1,3,0.02)
            widget.addEntry("Bend",&control.bend,0.01,0.03,0.0001)
        case EQU_04_KLEINIAN :
            widget.addBoolean("B: ShowBalls",&control.showBalls)
            widget.addBoolean("F: FourGen",&control.fourGen)
            widget.addEntry("Final Iterations",&control.fFinal_Iterations, 1,39,1)
            widget.addEntry("Box Iterations",&control.fBox_Iterations,1,10,1)
            widget.addEntry("Box Size X",&control.box_size_x, 0.01,2,0.006)
            widget.addEntry("Box Size Z",&control.box_size_z, 0.01,2,0.006)
            widget.addEntry("Klein R",&control.KleinR, 0.01,2.5,0.005)
            widget.addEntry("Klein I",&control.KleinI, 0.01,2.5,0.005)
            widget.addEntry("Clamp Y",&control.Clamp_y, 0.001,2,0.01)
            widget.addEntry("Clamp DF",&control.Clamp_DF, 0.001,2,0.03)
        case EQU_05_MANDELBOX :
            widget.addEntry("Iterations",&control.fMaxSteps,3,60,1)
            widget.addEntry("Scale Factor",&control.power,0.6,10,0.04)
            widget.addEntry("Box",&control.cx, 0,10,0.02)
            widget.addEntry("Sphere 1",&control.cz, 0,4,0.02)
            widget.addEntry("Sphere 2",&control.cw, 0,4,0.02)
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
            widget.addEntry("Y",&control.cy,3.5,7,0.1)
            widget.addEntry("Z",&control.cz,0.45,2.8,0.05)
            widget.addEntry("Scale",&control.cw,1,1.6,0.02)
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
            widget.addEntry("Iterations",&control.fMaxSteps,2,20,1)
            widget.addEntry("T",&control.cx,-5,5,0.02)
            widget.addEntry("U",&control.cy,-5,5,0.02)
            widget.addEntry("V",&control.cz,-5,5,0.02)
            widget.addEntry("W",&control.cw,-5,5,0.02)
            widget.addEntry("X",&control.dx,-5,5,0.05)
            widget.addEntry("Y",&control.dy,-5,5,0.05)
            widget.addEntry("Z",&control.dz,-5,5,0.05)
        case EQU_11_SPIDER :
            widget.addEntry("X",&control.cx,0.001,5,0.01)
            widget.addEntry("Y",&control.cy,0.001,5,0.01)
            widget.addEntry("Z",&control.cz,0.001,5,0.01)
        case EQU_12_KLEINIAN2 :
            widget.addEntry("Iterations",&control.fMaxSteps,1,12,1)
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
            widget.addEntry("Y",&control.cy,2,10,0.3)
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
            widget.addLegend("MandelBulb --------------")
            widget.addEntry("   Iterations",&control.fMaxSteps,0,20,1,.integer,true)
            widget.addEntry("   Power",&control.power,1,12,0.1)
            widget.addLegend("Sphere Menger -----------")
            widget.addEntry("   Iterations",&control.fmsIterations,0,20,1,.integer,true)
            widget.addEntry("   Shape",&control.cx,-0.6,2.5,0.003)
            widget.addEntry("   Angle",&control.angle2,-4,4,0.006)
            widget.addLegend("MandelBox ---------------")
            widget.addEntry("   Iterations",&control.fmbIterations,0,20,1,.integer,true)
            widget.addEntry("   Angle",&control.angle1,-4,4,0.002)
            widget.addBoolean("   K: Alternate Version",&control.AlternateVersion)
            juliaGroup(10,0.005)
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
            widget.addEntry("Scale",&control.cx,-5,5,0.1)
            widget.addEntry("MinRad2",&control.cy,-5,5,0.1)
            widget.addEntry("Trans X",&control.dx,-15,15,0.05)
            widget.addEntry("Trans Y",&control.dy,-15,15,0.05)
            widget.addEntry("Trans Z",&control.dz,-1,5,0.05)
            widget.addEntry("Angle",&control.angle1,-4,4,0.05)
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
            widget.addBoolean("Q: polygonate",&control.polygonate)
            if control.polygonate { widget.addEntry("# Sides",&control.cx,0,15,0.1) }
            widget.addBoolean("W: polyhedronate",&control.polyhedronate)
            if control.polyhedronate { widget.addEntry("# Sides2",&control.cy,0,15,0.1) }
            widget.addBoolean("E: TotallyTubular",&control.TotallyTubular)
            widget.addBoolean("R: Sphere",&control.Sphere)
            widget.addBoolean("T: HoleSphere",&control.HoleSphere)
            widget.addBoolean("Y: unSphere",&control.unSphere)
            widget.addBoolean("U: gravity",&control.gravity)
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
            widget.addBoolean("U: Moebius",&control.gravity)
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
            juliaGroup(2,0.1)
        case EQU_38_ALEK_BULB :
            widget.addEntry("Iterations",&control.fMaxSteps,3,30,1)
            widget.addEntry("Power",&control.power,1.5,12,0.02)
            juliaGroup(1.6,0.1)
        case EQU_39_SURFBOX :
            widget.addEntry("Iterations",&control.fMaxSteps,3,20,1)
            widget.addEntry("Scale Factor",&control.power,0.6,3,0.05)
            widget.addEntry("Box 1",&control.cx, 0,3,0.02)
            widget.addEntry("Box 2",&control.cy, 4,5.6,0.02)
            widget.addEntry("Sphere 1",&control.cz, 0,4,0.05)
            widget.addEntry("Sphere 2",&control.cw, 0,4,0.05)
            juliaGroup(10,0.01)
        case EQU_40_TWISTBOX :
            widget.addEntry("Iterations",&control.fMaxSteps,3,60,1)
            widget.addEntry("Scale Factor",&control.power,0.6,10,0.2)
            widget.addEntry("Box",&control.cx, 0,10,0.001)
            juliaGroup(10,0.0001)
        case EQU_41_KALI_RONTGEN :
            widget.addEntry("Iterations",&control.fMaxSteps,1,30,1)
            widget.addEntry("X",&control.cx, -10,10,0.01)
            widget.addEntry("Y",&control.cy, -10,10,0.01)
            widget.addEntry("Z",&control.cz, -10,10,0.01)
            widget.addEntry("Angle",&control.angle1,-4,4,0.02)
        case EQU_42_VERTEBRAE :
            widget.addEntry("Iterations",&control.fMaxSteps,1,50,1)
            widget.addEntry("X",&control.cx,       -10,10,0.1)
            widget.addEntry("Y",&control.cy,       -10,10,0.1)
            widget.addEntry("Z",&control.cz,       -10,10,0.1)
            widget.addEntry("W",&control.cw,       -10,10,0.1)
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
            widget.addEntry("scale",&control.cx,    -10,10,0.05)
            widget.addEntry("MinRad",&control.cy,   -10,10,0.05)
            widget.addEntry("Scale",&control.cz,    -10,10,0.5)
            widget.addEntry("Fold X",&control.dx,   -10,10,0.05)
            widget.addEntry("Fold Y",&control.dy,   -10,10,0.05)
            widget.addEntry("Fold Z",&control.dz,   -10,10,0.05)
            widget.addEntry("FoldMod X",&control.ex,-10,10,0.05)
            widget.addEntry("FoldMod Y",&control.ey,-10,10,0.05)
            widget.addEntry("FoldMod Z",&control.ez,-10,10,0.05)
            widget.addEntry("Angle",&control.angle1,-4,4,0.05)
        case EQU_44_BUFFALO :
            widget.addEntry("Iterations",&control.fMaxSteps,2,60,1)
            widget.addEntry("Power",&control.cy,  0.1,30,0.01)
            widget.addEntry("Angle",&control.angle1,-4,4,0.01)
            widget.addBoolean("Q: Pre Abs X",&control.preabsx)
            widget.addBoolean("W: Pre Abs Y",&control.preabsy)
            widget.addBoolean("E: Pre Abs Z",&control.preabsz)
            widget.addBoolean("R: Abs X",&control.absx)
            widget.addBoolean("T: Abs Y",&control.absy)
            widget.addBoolean("Y: Abs Z",&control.absz)
            widget.addBoolean("U: Delta DE",&control.UseDeltaDE)
            if control.UseDeltaDE {
                widget.addEntry("DE Scale",&control.cx, 0,2,0.01)
            }
            juliaGroup(10,0.01)
        case EQU_45_TEMPLE :
            widget.addEntry("Iterations",&control.fMaxSteps,1,16,1)
            widget.addEntry("X",&control.cx,        -10,10,0.02)
            widget.addEntry("Y",&control.cy,        -10,10,0.02)
            widget.addEntry("Z",&control.dx,        -4,4,0.02)
            widget.addEntry("W",&control.dy,        -4,4,0.02)
            widget.addEntry("A1",&control.angle1,   -10,10,0.03)
            widget.addEntry("A2",&control.angle2,   -10,10,0.03)
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
            widget.addEntry("X",&control.cx,        -20,20,0.05)
            widget.addEntry("Y",&control.cy,        -20,20,0.05)
            widget.addEntry("CSize X",&control.dx,  -20,20,0.05)
            widget.addEntry("CSize Y",&control.dy,  -20,20,0.05)
            widget.addEntry("CSize Z",&control.dz,  -20,20,0.05)
            widget.addEntry("C1    X",&control.ex,  -20,20,0.05)
            widget.addEntry("C1    Y",&control.ey,  -20,20,0.05)
            widget.addEntry("C1    Z",&control.ez,  -20,20,0.05)
            widget.addEntry("Offset X",&control.fx, -20,20,0.05)
            widget.addEntry("Offset Y",&control.fy, -20,20,0.05)
            widget.addEntry("Offset Z",&control.fz, -20,20,0.05)
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
        
        // ----------------------------
        widget.addLegend("")
        widget.addBoolean("P: Texture",&control.txtOnOff)
        if control.txtOnOff {
            widget.addEntry("   X",&control.tCenterX,0.01,1,0.02)
            widget.addEntry("   Y",&control.tCenterY,0.01,1,0.02)
            widget.addEntry("   Scale",&control.tScale,0.01,1,0.02)
        }

        // ----------------------------
        widget.addLegend("")
        widget.addBoolean("I: Spherical Inversion",&control.doInversion)
        
        if control.doInversion {
            widget.addEntry("   X",&control.InvCx,-5,5,0.002)
            widget.addEntry("   Y",&control.InvCy,-5,5,0.002)
            widget.addEntry("   Z",&control.InvCz,-5,5,0.002)
            widget.addEntry("   Radius",&control.InvRadius,0.01,10,0.01)
            widget.addEntry("   Angle",&control.InvAngle,-10,10,0.01)
        }
        
        // ----------------------------
        widget.addLegend("")
        widget.addEntry("Fog Amount",&control.fog,0,12,0.1)
        widget.addEntry("R",&control.fogR,0,1,0.1)
        widget.addEntry("G",&control.fogG,0,1,0.1)
        widget.addEntry("B",&control.fogB,0,1,0.1)

        // ----------------------------
        widget.addLegend("")
        widget.addLegend("Orbit Trap --")
        widget.addEntry("O Strength",&vc.control.OrbitStrength,0,1,0.1)
        widget.addEntry("Cycles",&vc.control.Cycles,0,100,0.5)
        widget.addEntry("X Weight",&vc.control.xWeight,-5,5,0.1)
        widget.addEntry("Y",&vc.control.yWeight,-5,5,0.1)
        widget.addEntry("Z",&vc.control.zWeight,-5,5,0.1)
        widget.addEntry("R",&vc.control.rWeight,-5,5,0.1)
        widget.addEntry("X Color",&vc.control.xIndex,0,255,10)
        widget.addEntry("Y",&vc.control.yIndex,0,255,10)
        widget.addEntry("Z",&vc.control.zIndex,0,255,10)
        widget.addEntry("R",&vc.control.rIndex,0,255,10)
        widget.addEntry("Fixed Trap",&control.orbitStyle,0,2,1,.integer,true)
        widget.addEntry("X",&vc.control.otFixedX,-10,10,0.1)
        widget.addEntry("Y",&vc.control.otFixedY,-10,10,0.1)
        widget.addEntry("Z",&vc.control.otFixedZ,-10,10,0.1)

//        // ----------------------------
//        widget.addLegend("")
//        widget.addEntry("Light",lightPower(0),0,1,0.1)
//        widget.addEntry("X",lightX(0),-20,20,0.2)
//        widget.addEntry("Y",lightY(0),-20,20,0.2)
//        widget.addEntry("Z",lightZ(0),-20,20,0.2)

        displayWidgets()
        updateWindowTitle()
    }
    
    func displayWidgets() {
        let str = NSMutableAttributedString()
        widget.addinstructionEntries(str)
        instructions.attributedStringValue = str        
        instructionsG.refresh()
    }
    
    func hasFocus() -> Bool {
        return view.window!.isKeyWindow
    }
    
    //MARK: -
    
    /// detemine shader threading settings for 2D and 3D windows (varies according to window size)
    func updateThreadGroupsAccordingToWindowSize() {
        var w = pipeline[PIPELINE_FRACTAL].threadExecutionWidth
        var h = pipeline[PIPELINE_FRACTAL].maxTotalThreadsPerThreadgroup / w
        threadsPerGroup[PIPELINE_FRACTAL] = MTLSizeMake(w, h, 1)
        
        let wxs = Int(metalView.bounds.width) * 2     // why * 2 ??
        let wys = Int(metalView.bounds.height) * 2
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
            r.size.width *= CGFloat(control.isStereo ? 2.0 : 0.5)
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
            metalView.frame = CGRect(x:0, y:0, width:r.size.width, height:r.size.height)
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
            
            metalView.frame = CGRect(x:1, y:1, width:r.size.width-2, height:r.size.height-2)
        }
        
        let widgetPanelHeight:Int = 1200
        instructionsG.frame = CGRect(x:5, y:5, width:75, height:widgetPanelHeight)
        instructionsG.bringToFront()
        instructionsG.refresh()
        
        instructions.frame = CGRect(x:50, y:5, width:500, height:widgetPanelHeight)
        instructions.textColor = .white
        instructions.backgroundColor = .black
        instructions.bringToFront()
        
        updateThreadGroupsAccordingToWindowSize()
        flagViewToRecalcFractal()
    }
    
    func windowDidResize(_ notification: Notification) { updateLayoutOfChildViews() }
    
    //MARK: -
    
    /// store just loaded .png picture to texture
    func loadTexture(from image: NSImage) -> MTLTexture? {
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        
        let textureLoader = MTKTextureLoader(device: device)
        var textureOut:MTLTexture! = nil
        
        do {
            textureOut = try textureLoader.newTexture(cgImage:cgImage)
            
            control.txtSize.x = Float(cgImage.width)
            control.txtSize.y = Float(cgImage.height)
            control.tCenterX = 0.5
            control.tCenterY = 0.5
            control.tScale = 0.5
        }
        catch {
            let alert = NSAlert()
            alert.messageText = "Cannot Continue"
            alert.informativeText = "Error while trying to load this texture."
            alert.beginSheetModal(for: view.window!) { ( returnCode: NSApplication.ModalResponse) -> Void in () }
        }
        
        return textureOut
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
                    self.control.txtOnOff = coloringTexture != nil
                }
            }
            
            openPanel.close()
            
            if self.control.txtOnOff { // just loaded a texture
                self.defineWidgetsForCurrentEquation()
                self.flagViewToRecalcFractal()
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
