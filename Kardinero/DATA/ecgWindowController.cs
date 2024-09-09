using System;
using AppKit;
using CoreGraphics;
using Foundation;
using ScottPlot;
using System.Linq;
using System.Collections.Generic;
using SkiaSharp;
using CoreAnimation;
using ScottPlot.Colormaps;

public class EcgWindowController : NSWindowController, INSWindowDelegate
{
    private int[][] _ecgData;
    private NSGridView _grid;
    private NSScrollView _scrollView;
    private List<NSView> _addedViews; // Track added views
    private string _currentLead = "All Leads"; // Track the currently selected lead

    public EcgWindowController(int[][] ecgData) : base()
    {
        _ecgData = ecgData;
        _addedViews = new List<NSView>(); // Initialize tracking list
        InitializeWindow();
    }

    private void InitializeWindow()

    {
        var rect = new CGRect(0, 0, 1200, 800); // Initial window size
        var window = new NSWindow(rect, NSWindowStyle.Titled | NSWindowStyle.Resizable | NSWindowStyle.Closable, NSBackingStore.Buffered, false)
        {
            Title = "ECG Waveform",
            Delegate = this  // Set the window delegate to the current controller
        };

        // Create the dropdown button (NSPopUpButton)
        var dropdown = new NSPopUpButton(new CGRect(20, 740, 200, 25), false);
        dropdown.AddItems(new string[] { "All Leads", "Lead I", "Lead II", "Lead III", "Lead V1", "Lead V2", "Lead V3", "Lead V4", "Lead V5", "Lead V6", "Lead aVR", "Lead aVL", "Lead aVF" });
        dropdown.Activated += Dropdown_Activated;

        // Create the scroll view
        _scrollView = new NSScrollView
        {
            Frame = new CGRect(0, 0, 1200, 700),
            HasVerticalScroller = true,
            HasHorizontalScroller = false,
            AutohidesScrollers = true
        };

        // Create a grid to hold the plots
        _grid = new NSGridView
        {
            ColumnSpacing = 0, // Remove column spacing
            RowSpacing = 10    // Add spacing between rows for visibility
        };

        // Add the default plots to the grid
        AddEcgPlotsToGrid("All Leads", 1200, 200); // Initial plot size based on window size

        // Add the grid to the scroll view's document view
        _scrollView.DocumentView = _grid;

        // Set the scroll position to the top of the document view
        _scrollView.ContentView.ScrollToPoint(new CGPoint(0, _scrollView.DocumentView.Frame.Size.Height));

        // Create a container view for dropdown and scrollable grid
        var containerView = new NSView(new CGRect(0, 0, 1200, 800));
        containerView.AddSubview(dropdown);
        containerView.AddSubview(_scrollView);

        window.ContentView = containerView;
        window.MakeKeyAndOrderFront(this);
        this.Window = window;
    }

    [Export("windowDidResize:")]
    public void DidResize(NSNotification notification)
    {
        var window = this.Window;

        if (window == null)
        {
            Console.WriteLine("Window is not initialized.");
            return;
        }

        var newSize = window.Frame.Size;

        if (newSize == CGSize.Empty)
        {
            Console.WriteLine("Window size is not available.");
            return;
        }

        // Update grid and plot sizes based on the new window size
        double newGridWidth = newSize.Width;
        double newGridHeight = newSize.Height - 100; // Leave some space for the dropdown

        // Adjust grid frame and plot sizes dynamically
        _grid.Frame = new CGRect(0, 0, newGridWidth, newGridHeight);
        AddEcgPlotsToGrid(_currentLead, (int)newGridWidth, 200); // Adjust the plot sizes
        _scrollView.DocumentView = _grid;
    }

