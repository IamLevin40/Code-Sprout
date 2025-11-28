# System Overview Diagram

## Code Sprout - Educational Programming Platform

This document provides a comprehensive system architecture overview of the Code Sprout Flutter application, illustrating the interaction between all major components, layers, and external services.

---

## System Architecture Diagram

```mermaid
---
config:
  theme: forest
  flowchart:
    curve: stepBefore
  layout: elk
---
flowchart LR
 subgraph AuthPages["Authentication Pages"]
        LoginPage["LoginPage"]
        RegisterPage["RegisterPage"]
  end
 subgraph MainPages["Core Pages"]
        MainNav["MainNav"]
        HomePage["HomePage"]
        CoursePage["CoursePage"]
        SproutPage["SproutPage"]
        SettingsPage["SettingsPage"]
  end
 subgraph SubPages["Feature Pages"]
        ModuleListPage["ModuleListPage"]
        ModuleLevelsPage["ModuleLevelsPage"]
        FarmPage["FarmPage"]
        AdminConfigPage["AdminConfigPage"]
  end
 subgraph CourseWidgets["Course Widgets"]
        MainCourseCards["MainCourseCards"]
        ContinueCourseCards["ContinueCourseCards"]
        DiscoverCourseCards["DiscoverCourseCards"]
        RecommendedCourseCards["RecommendedCourseCards"]
        GlobalCourseCards["GlobalCourseCards"]
        LockedOverlay["LockedOverlay"]
  end
 subgraph LevelWidgets["Level Widgets"]
        LectureContent["LectureContent"]
        MultipleChoiceContent["MultipleChoiceContent"]
        TrueFalseContent["TrueFalseContent"]
        FillInCodeContent["FillInCodeContent"]
        AssembleCodeContent["AssembleCodeContent"]
  end
 subgraph FarmWidgets["Farm Widgets"]
        FarmGridView["FarmGridView"]
        FarmPlotWidget["FarmPlotWidget"]
        CodeEditorWidget["CodeEditorWidget"]
        CodeExecutionLog["CodeExecutionLog"]
        ResearchLabDisplay["ResearchLabDisplay"]
        InventoryPopup["InventoryPopup"]
        NotificationDisplay["NotificationDisplay"]
        FarmTopControls["FarmTopControls"]
        FarmBottomControls["FarmBottomControls"]
  end
 subgraph SproutWidgets["Sprout Widgets"]
        InventoryGridDisplay["InventoryGridDisplay"]
        CurrentLanguageCard["CurrentLanguageCard"]
        CropResearchCards["CropResearchCards"]
        FarmResearchCards["FarmResearchCards"]
        FunctionsResearchCards["FunctionsResearchCards"]
  end
 subgraph DialogWidgets["Dialog & Popups"]
        CorrectPopup["CorrectPopup"]
        IncorrectPopup["IncorrectPopup"]
        ModuleAccomplishedPopup["ModuleAccomplishedPopup"]
        BackConfirmationPopup["BackConfirmationPopup"]
        SaveSuccessDialog["SaveSuccessDialog"]
        LogoutDialog["LogoutDialog"]
        SellItemDialog["SellItemDialog"]
        AddFileDialog["AddFileDialog"]
        DeleteFileDialog["DeleteFileDialog"]
        ClearFarmDialog["ClearFarmDialog"]
  end
 subgraph CommonWidgets["Common Widgets"]
        MainHeader["MainHeader"]
        RankCard["RankCard"]
        ProgressDisplay["ProgressDisplay"]
        LevelContentDisplay["LevelContentDisplay"]
        ErrorBoundary["ErrorBoundary"]
        SafeFutureBuilder["SafeFutureBuilder"]
        TermsConditionsDisplay["TermsConditionsDisplay"]
  end
 subgraph WidgetLayer["Reusable Widgets"]
        CourseWidgets
        LevelWidgets
        FarmWidgets
        SproutWidgets
        DialogWidgets
        CommonWidgets
  end
 subgraph UILayer["Presentation Layer (UI)"]
        MainApp["MainApp"]
        AuthPages
        MainPages
        SubPages
        WidgetLayer
  end
 subgraph Services["Service Layer"]
        AuthService["AuthService"]
        FirestoreService["FirestoreService"]
        LocalStorageService["LocalStorageService"]
        FarmProgressService["FarmProgressService"]
        CodeFilesService["CodeFilesService"]
  end
 subgraph Handlers["Handler Utilities"]
        HandleAccountValidation["HandleAccountValidation"]
        HandleCodeExecution["HandleCodeExecution"]
        HandleCodeEditing["HandleCodeEditing"]
        HandleCodeFiles["HandleCodeFiles"]
        HandleFarmProgress["HandleFarmProgress"]
        HandleResearchProgress["HandleResearchProgress"]
        HandleResearchCompleted["HandleResearchCompleted"]
  end
 subgraph Compilers["Code Interpreter"]
        BaseInterpreter["BaseInterpreter"]
        PythonInterpreter["PythonInterpreter"]
        JavaInterpreter["JavaInterpreter"]
        JavaScriptInterpreter["JavaScriptInterpreter"]
        CppInterpreter["CppInterpreter"]
        CSharpInterpreter["CSharpInterpreter"]
        GetInterpreter["GetInterpreter"]
  end
 subgraph Utils["Utility Modules"]
        InteractiveViewportController["InteractiveViewportController"]
        SinglePassPainters["SinglePassPainters"]
        NumberUtils["NumberUtils"]
        StringManipUtils["StringManipUtils"]
        GlassEffect["GlassEffect"]
        TouchMouseDragScroll["TouchMouseDragScroll"]
  end
 subgraph BusinessLayer["Business Logic Layer"]
        Services
        Handlers
        Compilers
        Utils
  end
 subgraph DataModels["Data Models"]
        UserData["UserData"]
        CourseData["CourseData"]
        FarmData["FarmData"]
        SproutData["SproutData"]
        InventoryData["InventoryData"]
        ResearchData["ResearchData"]
        RankData["RankData"]
        CodeFile["CodeFile"]
        LanguageCodeFiles["LanguageCodeFiles"]
  end
 subgraph SchemaModels["Schema Definitions"]
        UserDataSchema["UserDataSchema"]
        CourseDataSchema["CourseDataSchema"]
        FarmDataSchema["FarmDataSchema"]
        RankDataSchema["RankDataSchema"]
        ResearchItemsSchema["ResearchItemsSchema"]
        StylesSchema["StylesSchema"]
        TermsConditionsSchema["TermsConditionsSchema"]
  end
 subgraph DataLayer["Data Layer (Models & Schemas)"]
        DataModels
        SchemaModels
  end
 subgraph Firebase["Firebase Backend"]
        FirebaseAuth["FirebaseAuth"]
        CloudFirestore["CloudFirestore"]
        FirebaseCore["FirebaseCore"]
  end
 subgraph FlutterPlatform["Flutter Framework"]
        FlutterSDK["FlutterSDK"]
        MaterialDesign["MaterialDesign"]
        CupertinoIcons["CupertinoIcons"]
  end
 subgraph DeviceStorage["Device Storage"]
        SecureStorage["SecureStorage"]
  end
 subgraph AssetResources["Asset Resources"]
        ImageAssets["ImageAssets"]
        FontAssets["FontAssets"]
        SchemaFiles["SchemaFiles"]
  end
 subgraph ExternalServices["External Services & Platform"]
        Firebase
        FlutterPlatform
        DeviceStorage
        AssetResources
  end
 subgraph PlatformLayer["Platform Layer"]
    direction LR
        AndroidPlatform["AndroidPlatform"]
        IOSPlatform["IOSPlatform"]
        WebPlatform["WebPlatform"]
        LinuxPlatform["LinuxPlatform"]
        MacOSPlatform["MacOSPlatform"]
        WindowsPlatform["WindowsPlatform"]
  end
    MainApp --> AuthPages & MainNav & StylesSchema & FarmDataSchema & ResearchItemsSchema & FirebaseCore & FlutterSDK & MaterialDesign
    AuthPages --> LoginPage & RegisterPage & AuthService & HandleAccountValidation
    MainNav --> HomePage & CoursePage & SproutPage & SettingsPage & TermsConditionsDisplay
    HomePage --> ModuleListPage & CourseWidgets & CommonWidgets
    CoursePage --> ModuleListPage & CourseWidgets & CommonWidgets
    ModuleListPage --> ModuleLevelsPage
    ModuleLevelsPage --> FarmPage & LevelWidgets & DialogWidgets
    FarmPage --> FarmWidgets & DialogWidgets
    SproutPage --> SproutWidgets & CommonWidgets
    SettingsPage --> DialogWidgets & CommonWidgets & AuthService & FirestoreService & HandleAccountValidation
    FarmWidgets --> CodeFilesService & FarmProgressService & HandleCodeExecution & HandleCodeEditing & HandleCodeFiles
    CourseWidgets --> FirestoreService & LocalStorageService
    SproutWidgets --> FirestoreService & LocalStorageService & HandleResearchProgress & HandleResearchCompleted
    AuthService --> FirebaseAuth & FirestoreService
    FirestoreService --> CloudFirestore & LocalStorageService & UserData
    LocalStorageService --> SecureStorage & UserData
    FarmProgressService --> CloudFirestore & FarmData
    CodeFilesService --> CodeFile & LanguageCodeFiles
    HandleCodeExecution --> GetInterpreter
    GetInterpreter --> BaseInterpreter
    BaseInterpreter --> PythonInterpreter & JavaInterpreter & JavaScriptInterpreter & CppInterpreter & CSharpInterpreter
    PythonInterpreter --> FarmData & ResearchData
    JavaInterpreter --> FarmData & ResearchData
    JavaScriptInterpreter --> FarmData & ResearchData
    CppInterpreter --> FarmData & ResearchData
    CSharpInterpreter --> FarmData & ResearchData
    UserData --> UserDataSchema
    CourseData --> CourseDataSchema
    FarmData --> FarmDataSchema
    RankData --> RankDataSchema
    ResearchData --> ResearchItemsSchema
    UserDataSchema --> SchemaFiles
    CourseDataSchema --> SchemaFiles
    FarmDataSchema --> SchemaFiles
    RankDataSchema --> SchemaFiles
    ResearchItemsSchema --> SchemaFiles
    StylesSchema --> SchemaFiles & UILayer & WidgetLayer
    TermsConditionsSchema --> SchemaFiles
    WidgetLayer --> ImageAssets & FontAssets
    FirebaseCore --> Firebase
    FlutterSDK --> PlatformLayer
    ErrorBoundary --> MainApp & UILayer
    SafeFutureBuilder --> BusinessLayer
    Utils --> WidgetLayer & BusinessLayer
    TermsConditionsDisplay --> TermsConditionsSchema
    AdminConfigPage --> SchemaModels & FirestoreService

     MainApp:::uiClass
     AuthPages:::uiClass
     WidgetLayer:::uiClass
     HandleAccountValidation:::handlerClass
     HandleCodeExecution:::handlerClass
     HandleCodeEditing:::handlerClass
     HandleCodeFiles:::handlerClass
     HandleFarmProgress:::handlerClass
     HandleResearchProgress:::handlerClass
     HandleResearchCompleted:::handlerClass
     BaseInterpreter:::compilerClass
     PythonInterpreter:::compilerClass
     JavaInterpreter:::compilerClass
     JavaScriptInterpreter:::compilerClass
     CppInterpreter:::compilerClass
     CSharpInterpreter:::compilerClass
     GetInterpreter:::compilerClass
     Utils:::serviceClass
     SchemaModels:::dataClass
     Firebase:::externalClass
     AndroidPlatform:::platformClass
     IOSPlatform:::platformClass
     WebPlatform:::platformClass
     PlatformLayer:::platformClass
    classDef uiClass fill:#4A90E2,stroke:#2E5C8A,stroke-width:2px,color:#fff
    classDef serviceClass fill:#50C878,stroke:#2E7D4E,stroke-width:2px,color:#fff
    classDef dataClass fill:#F39C12,stroke:#C87F0A,stroke-width:2px,color:#fff
    classDef externalClass fill:#9B59B6,stroke:#6C3483,stroke-width:2px,color:#fff
    classDef platformClass fill:#E74C3C,stroke:#A93226,stroke-width:2px,color:#fff
    classDef compilerClass fill:#1ABC9C,stroke:#138D75,stroke-width:2px,color:#fff
    classDef handlerClass fill:#3498DB,stroke:#21618C,stroke-width:2px,color:#fff
```

