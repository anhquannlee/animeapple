import SwiftUI

struct ServerSelectorSheet: View {
    let servers: [ServerInfo]
    let currentServer: ServerInfo?
    let onSelect: (ServerInfo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Chọn Server")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 16)

            ForEach(servers, id: \.name) { server in
                Button(action: { onSelect(server) }) {
                    HStack {
                        Text(server.name)
                            .foregroundColor(server.name == currentServer?.name ? .red : .white)
                        Spacer()
                        if server.name == currentServer?.name {
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color(hex: "#1e1e1e"))
    }
}
