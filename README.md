# LiDAR DEM/DSM/CHM Explorer

This repository contains an end-to-end workflow for processing raw LiDAR point cloud data (LAS) into Digital Elevation Model (DEM), Digital Surface Model (DSM), and Canopy Height Model (CHM), along with an interactive Shiny application to visualize and explore these layers in both 2D and 3D.

---

## Repository Structure

```
├── app.R               # Shiny application to explore DEM/DSM/CHM
├── lidar_processing.R  # (Optional) Script to process LAS → DEM/DSM/CHM
├── DEM_Vancouver.tif   # Generated DEM raster (1 m resolution)
├── DSM_Vancouver.tif   # Generated DSM raster (1 m resolution)
├── CHM_Vancouver.tif   # Generated CHM raster (1 m resolution)
├── README.md           # Project overview and instructions
└── .gitignore          # Ignored files (large binaries, temp files, etc.)
```

> **Note:** If you prefer to keep processing separate, extract the LiDAR pipeline (steps 1–11) into a dedicated `lidar_processing.R` file and run it before launching the app.

---

## Prerequisites

- R (>= 4.0)
- R packages:
  - **lidR** (LiDAR processing)
  - **terra** (Raster I/O)
  - **shiny** (Web app framework)
  - **plotly** (3D surface visualization)
  - **viridis** (Color palettes)
  - **leaflet** (2D interactive maps)

You can install missing packages automatically by running:
```r
required_pkgs <- c("lidR","terra","shiny","plotly","viridis","leaflet")
install.packages(setdiff(required_pkgs, rownames(installed.packages())))
```

---

## Data Processing Pipeline

> **Run once** to generate `DEM_Vancouver.tif`, `DSM_Vancouver.tif`, and `CHM_Vancouver.tif`.

1. **Load raw LAS**: Specify the `las_file` path.
2. **Classify ground points** (if missing) using the PMF algorithm.
3. **Decimate** to ~5 m spacing to speed up processing.
4. **Generate DEM** via **knnidw** interpolation.
5. **Generate DSM** via **p2r** interpolation.
6. **Compute CHM** = DSM − DEM.
7. **Save** each raster as GeoTIFF.

```bash
Rscript lidar_processing.R
```  
_or within R:_
```r
source('lidar_processing.R')
```

---

## Launching the Shiny App

1. Ensure `DEM_Vancouver.tif`, `DSM_Vancouver.tif`, and `CHM_Vancouver.tif` are in the working directory.
2. Run the app:
   ```r
   library(shiny)
   runApp('app.R')
   ```
3. In the browser or RStudio Viewer, use the sidebar to:
   - Select **DEM**, **DSM**, or **CHM**.
   - Adjust **Subsample factor** (×) for performance.
   - Adjust **Vertical exaggeration** for relief.
4. View the 2D map and the 3D surface side-by-side.

5. Screenshot
![Interactive DEM/DSM/CHM Shiny App](https://raw.githubusercontent.com/Bee-pixel-bo/lidar-dem/main/Screenshot%202025-07-23%20125446.png)

---