---

## Architecture Overview

### 1. **Presentation Layer (UI)**
The presentation layer consists of all user-facing components:

- **Authentication Pages**: Handle user login and registration
- **Core Application Pages**: Main navigation with 4 primary tabs (Home, Course, Sprout, Settings)
- **Feature Pages**: Specialized pages for modules, levels, farm, and admin configuration
- **Widget Components**: Reusable UI components organized by feature domain

### 2. **Business Logic Layer**
The business logic layer manages application logic and data processing:

- **Service Layer**: Core services for authentication, database operations, caching, and file management
- **Handler Utilities**: Specialized handlers for validation, code execution, editing, and progress management
- **Code Interpreter Engine**: Multi-language code interpreter supporting Python, Java, JavaScript, C++, and C#
- **Utility Modules**: Helper functions for viewport control, rendering, string manipulation, and UI effects

### 3. **Data Layer (Models & Schemas)**
The data layer defines data structures and configurations:

- **Data Models**: Object models representing users, courses, farm state, inventory, research, and rankings
- **Schema Definitions**: Dynamic schema-driven configuration for flexible data management and UI theming

### 4. **External Services & Platform**
Integration with external services and frameworks:

- **Firebase Backend**: Authentication, Cloud Firestore database, and core SDK
- **Flutter Framework**: Flutter SDK, Material Design components, and iOS icons
- **Device Storage**: Encrypted local storage for offline caching
- **Asset Resources**: Images, fonts, and configuration files

