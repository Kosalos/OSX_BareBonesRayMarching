import Cocoa

enum WidgetKind { case integer,float,dash }

var alterationSpeed:Float = 1

struct WidgetData {
    var kind:WidgetKind = .float
    var legend:String = ""
    var valuePtr:UnsafeMutableRawPointer! = nil
    var delta:Float = 0
    var range = float2()
    var showValue:Bool = false
    
    func alterValue(_ direction:Int) -> Bool {
        var value:Float = valuePtr.load(as:Float.self)
        let oldValue = value
        let amt:Float = delta * alterationSpeed
        
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

    func updateAlterationSpeed(_ event:NSEvent) {
        let rv = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        let shiftKeyDown:Bool = rv & (1 << 17) != 0
        let optionKeyDown:Bool = rv & (1 << 19) != 0

        alterationSpeed = 1
        if shiftKeyDown { alterationSpeed = 0.1 } else if optionKeyDown { alterationSpeed = 10 }
    }
    
    func keyPress(_ event:NSEvent) -> Bool {
        //print(event.keyCode)
        
        updateAlterationSpeed(event)
        
        switch event.keyCode {
        case 123: // Left arrow
            if data[focus].alterValue(-1) {
                vc.setIsDirty()
                if data[focus].showValue { updateInstructions() }
                return true
            }
        case 124: // Right arrow
            if data[focus].alterValue(+1) {
                vc.setIsDirty()
                if data[focus].showValue { updateInstructions() }
                return true
            }
        case 125: moveFocus(+1) // Down arrow
        case 126: moveFocus(-1) // Up arrow
        //case 53 : NSApplication.shared.terminate(self) // Esc
        default : break
        }
        
        return false
    }
    
    func focusString() -> String { return data[focus].displayString() }
    
    func updateInstructions() {
        let str = NSMutableAttributedString()
        
        func booleanEntry(_ onoff:Bool, _ legend:String) { str.normal(legend + (onoff ? " = true" : " = false")) }
        func juliaEntry() {
            booleanEntry(vc.control.juliaboxMode,"J: Julia Mode")
            str.normal("")
        }

        switch Int(vc.control.equation) {
        case EQU_04_KLEINIAN :
            booleanEntry(vc.control.showBalls,"B: ShowBalls")
            booleanEntry(vc.control.fourGen,"F: FourGen")
            booleanEntry(vc.control.doInversion,"I: Do Inversion")
            str.normal("")
        case EQU_30_KALIBOX, EQU_37_SPIRALBOX :
            juliaEntry()
        case EQU_27_FRAGM :
            booleanEntry(vc.control.AlternateVersion,"K: Alternate Version")
            juliaEntry()
        case EQU_32_MPOLY :
            booleanEntry(vc.control.polygonate,"Q: polygonate")
            booleanEntry(vc.control.polyhedronate,"W: polyhedronate")
            booleanEntry(vc.control.TotallyTubular,"E: TotallyTubular")
            booleanEntry(vc.control.Sphere,"R: Sphere")
            booleanEntry(vc.control.HoleSphere,"T: HoleSphere")
            booleanEntry(vc.control.unSphere,"Y: unSphere")
            booleanEntry(vc.control.gravity,"U: gravity")
        case EQU_33_MHELIX :
            booleanEntry(vc.control.gravity,"U: Moebius")
            str.normal("")
        case EQU_05_MANDELBOX :
            booleanEntry(vc.control.doInversion,"I: Box Fold both sides")
            juliaEntry()
        case EQU_44_BUFFALO :
            booleanEntry(vc.control.preabsx,"Q: Pre Abs X")
            booleanEntry(vc.control.preabsy,"W: Pre Abs Y")
            booleanEntry(vc.control.preabsz,"E: Pre Abs Z")
            booleanEntry(vc.control.absx,"R: Abs X")
            booleanEntry(vc.control.absy,"T: Abs Y")
            booleanEntry(vc.control.absz,"Y: Abs Z")
            booleanEntry(vc.control.UseDeltaDE,"U: Delta DE")
            juliaEntry()
        default : break
        }

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
