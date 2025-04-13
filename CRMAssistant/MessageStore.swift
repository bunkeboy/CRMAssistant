// MessageStore.swift
import Foundation
import SwiftUI

class MessageStore: ObservableObject {
    @Published var messages: [Message] = []
    private let intentAnalyzer: IntentAnalyzer
    private let crmService: CRMService
    private let responseGenerator: ResponseGenerator
    private var isProcessing = false
    
    init() {
        self.intentAnalyzer = IntentAnalyzer(openAIAPIKey: APIKeys.openAI)
        self.crmService = CRMService(apiKey: APIKeys.followUpBoss)
        self.responseGenerator = ResponseGenerator(openAIAPIKey: APIKeys.openAI)
        
        // Add welcome message
        let welcomeMessage = Message(content: "Hello! I'm your CRM Assistant. How can I help you today?", isUser: false)
        messages.append(welcomeMessage)
    }
    
    func sendMessage(_ text: String, isUser: Bool) {
        let newMessage = Message(content: text, isUser: isUser)
        messages.append(newMessage)
        
        // If this is a user message, process it
        if isUser && !isProcessing {
            processUserMessage(text)
        }
    }
    
    private func processUserMessage(_ message: String) {
        // Show typing indicator
        isProcessing = true
        let typingMessage = Message(content: "...", isUser: false)
        messages.append(typingMessage)
        
        // Process in background
        Task {
            do {
                // Step 1: Analyze intent
                let intent = try await intentAnalyzer.analyzeIntent(userMessage: message)
                
                // Step 2: Call appropriate CRM endpoint
                let crmData: Any
                
                switch intent.action {
                case .getPeople(let query):
                    crmData = try await crmService.getPeople(query: query)
                case .getTasks(let query):
                    crmData = try await crmService.getTasks(query: query)
                case .getAppointments(let query):
                    crmData = try await crmService.getAppointments(query: query)
                case .getLeads(let query):
                    // For this example, we'll treat leads as people with a specific filter
                    crmData = try await crmService.getPeople(query: "stage:Lead \(query ?? "")")
                case .unknown:
                    // Handle unknown intent - perhaps use a generic AI response
                    crmData = ["error": "I couldn't determine what CRM data you need."]
                }
                
                // Step 3: Generate natural language response
                let response = try await responseGenerator.generateResponse(
                    userMessage: message,
                    crmData: crmData
                )
                
                // Step 4: Update UI on main thread
                await MainActor.run {
                    // Remove typing indicator
                    self.messages.removeAll(where: { $0.content == "..." })
                    
                    // Add response message
                    self.sendMessage(response, isUser: false)
                    self.isProcessing = false
                }
            } catch {
                // Handle errors
                await MainActor.run {
                    // Remove typing indicator
                    self.messages.removeAll(where: { $0.content == "..." })
                    
                    // Add error message
                    self.sendMessage("Sorry, I encountered an error: \(error.localizedDescription)", isUser: false)
                    self.isProcessing = false
                }
            }
        }
    }
}