### 5. **Platform Layer**
Multi-platform support:

- **Primary Platforms**: Android, iOS, Web
- **Limited Support**: Linux, MacOS, Windows

---

## Key System Components

### Code Execution Flow
1. User writes code in **Code Editor Widget**
2. Code is parsed by **Handle Code Execution**
3. **Get Interpreter** factory selects appropriate language interpreter
4. **Base Interpreter** executes code with farm state context
5. Results update **Farm Data** and trigger UI updates
6. Execution logs displayed in **Code Execution Log Widget**

### Data Persistence Flow
1. User actions modify data in **Data Models**
2. **Services** validate and process changes
3. Data saved to **Cloud Firestore** (remote)
4. **Local Storage Service** caches data in **Secure Storage** (local)
5. **UserData Notifier** triggers UI updates across the app

### Authentication Flow
1. User submits credentials via **Login/Register Page**
2. **Auth Service** communicates with **Firebase Authentication**
3. On success, **Firestore Service** creates/loads user document
4. **Local Storage Service** caches user data
5. **Main Navigation Page** becomes accessible

### Course Progress Flow
1. User selects course from **Course Page**
2. **Module List Page** displays difficulty levels
3. **Module Levels Page** shows individual lessons
4. User completes level content (lecture, quiz, coding challenge)
5. Progress saved via **Firestore Service** and **Farm Progress Service**
6. **User Data** updated with completion status

