using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

public class SCPParser
{
    public string ExtractInfoFromScp(string filePath)
    {
        try
        {
            byte[] fileBytes = File.ReadAllBytes(filePath);

            // Convert the byte array to a string, ensuring UTF-8 encoding to handle Turkish characters
            string content = Encoding.UTF8.GetString(fileBytes);

            // Find the starting point of the data block after "SCPECG"
            int startIndex = content.IndexOf("SCPECG");
            if (startIndex == -1) return "SCPECG marker not found.";

            // Skip the "SCPECG" marker and any other initial characters
            content = content.Substring(startIndex + "SCPECG".Length);

            // Find the position of "1958" or another marker to limit the extraction range
            int endIndex = content.IndexOf("1958");
            if (endIndex == -1) return "End marker not found.";

            // Extract the substring between the markers
            string relevantContent = content.Substring(0, endIndex);

            // Split the content by non-word characters, preserving Turkish characters and filtering out single character words
            string[] words = Regex.Split(relevantContent, @"\W+");
            string name = string.Empty;
            string id = string.Empty;

            // Iterate over the words to find the name and ID
            foreach (string word in words)
            {
                if (word.Length > 1 && string.IsNullOrEmpty(id))
                {
                    if (Regex.IsMatch(word, @"^\d+$")) // Word is numeric, likely the ID
                    {
                        id = word;
                    }
                    else
                    {
                        if (!string.IsNullOrEmpty(name))
                        {
                            name += " ";
                        }
                        name += word;  // Add to the name
                    }
                }
            }

            if (!string.IsNullOrEmpty(name) && !string.IsNullOrEmpty(id))
            {
                return $"Name: {name}\nID: {id}";
            }

            return "Patient information not found.";
        }
        catch (Exception ex)
        {
            return $"Error reading the file: {ex.Message}";
        }
    }
    public int[][] ReadScpFile(string filePath)
    {
        try
        {
            // Read the SCP-ECG file and extract ECG data
            byte[] fileBytes = File.ReadAllBytes(filePath);

            // Extract ECG data from the fileBytes
            int[][] ecgData = ExtractEcgData(fileBytes);

            return ecgData;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error reading the SCP-ECG file: {ex.Message}");
            return null;
        }
    }

   public int[][] ExtractEcgData(byte[] fileBytes)
{
    try
    {
        Console.WriteLine("Starting SCP-ECG data extraction...");

        // Define how many leads are expected
        const int numLeads = 8; // For example: I, II, V1, V2, V3, V4, V5, V6
        const int expectedLength = 10000; // Adjust this to your expected minimum file size

        // Check if the file has sufficient length
        if (fileBytes.Length < expectedLength)
        {
            throw new Exception($"File is too short to be a valid SCP-ECG file. Expected at least {expectedLength} bytes.");
        }

        // Create an array to hold the ECG data for each lead
        int[][] ecgData = new int[numLeads][];

        // Loop through each lead and extract data
        for (int leadIndex = 0; leadIndex < numLeads; leadIndex++)
        {
            Console.WriteLine($"Parsing lead {leadIndex + 1}...");

            // Set the starting index for this lead
            int startIndex = 1000 + (leadIndex * 1000); // Adjust this to your format

            // Ensure that the start index is within bounds
            if (startIndex >= fileBytes.Length)
            {
                throw new Exception($"Invalid SCP-ECG file: insufficient data length for lead {leadIndex + 1}.");
            }

            // Determine the number of data points to extract for this lead
            int numDataPoints = 5000; // Adjust based on actual data format

            // Ensure we do not read beyond the file bounds
            if (startIndex + numDataPoints * 2 > fileBytes.Length)
            {
                throw new Exception($"Invalid SCP-ECG file: insufficient data length for lead {leadIndex + 1}.");
            }

            // Initialize the array to store data for this lead
            ecgData[leadIndex] = new int[numDataPoints];

            // Extract the data points
            for (int i = 0; i < numDataPoints; i++)
            {
                // Convert two bytes to a 16-bit signed integer (ECG data point)
                ecgData[leadIndex][i] = -BitConverter.ToInt16(fileBytes, startIndex + i * 2);
            }

            Console.WriteLine($"Lead {leadIndex + 1} parsed successfully.");
        }

        Console.WriteLine("SCP-ECG data extraction completed successfully.");
        return ecgData;
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error during SCP-ECG data extraction: {ex.Message}\n{ex.StackTrace}");
        throw;  // Rethrow the exception so that it can be caught in the calling method
    }
}



}
