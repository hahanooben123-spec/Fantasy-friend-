import SwiftUI

struct PumpkinEditorStage:View {
    @Binding var lantern:PumpkinLantern
    let step:PumpkinStep
    let tool:PumpkinTool
    let stamp:PumpkinCutKind
    @Binding var selected:UUID?
    let onBegin:()->Void
    let onEnd:()->Void
    let onWarning:()->Void
    @State private var origin:PumpkinLantern?
    @State private var moving:PumpkinCut?
    @State private var stroke:[PumpkinPoint]=[]
    @State private var lastScoop:CGPoint?
    @State private var handleOrigin:PumpkinCut?
    @State private var seedFlights:[PumpkinFlyingSeed]=[]
    @State private var seenSeeds=0
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body:some View {
        GeometryReader {proxy in
            let width=max(1,min(proxy.size.width-10,proxy.size.height*300/320))
            let size=CGSize(width:width,height:width*320/300)
            stage(size)
                .position(x:proxy.size.width/2,y:proxy.size.height/2)
        }
        .onAppear {seenSeeds=Int(lantern.scooped*12)}
        .onChange(of:lantern.scooped) {value in scatterSeeds(value)}
        .onChange(of:step) {_ in stroke=[];origin=nil;moving=nil;lastScoop=nil;seedFlights=[]}
        .onChange(of:tool) {_ in stroke=[];origin=nil;moving=nil}
    }
    private func stage(_ size:CGSize)->some View {
        ZStack {
            PumpkinIllustration(lantern:lantern,animated:step == .light,opened:step == .scoop)
            trace(size)
            scoopOverlay(size)
            selection(size)
        }.frame(width:size.width,height:size.height)
            .contentShape(Rectangle()).coordinateSpace(name:"pumpkinEditor")
            .gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("pumpkinEditor"))
                .onChanged {drag($0,size:size)}
                .onEnded {_ in endDrag()})
    }
    @ViewBuilder private func trace(_ size:CGSize)->some View {
        if !stroke.isEmpty {
            Canvas {context,_ in
                let r=PumpkinGeometry.rect(lantern.form)
                var path=Path()
                for (i,p) in stroke.enumerated() {
                    let canonicalPoint=CGPoint(x:r.minX+CGFloat(p.x)*r.width,y:r.minY+CGFloat(p.y)*r.height)
                    let q=screen(canonicalPoint,size:size)
                    if i == 0 {path.move(to:q)} else {path.addLine(to:q)}
                }
                context.stroke(path,with:.color(.white),style:StrokeStyle(lineWidth:4,lineCap:.round,lineJoin:.round))
            }.allowsHitTesting(false)
        }
    }
    @ViewBuilder private func scoopOverlay(_ size:CGSize)->some View {
        if step == .scoop {
            PumpkinSeedBowl(amount:lantern.scooped)
                .frame(width:size.width*0.27,height:size.height*0.12)
                .scaleEffect(lantern.scooped>=1 ? 1.08 : 1)
                .animation(reduced ? nil : .spring(response:0.4,dampingFraction:0.5),value:lantern.scooped>=1)
                .position(screen(CGPoint(x:249,y:297),size:size))
                .allowsHitTesting(false)
            ForEach(seedFlights) {seed in
                PumpkinSeedFlight(seed:seed,size:size) {seedFlights.removeAll {$0.id == seed.id}}
            }.allowsHitTesting(false)
            if let pointer=lastScoop {
                Text("🥄").font(.system(size:43)).position(screen(pointer,size:size)).allowsHitTesting(false)
            }
        }
    }
    private func scatterSeeds(_ amount:Double) {
        let count=Int(amount*12),previous=seenSeeds
        seenSeeds=count
        guard step == .scoop,count>previous else {return}
        SoundService.shared.play(count>=12 ? .complete : .click)
        guard !reduced else {return}
        let r=PumpkinGeometry.rect(lantern.form)
        let start=lastScoop ?? CGPoint(x:r.midX,y:r.minY+20)
        for i in 0..<min(4,count-previous) {
            seedFlights.append(PumpkinFlyingSeed(start:start,variation:count+i))
        }
        if seedFlights.count>20 {seedFlights.removeFirst(seedFlights.count-20)}
    }
    @ViewBuilder private func selection(_ size:CGSize)->some View {
        if step == .carve,tool == .move,let id=selected,let cut=lantern.cuts.first(where:{$0.id == id}) {
            let rect=PumpkinGeometry.cut(cut,form:lantern.form).boundingRect
            let center=screen(CGPoint(x:rect.midX,y:rect.midY),size:size)
            let rotatePoint=CGPoint(x:min(280,rect.maxX+10),y:max(30,rect.minY-12))
            let resizePoint=CGPoint(x:min(280,rect.maxX+10),y:min(290,rect.maxY+12))
            RoundedRectangle(cornerRadius:10).stroke(.white,style:StrokeStyle(lineWidth:2,dash:[5,4]))
                .frame(width:rect.width*size.width/300+10,height:rect.height*size.height/320+10)
                .position(center).allowsHitTesting(false)
            handle(cut,rotate:true,size:size).position(screen(rotatePoint,size:size))
            handle(cut,rotate:false,size:size).position(screen(resizePoint,size:size))
        }
    }
    private func drag(_ value:DragGesture.Value,size:CGSize) {
        let point=canonical(value.location,size:size)
        let r=PumpkinGeometry.rect(lantern.form)
        let unit=PumpkinPoint(x:Double(min(1,max(0,(point.x-r.minX)/r.width))),
                              y:Double(min(1,max(0,(point.y-r.minY)/r.height))))
        if origin == nil {
            origin=lantern;onBegin()
            if step == .carve {
                if tool == .draw {stroke=[]}
                let hit=PumpkinGeometry.hit(point,lantern:lantern)
                if tool == .move {selected=hit;moving=lantern.cuts.first {$0.id == hit}}
                if tool == .fill,let hit=hit {lantern.cuts.removeAll {$0.id == hit};selected=nil}
                if tool == .stamp,r.contains(point),lantern.cuts.count<80 {
                    var cut=PumpkinCut(kind:stamp,x:unit.x,y:unit.y)
                    if stamp == .smile || stamp == .tooth {cut.width=0.46;cut.height=0.24}
                    lantern.cuts.append(cut);selected=cut.id;moving=cut
                }
            }
        }
        if step == .scoop {
            if r.insetBy(dx:-12,dy:-12).contains(point) {
                if let last=lastScoop {
                    let distance=Double(hypot(point.x-last.x,point.y-last.y))
                    lantern.scooped=min(1,lantern.scooped+distance/480)
                }
                lastScoop=point
            } else {lastScoop=nil}
        }
        if step == .carve && tool == .draw && r.contains(point) {
            if stroke.count>=240 {stroke=stroke.enumerated().filter {$0.offset.isMultiple(of:2)}.map(\.element)}
            if let last=stroke.last {
                if hypot(last.x-unit.x,last.y-unit.y)>0.008 {stroke.append(unit)}
            } else {stroke=[unit]}
        }
        if step == .carve && (tool == .move || tool == .stamp),let base=moving,
           let i=lantern.cuts.firstIndex(where:{$0.id == base.id}) {
            var cut=base
            let dx=Double(value.translation.width/size.width*300/r.width)
            let dy=Double(value.translation.height/size.height*320/r.height)
            cut.move(x:base.x+dx,y:base.y+dy)
            lantern.cuts[i]=cut
        }
    }
    private func endDrag() {
        if step == .carve && tool == .draw {
            if lantern.cuts.count<80,let cut=PumpkinCut.fromStroke(stroke) {
                lantern.cuts.append(cut);selected=cut.id;stroke=[]
            } else {onWarning()}
        }
        origin=nil;moving=nil;lastScoop=nil;onEnd()
    }
    private func screen(_ point:CGPoint,size:CGSize)->CGPoint {CGPoint(x:point.x/300*size.width,y:point.y/320*size.height)}
    private func canonical(_ point:CGPoint,size:CGSize)->CGPoint {CGPoint(x:point.x/size.width*300,y:point.y/size.height*320)}
    private func handle(_ cut:PumpkinCut,rotate:Bool,size:CGSize)->some View {
        CreatorLineIcon(mark:rotate ? .rotate : .resize,color:PumpkinLook.ink).frame(width:28,height:28)
            .frame(width:46,height:46).background(Circle().fill(PumpkinLook.cream)).overlay(Circle().stroke(.white,lineWidth:3))
            .highPriorityGesture(DragGesture(coordinateSpace:.named("pumpkinEditor")).onChanged {value in
                if handleOrigin == nil {handleOrigin=cut;onBegin()}
                guard let base=handleOrigin,let i=lantern.cuts.firstIndex(where:{$0.id == base.id}) else {return}
                let r=PumpkinGeometry.rect(lantern.form)
                let center=CGPoint(x:r.minX+CGFloat(base.x)*r.width,y:r.minY+CGFloat(base.y)*r.height)
                let start=canonical(value.startLocation,size:size),point=canonical(value.location,size:size)
                if rotate {
                    let angle=atan2(point.y-center.y,point.x-center.x)-atan2(start.y-center.y,start.x-center.x)
                    let total=base.rotation+Double(angle)*180/Double.pi
                    lantern.cuts[i].rotation=atan2(sin(total*Double.pi/180),cos(total*Double.pi/180))*180/Double.pi
                } else {
                    let scale=Double(hypot(point.x-center.x,point.y-center.y)/max(12,hypot(start.x-center.x,start.y-center.y)))
                    lantern.cuts[i].width=min(1,max(0.03,base.width*scale))
                    lantern.cuts[i].height=min(1,max(0.03,base.height*scale))
                }
            }.onEnded {_ in handleOrigin=nil;onEnd() })
    }
}


