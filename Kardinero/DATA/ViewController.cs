using ObjCRuntime;
namespace Kardinero;


public partial class ViewController : NSViewController
{
  


    protected ViewController(NativeHandle handle) : base(handle)
    {
        // This constructor is required if the view controller is loaded from a xib or a storyboard.
        // Do not put any initialization here, use ViewDidLoad instead.
    }

    public override void ViewDidLoad()
    {
        base.ViewDidLoad();
        addFileButton.Activated += OnAddFileButtonClicked;
        findInfo.Activated += OnInfoButtonClicked;

    }


    public override NSObject RepresentedObject
    {
        get => base.RepresentedObject;
        set
        {
            base.RepresentedObject = value;

            // Update the view, if already loaded.
        }
    }
    private void OnAddFileButtonClicked(object sender, EventArgs e)
    {
        var openPanel = NSOpenPanel.OpenPanel;

        openPanel.AllowsMultipleSelection = false;
        openPanel.AllowedFileTypes = new string[] { "scp" };
        openPanel.CanChooseDirectories = false;
        openPanel.CanCreateDirectories = false;

        if (openPanel.RunModal() == 1) // If user clicks "Open"
        {
            var filePath = openPanel.Url.Path;

            try
            {
                // Read the SCP-ECG file and extract the ECG data
                var scpParser = new SCPParser();
                int[][] ecgData = scpParser.ExtractEcgData(File.ReadAllBytes(filePath));

                // Create a new window to display the ECG plot
                var ecgWindowController = new EcgWindowController(ecgData);
                ecgWindowController.ShowWindow(this);
            }
            catch (Exception ex)
            {
                // Log the error with detailed information
                Console.WriteLine($"Error reading the SCP-ECG file: {ex.Message}\n{ex.StackTrace}");

                var alert = new NSAlert
                {
                    AlertStyle = NSAlertStyle.Critical,
                    MessageText = "Error",
                    InformativeText = $"Failed to read the SCP-ECG file. Please ensure the file is valid.\nError: {ex.Message}",
                };
                alert.RunModal();
            }
        }
    }





    private void ShowFileContent(string filePath)
    {
        if (File.Exists(filePath))
        {
            // Read the file content
            var fileContent = File.ReadAllText(filePath);

            // Create and show a new window with the file content
            var contentWindowController = new ContentWindowController(fileContent);
            contentWindowController.ShowWindow(this);
        }
        else
        {
            Console.WriteLine("File not found.");
        }
    }
    private void OnInfoButtonClicked(object sender, EventArgs e)
    {
        // Open file dialog for the user to select an SCP file
        var openPanel = NSOpenPanel.OpenPanel;
        openPanel.AllowsMultipleSelection = false;
        openPanel.CanChooseDirectories = false;
        openPanel.CanCreateDirectories = false;
        openPanel.AllowedFileTypes = new string[] { "scp" };

        if (openPanel.RunModal() == 1) // User clicked "Open"
        {
            var filePath = openPanel.Url.Path;

            // Extract and display the information
            SCPParser parser = new SCPParser();
            string patientInfo = parser.ExtractInfoFromScp(filePath);

            // Display the information in a new window
            var infoWindowController = new InfoWindowController(patientInfo);
            infoWindowController.ShowWindow(this);
        }
    }
    public int[][] ReadScpData(string filePath)
    {
        try
        {
            // Read the SCP-ECG file as bytes
            byte[] fileBytes = File.ReadAllBytes(filePath);

            // Example: Assume each channel has 1000 data points, and there are 12 channels
            int numChannels = 12;
            int numDataPoints = 1000;

            // Create a 2D array to hold ECG data for 12 channels
            int[][] ecgChannels = new int[numChannels][];

            for (int i = 0; i < numChannels; i++)
            {
                ecgChannels[i] = new int[numDataPoints];

                // Example: Fill with mock data (replace with real parsing logic)
                for (int j = 0; j < numDataPoints; j++)
                {
                    ecgChannels[i][j] = fileBytes[(i * numDataPoints) + j]; // Simplified logic
                }
            }

            return ecgChannels;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error reading the SCP-ECG file: {ex.Message}");
            return null;
        }
    }

    private int[][] ExtractEcgData(byte[] fileBytes)
    {
        const int startIndex = 1000; // Adjust as needed
        int numberOfDataPoints = 5000; // Example length, adjust based on real data

        int[][] ecgData = new int[12][]; // 12 leads

        // Extract primary leads (I, II, V1-V6)
        for (int lead = 0; lead < 8; lead++)
        {
            if (fileBytes.Length < startIndex + numberOfDataPoints * 2)
            {
                throw new Exception($"Invalid SCP-ECG file: insufficient data length for lead {lead + 1}.");
            }

            ecgData[lead] = new int[numberOfDataPoints];
            for (int i = 0; i < numberOfDataPoints; i++)
            {
                ecgData[lead][i] = BitConverter.ToInt16(fileBytes, startIndex + lead * numberOfDataPoints * 2 + i * 2);
            }
        }

        // Calculate derived leads
        int[] leadI = ecgData[0];
        int[] leadII = ecgData[1];
        int[] leadIII = new int[numberOfDataPoints];
        int[] aVR = new int[numberOfDataPoints];
        int[] aVL = new int[numberOfDataPoints];
        int[] aVF = new int[numberOfDataPoints];

        for (int i = 0; i < numberOfDataPoints; i++)
        {
            leadIII[i] = leadII[i] - leadI[i];
            aVR[i] = -(leadI[i] + leadII[i]) / 2;
            aVL[i] = (leadI[i] - leadIII[i]) / 2;
            aVF[i] = (leadII[i] + leadIII[i]) / 2;
        }

        // Assign derived leads to the ecgData array
        ecgData[2] = leadIII;
        ecgData[3] = aVR;
        ecgData[4] = aVL;
        ecgData[5] = aVF;

        // V1-V6 are already in place

        return ecgData;
    }

}


