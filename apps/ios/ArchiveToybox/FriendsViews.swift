import SwiftUI

struct FriendsHomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var friends: [FriendUser] = []
    @State private var requests: [FriendRequestItem] = []
    @State private var searchText = ""
    @State private var searchResults: [FriendUser] = []
    @State private var transferFriend: FriendUser?
    @State private var transferAmount = "10"
    @State private var message = ""

    var body: some View {
        NavigationStack {
            List {
                Section("搜索好友") {
                    HStack {
                        TextField("输入短 ID", text: $searchText)
                        Button("搜索") { Task { await search() } }
                    }
                    ForEach(searchResults) { user in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.nickname).font(.headline)
                                Text(user.shortId).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("加好友") { Task { try? await appState.api.sendFriendRequest(toUserId: user.id); await reload() } }
                        }
                    }
                }
                if !requests.isEmpty {
                    Section("待处理申请") {
                        ForEach(requests) { request in
                            HStack {
                                Text(request.fromUser?.nickname ?? "未知用户")
                                Spacer()
                                Button("接受") { Task { try? await appState.api.acceptFriendRequest(id: request.id); await reload() } }
                            }
                        }
                    }
                }
                Section("好友列表") {
                    ForEach(friends) { friend in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(friend.nickname).font(.headline)
                                Text("功德 \(friend.totalMerit ?? 0)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("传功德") { transferFriend = friend }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle("好友")
            .task { await reload() }
            .sheet(item: $transferFriend) { friend in
                TransferMeritSheet(friend: friend)
            }
        }
    }

    private func search() async {
        searchResults = (try? await appState.api.searchFriends(shortId: searchText)) ?? []
    }

    private func reload() async {
        friends = (try? await appState.api.listFriends()) ?? []
        requests = (try? await appState.api.listFriendRequests())?.incoming ?? []
    }
}

struct TransferMeritSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let friend: FriendUser
    @State private var amount = "10"
    @State private var message = ""
    @State private var status: String?

    var body: some View {
        NavigationStack {
            Form {
                Text("给 \(friend.nickname) 传功德")
                TextField("数量", text: $amount).keyboardType(.numberPad)
                TextField("留言（可选）", text: $message)
                Button("确认传递") {
                    Task {
                        let value = Int(amount) ?? 0
                        do {
                            let result = try await appState.api.transferMerit(
                                toUserId: friend.id,
                                amount: value,
                                clientRequestId: UUID().uuidString,
                                message: message.isEmpty ? nil : message
                            )
                            status = result.duplicate ? "已传递过（幂等）" : "传递成功"
                            await appState.refreshProfile()
                        } catch {
                            status = error.localizedDescription
                        }
                    }
                }
                if let status { Text(status).foregroundStyle(.secondary) }
            }
            .navigationTitle("传功德")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
    }
}

extension FriendUser: Hashable {
    static func == (lhs: FriendUser, rhs: FriendUser) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
