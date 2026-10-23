import Foundation

/// Stars remain temporary play state; collecting them never locks content.
struct PlayStar:Identifiable,Equatable {
    let id:Int
    var x:Double
    var y:Double
}
struct StarTrail {
    private(set) var stars:[PlayStar]=[]
    private(set) var collected=0
    private(set) var round=0
    init() {reseed()}
    mutating func reseed() {
        round+=1
        stars=(0..<5).map {i in PlayStar(id:round*10+i,x:0.16+Double(i)*0.17,y:0.24+Double((i+round)%3)*0.12)}
    }
    mutating func follow(_ track:SlideTrack) {
        round+=1
        stars=(0..<5).map {i in PlayStar(id:round*10+i,x:0.0875+Double(i)*0.2,y:0.2+track.heights[i]*0.6-0.09)}
    }
    mutating func collect(x:Double,y:Double,radius:Double=0.12)->Bool {
        guard x.isFinite,y.isFinite else {return false}
        let old=stars.count
        stars.removeAll {hypot($0.x-x,$0.y-y)<radius}
        collected+=old-stars.count
        return stars.count<old
    }
}
