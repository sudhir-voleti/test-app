#################################################################
# Simple Sound Wave Visualizer Shiny App
#
# Description:
# Visualizes a basic waveform based on user-entered text.
# Maps letters (A-Z) to frequencies and uses case (upper/lower)
# to determine amplitude (loud/soft).
#
# Features:
# - Text input for phrase.
# - Uppercase letters = higher amplitude.
# - Lowercase letters = lower amplitude.
# - Plots the resulting waveform.
# - Annotates the x-axis with corresponding letters.
#
# How to Run:
# 1. Save this code as 'app.R'.
# 2. Open R or RStudio.
# 3. Ensure you have internet access (for potential package install).
# 4. If in RStudio, click 'Run App' button.
# 5. If in R console, navigate to the directory containing 'app.R'
#    using setwd() and then run: shiny::runApp()
#
# Author: [Your Name/Sudhir Voleti - Optional]
# Date: [Current Date]
#################################################################

# --- Setup Chunk: Install and Load Required Packages ---

# Check if 'shiny' package is installed, install if not
if (!requireNamespace("shiny", quietly = TRUE)) {
  message("Package 'shiny' not found. Installing...")
  install.packages("shiny")
}

# Load the Shiny library
library(shiny)

# --- Configuration ---

# 1. Define a simple mapping from letters to frequencies (Hz)
#    (These are just example frequencies, not perfectly musically accurate C-major scale)
note_freq <- c(A = 262, B = 294, C = 330, D = 349, E = 392, F = 440, G = 494,
               H = 523, I = 587, J = 659, K = 698, L = 784, M = 880, N = 988,
               O = 1047, P = 1175, Q = 1319, R = 1397, S = 1568, T = 1760, U = 1976,
               V = 2093, W = 2349, X = 2489, Y = 2794, Z = 3136)

# 2. Define Amplitudes
amplitude_loud <- 1.0  # Amplitude for uppercase letters
amplitude_soft <- 0.4  # Amplitude for lowercase letters

# 3. Wave Generation Parameters
duration_per_note <- 0.1 # How long each note's wave segment lasts (in seconds)
sample_rate <- 2000     # How many data points per second (affects smoothness)

# --- Define the User Interface (UI) ---
ui <- fluidPage(
    # Application title
    titlePanel("Simple Sound Wave Visualizer (with Amplitude!)"),

    # Sidebar layout with input and output definitions
    sidebarLayout(
        # Sidebar panel for inputs
        sidebarPanel(
            textInput("inputText",            # Input ID used in the server code
                      "Enter Text (A-Z, a-z):", # Label displayed to the user
                      value = "SoFt LOUD soFt"),# Default starting value
            helpText("Use CAPS for LOUD sounds and lowercase for soft sounds. Non-letters are ignored.")
        ),

        # Main panel for displaying outputs
        mainPanel(
           # Output: Display the generated plot
           plotOutput("soundPlot")          # Output ID used in the server code
        )
    )
)

# --- Define the Server Logic ---
server <- function(input, output) {

    # Reactive expression to generate the plot
    output$soundPlot <- renderPlot({

        # --- 1. Get and Process Input ---
        user_text <- input$inputText
        # Require() makes sure there's text before proceeding
        req(user_text)

        # Split into characters *before* changing case to preserve original
        original_chars <- strsplit(user_text, "")[[1]]

        # Create an uppercase version for frequency lookup
        chars_upper <- toupper(original_chars)

        # Look up frequencies based on the uppercase version
        frequencies <- note_freq[chars_upper]

        # Identify valid characters (A-Z, ignoring case for validity check)
        valid_indices <- !is.na(frequencies)

        # Ensure we have at least one valid letter frequency before proceeding
        req(sum(valid_indices) > 0)

        # Get the valid frequencies
        valid_frequencies <- frequencies[valid_indices]
        # Get the *original case* valid characters corresponding to valid frequencies
        valid_original_chars <- original_chars[valid_indices]


        # --- 2. Generate Wave Data ---
        # Create a time sequence for a single note's duration
        t_note <- seq(0, duration_per_note, length.out = floor(duration_per_note * sample_rate))

        # Initialize an empty vector to store the final combined wave
        wave <- numeric(0)

        # Loop through each valid frequency and its original character
        for (i in 1:length(valid_frequencies)) {
            freq <- valid_frequencies[i]
            char <- valid_original_chars[i]

            # Determine amplitude based on original case (uppercase = loud, lowercase = soft)
            current_amplitude <- ifelse(char %in% LETTERS, amplitude_loud, amplitude_soft)
            # Note: LETTERS is a built-in R constant for A-Z uppercase

            # Generate wave segment: Amplitude * sin(2 * pi * frequency * time)
            note_wave_segment <- current_amplitude * sin(2 * pi * freq * t_note)

            # Append this segment to the main wave vector
            wave <- c(wave, note_wave_segment)
        }

        # Create a corresponding time vector for the *entire* combined wave
        num_notes <- length(valid_frequencies)
        total_duration <- num_notes * duration_per_note
        # Ensure t_total has the same length as the 'wave' data
        t_total <- seq(0, total_duration, length.out = length(wave))


        # --- 3. Create the Plot ---

        # Adjust plot margins slightly to make space for labels below axis
        # Format: c(bottom, left, top, right) - adding extra space at the bottom
        par(mar = c(5.1, 4.1, 4.1, 2.1) + c(1.5, 0, 0, 0))

        # Create the main plot, including standard x-axis time labels
        plot(t_total, wave,
             type = 'l',                         # 'l' for line plot
             col = "dodgerblue",                 # Color of the line
             lwd = 1.5,                          # Line width (slightly thicker)
             xlab = "",                          # Remove default x-label, we add it manually later
             ylab = "Amplitude",                 # Y-axis label
             main = paste("Waveform for:", user_text) # Plot title using original input text
             # We keep the default numeric x-axis labels this time
             )
        grid() # Add a background grid

        # --- 4. Add Custom X-axis Annotations ---

        # Calculate positions for vertical lines (boundaries between notes)
        # Don't draw a line before the first note or after the last one
        boundary_times <- seq(from = duration_per_note,
                              by = duration_per_note,
                              length.out = num_notes - 1) # Only need N-1 lines for N notes

        # Calculate positions for the letter labels (midpoints of each note segment)
        midpoint_times <- seq(from = duration_per_note / 2,
                              by = duration_per_note,
                              length.out = num_notes)

        # Add vertical dashed lines at the boundaries (only if more than one note)
        if (num_notes > 1) {
           abline(v = boundary_times, col = "grey80", lty = "dashed") # Lighter grey dashed lines
        }

        # Add the letter labels (using original case) below the numeric axis
        # 'side = 1' means below the plot
        # 'line = 2.5' adjusts vertical position relative to axis numbers
        # 'cex = 0.9' makes the font slightly smaller
        mtext(text = valid_original_chars, side = 1, line = 2.5, at = midpoint_times, cex = 0.9)

        # Add the overall X-axis title below the letters
        # Adjust 'line' to position it further down
        title(xlab = "Time (s) / Letter Segments", line = 4.0)

    }) # End renderPlot
}

# --- Run the Application ---
shinyApp(ui = ui, server = server)
