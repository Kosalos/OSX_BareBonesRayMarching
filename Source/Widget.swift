import Cocoa

enum WidgetKind { case integer,float,dash }
enum AlterationSpeed { case normal,fast,slow }

struct WidgetData {
    var kind:WidgetKind = .float
    var legend:String = ""
    var valuePtr:UnsafeMutableRawPointer! = nil
    var delta:Float = 0
    var range = float2()
    var showValue:Bool = false
    
    func alterValue(_ direction:Int, _ speed:AlterationSpeed) -> Bool {
        var value:Float = valuePtr.load(as:Float.self)
        let oldValue = value

        var amt:Float = delta
        switch speed {
        case .normal : break
        case .slow : amt *= 0.1
        case .fast : amt *= 10
        }
        
        value += direction > 0 ? amt : -amt
        value = max( min(value, range.y), range.x)

        if value != oldValue {
            valuePtr.storeBytes(of:value, as:Float.self)
            return true
        }
        
        return false
    }
    
    func valueString() -> String {
        let value:Float = valuePtr.load(as:Float.self)
        if kind == .integer { return String(format:"%d", Int(value)) }
        return value.debugDescription
    }
    
    func displayString() -> String {
        var s:String = legend
        if showValue { s = s + " : " + valueString() }
        return s
    }
}

class Widget {
    var data:[WidgetData] = []
    var focus:Int = 0
    
    func reset() {
        data.removeAll()
        focus = 0
    }
    
    func addEntry(_ nLegend:String,
                  _ nValuePtr:UnsafeMutableRawPointer,
                  _ minValue:Float, _ maxValue:Float, _ nDelta:Float,
                  _ nKind:WidgetKind = .float,
                  _ nShowValue:Bool = false) {
        var w = WidgetData()
        w.legend = nLegend
        w.valuePtr = nValuePtr
        w.range.x = minValue
        w.range.y = maxValue
        w.delta = nDelta
        w.kind = nKind
        w.showValue = nShowValue
        data.append(w)
    }

    func addDash() {
        var w = WidgetData()
        w.kind = .dash
        data.append(w)
    }
    
    func moveFocus(_ direction:Int) {
        if data.count > 1 {
            focus += direction
            if focus < 0 { focus = data.count-1 }
            if focus >= data.count { focus = 0 }
            
            if data[focus].kind == .dash { moveFocus(direction) }
            
            updateInstructions()
            vc.updateWindowTitle()
        }
    }

    func keyPress(_ event:NSEvent) {
        //print(event.keyCode)
        
        let rv = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        let shiftKeyDown:Bool = rv & (1 << 17) != 0
        let optionKeyDown:Bool = rv & (1 << 19) != 0
        var speed:AlterationSpeed = .normal
        if shiftKeyDown { speed = .slow } else if optionKeyDown { speed = .fast }
        
        switch event.keyCode {
        case 123: // Left arrow
            if data[focus].alterValue(-1,speed) {
                vc.setIsDirty()
                if data[focus].showValue { updateInstructions() }
            }
        case 124: // Right arrow
            if data[focus].alterValue(+1,speed) {
                vc.setIsDirty()
                if data[focus].showValue { updateInstructions() }
            }
        case 125: moveFocus(+1) // Down arrow
        case 126: moveFocus(-1) // Up arrow
        case 53 : NSApplication.shared.terminate(self) // Esc
        default : break
        }
    }
    
    func focusString() -> String { return data[focus].displayString() }
    
    func updateInstructions() {
        let str = NSMutableAttributedString()
        
        func booleanEntry(_ onoff:Bool, _ legend:String) { str.normal(legend + (onoff ? " = true" : " = false")) }
        func juliaEntry() { booleanEntry(vc.control.juliaboxMode,"J: Julia Mode") }

        switch vc.style {
        case .move :
            str.normal("M : Mouse controls Movement")
            str.normal("      Left Mouse Button + Drag : Pan (+ 'Z' for finetune)")
            str.normal("      Right Mouse Button + Drag : Move forward,back")
            str.normal("S : Stop all movement")
        case .rotate :
            str.normal("M : Mouse controls Rotation")
            str.normal("      Left Mouse Button + Drag to Rotate (+ 'Z' for finetune)")
            str.normal("S : Stop all Movement")
        }
        
        str.normal("<, > : Change window size")
        str.normal("1,2 : Change Equation (previous, next)")
        str.normal("3 : Toggle Cross-Eyed Stereo")
        
        switch Int(vc.control.equation) {
        case EQU_KLEINIAN :
            booleanEntry(vc.control.showBalls,"B: ShowBalls")
            booleanEntry(vc.control.fourGen,"F: FourGen")
            booleanEntry(vc.control.doInversion,"I: Do Inversion")
        case EQU_MANDELBOX :
            juliaEntry()
        case EQU_FRAGM :
            juliaEntry()
            booleanEntry(vc.control.AlternateVersion,"K: Alternate Version")
        case EQU_KALIBOX :
            juliaEntry()
        case EQU_MPOLY :
            booleanEntry(vc.control.polygonate,"Q: polygonate")
            booleanEntry(vc.control.polyhedronate,"W: polyhedronate")
            booleanEntry(vc.control.TotallyTubular,"E: TotallyTubular")
            booleanEntry(vc.control.Sphere,"R: Sphere")
            booleanEntry(vc.control.HoleSphere,"T: HoleSphere")
            booleanEntry(vc.control.unSphere,"Y: unSphere")
            booleanEntry(vc.control.gravity,"U: gravity")
        default : break
        }

        str.normal("")
        str.normal("Left/Right Arrows alter value (+ 'Shift' for slow, 'Option' for fast)")
        str.normal("Up/Down Arrows move focus")
        str.normal("Spacebar: Toggle instructions Display")
        str.normal("")
        
        for i in 0 ..< data.count {
            switch data[i].kind {
            case .integer, .float :
                str.colored(data[i].displayString(), i == focus ? .red : .white)
            case .dash :
                str.normal("-------------")
            }
        }
        
        vc.instructions.attributedStringValue = str
    }
}
