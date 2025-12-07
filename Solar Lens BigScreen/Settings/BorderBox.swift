import SwiftUI

struct BorderBox<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.all, 30)
            .background(.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

#Preview {
    BorderBox {
        VStack {
            Text("Example Content")
                .font(.title)
            Text("Inside the BorderBox")
                .font(.caption)
        }
    }
    .padding()
}
