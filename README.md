# rk.data.table: Lightning-Fast Data Manipulation for RKWard

![Version](https://img.shields.io/badge/Version-0.0.1-blue.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.data.table/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.data.table/actions/workflows/lintr.yml)
![AI Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=googlegemini&logoColor=white)

**A Powerful GUI Wrapper for the `data.table` Package Bringing Extreme Speed and Memory Efficiency to RKWard**

`rk.data.table` provides a seamless, point-and-click interface for high-performance data manipulation. By leveraging the legendary `data.table` package, this plugin allows users to filter, aggregate, reshape, and merge datasets containing millions of rows in fractions of a second—all without writing a single line of R code. It is the ultimate tool for handling massive microdata (like censuses or hospital records) on standard computers without running out of RAM.

---

## 🌟 Key Features

*   **Zero-Code `DT[i, j, by]` Syntax:** Execute complex data manipulations through an intuitive tabbed interface that perfectly mimics the famous `data.table` logic.
*   **Memory Efficient (Zero-Copy):** Create and update columns by reference (`:=`) directly from the GUI, modifying massive datasets instantly without exhausting your computer's RAM.
*   **Blazing Fast I/O:** Import and export massive `.csv` or `.txt` files in seconds using the highly optimized `fread` and `fwrite` modules.
*   **Painless Reshaping:** Easily pivot data from Wide to Long (`melt`) or Long to Wide (`dcast`) with built-in aggregation functions.
*   **Advanced Data Binding:** Merge tables using robust Joins (Left, Right, Inner, Full, Anti) or vertically stack multiple data frames at lightning speed using `rbindlist`.
*   **Smart Code Generation:** Automatically generates idiomatic, chained `data.table` R code in the background, helping you learn the syntax while you work.
*   **Multilingual Ready:** Fully prepared for translation into English, Spanish, French, German, and Portuguese (Brazil).

---

## What's New in Version 0.0.1

*   **Initial Release:** Introduces the foundational GUI for the `data.table` package in RKWard.
*   **4 Core Modules:** Carefully organized into `Manipulate`, `Fast I/O`, `Reshape`, and `Joins & Bindings` to match the official `data.table` Cheat Sheet workflow.
*   **Dynamic UI Logic:** Menus intelligently adapt and gray-out based on the selected operations, preventing incompatible argument combinations.
*   **Live Previews:** Safely preview the top 50 rows of your massive datasets directly in the RKWard output window before saving them to your workspace.

---

## ⚙️ Prerequisites

You must have [RKWard](https://rkward.kde.org/) installed along with the following R package. The plugin will automatically attempt to load it when required:

```R
install.packages("data.table")
```

---

## 🚀 Installation

You can install this plugin directly from GitHub using `remotes` or `devtools` inside your RKWard console:

```R
# Install the plugin
library("remotes")
install_github("AlfCano/rk.data.table")
```

Once installed, restart RKWard to ensure the new menu entries and translations appear correctly.

---

## 🛠️ Usage Workflow

This plugin adds a comprehensive suite of tools under the **Data > data.table** menu in RKWard:

### 1. Manipulate (DT[i, j, by])
*The core engine for filtering, selecting, and summarizing data.*
*   **Data & Rows (i):** Apply logical subset expressions (e.g., `age > 18`) and instantly sort your data.
*   **Columns (j):** Choose between subsetting specific columns, computing summary statistics (Mean, Sum, Count), or mathematically updating columns by reference (`:=`) for zero memory overhead.
*   **Groups (by):** Aggregate your results effortlessly by selecting grouping variables.

### 2. Fast I/O (fread & fwrite)
*Import and Export massive text files.*
*   **Read (fread):** Auto-detects delimiters and data types to load GB-sized CSVs in seconds.
*   **Write (fwrite):** Rapidly dump processed data frames back to your hard drive.

### 3. Reshape (melt & dcast)
*Pivot your datasets.*
*   **Melt:** Convert wide tables to long format by selecting ID and Measure variables.
*   **Dcast:** Convert long tables to wide format by dragging Row and Column variables to build formulas, with options to apply aggregation functions (e.g., `length`, `mean`, `paste`) to duplicates.

### 4. Joins & Bindings
*Combine multiple datasets efficiently.*
*   **Merge / Join:** Perform precise relational joins (Left, Right, Inner, Full Outer, and Anti-Joins) between two tables. Auto-detects matching keys or allows manual specification.
*   **Bind Rows:** Use `rbindlist` to vertically stack multiple tables at once, with smart options to fill missing columns with NAs (`fill = TRUE`) and generate source ID columns.

---

## 🌍 Internationalization (i18n)

The graphical interface automatically adapts to your RKWard language settings. Currently supported languages:
*   🇺🇸 English (Default)
*   🇪🇸 Spanish (Español)
*   🇫🇷 French (Français)
*   🇩🇪 German (Deutsch)
*   🇧🇷 Portuguese (Português do Brasil)

---

## 📝 License and Author

**Author:** Alfonso Cano ([@AlfCano](https://github.com/AlfCano))  
**Email:** alfonso.cano@correo.buap.mx  
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)

This project is licensed under the **GPL (>= 3)** License.
