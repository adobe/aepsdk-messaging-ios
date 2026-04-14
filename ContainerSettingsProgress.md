# Content Card Container Architecture - Implementation Guide

This document provides a comprehensive overview of the Content Card Container implementation, including architecture, APIs, testing approach, and next steps for completion.

## 1. Architecture

### Container Architecture Overview

The container system extends the existing Content Card architecture with a new layer that provides templated layouts and state management for collections of content cards.

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT APPLICATION                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐  ┌─────────────────────────────────────┐ │
│  │  Individual Cards   │  │       Container UI                  │ │
│  │                     │  │                                     │ │
│  │ getContentCardsUI() │  │ getContentCardContainerUI()         │ │
│  └─────────────────────┘  └─────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                    PUBLIC API LAYER                             │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │             Messaging+UIPublicAPI.swift                     │ │
│  └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                    CONTAINER LAYER (NEW)                       │
│  ┌─────────────────────┐  ┌─────────────────────────────────────┐ │
│  │ ContainerSettingsUI │  │     Container Templates             │ │
│  │ • Event Handling    │  │ • InboxContainerTemplate            │ │
│  │ • Template Creation │  │ • CarouselContainerTemplate         │ │
│  │ • Card Management   │  │ • CustomContainerTemplate           │ │
│  └─────────────────────┘  └─────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                 EXISTING CONTENT CARD LAYER                    │
│  ┌─────────────────────┐  ┌─────────────────────────────────────┐ │
│  │   ContentCardUI     │  │        Card Templates               │ │
│  │ • Individual Cards  │  │ • LargeImageTemplate                │ │
│  │ • Template Creation │  │ • SmallImageTemplate                │ │
│  │ • Event Handling    │  │ • ImageOnlyTemplate                 │ │
│  └─────────────────────┘  └─────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                      DATA LAYER                                │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │               Proposition System                            │ │
│  │ • Surface-based Content Retrieval                          │ │
│  │ • Schema-driven Parsing                                     │ │
│  │ • Container Settings Schema                                 │ │
│  │ • Content Card Schema                                       │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components

#### ContainerSettingsUI
- **Purpose**: Central orchestrator for container display and management
- **Responsibilities**:
  - Downloads and manages content cards for a surface
  - Creates and manages container templates
  - Provides SwiftUI-observable interface
  - Handles container lifecycle events
- **Location**: `AEPMessaging/Sources/UI/ContainerSettings/ContainerSettingsUI.swift`

#### Container Templates
- **Purpose**: SwiftUI view implementations for different container layouts
- **Templates**:
  - `InboxContainerTemplate`: Vertical scrolling list layout
  - `CarouselContainerTemplate`: Horizontal scrolling carousel
  - `CustomContainerTemplate`: Configurable layout (horizontal/vertical)
- **Common Features**: Header support, customizable styling


### Integration with Existing Architecture

The container system **extends** rather than replaces the existing content card architecture:

1. **Individual Cards**: Still accessible via `getContentCardsUI()` API
2. **Container Collections**: New `getContentCardContainerUI()` API for templated layouts
3. **Shared Components**: Both use the same `ContentCardUI` and template system
4. **Unified Event Handling**: Compatible event listening patterns

## 2. Public API

### Primary Container API

```swift
static func getContentCardContainerUI(
    for surface: Surface,
    customizer: ContentCardCustomizing? = nil,
    containerCustomizer: ContainerCustomizing? = nil,
    listener: ContainerSettingsEventListening? = nil,
    _ completion: @escaping (Result<ContainerSettingsUI, Error>) -> Void
)
```

**Parameters:**
- `surface`: Surface defining the content source
- `customizer`: Optional customization for individual content cards
- `containerCustomizer`: Optional customization for container template appearance
- `listener`: Optional event listener for container lifecycle and user interactions
- `completion`: Result callback with `ContainerSettingsUI` or error

**Usage Example:**
```swift
Messaging.getContentCardContainerUI(
    for: Surface(path: "myapp://inbox"),
    customizer: MyCardCustomizer(),
    containerCustomizer: MyContainerCustomizer(),
    listener: self
) { result in
    switch result {
    case .success(let containerUI):
        // Use containerUI.view in SwiftUI
        self.containerView = containerUI.view
    case .failure(let error):
        // Handle error
        print("Container loading failed: \(error)")
    }
}
```

### ContainerSettingsUI Interface

```swift
public class ContainerSettingsUI: ObservableObject {
    // Published properties for SwiftUI observation
    @Published private(set) var contentCards: [ContentCardUI]
    @Published private(set) var state: ContainerState
    @Published private(set) var containerTemplate: (any ContainerTemplate)?
    
    // SwiftUI view representation
    public var view: some View
    
    // Public methods
    public func downloadCards()
    public func refresh()
}
```

### Event Listening

#### Container Events
```swift
public protocol ContainerSettingsEventListening {
    func onLoading(_ container: ContainerSettingsUI)
    func onLoaded(_ container: ContainerSettingsUI)
    func onError(_ container: ContainerSettingsUI, _ error: Error)
    func onEmpty(_ container: ContainerSettingsUI)
}
```

#### Content Card Events (Reused)
```swift
public protocol ContentCardUIEventListening {
    func onDisplay(_ card: ContentCardUI)
    func onDismiss(_ card: ContentCardUI)
    func onInteract(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool
}
```

### Container Customization

```swift
public protocol ContainerCustomizing {
    func customize(template: InboxContainerTemplate)
    func customize(template: CarouselContainerTemplate)  
    func customize(template: CustomContainerTemplate)
}
```

## 3. Testing

### Mock Data Implementation

For development and testing, we're using mock data that simulates the full proposition system:

**Key Files:**
- **Mock API**: `AEPMessaging/Sources/UI/ContainerSettings/ContainerSettingsMocks.swift`
- **Demo Implementation**: `TestApps/MessagingDemoAppSwiftUI/AppPages/CardsView.swift`

### Mock API Usage

The demo app uses `getContentCardContainerUIMock()` instead of the production API:

```swift
// Demo app usage - this will change to production API later
Messaging.getContentCardContainerUIMock(
    for: surface,
    customizer: CardCustomizer(),
    containerCustomizer: ContainerCustomizer(),
    listener: self
) { result in
    // Handle result
}
```

### Mock Surface Paths

```swift
private func getSurfacePathForTemplate(_ template: ContainerTemplateType) -> String {
    switch template {
    case .inbox:
        return "demo://inbox-container"
    case .carousel:
        return "demo://carousel-container" 
    case .custom:
        return "demo://custom-container"
    default:
        return "demo://unknown-container"
    }
}
```

### Mock Data Features

- **Realistic Propositions**: Creates mock propositions with container settings + content cards
- **Template-Specific Content**: Different surface paths return different template configurations  
- **Template Testing**: Mock data supports testing different container template types
- **Network Simulation**: Includes realistic delays (0.3-0.5 seconds)

### Production Migration

**Current (Mock)**: `Messaging.getContentCardContainerUIMock()`  
**Future (Production)**: `Messaging.getContentCardContainerUI()`

The mock will be removed once AJO UI supports container configuration and real proposition payloads are available.

## 4. Next Steps

### 4.1 Decide on Final Public API

**Issue**: Currently we have separate listeners for container events (`ContainerSettingsEventListening`) and content card events (`ContentCardUIEventListening`). The API could be cleaner.

**Options:**
1. **Keep separate listeners** (current approach)
   ```swift
   getContentCardContainerUI(
       customizer: cardCustomizer,
       containerCustomizer: containerCustomizer,
       listener: containerListener  // Container events only
   )
   // Card events handled via individual ContentCardUI listeners
   ```

2. **Unified listener approach**
   ```swift
   // Option A: Expand ContainerSettingsEventListening to include card events
   public protocol ContainerSettingsEventListening {
       // Container events
       func onLoading(_ container: ContainerSettingsUI)
       func onLoaded(_ container: ContainerSettingsUI)
       
       // Card events  
       func onCardDisplayed(_ card: ContentCardUI)
       func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool
   }
   
   // Option B: Add both listeners to API
   getContentCardContainerUI(
       containerListener: ContainerSettingsEventListening?,
       cardListener: ContentCardUIEventListening?
   )
   ```

**Recommendation Needed**: Evaluate which approach provides the cleanest developer experience.

### 4.2 Implement Content Card State Management

**Current State**: No state management implementation exists for content cards within containers.

**Requirements**: Implement read/unread status tracking and other card states (favorites, view counts, etc.) with proper architecture separation.

**Recommended Architecture:**
```
ContentCardUI → BusinessLogicLayer → StateManager → Storage
                       ↓                ↓
                ContainerSettingsUI ← StateObserver
                       ↓
                 SwiftUI Rendering
```

**Implementation Needs:**
1. **State Management Protocols**: Define interfaces for card state operations
2. **Persistent Storage**: Implement state persistence using `NamedCollectionDataStore`
3. **Business Logic Layer**: Separate state management from UI concerns
4. **Observer Pattern**: Efficient UI updates when state changes
5. **Template Integration**: Add unread indicators and other state-based UI elements

**Key Features to Implement:**
- Read/unread status tracking
- Visual unread indicators in container templates
- State persistence across app sessions
- Extensible architecture for future states (favorites, view counts)

**Files to Create:**
- `ContentCardStateManaging.swift`: State management protocols
- `DefaultContentCardStateManager.swift`: Storage implementation
- `ContainerStateCoordinator.swift`: Business logic layer
- Update container templates to show state-based UI elements

### 4.3 Finalize Payload Structure Based on AJO UI

**Current State**: Using mock propositions with assumed schema structure

**Required Changes:**
1. **Remove Mock Implementation**: Delete `ContainerSettingsMocks.swift` once real data is available
2. **Update Schema Parsing**: Verify and update `ContainerSettingsSchemaData` parsing based on actual AJO payload structure
3. **Surface Path Mapping**: Update surface path conventions to match AJO UI configuration
4. **Template Selection Logic**: Ensure container template type mapping aligns with AJO UI options

**Key Files to Update:**
- `ContainerSettingsSchemaData+Parsing.swift`: Schema parsing logic
- `Messaging+UIPublicAPI.swift`: Remove mock API references
- Demo apps: Switch from mock to production API calls

### 4.4 Write Tests

**Test Coverage Needed:**

**Unit Tests:**
- `ContainerSettingsUI` state management
- Container template creation and customization
- State manager persistence and retrieval
- Schema parsing for container settings

**Integration Tests:**
- Full container creation flow
- Event listener callback verification  
- Template switching and state preservation
- Error handling for malformed propositions

**UI Tests:**
- Container template rendering
- Unread indicator behavior
- User interaction flows (tap, dismiss, navigate)
- State persistence across app backgrounding

**Performance Tests:**
- Large content card collections (100+ cards)
- State management overhead
- Template re-rendering efficiency

## Implementation Status

✅ **Completed:**
- Container architecture and template system
- Public API design and implementation
- Mock data system for testing
- Demo app integration
- Basic customization support

🚧 **In Progress:**
- Testing with mock data in demo app
- API refinement based on usage feedback

⏳ **Pending:**
- Content card state management implementation (read/unread status)
- Unread indicators in container templates
- Final API design decisions
- Production payload integration
- Comprehensive test suite

---