### Research & Gamification Flow
1. User plants crops and writes code in **Farm Page**
2. Successful code execution yields rewards
3. **Research Progress Handler** updates unlocked features
4. **Sprout Page** displays inventory, research tree, and achievements
5. **Rank Data** calculates user level based on experience points

---

## Technology Stack

### Frontend Framework
- **Flutter SDK 3.5.4+**: Cross-platform UI framework
- **Material Design**: UI component library
- **Dart Language**: Programming language for Flutter

### Backend Services
- **Firebase Authentication**: User authentication and authorization
- **Cloud Firestore**: NoSQL cloud database
- **Firebase Core**: Firebase SDK initialization

### Local Storage
- **Flutter Secure Storage**: Encrypted local data persistence

### Code Execution
- **Custom Interpreters**: Multi-language code interpretation engine supporting:
  - Python
  - Java
  - JavaScript
  - C++
  - C#

---

## Design Patterns

### Architectural Patterns
- **Layered Architecture**: Clear separation between UI, business logic, and data layers
- **Model-View Pattern**: Data models separated from UI components
- **Service Pattern**: Business logic encapsulated in service classes

### Coding Patterns
- **Factory Pattern**: `GetInterpreter` for language interpreter selection
- **Singleton Pattern**: `LocalStorageService` and schema instances
- **Observer Pattern**: `ValueNotifier` for reactive state management
- **Strategy Pattern**: `BaseInterpreter` with language-specific implementations
- **Error Boundary Pattern**: Centralized error handling with `ErrorBoundary`
- **Schema-Driven Development**: Dynamic data structures based on configuration files

