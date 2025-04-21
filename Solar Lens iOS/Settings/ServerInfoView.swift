import SwiftUI

struct ServerInfoView: View {
    var serverInfo: ServerInfo?
    
    var body: some View {
        Grid(
            alignment: .leadingFirstTextBaseline,
            horizontalSpacing: 10,
            verticalSpacing: 10
        ) {
            
            GridRow {
                Text("Solar Manager")
                    .font(.title)
                    .gridCellColumns(2)
            }
            
            if let serverInfo = serverInfo {
                GridRow {
                    Text("Solar Manager ID:")
                        .fontWeight(.bold)
                    
                    Text(serverInfo.smId)
                }
                
                GridRow {
                    Text("Email:")
                        .fontWeight(.bold)
                    
                    Text(serverInfo.email)
                }
                
                GridRow {
                    Text("Hardware Version:")
                        .fontWeight(.bold)
                    
                    Text(serverInfo.hardwareVersion)
                }
                
                GridRow {
                    Text("Software Version:")
                        .fontWeight(.bold)
                    
                    Text(serverInfo.softwareVersion)
                }
                
                GridRow {
                    Text("Software Installation:")
                        .fontWeight(.bold)
                    
                    if serverInfo.registrationDate != nil {
                        Text(serverInfo.registrationDate!, style: .date)
                    } else {
                        Text(verbatim: "-")
                        
                    }
                }
                
            } else {
                GridRow {
                    Text("Not data")
                        .foregroundColor(.gray)
                        .gridCellColumns(2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ServerInfoView(serverInfo: ServerInfo.fake())
}
