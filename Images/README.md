# 💎 Crystal Path Finding System

![./Images/Snapshot_Form](./Images/logo.png)

**Crystal Path Finding** is a high-performance pathfinding engine developed with Delphi 12 Athens and the FMX (FireMonkey) framework. It goes beyond simple grid-based algorithms by analyzing real-world map images (Height Maps) to simulate and calculate optimal paths based on terrain difficulty in real-time.
* This program is still in the experimental stage

## 🚀 Key Features

*   **High-Performance A Algorithm**: Leverages a Binary Heap-based priority queue for ultra-fast path calculation, even across tens of thousands of nodes.

*  **Terrain Height Map Analysis**: Automatically converts satellite imagery or topographic maps into cost weights (Weight Map) based on pixel luminance and saturation.

* **Real-time Weight Tuning**: Dynamically adjust the influence of terrain difficulty using an intuitive slider to observe immediate path variations.

* **Parallel Processing Support**: Utilizes the TParallel.For from the Parallel Programming Library (PPL) to compute multiple paths simultaneously from different starting points.

* **Flexible Map Configurations**: Full support for 4-way (Simple), 8-way (Diagonal), and custom weighting systems.

## 🚩 Architecture — Image Processing Pipeline

![./Images/pipeline](./images/pipeline.png)

## 📺 Screenshots

* Original Image (from Google Map / Seoul, Korea )

![./Images/mapsample_11](./Images/mapsample_11.png)

* Optimal Path Result

![./Images/snapshot_0](./Images/snapshot_0.png)

* Terrain Analysis Mode

![./Images/snapshot_1](./Images/snapshot_1.png)

* Hexagonal Tile Kind Drawing

![./Images/snapshot_2](./Images/snapshot_2.png)

![./Images/newyork](./Images/newyork.png)

![./Images/washington](./Images/washington.png)

##
 🛠 Tech Stack

*   **Language:** Delphi (Object Pascal)

*   **Framework:** FireMonkey (FMX)

*   **Algorithm:** Optimized A* with Binary Heap implementation

*   **Optimization:** Optimization: Parallel Programming Library (PPL) for multi-threaded performance
*   **Helped by AI:** Much of the code in this program has been written with the help of Google Gemini.
*   **Inspired by:** Crystal Path Finding <https://github.com/d-mozulyov/CrystalPathFinding>
*   **Optional:** FastMM4 Lib.<https://github.com/maximmasiutin/FastMM4-AVX>


## 🏁 Quick Start
*   **Open the Project:** Open CrystalPathFinding.dproj in Delphi 12 Athens or later.

*   **Build and Run:**  Press F9 to compile and run the application.

*   **Click the Load Map button:** to import a map image and start testing.

## 📄 Analysis Logic (Height Map)

* The system calculates terrain traversal costs using the following formula:

* Weight = (255 - Luminance) \times Multiplier

* Luminance: Calculated brightness of a pixel (Darker areas are treated as higher elevations or difficult obstacles).

* Multiplier: User-defined sensitivity scale for terrain difficulty.

## 🎓 Infographics

![./Images/infographic_en3](./Images/infographic_en3.png)

## 🤝 Contributing

* This is an open-source project and all contributions are welcome!

* Report bugs or suggest features via Issues.

* Improve performance or fix code via Pull Requests.

## 📜 License

* This project is distributed under the MIT License. You are free to modify and use it for any purpose.

* Developed with ❤️ using Delphi 12 Athens and 13.1 Florence