// Each short flight owns its animation task; leaving the workshop cancels it.
private struct PumpkinFlyingSeed:Identifiable {
    let id=UUID()
    let start:CGPoint
    let variation:Int
}
private struct PumpkinSeedFlight:View {
    let seed:PumpkinFlyingSeed
    let size:CGSize
    let onFinish:()->Void
    @State private var progress:CGFloat=0
    private var position:CGPoint {
        let end=CGPoint(x:239+CGFloat(seed.variation%5)*4,y:292)
        let x=seed.start.x+(end.x-seed.start.x)*progress
        let y=seed.start.y+(end.y-seed.start.y)*progress-sin(progress * .pi)*75
        return CGPoint(x:x/300*size.width,y:y/320*size.height)
    }
    var body:some View {
        Ellipse().fill(PumpkinLook.cream)
            .overlay(Ellipse().stroke(Color.orange,lineWidth:1.5))
            .frame(width:13,height:7)
            .rotationEffect(.degrees(Double(progress)*420+Double(seed.variation)*27))
            .position(position)
            .task {
                withAnimation(.linear(duration:0.65)) {progress=1}
                do {try await Task.sleep(nanoseconds:700_000_000)} catch {return}
                onFinish()
            }
    }
}
private struct PumpkinSeedBowl:View {
    let amount:Double
    var body:some View {
        Canvas {context,size in
            let w=size.width,h=size.height
            var bowl=Path()
            bowl.move(to:CGPoint(x:0,y:h*0.24))
            bowl.addCurve(to:CGPoint(x:w,y:h*0.24),control1:CGPoint(x:w*0.1,y:h*1.25),control2:CGPoint(x:w*0.9,y:h*1.25))
            bowl.closeSubpath()
            context.fill(bowl,with:.linearGradient(Gradient(colors:[Color.cyan,Color(red:0.08,green:0.4,blue:0.56)]),
                startPoint:.zero,endPoint:CGPoint(x:0,y:h)))
            context.stroke(bowl,with:.color(PumpkinLook.ink),lineWidth:2)
            let opening=CGRect(x:0,y:h*0.08,width:w,height:h*0.35)
            context.fill(Path(ellipseIn:opening),with:.color(Color(red:0.11,green:0.42,blue:0.48)))
            for i in 0..<Int(amount*18) {
                let x=w*0.12+CGFloat((i*23)%67)/100*w
                let y=h*0.16+CGFloat(i%3)*h*0.055
                context.fill(Path(ellipseIn:CGRect(x:x,y:y,width:w*0.12,height:h*0.1)),with:.color(PumpkinLook.cream))
            }
            context.stroke(Path(ellipseIn:opening),with:.color(Color.cyan),lineWidth:3)
            var shine=Path();shine.move(to:CGPoint(x:w*0.21,y:h*0.56));shine.addLine(to:CGPoint(x:w*0.33,y:h*0.72))
            context.stroke(shine,with:.color(.white.opacity(0.65)),style:StrokeStyle(lineWidth:3,lineCap:.round))
        }
    }
}
