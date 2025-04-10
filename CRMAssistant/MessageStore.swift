import Foundation

class MessageStore: ObservableObject {
    @Published var messages: [Message] = []
    private let apiService = ApiService()
    
    init() {
        // Add welcome message
        let welcomeMessage = Message(content: "Hello! I'm your CRM Assistant. How can I help you today?", isUser: false)
        messages.append(welcomeMessage)
    }
    
    func sendMessage(_ text: String, isUser: Bool) {
        let newMessage = Message(content: text, isUser: isUser)
        messages.append(newMessage)
        
        // If this is a user message, get response from API
        if isUser {
            // Show typing indicator
            let typingMessage = Message(content: "...", isUser: false)
            messages.append(typingMessage)
            
            // Get response from API
            apiService.sendMessage(text) { [weak self] response, error in
                // Remove typing indicator
                self?.messages.removeAll(where: { $0.content == "..." })
                
                if let response = response {
                    // Add response message
                    self?.sendMessage(response, isUser: false)
                } else if let error = error {
                    // Add error message
                    self?.sendMessage("Sorry, I encountered an error: \(error.localizedDescription)", isUser: false)
                }
            }
        }
    }
}