---

## Data Flow

### Synchronization Strategy
- **Cache-First Approach**: Local storage checked before remote database
- **Optimistic Updates**: UI updates immediately, syncs in background
- **Offline Support**: Cached data enables offline functionality

### State Management
- **ValueNotifier**: Reactive state updates for cached user data
- **StatefulWidget**: Local component state management
- **Service Layer State**: Shared state across multiple screens

---

## Security Considerations

### Authentication Security
- Firebase Authentication with email/password
- Session management via Firebase Auth tokens
- Secure logout with token invalidation

### Data Security
- Encrypted local storage via Flutter Secure Storage
- Firestore security rules for data access control
- Input validation handlers prevent injection attacks

### Code Execution Security
- Sandboxed interpreter environment
- Resource limitations on code execution
- Error handling prevents application crashes

---

## Scalability & Performance

### Performance Optimizations
- **Lazy Loading**: Schemas and assets loaded on demand
- **Image Optimization**: Asset compression and caching
- **Widget Reusability**: Modular widget architecture reduces redundancy
- **Error Recovery**: Safe builders and boundaries prevent cascading failures

### Scalability Features
- **Schema-Driven Architecture**: Easy to add new features via configuration
- **Modular Interpreter Engine**: Simple to add new programming languages
- **Cloud-Based Backend**: Firebase scales automatically with user growth
- **Multi-Platform Support**: Single codebase deploys to 6+ platforms

---

## System Interactions Summary

This architecture enables:
- ✅ **Seamless multi-platform deployment** (Android, iOS, Web, Desktop)
- ✅ **Real-time data synchronization** between local and cloud storage
- ✅ **Interactive code learning** with multi-language support
- ✅ **Gamification mechanics** through farm management and research systems
- ✅ **Offline-first functionality** with secure local caching
- ✅ **Dynamic content management** via schema-driven configuration
- ✅ **Comprehensive error handling** at all architectural layers
- ✅ **Scalable and maintainable codebase** with clear separation of concerns

---

**Document Version**: 1.0  
**Last Updated**: November 28, 2025  
**Project**: Code Sprout - Educational Programming Platform  
**Repository**: Code-Sprout by IamLevin40