    private void Dropdown_Activated(object sender, EventArgs e)
    {
        var dropdown = sender as NSPopUpButton;
        _currentLead = dropdown.SelectedItem.Title; // Update the current lead

        // Clear the grid and remove all added views
        foreach (var view in _grid.Subviews)
        {
            view.RemoveFromSuperview(); // Remove each view from the grid
        }
        _addedViews.Clear(); // Clear the tracking list

        // Determine the plot size based on the selected lead
        int plotWidth = (int)_scrollView.Frame.Width;
        int plotHeight = _currentLead == "All Leads" ? 200 : 400; // Height based on lead selection

        // Add new ECG plots to the grid
        AddEcgPlotsToGrid(_currentLead, plotWidth, plotHeight);

        // Update the scroll view's document view and adjust scroll position
        _scrollView.DocumentView = _grid;
        _scrollView.ContentView.ScrollToPoint(new CGPoint(0, _scrollView.DocumentView.Frame.Size.Height));
        _scrollView.ReflectScrolledClipView(_scrollView.ContentView); // Ensure the scroll position is updated
    }
    private void AddEcgPlotsToGrid(string leadToShow, int plotWidth, int plotHeight)
    {
        // Clear the grid first by removing all the rows
        while (_grid.RowCount > 0)
        {
            _grid.RemoveRow(0);
        }

        // Extract and prepare ECG data for plotting
        double[] leadI = _ecgData[0].Select(v => (double)v).ToArray();
        double[] leadII = _ecgData[1].Select(v => (double)v).ToArray();
        double[] leadV1 = _ecgData[2].Select(v => (double)v).ToArray();
        double[] leadV2 = _ecgData[3].Select(v => (double)v).ToArray();
        double[] leadV3 = _ecgData[4].Select(v => (double)v).ToArray();
        double[] leadV4 = _ecgData[5].Select(v => (double)v).ToArray();
        double[] leadV5 = _ecgData[6].Select(v => (double)v).ToArray();
        double[] leadV6 = _ecgData[7].Select(v => (double)v).ToArray();

        // Calculate derived leads
        double[] leadIII = leadII.Zip(leadI, (ii, i) => ii - i).ToArray();
        double[] leadAVR = leadI.Zip(leadII, (i, ii) => -(i + ii) / 2).ToArray();
        double[] leadAVL = leadI.Zip(leadIII, (i, iii) => (i - iii) / 2).ToArray();
        double[] leadAVF = leadII.Zip(leadIII, (ii, iii) => (ii + iii) / 2).ToArray();

        // Define the leads to be plotted
        var leads = new[]
        {
        new { Name = "Lead I", Data = leadI },
        new { Name = "Lead II", Data = leadII },
        new { Name = "Lead III", Data = leadIII },
        new { Name = "Lead V1", Data = leadV1 },
        new { Name = "Lead V2", Data = leadV2 },
        new { Name = "Lead V3", Data = leadV3 },
        new { Name = "Lead V4", Data = leadV4 },
        new { Name = "Lead V5", Data = leadV5 },
        new { Name = "Lead V6", Data = leadV6 },
        new { Name = "Lead aVR", Data = leadAVR },
        new { Name = "Lead aVL", Data = leadAVL },
        new { Name = "Lead aVF", Data = leadAVF }
    };

        // If "All Leads" is selected, display all plots
        if (leadToShow == "All Leads")
        {
            // Resize the grid to fit all leads
            int newGridHeight = leads.Length * plotHeight + (leads.Length - 1) * (int)_grid.RowSpacing;
            _grid.Frame = new CGRect(0, 0, plotWidth, newGridHeight);

            // Add each lead plot to the grid
            foreach (var lead in leads)
            {
                var plt = CreatePlotForLead(lead.Name, lead.Data, plotWidth, plotHeight);
                var imageView = new NSImageView { Image = plt };

                _grid.AddRow(new[] { imageView });
                _addedViews.Add(imageView);
            }
        }
        else
        {
            // Display only the selected lead
            foreach (var lead in leads)
            {
                if (lead.Name == leadToShow)
                {
                    var plt = CreatePlotForLead(lead.Name, lead.Data, plotWidth, plotHeight);
                    var ecgView = new NSImageView { Image = plt };

                    _grid.Frame = new CGRect(0, 0, plotWidth, plotHeight); // Resize grid for a single lead
                    _grid.AddRow(new[] { ecgView });
                    _addedViews.Add(ecgView);
                }
            }
        }
    }

    private NSImage CreatePlotForLead(string leadName, double[] ecgData, int width, int height)
    {
        // Create the plot
        var plt = new ScottPlot.Plot();

        // Generate x-axis data (time axis)
        double[] timeData = new double[ecgData.Length];
        for (int i = 0; i < timeData.Length; i++)
            timeData[i] = i / 1000.0; // Assuming data is in milliseconds

        // Add the scatter plot for the ECG signal
        plt.Add.Scatter(timeData, ecgData);
        plt.Title(leadName);

        // Render the plot as an SKImage and return it as NSImage
        using (var surface = SKSurface.Create(new SKImageInfo(width, height)))
        {
            plt.Render(surface.Canvas, width, height);
            using (var skImage = surface.Snapshot())
            {
                NSData imgData = SKImageToNSData(skImage);
                return new NSImage(imgData);
            }
        }
    }

    // Convert SkiaSharp.SKImage to NSData
    private NSData SKImageToNSData(SKImage skImage)
    {
        using (var skData = skImage.Encode(SKEncodedImageFormat.Png, 100))
        {
            if (skData == null) return null;
            return NSData.FromArray(skData.ToArray());
        }
    }
}

public class EcgView : NSView
{
    private readonly CGImage _plotImage;
    private nfloat _zoomFactor = 1.0f;
    private bool _isSinglePlot;

    public EcgView(NSImage plotImage, bool isSinglePlot)
    {
        _plotImage = plotImage.AsCGImage();
        _isSinglePlot = isSinglePlot;

        WantsLayer = true;
        Layer.Contents = _plotImage;

        if (_isSinglePlot)
        {
            // Enable pinch-to-zoom gestures only if displaying a single plot
            AcceptsTouchEvents = true;
            WantsRestingTouches = true;
        }
    }

    public override void MagnifyWithEvent(NSEvent theEvent)
    {

        // Handle pinch gestures (zoom in/out)
        _zoomFactor += theEvent.Magnification;
        _zoomFactor = (float)Math.Max(0.5f, Math.Min(_zoomFactor, 5.0f)); // Limit zoom factor

        // Apply zoom by scaling the layer
        Layer.Transform = CATransform3D.MakeScale(_zoomFactor, _zoomFactor, 1.0f);
    }

    public override void ScrollWheel(NSEvent theEvent)
    {
        // Scroll the view when using the scroll wheel
        base.ScrollWheel(theEvent);
    }
}

public static class NSImageExtensions
{
    // Convert NSImage to CGImage
    public static CGImage AsCGImage(this NSImage nsImage)
    {
        var imageData = nsImage.AsTiff();
        using (var imageRep = NSBitmapImageRep.ImageRepFromData(imageData) as NSBitmapImageRep)
        {
            return imageRep?.CGImage;
        }
    }
}
