import Foundation
import UIKit

func uploadImage(selectedImage: UIImage, initialText: String, completion: @escaping (String, String) -> Void) {
    print("Starting image upload and description generation...")

    let imageData = selectedImage.jpegData(compressionQuality: 0.5)
    let url = URL(string: "https://develop.ewlab.di.unimi.it/descripix/predict")!

    // Create the HTTP request for your server
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Build the request body
    let base64String = imageData?.base64EncodedString() ?? ""
    let json = [
        "text": initialText,
        "image": "data:image/jpeg;base64,\(base64String)"
    ]
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    
    request.httpBody = jsonData
    
    // Send the request to your server
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            return
        }
        
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
               let generatedText = jsonResponse["generated_text"] as? String {
                print("Description from model: \(generatedText)")
                
                // Now call OpenAI API to get a new description
                describeImageWithOpenAI(imageBase64: base64String) { openAIDescription in
                    completion(generatedText, openAIDescription)
                }
            }
        } catch let error {
            print("Error during JSON deserialization", error)
        }
    }.resume()
}

func describeImageWithOpenAI(imageBase64: String, completion: @escaping (String) -> Void) {
    print("Calling OpenAI API...")

    // 1. Prepare the first API request
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    let apiKey = "your api key"

    let headers = [
        "Content-Type": "application/json",
        "Authorization": "Bearer \(apiKey)"
    ]
    
    let payload: [String: Any] = [
        "model": "gpt-4o",
        "messages": [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": "Provide me the name and the artist of the painting in the image without any other words"
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(imageBase64)",
                            "detail": "low"
                        ]
                    ]
                ]
            ]
        ],
        "max_tokens": 300
    ]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: payload)
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = jsonData
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            return
        }
        
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = jsonResponse["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String,
               let usage = jsonResponse["usage"] as? [String: Any],
               let totalTokens = usage["total_tokens"] as? Int {
                
                // 2. Print the content and calculate tokens
                //print("Message Content:", content)
                //print("Total Tokens Used:", totalTokens)
                
                // 3. Craft the detailed description prompt
                let descriptionPrompt = "Provide a detailed description of the painting: \(content)"
                
                // 4. Make the second API request
                let secondPayload: [String: Any] = [
                    "model": "gpt-4o",
                    "messages": [
                        ["role": "user", "content": descriptionPrompt]
                    ]
                ]
                
                let secondJsonData = try? JSONSerialization.data(withJSONObject: secondPayload)
                
                var secondRequest = URLRequest(url: url)
                secondRequest.httpMethod = "POST"
                secondRequest.allHTTPHeaderFields = headers
                secondRequest.httpBody = secondJsonData
                
                URLSession.shared.dataTask(with: secondRequest) { secondData, secondResponse, secondError in
                    guard let secondData = secondData, secondError == nil else {
                        print(secondError?.localizedDescription ?? "No data")
                        return
                    }
                    
                    do {
                        if let secondJsonResponse = try JSONSerialization.jsonObject(with: secondData, options: []) as? [String: Any],
                           let secondChoices = secondJsonResponse["choices"] as? [[String: Any]],
                           let secondMessage = secondChoices.first?["message"] as? [String: Any],
                           let description = secondMessage["content"] as? String,
                           let secondUsage = secondJsonResponse["usage"] as? [String: Any],
                           let secondTotalTokens = secondUsage["total_tokens"] as? Int {
                            
                            // Print final description and token usage
                            print("Description from OpenAI:", description)
                            print("Total Cost:", totalTokens + secondTotalTokens)
                            
                            // Return final description
                            completion(description)
                        }
                    } catch let error {
                        print("Error during JSON deserialization", error)
                    }
                }.resume()
                
            }
        } catch let error {
            print("Error during JSON deserialization", error)
        }
    }.resume()
}
