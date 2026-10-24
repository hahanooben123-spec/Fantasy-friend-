import SwiftUI

enum VillageArtwork {
    static func image(_ name:String)->Image {
        #if SWIFT_PACKAGE
        return Image(name,bundle:.module)
        #else
        return Image(name)
        #endif
    }
}

extension VillagePlace {
    var artworkName: String {
        switch self {
        case .studio: return "VillageStudio"
        case .pizza: return "VillagePizza"
        case .games: return "VillageGames"
        case .homes: return "VillageHomes"
        case .pumpkins: return "VillagePumpkins"
        }
    }
    // Door hinges are authored per illustration, independently of screen size.
    var illustratedDoor: CGRect {
        switch self {
        case .studio: return CGRect(x:0.277,y:0.561,width:0.226,height:0.335)
        case .pizza: return CGRect(x:0.354,y:0.595,width:0.229,height:0.321)
        case .games: return CGRect(x:0.357,y:0.608,width:0.255,height:0.325)
        case .homes: return CGRect(x:0.416,y:0.565,width:0.166,height:0.220)
        case .pumpkins: return CGRect(x:0.424,y:0.602,width:0.177,height:0.331)
        }
    }
}

/// Painted architecture remains separate from doors, characters, labels and keepsakes.
struct PaintedVillageBuilding: View {
    let place: VillagePlace
    var opening: Double
    var rug: Color?
    var body: some View {
        GeometryReader { proxy in
            let size=proxy.size
            let unit=place.illustratedDoor
            let door=CGRect(x:unit.minX*size.width,y:unit.minY*size.height,
                            width:unit.width*size.width,height:unit.height*size.height)
            ZStack(alignment:.topLeading) {
                Ellipse().fill(StorybookStyle.plum.opacity(0.22))
                    .frame(width:size.width*0.76,height:size.height*0.075)
                    .blur(radius:3)
                    .position(x:size.width*0.5,y:size.height*0.93)
                if let rug=rug {
                    Ellipse().fill(rug).overlay(Ellipse().stroke(StorybookStyle.cream,lineWidth:1))
                        .frame(width:size.width*0.25,height:size.height*0.04)
                        .position(x:door.midX,y:size.height*0.95)
                }
                StorybookDoorArch().fill(LinearGradient(colors:[
                    Color(red:0.97,green:0.65,blue:0.21),StorybookStyle.cream],
                    startPoint:.top,endPoint:.bottom))
                    .frame(width:door.width,height:door.height).position(x:door.midX,y:door.midY)
                VillageArtwork.image(place.artworkName).resizable().interpolation(.high)
                    .frame(width:size.width,height:size.height)
                    .mask(VillageDoorCutout(door:unit).fill(style:FillStyle(eoFill:true)))
                    .shadow(color:StorybookStyle.plum.opacity(0.12),radius:4,x:1,y:4)
                // Reuse the painted door pixels, hinged in 3D; no flat replacement door.
                VillageArtwork.image(place.artworkName).resizable().interpolation(.high)
                    .frame(width:size.width,height:size.height)
                    .offset(x:-door.minX,y:-door.minY)
                    .frame(width:door.width,height:door.height,alignment:.topLeading)
                    .clipped().clipShape(StorybookDoorArch())
                    .rotation3DEffect(.degrees(-min(1,max(0,opening))*88),
                                      axis:(x:0,y:1,z:0),anchor:.leading,perspective:0.55)
                    .position(x:door.midX,y:door.midY)
                if opening>0 {
                    Ellipse().fill(RadialGradient(colors:[
                        StorybookStyle.honey.opacity(opening*0.34),.clear],
                        center:.center,startRadius:0,endRadius:door.width*1.6))
                        .frame(width:door.width*3.2,height:door.height*1.5)
                        .position(x:door.midX,y:door.midY)
                        .blendMode(.screen)
                }
            }
        }.aspectRatio(1,contentMode:.fit).allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct StorybookDoorArch: Shape {
    func path(in r:CGRect)->Path {
        var p=Path()
        p.move(to:CGPoint(x:r.minX,y:r.maxY))
        p.addLine(to:CGPoint(x:r.minX,y:r.minY+r.width*0.5))
        p.addCurve(to:CGPoint(x:r.maxX,y:r.minY+r.width*0.5),
            control1:CGPoint(x:r.minX,y:r.minY-r.width*0.17),
            control2:CGPoint(x:r.maxX,y:r.minY-r.width*0.17))
        p.addLine(to:CGPoint(x:r.maxX,y:r.maxY));p.closeSubpath()
        return p
    }
}
private struct VillageDoorCutout: Shape {
    let door:CGRect
    func path(in r:CGRect)->Path {
        var p=Path(r)
        let cut=CGRect(x:door.minX*r.width,y:door.minY*r.height,
                       width:door.width*r.width,height:door.height*r.height)
        p.addPath(StorybookDoorArch().path(in:cut))
        return p
    }
}

/// One bundled environment, with live lighting and foreground motes.
/// No parallax movement is applied to hit targets or saved creations.
struct PaintedVillageBackdrop: View {
    var dusk=false
    var active=true
    var animated=true
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VillageArtwork.image("VillageEnvironment").resizable().interpolation(.high).scaledToFill()
                    .frame(width:proxy.size.width,height:proxy.size.height).clipped()
                Color(red:0.08,green:0.12,blue:0.29).opacity(dusk ? 0.28 : 0)
                LinearGradient(colors:[StorybookStyle.honey.opacity(dusk ? 0.03 : 0.10),.clear],
                    startPoint:.topTrailing,endPoint:.bottomLeading).blendMode(.screen)
                if animated && !reduced {
                    TimelineView(.animation(minimumInterval:1.0/12,paused:!active || phase != .active)) { frame in
                        Canvas { c,s in
                            let t=frame.date.timeIntervalSinceReferenceDate
                            for i in 0..<(dusk ? 16 : 8) {
                                let x=s.width*(0.04+CGFloat((i*71)%97)/105)+CGFloat(sin(t*0.35+Double(i))*9)
                                let y=s.height*(0.23+CGFloat((i*43)%71)/100)+CGFloat(cos(t*0.27+Double(i))*7)
                                let point=CGPoint(x:x,y:y)
                                let radius:CGFloat=dusk ? 11 : 5
                                let alpha=(0.5+sin(t*1.2+Double(i))*0.3)*(dusk ? 0.6 : 0.24)
                                c.fill(Path(ellipseIn:CGRect(x:x-radius,y:y-radius,width:radius*2,height:radius*2)),
                                    with:.radialGradient(Gradient(colors:[StorybookStyle.honey.opacity(alpha),.clear]),
                                        center:point,startRadius:0,endRadius:radius))
                                c.fill(Path(ellipseIn:CGRect(x:x-1,y:y-1,width:2,height:2)),
                                    with:.color(StorybookStyle.cream.opacity(alpha)))
                            }
                        }
                    }
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
