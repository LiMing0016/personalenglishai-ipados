import SwiftUI

struct MessageBubbleView: View {
    let message: AssistantMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                bubble
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var bubble: some View {
        Text(message.content)
            .font(.body)
            .padding(Spacing.md)
            .foregroundStyle(foregroundColor)
            .background(background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var foregroundColor: Color {
        message.role == .assistant ? Color.primary : Color.white
    }

    private var background: Color {
        message.role == .assistant ? Color.peaiSurface : Color.peaiAccent
    }
}

struct MessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageBubbleView(message: AssistantMessage.samples[0])
            MessageBubbleView(message: AssistantMessage.samples[1])
        }
        .padding()
    }
}
