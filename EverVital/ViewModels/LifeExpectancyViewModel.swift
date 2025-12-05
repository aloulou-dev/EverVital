import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation

@Observable
class LifeExpectancyViewModel {
    var minYears: Int?
    var maxYears: Int?
    var reasoning: String = ""
    var recommendations: [String] = []
    var isLoading = false
    var errorMessage: String?
    var didSaveSuccessfully = false
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func calculateLifeExpectancy() {
        guard let userId = currentUserId else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        minYears = nil
        maxYears = nil
        reasoning = ""
        recommendations = []
        didSaveSuccessfully = false
        
        Task {
            do {
                // Fetch both survey data and HealthKit data
                let document = try await db.collection("users").document(userId).getDocument()
                guard let data = document.data() else {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "No user data found"
                    }
                    return
                }
                
                let surveyData = data["surveyData"] as? [String: Any]
                let healthKitData = data["healthKitData"] as? [String: Any]
                let additionalInfo = data["additionalInfo"] as? String ?? ""
                
                await self.sendToOpenAI(surveyData: surveyData, healthKitData: healthKitData, additionalInfo: additionalInfo)
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func sendToOpenAI(surveyData: [String: Any]?, healthKitData: [String: Any]?, additionalInfo: String) async {
        // Combine data into JSON string
        var combinedData: [String: Any] = [:]
        
        if let survey = surveyData {
            combinedData.merge(survey) { (_, new) in new }
        }
        
        if let healthKit = healthKitData {
            // Only include the health metrics, not the timestamp
            if let steps = healthKit["appleSteps"] as? Int {
                combinedData["appleSteps"] = steps
            }
            if let heartRate = healthKit["appleHeartRate"] as? Double {
                combinedData["appleHeartRate"] = heartRate
            }
            if let sleep = healthKit["appleSleepHours"] as? Double {
                combinedData["appleSleepHours"] = sleep
            }
        }
        
        // Add additional info if provided
        if !additionalInfo.isEmpty {
            combinedData["additionalInfo"] = additionalInfo
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: combinedData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            isLoading = false
            errorMessage = "Failed to format data"
            return
        }
        
        // Create OpenAI API request
        let prompt = """
        You are a specialized health & longevity assistant.

        Using ONLY the information below about the user’s lifestyle, health data, and additional notes, calculate:

        1. A realistic **life expectancy RANGE** (example: "78–84 years").
        2. A list of **specific, personalized, and quantified recommendations**, ordered by the impact they would have on life expectancy.
        3. A short explanation (second person) summarizing the logic behind your evaluation.

        REQUIREMENTS FOR RECOMMENDATIONS:

        - ALWAYS include numerical estimates of impact, such as:
          - “reduces mortality risk by 10–20%”
          - “could add 1–3 years to your life expectancy”
          - “reduces cardiovascular risk by ~30%”
          - "decreases diabetes risk by up to 50%”
        - Speak directly to the user using “you” and “your.”
        - Use ALL provided data, including the user’s additionalInfo text.
        - Be highly specific and actionable:
          - step goals (e.g., “increase to 7,000 steps/day”)
          - sleep targets (e.g., “increase sleep to 7.5 hours”)
          - dietary specifics (“reduce sugary drinks to 1 per week”)
          - alcohol/smoking reduction amounts
          - frequency-based exercise targets
        - Avoid generic advice like “eat better” or “exercise more.”
        - Order the recommendations from greatest projected longevity impact to least.
        
        LIFE EXPECTANCY RULES continued(IMPORTANT):
        - Life expectancy must be realistically lowered when the user has multiple major risk factors.
        - If the user smokes daily, drinks heavily, sleeps < 6 hours, is sedentary, or has obesity, the estimated life expectancy MUST be significantly below the general population average for their country.
        - DO NOT give overly optimistic or inflated life expectancy ranges.
        - When risk factors stack (example: smoker + poor diet + low sleep + no exercise), the range MUST reflect real statistical reductions (5–15+ years below typical averages).
        - Only give high life expectancy ranges when lifestyle patterns are genuinely excellent.
        - Do NOT assume medical intervention unless explicitly stated by the user.

        Base life expectancy benchmarks to anchor realism:
        - Average healthy adult: ~78–82 years (US), ~82–85 years (Europe/Canada)
        - Multiple high-risk behaviors: expect decreases of 5–20+ years
        - Exceptional health habits (rare): increases of 2–5 years above average

        Life expectancy MUST reflect the severity of the habits provided by the user.

        USER INPUT DATA:
        \(jsonString)

        Return the output STRICTLY in this JSON structure:

        {
          "lifeExpectancyRange": "string",
          "recommendations": ["string", "string", "string"],
          "reasoning": "string"
        }
        """
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            isLoading = false
            errorMessage = "Invalid API URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Secrets.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                await MainActor.run {
                    self.errorMessage = "Failed to parse OpenAI response"
                }
                return
            }
            
            // Parse the JSON response from OpenAI
            if let contentData = content.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any] {
                await MainActor.run {
                    // Parse lifeExpectancyRange (e.g., "78–84 years" or "78-84")
                    if let rangeString = parsed["lifeExpectancyRange"] as? String {
                        let (min, max) = self.parseLifeExpectancyRange(rangeString)
                        self.minYears = min
                        self.maxYears = max
                    }
                    
                    self.reasoning = parsed["reasoning"] as? String ?? ""
                    self.recommendations = parsed["recommendations"] as? [String] ?? []
                }
                // Save results to Firestore
                await self.saveLifeExpectancyResults()
            } else {
                // Fallback: try to extract from text
                await MainActor.run {
                    self.parseTextResponse(content)
                }
                // Save results to Firestore even if parsed from text
                if await MainActor.run(body: { self.minYears != nil && self.maxYears != nil }) {
                    await self.saveLifeExpectancyResults()
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Parse life expectancy range string (e.g., "78–84 years" or "78-84")
    private func parseLifeExpectancyRange(_ rangeString: String) -> (Int?, Int?) {
        // Remove "years" and other text, keep only numbers and dash/en-dash
        let cleaned = rangeString.replacingOccurrences(of: "years", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find pattern like "78–84" or "78-84" or "78 to 84"
        let patterns = [
            #"(\d+)[–-](\d+)"#,  // en-dash or hyphen
            #"(\d+)\s+to\s+(\d+)"#,  // "78 to 84"
            #"(\d+)\s+(\d+)"#  // "78 84"
        ]
        
        for pattern in patterns {
            if let range = cleaned.range(of: pattern, options: .regularExpression) {
                let match = String(cleaned[range])
                let numbers = match.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap { Int($0) }
                
                if numbers.count >= 2 {
                    let min = numbers[0]
                    var max = numbers[1]
                    
                    // Ensure range doesn't exceed 10 years
                    if max - min > 10 {
                        max = min + 10
                    }
                    
                    return (min, max)
                }
            }
        }
        
        return (nil, nil)
    }
    
    private func parseTextResponse(_ text: String) {
        // Simple parsing fallback if JSON parsing fails
        var min: Int?
        var max: Int?
        
        // Try to find lifeExpectancyRange in text
        if let rangeMatch = text.range(of: #"lifeExpectancyRange["\s:]*"([^"]+)"#, options: .regularExpression) {
            let match = String(text[rangeMatch])
            if let rangeStart = match.range(of: #""([^"]+)""#, options: .regularExpression) {
                let rangeString = String(match[rangeStart])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                let parsed = parseLifeExpectancyRange(rangeString)
                min = parsed.0
                max = parsed.1
            }
        }
        
        // Fallback: try old format
        if min == nil || max == nil {
            if let minRange = text.range(of: #""min"[\s:]*(\d+)"#, options: .regularExpression) {
                let match = String(text[minRange])
                if let number = Int(match.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                    min = number
                }
            }
            
            if let maxRange = text.range(of: #""max"[\s:]*(\d+)"#, options: .regularExpression) {
                let match = String(text[maxRange])
                if let number = Int(match.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                    max = number
                }
            }
        }
        
        // Ensure range doesn't exceed 10 years
        if let minValue = min, let maxValue = max {
            let range = maxValue - minValue
            if range > 10 {
                // Adjust max to be exactly 10 years from min
                max = minValue + 10
            }
        }
        
        self.minYears = min
        self.maxYears = max
        
        if let reasoningRange = text.range(of: #"reasoning["\s:]*"([^"]+)"#, options: .regularExpression) {
            self.reasoning = String(text[reasoningRange])
        }
        
        // Try to extract recommendations array
        if let recStart = text.range(of: #"recommendations"[\s:]*\["#, options: .regularExpression) {
            let remaining = String(text[recStart.upperBound...])
            if let recEnd = remaining.range(of: #"\]"#, options: .regularExpression) {
                let recString = String(remaining[..<recEnd.lowerBound])
                self.recommendations = recString.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"[] ")) }
                    .filter { !$0.isEmpty }
            }
        }
    }
    
    private func saveLifeExpectancyResults() async {
        guard let userId = currentUserId,
              let min = minYears,
              let max = maxYears else {
            return
        }
        
        let data: [String: Any] = [
            "min": min,
            "max": max,
            "recommendations": recommendations,
            "reasoning": reasoning,
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users").document(userId).setData(["lifeExpectancy": data], merge: true)
            print("✅ Life expectancy results saved successfully!")
            await MainActor.run {
                self.didSaveSuccessfully = true
            }
        } catch {
            print("Error saving life expectancy results: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to save results: \(error.localizedDescription)"
            }
        }
    }
}

