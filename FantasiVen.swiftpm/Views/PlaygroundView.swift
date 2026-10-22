import SwiftUI

struct PlaygroundView: View {
    @EnvironmentObject private var store: FriendStore
    var initialID: UUID? = nil
    var onCreate: () -> Void
    @State private var selectedID: UUID?
    @State private var action: PlayAction = .jump
    @State private var signal = 0
    private let icons = ["hand.draw.fill", "leaf.fill", "arrow.up", "music.note", "moon.fill", "heart.fill"]
    private var friend: FantasyFriend? {
        store.friends.first { $0.id == (selectedID ?? initialID) } ?? store.friends.first
    }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                WorldBackdrop(world: friend?.world ?? .forest)
                if let friend = friend {
                    VStack(spacing: 10) {
                        Text(friend.name).font(.system(.title, design: .rounded).weight(.heavy)).lineLimit(1)
                        RagdollPlayground(friend: friend, action: action, signal: signal)
                            .id(friend.id).frame(height: min(geometry.size.height * 0.45, 390))
                        Label(store.t("ragdollHint"), systemImage: "hand.draw.fill")
                            .font(.system(.caption, design: .rounded)).foregroundColor(GameStyle.purple)
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(Array(PlayAction.allCases.enumerated()), id: \.element.rawValue) { index, item in
                                        Button { action = item; signal += 1 } label: {
                                            VStack(spacing: 7) {
                                                Image(systemName: icons[index]).font(.system(size: 27, weight: .semibold))
                                                Text(store.t(item.rawValue)).font(.system(.caption, design: .rounded).weight(.bold))
                                            }.foregroundColor(GameStyle.ink).frame(maxWidth: .infinity).frame(height: 76)
                                                .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.82)))
                                        }.buttonStyle(SquishStyle())
                                    }
                                }.padding(.horizontal, 20)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 9) {
                                        ForEach(World.allCases, id: \.rawValue) { world in
                                            Button {
                                                var changed = friend; changed.world = world
                                                if store.save(changed) { SoundService.shared.play(.click) }
                                            } label: {
                                                VStack(spacing: 4) {
                                                    WorldBackdrop(world: world).frame(width: 76, height: 50).clipShape(RoundedRectangle(cornerRadius: 14))
                                                    Text(store.t(Words.worldKeys[world.rawValue])).font(.system(size: 10, weight: .bold, design: .rounded))
                                                }.padding(6).background(RoundedRectangle(cornerRadius: 18).stroke(friend.world == world ? GameStyle.purple : .clear, lineWidth: 3))
                                            }.buttonStyle(SquishStyle()).accessibilityAddTraits(friend.world == world ? .isSelected : [])
                                        }
                                    }.padding(.horizontal, 20).padding(.vertical, 4)
                                }
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 10) {
                                        ForEach(store.friends) { item in
                                            Button { selectedID = item.id; signal = 0 } label: {
                                                VStack(spacing: 0) {
                                                    CharacterView(friend: item).frame(width: 75, height: 80)
                                                    Text(item.name).font(.system(size: 11, weight: .bold, design: .rounded)).lineLimit(1).frame(width: 88)
                                                }.padding(4).background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(item.id == friend.id ? 0.9 : 0.4)))
                                            }.buttonStyle(SquishStyle()).accessibilityLabel(item.name)
                                        }
                                    }.padding(.horizontal, 20)
                                }
                            }.padding(.bottom, 20)
                        }
                    }.padding(.top, 12).frame(maxWidth: 600).frame(maxWidth: .infinity)
                } else { EmptyCollectionView(create: onCreate) }
            }
        }.foregroundColor(GameStyle.ink).navigationTitle(store.t("play"))
            .navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
    }
}
