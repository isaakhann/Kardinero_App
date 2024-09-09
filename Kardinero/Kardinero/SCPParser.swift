import Foundation

class SCPParser {
    
    func extractInfoFromScp(filePath: String) -> String {
        do {
            // Read file as data
            let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            
            // Process the binary data to extract readable patient information
            let rawPatientInfo = extractRelevantData(from: fileData)

            // Clean up and format the extracted string as Name and ID
            let formattedInfo = formatPatientInfo(rawPatientInfo)
            
            return formattedInfo

        } catch {
            return "Error reading the file: \(error.localizedDescription)"
        }
    }

    private func extractRelevantData(from data: Data) -> String? {
        // Convert data to string
        let fileString = String(decoding: data, as: UTF8.self)

        // Find the positions of "SCPECG" and "1958"
        guard let startRange = fileString.range(of: "SCPECG"),
              let endRange = fileString.range(of: "1958") else {
            return nil
        }

        // Extract the substring between the markers and convert it to String
        let relevantSubstring = fileString[startRange.upperBound..<endRange.lowerBound]
        let relevantString = String(relevantSubstring) // Convert Substring to String

        // Process the extracted string to filter out irrelevant parts
        return processBinaryData(relevantString)
    }

    private func processBinaryData(_ data: String) -> String {
        var result = ""
        var isRecording = false
        var nameBuffer = ""

        // Mapping Turkish characters to their English equivalents
        let turkishToEnglishMap: [Character: Character] = [
            "ç": "c", "Ç": "C",
            "ğ": "g", "Ğ": "G",
            "ı": "i", "İ": "I",
            "ö": "o", "Ö": "O",
            "ş": "s", "Ş": "S",
            "ü": "u", "Ü": "U"
        ]

        for char in data {
            // Replace Turkish characters with their English equivalents if necessary
            let processedChar = turkishToEnglishMap[char] ?? char
            
            if processedChar.isLetter {
                // Start recording alphabetic sequences, using English equivalents for Turkish characters
                nameBuffer.append(processedChar)
                isRecording = true
            } else if processedChar.isNumber {
                if isRecording && nameBuffer.count > 1 {
                    // Only add the name if it has more than one character
                    result += nameBuffer + " "
                    nameBuffer = ""
                }
                result += String(processedChar)
                isRecording = false
            } else {
                if isRecording && nameBuffer.count > 1 {
                    // Save the valid name if it's longer than one character
                    result += nameBuffer + " "
                    nameBuffer = ""
                }
                isRecording = false
            }
        }

        // Add any remaining buffer content (for cases like "Ahmet")
        if !nameBuffer.isEmpty {
            result += nameBuffer + " "
        }

        print("Extracted patient info as ASCII string: \(result)")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }



    private func formatPatientInfo(_ rawInfo: String?) -> String {
        guard let rawInfo = rawInfo, !rawInfo.isEmpty else {
            return "Patient information not found."
        }

        // Split the cleaned string into words, trimming extra spaces
        let words = rawInfo.split(separator: " ").map { String($0) }
        
        // Variables to hold the extracted name and ID
        var nameParts: [String] = []
        var id: String = ""
        
        // Search for name and ID patterns in the words
        for word in words {
            if word.allSatisfy({ $0.isLetter }) && word.count > 1 {
                // Assuming the patient's name will be alphabetic and not a single character
                nameParts.append(word)
            } else if word.allSatisfy({ $0.isNumber }), id.isEmpty {
                // Assuming the ID will be numeric
                id = word
            } else if word.count > 1 {
                // Check for common ID or name patterns if needed (like mixed alphanumeric parts)
                if word.rangeOfCharacter(from: .decimalDigits) != nil {
                    id = word
                } else {
                    nameParts.append(word)
                }
            }
        }

        // Combine name parts into a full name
        let name = nameParts.joined(separator: " ")

        if !name.isEmpty && !id.isEmpty {
            return "Name: \(name)\nID: \(id)"
        } else {
            return "Patient information not found."
        }
    }


    func extractEcgData(fileBytes: Data) throws -> [[Int]] {
        print("Starting SCP-ECG data extraction...")
        
        let numLeads = 8 // For example: I, II, V1, V2, V3, V4, V5, V6
        let expectedLength = 40000 // Adjust this to your expected minimum file size
        
        // Check if the file has sufficient length
        guard fileBytes.count >= expectedLength else {
            throw NSError(domain: "SCPParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "File is too short to be a valid SCP-ECG file. Expected at least \(expectedLength) bytes."])
        }
        
        // Initialize the array to store ECG data for each lead
        var ecgData = [[Int]](repeating: [Int](), count: numLeads)
        
        for leadIndex in 0..<numLeads {
            print("Parsing lead \(leadIndex + 1)...")
            
            // Set the starting index for this lead
            let startIndex = 1000 + (leadIndex * 1000) // Adjust this based on your SCP file format
            
            // Ensure that the start index is within bounds
            guard startIndex < fileBytes.count else {
                throw NSError(domain: "SCPParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid SCP-ECG file: insufficient data length for lead \(leadIndex + 1)."])
            }
            
            // Determine the number of data points to extract for this lead
            let numDataPoints = 5000 // Adjust based on actual data format
            
            // Ensure we do not read beyond the file bounds
            guard startIndex + numDataPoints * 2 <= fileBytes.count else {
                throw NSError(domain: "SCPParser", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid SCP-ECG file: insufficient data length for lead \(leadIndex + 1)."])
            }
            
            // Extract the data points
            var leadData = [Int]()
            for i in 0..<numDataPoints {
                let dataPointStartIndex = startIndex + i * 2
                let dataPoint = -Int16(bitPattern: UInt16(fileBytes[dataPointStartIndex]) | UInt16(fileBytes[dataPointStartIndex + 1]) << 8)
                leadData.append(Int(dataPoint))
            }
            
            ecgData[leadIndex] = leadData
            print("Lead \(leadIndex + 1) parsed successfully.")
        }
        
        print("SCP-ECG data extraction completed successfully.")
        return ecgData
    }

}
