# Technical Specification: iOS Receipt Recognition App

## 1. Project Context

* Project Description: Canadian Receipt Scanner (MVP)

* Target Platform: iOS 17.0+

* Mission: Build a local-first, privacy-focused iOS app to scan, parse, and analyze grocery receipts from major Canadian retailers (Costco, T&T, Walmart, No Frills, Food Basics).

* Strict Constraints:

  * No Remote LLMs: All processing must happen on-device using Apple's Vision Framework.

  * No External Servers: User data must be stored locally using SwiftData.

  * Language: Swift 6.0+.

  * UI Framework: SwiftUI.

  * IDE: XCode

    

## 2. Technical Stack & Architecture

### Architecture Pattern

* MVVM-C (Model-View-ViewModel-Coordinator):
  * Coordinators: Manage navigation flow (e.g., CameraCoordinator, HomeCoordinator).
  * ViewModels: Handle business logic and state mapping. DO NOT import SwiftUI in ViewModels unless absolutely necessary.
  * Services: All heavy lifting (OCR, Parsing, Database) must be encapsulated in Service classes (e.g., OCRService, PersistenceService).

### Key Frameworks

* Vision (VNRecognizeTextRequest): For offline OCR.
* SwiftData: For local persistence (Core Data alternative).
* Swift Charts: For visualization.CodableCSV: For data export (or manual CSV string builder).
* Fastlane: For CI/CD automation.

## 3. Data Model (SwiftData Schema)

The AI should generate Item and Receipt models. 

## 4. Parsing Logic & Heuristics (The "Brain")

### Global OCR Configuration

* Engine: VNRecognizeTextRequest
* Recognition Level: .accurate (Essential for crumpled thermal paper).
* Language Hints: `` (Must include Chinese for T&T).`` 
*  Preprocessing: Implement a ImageProcessor service that converts the input UIImage to a high-contrast B&W image using CIFilter (CIColorControls) before passing to Vision.

### Merchant-Specific Regex & Logic

**A. Costco (Costco Wholesale)**

* Detection: Header contains "Costco" or "Wholesale".
* Row Format: <Item Code><Price>
* Regex Pattern: ^(\d+)\s+(.+?)\s+(-?\d+\.\d{2})\s*([HGE]?)$*
* Tax Codes:
  * H = HST (13% in Ontario)
  * E = Tax Exempt
  * _ (Empty) = No TaxEdge 
* Case: "Instant Savings" often appear on the line below the item with a negative price. Logic: If line price is negative, attach it to the previous item.

**B. T&T Supermarket (大统华)**

* Detection: Logo or text contains "T&T".
* Challenge: Mixed English and Chinese.
* Strategy:
  * Anchor on the Price at the right end of the line.
  * Everything to the left of the price is the name.
  * Do not try to split Chinese/English strictly; save the full string (e.g., "白菜 Bok Choy") as the item name.
* Regex Pattern: ^(.+?)\s+(\d+\.\d{2})\s*(?)$*

**C. Walmart Canada**

* Detection: Header "Walmart".
* Tax Column: Walmart uses specific single-letter codes, usually in a distinct column or next to price.
* Codes:
  * J = HST (13%)
  * D = Zero-rated/Exempt
* Structure: Often includes UPC numbers on the far left.

**D. No Frills / Food Basics**

* Detection: "NO FRILLS", "FOOD BASICS".
* Feature: Heavy use of abbreviations (e.g., "AVOC" for Avocado).
* Tax Codes:
  * H = HST
  * M or MR = Multi-buy rewards (Ignore or treat as discount).

## Implementation Roadmap

### Phase 1 Skeleton & CI/CD

"Initialize a Swift project. Config Xcode environment. Set up Fastlane Match for certificate management. Create a GitHub Actions workflow that runs unit tests on PR and builds for TestFlight on push to main."

### Phase 2: Camera & OCR Service

"Create a ScannerView wrapping VNDocumentCameraViewController. Create an OCRService that takes an image, performs Vision.accurate recognition, and returns an array of strings. Handle the zh-Hans language option."

### Phase 3: The Parser Engine

"Implement a Strategy Pattern for parsing. Create a protocol ReceiptParserStrategy. Implement concrete strategies: CostcoStrategy, WalmartStrategy, TNTStrategy. Each strategy should accept raw strings and return a Receipt object. Use the regex rules defined in Section 4."

### Phase 4: Persistence & UI

"Set up the SwiftData container. Create a ReceiptListView to show saved data. Create an EditReceiptView to allow users to manually fix OCR errors before saving."

### Phase 5: Analytics & Export

"Create a ChartsView using Swift Charts. Show 'Monthly Spending' (Bar) and 'Category Breakdown' (Pie). Implement a CSVExporter that converts `` to a CSV string and shares it via ShareLink."
