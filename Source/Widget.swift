import Cocoa

protocol WidgetDelegate {
    func displayWidgets()
}

enum WidgetKind { case integer,float,legend,boolean }

var alterationSpeed:Float = 1

struct WidgetData {
    var kind:WidgetKind = .float
    var legend:String = ""
    var valuePtr:UnsafeMutableRawPointer! = nil
    var delta:Float = 0
    var range = simd_float2()
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
        if kind == .boolean {
            let value:Bool = valuePtr.load(as:Bool.self)
            return value ? "Yes" : "No"
        }

        let value:Float = valuePtr.load(as:Float.self)
        if kind == .integer { return String(format:"%d", Int(value)) }
        return value.debugDescription
    }
    
    func displayString() -> String {
        var s:String = legend
        if showValue { s = s + " : " + valueString() }
        return s
    }

    func valuePercent() -> Int {
        let value:Float = valuePtr.load(as:Float.self)
        return Int((value - range.x) * 100 / (range.y - range.x));
    }
}

class Widget {
    var delegate:WidgetDelegate?
    var ident:Int = 0
    var data:[WidgetData] = []
    var focus:Int = 0
    
    init(_ id:Int, _ d:WidgetDelegate) {
        ident = id
        delegate = d
    }
    
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

    func addLegend(_ legend:String = "") {
        var w = WidgetData()
        w.kind = .legend
        w.legend = legend
        data.append(w)
    }
    
    func addBoolean(_ legend:String, _ nValuePtr:UnsafeMutableRawPointer) {
        var w = WidgetData()
        w.legend = legend
        w.valuePtr = nValuePtr
        w.kind = .boolean
        w.showValue = true
        data.append(w)
    }
    
    func focusChanged() {
        delegate?.displayWidgets()
        vc.updateWindowTitle()
        
        vc.instructionsG.refresh()
    }
    
    func moveFocus(_ direction:Int) {
        if data.count > 1 {
            focus += direction
            if focus < 0 { focus = data.count-1 }
            if focus >= data.count { focus = 0 }
            
            if data[focus].kind == .legend || data[focus].kind == .boolean { moveFocus(direction) }
            
            focusChanged()
        }
    }
    
    func focusDirect(_ index:Int) {
        if index < 0 || index >= data.count { return }
        if data[index].kind == .float {
            focus = index
            focusChanged()
        }
    }

    func updateAlterationSpeed(_ event:NSEvent) {
        let rv = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        let shiftKeyDown:Bool = rv & (1 << 17) != 0
        let optionKeyDown:Bool = rv & (1 << 19) != 0

        alterationSpeed = 1
        if shiftKeyDown && optionKeyDown { alterationSpeed = 50 } else
        if shiftKeyDown { alterationSpeed = 0.1 } else if optionKeyDown { alterationSpeed = 10 }
    }
    
    func keyPress(_ event:NSEvent) -> Bool {
        updateAlterationSpeed(event)
        
        switch event.keyCode {
        case 123: // Left arrow
            if data[focus].alterValue(-1) {
                if ident == 0 {
                    vc.flagViewToRecalcFractal()
                    if data[focus].showValue { delegate?.displayWidgets() }
                }
                return true
            }
        case 124: // Right arrow
            if data[focus].alterValue(+1) {
                if ident == 0 {
                    vc.flagViewToRecalcFractal()
                    if data[focus].showValue { delegate?.displayWidgets() }
                }
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
    
    func addinstructionEntries(_ str:NSMutableAttributedString) {
        for i in 0 ..< data.count {
            switch data[i].kind {
            case .integer, .float :
                str.colored(data[i].displayString(), i == focus ? .red : .white)
            case .legend :
                str.normal(data[i].legend != "" ? data[i].legend : "-------------")
            case .boolean :
                str.normal(data[i].displayString())
            }
        }
    }
}
