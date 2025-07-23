# ----------------------------
# 1. Install & load packages
# ----------------------------
if (!require("lidR")) install.packages("lidR")
if (!require("terra")) install.packages("terra")
if (!require("rgl")) install.packages("rgl")

library(lidR)
library(terra)
library(rgl)

# ----------------------------
# 2. Load LAS file
# ----------------------------
las_path <- "C:/Users/somua/Downloads/482000_5456000/482000_5456000.las"
las <- readLAS(las_path)

# Check if LAS loaded
if (is.empty(las) || is.null(las)) {
  stop("LAS file is empty or path is incorrect. Check file path and unzipped file.")
}

cat("LAS file loaded successfully\n")
print(las)

# ----------------------------
# 3. Ensure ground classification
# ----------------------------
# DEM needs ground points (class 2). If missing, classify automatically.
if (!2 %in% las$Classification) {
  cat("No ground classification detected. Running ground classification...\n")
  las <- classify_ground(las, algorithm = pmf())
}

# ----------------------------
# 4. Optional: Reduce density (if too large)
# ----------------------------
las <- decimate_points(las, homogenize(5)) # 5m spacing to reduce data size

# ----------------------------
# 5. Generate DEM (ground points)
# ----------------------------
cat("Generating DEM...\n")
dem <- grid_terrain(las, res = 1, algorithm = knnidw(k = 10, p = 2))

# ----------------------------
# 6. Generate DSM (surface model)
# ----------------------------
cat("Generating DSM...\n")
dsm <- grid_canopy(las, res = 1, algorithm = p2r())

# ----------------------------
# 7. Canopy Height Model (CHM = DSM - DEM)
# ----------------------------
cat("Creating CHM...\n")
chm <- dsm - dem

# ----------------------------
# 8. Visualization (2D)
# ----------------------------
par(mfrow = c(1, 3))
plot(dem, main = "Digital Elevation Model (DEM)", col = terrain.colors(50))
plot(dsm, main = "Digital Surface Model (DSM)", col = heat.colors(50))
plot(chm, main = "Canopy Height Model (CHM)", col = rev(terrain.colors(50)))

# ----------------------------
# 9. 3D Visualization of CHM (Optional)
# ----------------------------
cat("Generating 3D view of CHM...\n")
chm_points <- as.data.frame(chm, xy = TRUE)  # Extract x,y coords + raster values
colnames(chm_points) <- c("x", "y", "z")

# Remove NA rows
chm_points <- na.omit(chm_points)

open3d()
plot3d(chm_points$x, chm_points$y, chm_points$z,
       col = rev(heat.colors(100))[rank(chm_points$z)],
       size = 2,
       xlab = "X", ylab = "Y", zlab = "Height (m)")

# ----------------------------
# 10. Summary statistics
# ----------------------------
summary_stats <- c(
  Mean_Canopy_Height = mean(chm_points$z, na.rm = TRUE),
  Max_Canopy_Height = max(chm_points$z, na.rm = TRUE),
  Min_Elevation = min(values(dem), na.rm = TRUE),
  Max_Elevation = max(values(dem), na.rm = TRUE)
)
print(summary_stats)

# ----------------------------
# 11. Save outputs
# ----------------------------
writeRaster(dem, "DEM_Vancouver.tif", overwrite = TRUE)
writeRaster(dsm, "DSM_Vancouver.tif", overwrite = TRUE)
writeRaster(chm, "CHM_Vancouver.tif", overwrite = TRUE)

cat("Processing complete! DEM, DSM, and CHM saved as GeoTIFFs.\n")


# app.R
library(shiny)
library(terra)
library(plotly)
library(viridis)

#–– Load DEM once at startup
dem <- rast("DEM_Vancouver.tif")

ui <- fluidPage(
  titlePanel("Interactive DEM 3D Viewer"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("res", "Subsample factor:", 
                  min = 1, max = 20, value = 5, step = 1,
                  helpText("Larger → fewer points → faster")),
      sliderInput("exag", "Vertical Exaggeration:", 
                  min = 1, max = 10, value = 2, step = 0.5)
    ),
    mainPanel(
      plotlyOutput("dem3d", height = "600px")
    )
  )
)

server <- function(input, output, session) {
  
  demData <- reactive({
    # 1. Aggregate (subsample) by factor
    dem_sub <- if (input$res > 1) {
      aggregate(dem, fact = input$res, fun = mean)
    } else {
      dem
    }
    
    # 2. Extract matrix & coords
    vals   <- values(dem_sub)
    ncol_  <- ncol(dem_sub); nrow_ <- nrow(dem_sub)
    mat_z  <- matrix(vals * input$exag, nrow = nrow_, ncol = ncol_, byrow = TRUE)
    x_vec  <- seq(xmin(dem_sub), xmax(dem_sub), length.out = ncol_)
    y_vec  <- rev(seq(ymin(dem_sub), ymax(dem_sub), length.out = nrow_))
    
    list(x = x_vec, y = y_vec, z = mat_z)
  })
  
  output$dem3d <- renderPlotly({
    d <- demData()
    # Choose a 100‑step Viridis palette
    pal <- viridis(100)
    
    # Plotly 3D surface:
    plot_ly(
      x = ~d$x, 
      y = ~d$y, 
      z = ~d$z, 
      type = "surface",
      colors = pal
    ) %>%
      colorbar(title = "Elevation") %>%
      layout(
        scene = list(
          camera = list(eye = list(x=1.5, y=1.5, z=0.8))
        )
      )
  })
}

shinyApp(ui, server)


