# Courses System Documentation

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Data Models](#data-models)
4. [Schema Structure](#schema-structure)
5. [Core Components](#core-components)
6. [User Interface](#user-interface)
7. [Progress Tracking](#progress-tracking)
8. [Learning Modes](#learning-modes)
9. [Data Flow](#data-flow)
10. [Workflows](#workflows)
11. [Implementation Details](#implementation-details)

---

## System Overview

The Code Sprout Courses System is a comprehensive, schema-driven educational framework designed to teach multiple programming languages through structured, progressive learning paths. The system provides an adaptive, gamified learning experience with multiple content delivery modes and robust progress tracking.

### Key Features

- **Multi-Language Support**: C++, C#, Java, Python, JavaScript
- **Three-Tier Difficulty System**: Beginner, Intermediate, Advanced
- **Hierarchical Organization**: Languages → Difficulties → Chapters → Modules → Levels
- **Five Learning Modes**: Lecture, Multiple Choice, True/False, Fill in the Code, Assemble the Code
- **Progress Persistence**: User progress tracked across all languages and difficulties
- **Adaptive Content**: Locked/unlocked difficulty progression based on completion
- **Schema-Driven**: All content defined in JSON schemas for maintainability
- **Caching System**: Efficient loading with multi-level caching

### Supported Programming Languages

| Language ID | Display Name | Status |
|-------------|--------------|--------|
| `cpp` | C++ | ✅ Active |
| `csharp` | C# | ✅ Active |
| `java` | Java | ✅ Active |
| `python` | Python | ✅ Active |
| `javascript` | JavaScript | ✅ Active |

---

## Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface Layer                      │
├─────────────┬──────────────┬──────────────┬─────────────────────┤
│ CoursePage  │ ModuleList   │ ModuleLevels │ Level Content       │
│             │ Page         │ Page         │ Widgets             │
└─────────────┴──────────────┴──────────────┴─────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                        │
├─────────────────────────────────────────────────────────────────┤
│  CourseDataSchema (Singleton)                                   │
│  - Schema Loading & Caching                                     │
│  - Progress Management                                          │
│  - Difficulty Locking Logic                                     │
│  - Navigation Helpers                                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                              │
├─────────────┬──────────────┬──────────────┬─────────────────────┤
│ Local       │ Firestore    │ Schema       │ User Data           │
│ Storage     │ Service      │ Files        │ Cache               │
└─────────────┴──────────────┴──────────────┴─────────────────────┘
```

### Component Hierarchy

```
CourseDataSchema (Singleton)
├── CourseData (Language Index)
│   └── ModuleData (Language Module Structure)
│       └── DifficultyLevel (Beginner/Intermediate/Advanced)
│           └── Chapter
│               └── Module
│                   └── LevelData
│                       └── Level
│                           └── Content (Mode-Specific)
```

---

## Data Models

### 1. CourseData

Represents the top-level course information for a programming language.

```dart
class CourseData {
  final String programmingLanguageId;  // e.g., "cpp", "python"
  final String moduleSchemaFile;       // Path to module schema
}
```

**Purpose**: Maps language IDs to their module schema files.

**Example**:
```json
{
  "programmingLanguageId": "cpp",
  "moduleSchemaFile": "schemas/courses/cpp/cpp_modules_schema.txt"
}
```

### 2. ModuleData

Contains the complete structure for a programming language across all difficulties.

```dart
class ModuleData {
  final String programmingLanguage;     // Display name (e.g., "C++")
  final DifficultyLevel beginner;
  final DifficultyLevel intermediate;
  final DifficultyLevel advanced;
}
```

**Purpose**: Organizes all content for a language by difficulty level.

### 3. DifficultyLevel

Represents one difficulty tier with its chapters and estimated duration.

```dart
class DifficultyLevel {
  final EstimatedDuration estimatedDuration;
  final Map<String, Chapter> chapters;  // Key: "chapter_1", "chapter_2", etc.
}
```

**Purpose**: Defines the structure and time commitment for a difficulty level.

### 4. EstimatedDuration

Time estimate for completing a difficulty level.

```dart
class EstimatedDuration {
  final int hours;
  final int minutes;
  
  String toDisplayString() {
    // Returns: "8 hours 30 minutes" or "45 minutes"
  }
}
```

### 5. Chapter

A collection of related modules within a difficulty level.

```dart
class Chapter {
  final Map<String, Module> modules;  // Key: "module_1", "module_2", etc.
}
```

**Purpose**: Groups related learning modules together.

### 6. Module

A learning unit with a title and reference to its levels.

```dart
class Module {
  final String title;          // e.g., "Introduction to C++"
  final String levelSchema;    // Path to level schema file
}
```

**Purpose**: Defines a discrete learning topic with multiple levels.

### 7. LevelData

Container for all levels within a module.

```dart
class LevelData {
  final Map<String, Level> levels;  // Key: "level_1", "level_2", etc.
}
```

### 8. Level

Individual learning activity with a mode and content.

```dart
class Level {
  final String mode;  // "lecture", "multiple_choice", etc.
  final Map<String, dynamic> content;  // Mode-specific content
  
  // Typed content accessors
  LectureContent? getLectureContent();
  MultipleChoiceContent? getMultipleChoiceContent();
  TrueOrFalseContent? getTrueOrFalseContent();
  FillInTheCodeContent? getFillInTheCodeContent();
  AssembleTheCodeContent? getAssembleTheCodeContent();
}
```

### 9. Content Models

#### LectureContent
```dart
class LectureContent {
  final Map<String, List<String>> sections;
  
  List<MapEntry<String, List<String>>> getOrderedSections();
  String getSectionType(String key);  // Returns: "title", "plain", "input_code", etc.
}
```

#### MultipleChoiceContent
```dart
class MultipleChoiceContent {
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;
  
  List<String> getAllChoices({bool shuffled = false});
}
```

#### TrueOrFalseContent
```dart
class TrueOrFalseContent {
  final String question;
  final bool correctAnswer;
}
```

#### FillInTheCodeContent
```dart
class FillInTheCodeContent {
  final List<String> codeLines;       // Lines with [_] markers for blanks
  final List<String> choices;          // Available answer choices
  final List<String> correctAnswers;   // Correct answers in order
  
  int getBlankCount();
}
```

#### AssembleTheCodeContent
```dart
class AssembleTheCodeContent {
  final String question;
  final List<String> correctCodeLines;  // Correct order with indentation
  final List<String> choices;           // All available lines (correct + incorrect)
  
  List<String> get lineIndents;
  List<String> get trimmedCorrectCodeLines;
  List<String> get normalizedChoicesForDisplay;
  String assembleLine(int lineIndex, List<String> tokens);
}
```

---

## Schema Structure

### File Organization

```
assets/schemas/
├── courses_schema.txt                    # Main index of all languages
└── courses/
    ├── cpp/
    │   ├── cpp_modules_schema.txt        # C++ structure
    │   ├── beginner/
    │   │   ├── chapter_1/
    │   │   │   ├── module_1_levels.txt
    │   │   │   ├── module_2_levels.txt
    │   │   │   └── module_3_levels.txt
    │   │   └── chapter_2/
    │   │       └── ...
    │   ├── intermediate/
    │   │   └── ...
    │   └── advanced/
    │       └── ...
    ├── python/
    │   └── ...
    ├── java/
    │   └── ...
    ├── csharp/
    │   └── ...
    └── javascript/
        └── ...
```

### 1. Main Courses Schema (`courses_schema.txt`)

**Location**: `assets/schemas/courses_schema.txt`

**Purpose**: Root index mapping language IDs to module schemas and recommended languages.

**Structure**:
```json
{
    "cpp": {
        "module_schema_file": "schemas/courses/cpp/cpp_modules_schema.txt"
    },
    "python": {
        "module_schema_file": "schemas/courses/python/python_modules_schema.txt"
    },
    "recommended": ["cpp", "java", "python"]
}
```

**Fields**:
- `[language_id]`: Object with `module_schema_file` path
- `recommended`: Array of language IDs to highlight in UI (optional)

### 2. Module Schema (`[language]_modules_schema.txt`)

**Location**: `assets/schemas/courses/[language]/[language]_modules_schema.txt`

**Purpose**: Complete structural definition for a programming language.

**Structure**:
```json
{
    "programming_language": "C++",
    "beginner": {
        "estimated_duration": {
            "hours": 8,
            "minutes": 30
        },
        "chapter_1": {
            "module_1": {
                "title": "Introduction to C++",
                "level_schema": "schemas/courses/cpp/beginner/chapter_1/module_1_levels.txt"
            },
            "module_2": { ... }
        },
        "chapter_2": { ... }
    },
    "intermediate": { ... },
    "advanced": { ... }
}
```

**Example** (C++ Beginner):
- **Chapters**: 2
- **Total Modules**: 6 (3 per chapter)
- **Duration**: 8 hours 30 minutes

**Example** (Python Intermediate):
- **Chapters**: 2
- **Total Modules**: 5
- **Duration**: 10 hours 30 minutes

### 3. Level Schema (`module_[n]_levels.txt`)

**Location**: `assets/schemas/courses/[language]/[difficulty]/chapter_[n]/module_[n]_levels.txt`

**Purpose**: Defines all learning activities (levels) for a module.

**Structure**:
```json
{
    "level_1": {
        "mode": "lecture",
        "content": { ... }
    },
    "level_2": {
        "mode": "multiple_choice",
        "content": { ... }
    },
    "level_3": { ... }
}
```

---

## Core Components

### 1. CourseDataSchema (Singleton)

**File**: `lib/models/course_data_schema.dart`

**Purpose**: Central service for loading, caching, and managing course data and user progress.

#### Key Responsibilities

1. **Schema Loading**: Load and parse JSON schema files
2. **Caching**: Multi-level cache for courses, modules, and levels
3. **Progress Management**: Track and update user progress
4. **Navigation**: Provide course structure information
5. **Difficulty Locking**: Determine which difficulties are accessible

#### Core Methods

##### Schema Loading

```dart
// Load main courses index
Future<Map<String, CourseData>> loadCoursesSchema()

// Load module structure for a language
Future<ModuleData> loadModuleSchema(String programmingLanguageId)

// Load level content for a module
Future<LevelData> loadLevelSchema(String levelSchemaPath)

// Get specific level
Future<Level?> getLevel({
  required String levelSchemaPath,
  required String levelId,
})

// Get all levels in a module
Future<Map<String, Level>> getAllLevels({
  required String levelSchemaPath,
})
```

##### Navigation Helpers

```dart
// Get available languages
Future<List<String>> getAvailableLanguages()

// Get recommended languages
Future<List<String>> getRecommendedLanguages()

// Get specific module
Future<Module?> getModule({
  required String programmingLanguageId,
  required String difficulty,
  required String chapterId,
  required String moduleId,
})

// Get all modules for a difficulty
Future<Map<String, Map<String, Module>>> getModulesByDifficulty({
  required String programmingLanguageId,
  required String difficulty,
})

// Get estimated duration for difficulty
Future<EstimatedDuration?> getEstimatedDuration({
  required String programmingLanguageId,
  required String difficulty,
})

// Get chapter count
Future<int> getChapterCount({
  required String languageId,
  required String difficulty,
})

// Get module count in chapter
Future<int> getModuleCountInChapter({
  required String languageId,
  required String difficulty,
  required int chapterNumber,
})

// Get level count in module
Future<int> getLevelCount({
  required String levelSchemaPath,
})
```

##### Progress Tracking

```dart
// Get current progress (chapter and module)
Map<String, int> getCurrentProgress({
  required Map<String, dynamic> userData,
  required String languageId,
  required String difficulty,
})
// Returns: {'currentChapter': 1, 'currentModule': 3}

// Get current module object
Future<Module?> getCurrentModule({
  required Map<String, dynamic> userData,
  required String languageId,
  required String difficulty,
})

// Advance to next module
Future<Map<String, dynamic>> advanceModule({
  required Map<String, dynamic> userData,
  required String languageId,
  required String difficulty,
  int? completedChapter,
  int? completedModule,
})

// Calculate progress percentage (0.0 to 1.0)
Future<double> getProgressPercentage({
  required Map<String, dynamic> userData,
  required String languageId,
  required String difficulty,
})

// Check if difficulty is completed
Future<bool> hasCompletedDifficulty({
  required Map<String, dynamic> userData,
  required String languageId,
  required String difficulty,
})

// Reset progress
Map<String, dynamic> resetProgress({
  required Map<String, dynamic> userData,
  required String languageId,
  required String difficulty,
})
```

##### Difficulty Locking

```dart
// Check if difficulty is locked
Future<bool> isDifficultyLocked({
  Map<String, dynamic>? userData,
  required String languageId,
  required String difficulty,
})

// Get previous difficulty key
String previousDifficultyKey(String difficulty)
// intermediate → beginner, advanced → intermediate

// Get previous difficulty display name
String previousDifficultyDisplay(String difficulty)
// intermediate → "Beginner", advanced → "Intermediate"
```

##### Last Interaction

```dart
// Get user's last course interaction
Map<String, dynamic> getLastInteraction({
  required Map<String, dynamic> userData,
})
// Returns: {'languageId': 'cpp', 'difficulty': 'beginner'}

// Get last interaction for specific language
Map<String, dynamic> getLastInteractionForLanguage({
  required Map<String, dynamic> userData,
  required String languageId,
})
```

##### Utilities

```dart
// Get mode display information
Map<String, String> getModeDisplay(String mode)
// Returns: {'title': 'Multiple Choice', 'description': '...'}

// Get course structure summary
Future<Map<String, dynamic>> getCourseStructure(String programmingLanguageId)

// Clear all caches
void clearCache()

// Clear cache for specific language
void clearLanguageCache(String programmingLanguageId)
```

#### Caching Strategy

The `CourseDataSchema` singleton implements a three-tier caching system:

1. **Course Cache** (`_coursesCache`): Maps language IDs to CourseData
2. **Module Cache** (`_modulesCache`): Maps language IDs to ModuleData
3. **Level Cache** (`_levelsCache`): Maps level schema paths to LevelData

**Benefits**:
- Reduces redundant file I/O operations
- Improves response times for navigation
- Persists across widget rebuilds
- Memory-efficient with targeted clearing

---

## User Interface

### 1. CoursePage

**File**: `lib/pages/course_page.dart`

**Purpose**: Main course selection page displaying all available courses organized by difficulty.

#### Features

- **Difficulty Selector**: Toggle between Beginner, Intermediate, Advanced
- **Continue Section**: Shows last accessed course for quick resume
- **Course Grid**: Displays all language/difficulty combinations as cards
- **Progress Tracking**: Visual indicators of completion status

#### UI Components

```dart
// Difficulty selector chips
Row(
  children: _difficulties.map((diff) => 
    GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = diff),
      child: Container(/* styled chip */),
    )
  ).toList(),
)

// Continue card (conditional)
if (userData.lastInteraction != null)
  ContinueCourseCard(
    userData: _userData,
    onTap: () => _onCourseCardTap(...),
  )

// Course cards grid
Wrap(
  children: _availableLanguages.map((langId) =>
    MainCourseCard(
      languageId: langId,
      difficulty: _selectedDifficulty,
      userData: _userData,
      onTap: () => _onCourseCardTap(langId, _selectedDifficulty),
    )
  ).toList(),
)
```

#### Navigation Flow

```
CoursePage
  ↓ (tap course card)
ModuleListPage(languageId, difficulty)
```

### 2. ModuleListPage

**File**: `lib/pages/module_list_page.dart`

**Purpose**: Displays all modules for a selected language and difficulty.

#### Features

- **Language Header**: Icon and name display with difficulty leaves
- **Progress Overview**: Shows chapters, duration, completion percentage
- **Module Cards**: Organized by chapters with lock/unlock states
- **Current Module Highlight**: Visual indicator of user's position

#### UI Structure

```dart
Column(
  children: [
    // Header: Back button + Language icon + Leaves
    Row(/* language display */),
    
    // Progress information
    ProgressDisplay(
      chapterCount: chapterCount,
      duration: duration,
      progress: progress,
    ),
    
    // Modules by chapter
    for (var chapter in chapters)
      Column(
        children: [
          Text('Chapter ${chapter.number}'),
          for (var module in chapter.modules)
            ModuleCard(
              module: module,
              isLocked: module.number > currentModule,
              isCurrent: module.number == currentModule,
              onTap: () => _navigateToModule(module),
            ),
        ],
      ),
  ],
)
```

#### Module Card States

1. **Current Module**: Highlighted with special styling
2. **Completed Modules**: Full opacity, clickable
3. **Locked Modules**: Reduced opacity, with lock icon

#### Navigation Flow

```
ModuleListPage
  ↓ (tap module card)
ModuleLevelsPage(languageId, difficulty, chapterNumber, moduleNumber)
```

### 3. ModuleLevelsPage

**File**: `lib/pages/module_levels_page.dart`

**Purpose**: Interactive learning page presenting individual levels within a module.

#### Features

- **Level Progress Bar**: Shows current level position
- **Dynamic Content**: Adapts UI based on level mode
- **Answer Feedback**: Correct/Incorrect popups
- **Module Completion**: Shows accomplishment popup and updates progress

#### UI Structure

```dart
Column(
  children: [
    // Header
    Row(
      children: [
        BackButton(),
        LanguageIcon(),
        DifficultyLeaves(),
      ],
    ),
    
    // Module title
    Text(moduleTitle),
    
    // Level progress bars
    Row(
      children: levels.map((level) =>
        Container(
          decoration: levelIndex == currentLevel 
            ? currentStyle 
            : levelIndex < currentLevel
              ? completedStyle
              : lockedStyle,
        )
      ).toList(),
    ),
    
    // Level content area (mode-specific)
    LevelContentDisplay(
      level: currentLevel,
      onNext: _handleNext,
    ),
  ],
)
```

#### Level Progression Logic

```dart
Future<void> _handleNext(int totalLevels) async {
  if (_currentLevelIndex < totalLevels) {
    // Move to next level
    setState(() => _currentLevelIndex += 1);
    return;
  }

  // Module completed - update progress
  final updatedUserData = await CourseDataSchema().advanceModule(
    userData: userData.toFirestore(),
    languageId: languageId,
    difficulty: difficulty,
    completedChapter: chapterNumber,
    completedModule: moduleNumber,
  );

  // Update lastInteraction
  updatedUserData['lastInteraction'] = {
    'languageId': languageId,
    'difficulty': difficulty,
  };

  // Save to Firestore and local storage
  await saveUserData(updatedUserData);

  // Show completion popup
  await ModuleAccomplishedPopup.show(context, progressPercent: ...);
  
  // Navigate back
  Navigator.pop(context);
}
```

### 4. Course Card Widgets

#### MainCourseCard

**File**: `lib/widgets/course_cards/main_course_cards.dart`

**Purpose**: Display course card with language, difficulty, progress, and metadata.

**Visual Elements**:
- Language icon (top)
- Difficulty leaves (1-3 based on level)
- Progress bar
- Chapter count
- Estimated duration
- Lock overlay (if locked)
- Completion checkmark (if completed)

#### ContinueCourseCard

**File**: `lib/widgets/course_cards/continue_course_cards.dart`

**Purpose**: Horizontal card showing user's last accessed course.

**Visual Elements**:
- Language icon
- Language name + difficulty
- Current chapter/module
- Progress percentage
- Estimated duration
- "Continue" styling

#### LockedOverlayCourseCard

**File**: `lib/widgets/course_cards/locked_overlay_course_card.dart`

**Purpose**: Overlay shown on locked course cards.

**Visual Elements**:
- Semi-transparent overlay
- Lock icon
- "Complete [Previous Difficulty] first" message

### 5. Level Content Widgets

#### LevelContentDisplay

**File**: `lib/widgets/module_items/level_content_display.dart`

**Purpose**: Router widget that renders appropriate content based on level mode.

```dart
Widget build(BuildContext context) {
  switch (level.mode) {
    case 'lecture':
      return LectureContentWidget(
        lectureContent: level.getLectureContent(),
        onProceed: onNext,
      );
    case 'multiple_choice':
      return MultipleChoiceContentWidget(
        content: level.getMultipleChoiceContent(),
        onAnswer: (correct) async {
          if (correct) {
            await CorrectLevelPopup.show(context);
            await onNext();
          } else {
            await IncorrectLevelPopup.show(context);
          }
        },
      );
    // ... other modes
  }
}
```

#### LectureContentWidget

**File**: `lib/widgets/level_contents/lecture_content.dart`

Renders lecture content with:
- Title sections
- Plain text paragraphs
- Code examples (syntax-highlighted)
- Output examples
- "Next" button

#### MultipleChoiceContentWidget

**File**: `lib/widgets/level_contents/multiple_choice_content.dart`

Displays:
- Question text
- 4 shuffled answer buttons
- Answer validation
- Visual feedback on selection

#### TrueOrFalseContentWidget

**File**: `lib/widgets/level_contents/true_or_false_content.dart`

Shows:
- Question text
- "True" and "False" buttons
- Answer validation

#### FillInTheCodeContentWidget

**File**: `lib/widgets/level_contents/fill_in_the_code_content.dart`

Interactive features:
- Code display with blank markers `[_]`
- Draggable choice chips
- Drop zones for each blank
- Answer validation when all filled
- Reset functionality

#### AssembleTheCodeContentWidget

**File**: `lib/widgets/level_contents/assemble_the_code_content.dart`

Drag-and-drop interface:
- Question/instructions
- Available code line choices
- Target area for assembly
- Drag-and-drop interaction
- Indentation preservation
- Order validation
- Reset functionality

### 6. Popup Widgets

#### CorrectLevelPopup

**File**: `lib/widgets/level_popups/correct_popup.dart`

Shows success feedback:
- Checkmark icon
- "Correct!" message
- Auto-dismisses after delay

#### IncorrectLevelPopup

**File**: `lib/widgets/level_popups/incorrect_popup.dart`

Shows error feedback:
- X icon
- "Incorrect!" message
- "Try Again" button

#### ModuleAccomplishedPopup

**File**: `lib/widgets/level_popups/module_accomplished_popup.dart`

Celebrates module completion:
- Trophy/achievement icon
- "Module Accomplished!" message
- Progress percentage
- Rewards earned (coins, XP)
- "Continue" button

---

## Progress Tracking

### User Data Structure

Progress is stored in the `courseProgress` section of user data in Firestore:

```json
{
  "courseProgress": {
    "cpp": {
      "beginner": {
        "currentChapter": 2,
        "currentModule": 3
      },
      "intermediate": {
        "currentChapter": 1,
        "currentModule": 1
      },
      "advanced": {
        "currentChapter": 1,
        "currentModule": 1
      }
    },
    "python": {
      "beginner": {
        "currentChapter": 1,
        "currentModule": 5
      },
      "intermediate": {
        "currentChapter": 1,
        "currentModule": 1
      },
      "advanced": {
        "currentChapter": 1,
        "currentModule": 1
      }
    }
  },
  "lastInteraction": {
    "languageId": "cpp",
    "difficulty": "beginner"
  }
}
```

### Progress States

#### Initial State

New users start with:
```json
{
  "currentChapter": 1,
  "currentModule": 1
}
```

#### Active State

User is progressing through modules:
```json
{
  "currentChapter": 2,    // Current chapter
  "currentModule": 3      // Current module within chapter
}
```

#### Completion Sentinel

When all modules are completed, progress moves to sentinel state:
```json
{
  "currentChapter": [totalChapters + 1],
  "currentModule": 1
}
```

This allows the system to detect completion via:
```dart
currentChapter > totalChapters  // Returns true if completed
```

### Progress Advancement Algorithm

```dart
Future<Map<String, dynamic>> advanceModule({
  required Map<String, dynamic> userData,
  required String languageId,
  required String difficulty,
  int? completedChapter,
  int? completedModule,
}) async {
  // 1. Get current progress
  final progress = getCurrentProgress(userData, languageId, difficulty);
  int currentChapter = progress['currentChapter']!;
  int currentModule = progress['currentModule']!;

  // 2. Verify user completed the expected module
  if (!(completedChapter == currentChapter && completedModule == currentModule)) {
    return userData;  // No change if not the current module
  }

  // 3. Get total chapters and modules
  final totalChapters = await getChapterCount(languageId, difficulty);
  final totalModulesInChapter = await getModuleCountInChapter(
    languageId, difficulty, currentChapter
  );

  // 4. Determine next position
  if (currentChapter > totalChapters) {
    // Already completed - stay at sentinel
    currentChapter = totalChapters + 1;
    currentModule = 1;
  } else if (currentModule >= totalModulesInChapter) {
    // Last module of chapter
    if (currentChapter < totalChapters) {
      // Move to next chapter
      currentChapter += 1;
      currentModule = 1;
    } else {
      // Completed last module of last chapter
      currentChapter = totalChapters + 1;
      currentModule = 1;
    }
  } else {
    // Move to next module in same chapter
    currentModule += 1;
  }

  // 5. Update userData
  userData['courseProgress'][languageId][difficulty.toLowerCase()] = {
    'currentChapter': currentChapter,
    'currentModule': currentModule,
  };

  return userData;
}
```

### Progress Percentage Calculation

```dart
Future<double> getProgressPercentage({
  required Map<String, dynamic> userData,
  required String languageId,
  required String difficulty,
}) async {
  final progress = getCurrentProgress(userData, languageId, difficulty);
  final currentChapter = progress['currentChapter']!;
  final currentModule = progress['currentModule']!;

  // Calculate completed modules
  int completedModules = 0;
  for (int i = 1; i < currentChapter; i++) {
    final modulesInChapter = await getModuleCountInChapter(
      languageId, difficulty, i
    );
    completedModules += modulesInChapter;
  }
  completedModules += (currentModule - 1);  // Modules in current chapter

  // Calculate total modules
  final totalChapters = await getChapterCount(languageId, difficulty);
  int totalModules = 0;
  for (int i = 1; i <= totalChapters; i++) {
    final modulesInChapter = await getModuleCountInChapter(
      languageId, difficulty, i
    );
    totalModules += modulesInChapter;
  }

  if (totalModules == 0) return 0.0;
  return completedModules / totalModules;
}
```

### Difficulty Locking System

#### Locking Rules

1. **Beginner**: Never locked
2. **Intermediate**: Locked until Beginner is completed
3. **Advanced**: Locked until Intermediate is completed

#### Implementation

```dart
Future<bool> isDifficultyLocked({
  Map<String, dynamic>? userData,
  required String languageId,
  required String difficulty,
}) async {
  // Beginner is never locked
  if (difficulty.toLowerCase() == 'beginner') return false;

  // No user data = locked for non-beginner
  if (userData == null) return true;

  // Determine prerequisite difficulty
  final previousDifficulty = difficulty.toLowerCase() == 'intermediate' 
    ? 'beginner' 
    : 'intermediate';

  // Check if prerequisite is completed
  return !(await hasCompletedDifficulty(
    userData: userData,
    languageId: languageId,
    difficulty: previousDifficulty,
  ));
}
```

#### Visual Indicators

Locked courses display:
- Reduced opacity (50%)
- Lock icon overlay
- "Complete [Previous] first" message
- Non-interactive (disabled tap)

---

## Learning Modes

### 1. Lecture Mode

**Purpose**: Present educational content with explanations and code examples.

**Content Structure**:
```json
{
  "1_title": ["Welcome to C++ Programming"],
  "2_plain": ["C++ is a powerful language...", "It was created by..."],
  "3_input_code": ["#include <iostream>", "int main() {", "    return 0;", "}"],
  "4_output_code": ["Hello, World!"],
  "5_plain": ["The code above demonstrates..."]
}
```

**Section Types**:
- `title`: Heading text (large, bold font)
- `plain`: Regular paragraph text
- `input_code`: Code examples (monospace, syntax highlighting)
- `input_valid_code`: Valid executable code
- `output_code`: Expected output (distinct styling)

**Ordering**: Numeric prefix (`1_`, `2_`, etc.) determines display order.

**UI Interaction**: User reads content and clicks "Next" to proceed.

### 2. Multiple Choice Mode

**Purpose**: Test comprehension with a question and four answer choices.

**Content Structure**:
```json
{
  "question": "Who created the C++ programming language?",
  "correct_answer": "Bjarne Stroustrup",
  "incorrect_answers": [
    "Dennis Ritchie",
    "James Gosling",
    "Guido van Rossum"
  ]
}
```

**Behavior**:
1. Display question
2. Show 4 shuffled answer buttons
3. User selects an answer
4. Validate selection
5. Show correct/incorrect popup
6. If correct, advance to next level
7. If incorrect, allow retry

### 3. True or False Mode

**Purpose**: Quick assessment with binary choice.

**Content Structure**:
```json
{
  "question": "C++ supports both procedural and object-oriented programming.",
  "correct_answer": true
}
```

**Behavior**:
1. Display question
2. Show "True" and "False" buttons
3. User selects
4. Validate
5. Show feedback
6. Advance or retry

### 4. Fill in the Code Mode

**Purpose**: Test ability to complete code by filling in missing characters/keywords.

**Content Structure**:
```json
{
  "code_lines": [
    "#include <iostream[_]",
    "int main() {",
    "    std::cout [_] \"Hello\" [_] std::endl;",
    "    return 0[_]",
    "}"
  ],
  "choices": [">", "<<", "<<", ";", ">>", ":", "?"],
  "correct_answers": [">", "<<", "<<", ";"]
}
```

**Blank Marker**: `[_]` indicates where user should fill in code.

**Behavior**:
1. Display code with blank markers
2. Show draggable choice chips
3. User drags choices to blanks
4. When all filled, validate
5. Show feedback
6. Advance or retry

**Implementation Details**:
- Drag-and-drop interaction
- Visual feedback on drop
- Validation only when complete
- Reusable choices (can drag multiple times)

### 5. Assemble the Code Mode

**Purpose**: Test understanding of code structure by arranging lines in correct order.

**Content Structure**:
```json
{
  "question": "Arrange the code to create a valid program",
  "correct_code_lines": [
    "#include <iostream>",
    "int main() {",
    "    std::cout << \"Hello, World!\" << std::endl;",
    "    return 0;",
    "}"
  ],
  "choices": [
    "#include <iostream>",
    "int main() {",
    "std::cout << \"Hello, World!\" << std::endl;",
    "std::cout >> \"Hello, World!\" >> std::endl;",
    "return 0;",
    "}",
    "int start() {",
    "return 1;"
  ]
}
```

**Key Features**:
- Choices include correct lines + incorrect alternatives
- Indentation is preserved from original lines
- Choices are displayed without indentation (normalized)
- User arranges lines in target area
- Indentation is restored when placed

**Behavior**:
1. Display question/instructions
2. Show available code line choices (no indentation)
3. User drags lines to assembly area
4. Lines display with proper indentation in assembly
5. User can reorder assembled lines
6. User can remove lines back to choices
7. When satisfied, submit for validation
8. Compare assembled order with correct order
9. Show feedback
10. Advance or retry

**Implementation Details**:
```dart
class AssembleTheCodeContent {
  // Original indentation for each line
  List<String> get lineIndents => 
    correctCodeLines.map((l) => _leadingIndent(l)).toList();

  // Lines without indentation for display
  List<String> get trimmedCorrectCodeLines =>
    correctCodeLines.map((l) => l.replaceFirst(RegExp(r'^\s*'), '')).toList();

  // Normalize choices for consistent display
  List<String> get normalizedChoicesForDisplay;

  // Reassemble line with proper indentation
  String assembleLine(int lineIndex, List<String> tokens) {
    final indent = lineIndents[lineIndex];
    return indent + tokens.join('');
  }
}
```

---

## Data Flow

### 1. Schema Loading Flow

```
User Opens CoursePage
    ↓
CourseDataSchema.loadCoursesSchema()
    ↓
Check _coursesCache
    ↓ (if empty)
Load assets/schemas/courses_schema.txt
    ↓
Parse JSON
    ↓
Create CourseData objects
    ↓
Store in _coursesCache
    ↓
Return courses map
    ↓
UI renders course cards
```

### 2. Module Loading Flow

```
User Taps Course Card
    ↓
Navigate to ModuleListPage(languageId, difficulty)
    ↓
CourseDataSchema.loadModuleSchema(languageId)
    ↓
Check _modulesCache[languageId]
    ↓ (if empty)
Get courseData.moduleSchemaFile path
    ↓
Load schema file from assets
    ↓
Parse JSON
    ↓
Create ModuleData with all difficulties
    ↓
Store in _modulesCache[languageId]
    ↓
Return ModuleData
    ↓
Extract DifficultyLevel for selected difficulty
    ↓
UI renders module cards by chapter
```

### 3. Level Loading Flow

```
User Taps Module Card
    ↓
Navigate to ModuleLevelsPage(...)
    ↓
CourseDataSchema.getAllLevels(levelSchemaPath)
    ↓
CourseDataSchema.loadLevelSchema(levelSchemaPath)
    ↓
Check _levelsCache[levelSchemaPath]
    ↓ (if empty)
Load level schema file from assets
    ↓
Parse JSON
    ↓
Create LevelData with all levels
    ↓
Store in _levelsCache[levelSchemaPath]
    ↓
Return levels map
    ↓
Set _currentLevelIndex = 1
    ↓
LevelContentDisplay renders current level
```

### 4. Level Progression Flow

```
User Completes Level Activity
    ↓
Level validates answer
    ↓
[If Correct]
    ↓
Show CorrectLevelPopup
    ↓
Call onNext()
    ↓
Check if more levels exist
    ↓
[If More Levels]
    ↓
Increment _currentLevelIndex
    ↓
Rebuild UI with next level
    ↓
[If Last Level]
    ↓
Call _handleNext() for module completion
```

### 5. Module Completion Flow

```
User Completes Last Level of Module
    ↓
_handleNext() called
    ↓
Get user data from LocalStorageService
    ↓
CourseDataSchema.advanceModule(userData, ...)
    ↓
Calculate next chapter/module position
    ↓
Update userData.courseProgress
    ↓
Update userData.lastInteraction
    ↓
Update userData.sproutProgress.isLanguageUnlocked (if chapter completed)
    ↓
Update userData.interaction.hasLearnedChapter (if chapter completed)
    ↓
Save to LocalStorageService
    ↓
Save to Firestore (async)
    ↓
Calculate new progress percentage
    ↓
Show ModuleAccomplishedPopup(progressPercent)
    ↓
User dismisses popup
    ↓
Navigate back to ModuleListPage
    ↓
ModuleListPage refreshes with new progress
```

### 6. Progress Sync Flow

```
User Data Changes
    ↓
LocalStorageService.userDataNotifier.value = newUserData
    ↓
Notifier triggers listeners
    ↓
All subscribed widgets receive notification:
    - CoursePage._onUserDataChanged()
    - ModuleListPage._onUserDataChanged()
    ↓
Widgets call setState()
    ↓
UI rebuilds with new progress data
    ↓
Parallel: Save to Firestore
    ↓
await UserData.save()
    ↓
FirestoreService.updateUserData(uid, data)
```

---

## Workflows

### 1. New User First Course Experience

```
1. User registers/logs in
   └─> Initial user data created with default progress (chapter 1, module 1)

2. User navigates to CoursePage
   └─> Sees all languages at Beginner difficulty
   └─> Intermediate and Advanced are locked

3. User selects "C++ - Beginner"
   └─> Navigate to ModuleListPage
   └─> Sees Chapter 1 with 3 modules
   └─> Module 1 is highlighted (current)
   └─> Module 2 and 3 are locked

4. User taps Module 1
   └─> Navigate to ModuleLevelsPage
   └─> Level 1 is current (highlighted)
   └─> Remaining levels are locked

5. User completes Level 1 (Lecture)
   └─> Reads content, clicks "Next"
   └─> Level 2 becomes current

6. User completes Level 2 (Multiple Choice)
   └─> Answers correctly
   └─> CorrectLevelPopup shows
   └─> Level 3 becomes current

7. User completes all levels (1-5)
   └─> After Level 5, module completion detected
   └─> Progress advances to Chapter 1, Module 2
   └─> ModuleAccomplishedPopup shows
   └─> User returns to ModuleListPage
   └─> Module 2 is now highlighted (current)
   └─> Module 1 shows as completed

8. User continues through Chapter 1
   └─> Completes Module 2
   └─> Completes Module 3
   └─> Progress advances to Chapter 2, Module 1

9. User completes all of Chapter 2
   └─> Progress advances to Chapter 3, Module 1 (sentinel)
   └─> Beginner is marked as completed
   └─> Intermediate difficulty unlocks
   └─> Language unlocks in Sprout system
```

### 2. Returning User Workflow

```
1. User logs in
   └─> User data loaded from Firestore
   └─> lastInteraction contains previous course

2. User navigates to Home/Course page
   └─> ContinueCourseCard displayed
   └─> Shows "Continue: C++ - Intermediate"
   └─> Shows current position: Chapter 2, Module 3

3. User taps Continue card
   └─> Navigate directly to ModuleListPage
   └─> languageId = "cpp", difficulty = "intermediate"
   └─> Current module highlighted

4. User resumes from current module
   └─> Can also navigate to other modules/chapters
   └─> Can switch languages/difficulties via back navigation
```

### 3. Difficulty Progression Workflow

```
1. User completes Beginner difficulty
   └─> All chapters and modules completed
   └─> Progress state: chapter > totalChapters
   └─> hasCompletedDifficulty() returns true

2. Intermediate difficulty unlocks
   └─> isDifficultyLocked() returns false
   └─> Lock overlay removed from cards
   └─> User can now access Intermediate

3. User starts Intermediate
   └─> Progress initialized at Chapter 1, Module 1
   └─> Same progression flow as Beginner

4. User completes Intermediate
   └─> Advanced difficulty unlocks
   └─> Pattern repeats
```

### 4. Multi-Language Learning Workflow

```
1. User progresses in C++
   └─> Currently on Beginner Chapter 2, Module 2

2. User switches to Python
   └─> Navigate to CoursePage
   └─> Select Python - Beginner
   └─> Python progress is independent
   └─> Starts at Chapter 1, Module 1 (or previous progress)

3. User works on multiple languages simultaneously
   └─> Each language maintains separate progress
   └─> Each difficulty within language is separate
   └─> lastInteraction updates to most recent course
   └─> ContinueCard shows most recent interaction
```

### 5. Content Creation Workflow

```
1. Define new module
   └─> Determine language, difficulty, chapter

2. Create module entry in module schema
   └─> Add module_N in chapter_N
   └─> Set title and level_schema path

3. Create level schema file
   └─> Create file at specified path
   └─> Define levels with modes

4. Write level content
   Level 1: Lecture (introduction)
   Level 2: Multiple Choice (basic concept)
   Level 3: True/False (reinforcement)
   Level 4: Fill in the Code (syntax practice)
   Level 5: Assemble the Code (structure understanding)

5. Update pubspec.yaml
   └─> Add new schema files to assets

6. Test module
   └─> Navigate to module in app
   └─> Complete all levels
   └─> Verify progression
   └─> Check completion status
```

---

## Implementation Details

### 1. Singleton Pattern

`CourseDataSchema` uses singleton pattern for:
- **Global access**: Available throughout app without passing references
- **Single instance**: Maintains one cache across all widgets
- **Memory efficiency**: Avoids duplicate schema loading

```dart
class CourseDataSchema {
  static final CourseDataSchema _instance = CourseDataSchema._internal();
  factory CourseDataSchema() => _instance;
  CourseDataSchema._internal();
  
  // Shared caches
  final Map<String, CourseData> _coursesCache = {};
  final Map<String, ModuleData> _modulesCache = {};
  final Map<String, LevelData> _levelsCache = {};
}
```

### 2. Error Handling

Schema loading includes robust error handling:

```dart
Future<Map<String, CourseData>> loadCoursesSchema() async {
  try {
    final String jsonString = await rootBundle.loadString('assets/schemas/courses_schema.txt');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    jsonData.forEach((key, value) {
      try {
        if (value is Map<String, dynamic> && value.containsKey('module_schema_file')) {
          _coursesCache[key] = CourseData.fromJson(key, value);
        }
      } catch (e) {
        // Skip invalid entries without failing entire load
        debugPrint('Error parsing course $key: $e');
      }
    });

    return _coursesCache;
  } catch (e) {
    throw Exception('Failed to load courses schema: $e');
  }
}
```

### 3. Progress Validation

Module completion validates that user is on expected module:

```dart
Future<Map<String, dynamic>> advanceModule({
  required Map<String, dynamic> userData,
  required String languageId,
  required String difficulty,
  int? completedChapter,
  int? completedModule,
}) async {
  final progress = getCurrentProgress(userData, languageId, difficulty);
  final currentChapter = progress['currentChapter']!;
  final currentModule = progress['currentModule']!;

  final finishedChapter = completedChapter ?? currentChapter;
  final finishedModule = completedModule ?? currentModule;

  // Only advance if completed module matches expected position
  if (!(finishedChapter == currentChapter && finishedModule == currentModule)) {
    return userData;  // No change
  }

  // ... proceed with advancement
}
```

This prevents:
- Skipping modules
- Duplicate completions
- Out-of-order progression

### 4. Indentation Preservation

Assemble the Code mode preserves code formatting:

```dart
class AssembleTheCodeContent {
  // Extract leading whitespace
  static String _leadingIndent(String line) {
    final match = RegExp(r'^(\s*)').firstMatch(line);
    return match?.group(1) ?? '';
  }

  // Store original indentation
  List<String> get lineIndents => 
    correctCodeLines.map((l) => _leadingIndent(l)).toList();

  // Trim for display
  List<String> get trimmedCorrectCodeLines =>
    correctCodeLines.map((l) => l.replaceFirst(RegExp(r'^\s*'), '')).toList();

  // Reassemble with indentation
  String assembleLine(int lineIndex, List<String> tokens) {
    final indent = (lineIndex >= 0 && lineIndex < lineIndents.length) 
      ? lineIndents[lineIndex] 
      : '';
    return indent + tokens.join('');
  }
}
```

### 5. Reactive UI Updates

User data changes propagate through ValueNotifier:

```dart
// Service
class LocalStorageService {
  final ValueNotifier<UserData?> userDataNotifier = ValueNotifier(null);
  
  Future<void> saveUserData(UserData userData) async {
    userDataNotifier.value = userData;
    // ... save to storage
  }
}

// Widget
class ModuleListPage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    LocalStorageService.instance.userDataNotifier.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    LocalStorageService.instance.userDataNotifier.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    if (!mounted) return;
    setState(() => _refreshCourseInfo());
  }
}
```

### 6. Async Operations

Course page handles async data loading gracefully:

```dart
@override
Widget build(BuildContext context) {
  return FutureBuilder<Map<String, dynamic>>(
    future: _loadCourseInfo(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return LoadingCard();
      }

      if (snapshot.hasError) {
        return ErrorCard(error: snapshot.error);
      }

      final data = snapshot.data!;
      return CourseCard(data: data);
    },
  );
}
```

### 7. Schema Versioning

While not currently implemented, the system supports future schema versioning:

```json
{
  "version": "1.0.0",
  "cpp": {
    "module_schema_file": "schemas/courses/cpp/cpp_modules_schema.txt"
  }
}
```

This allows:
- Schema migrations
- Backward compatibility
- Feature flags for new content

### 8. Performance Optimizations

**Lazy Loading**: Schemas loaded on-demand:
- Main schema loaded when CoursePage opens
- Module schema loaded when language selected
- Level schema loaded when module opened

**Caching Strategy**:
- In-memory caches persist for app session
- Cache invalidation only when necessary
- Targeted cache clearing by language

**Pagination** (future enhancement):
- Load modules in chunks
- Load levels as needed
- Reduce initial load time

---

## Best Practices

### For Content Creators

1. **Consistent Structure**: Follow established patterns for each mode
2. **Progressive Difficulty**: Order levels from easiest to hardest within modules
3. **Variety**: Mix different modes to maintain engagement
4. **Clear Questions**: Write unambiguous questions and answers
5. **Code Formatting**: Maintain proper indentation in code examples
6. **Testing**: Complete entire module before committing
7. **Validation**: Use JSON validator to check schema syntax

### For Developers

1. **Error Handling**: Always wrap schema operations in try-catch
2. **Null Safety**: Check for null before accessing nested data
3. **State Management**: Use appropriate lifecycle methods for listeners
4. **Cache Management**: Clear caches when schema files change
5. **Type Safety**: Use strongly-typed content models
6. **Progress Validation**: Verify user position before advancing
7. **UI Responsiveness**: Show loading states for async operations

### For Maintainers

1. **Documentation**: Keep this document updated with changes
2. **Schema Versioning**: Consider version field for future migrations
3. **Backward Compatibility**: Don't break existing progress data
4. **Testing**: Test across all languages and difficulties
5. **Performance Monitoring**: Track schema load times
6. **User Feedback**: Monitor completion rates per module
7. **Content Quality**: Regularly review and update educational content

---

## Future Enhancements

### Planned Features

1. **Hints System**: Optional hints for difficult questions
2. **Code Execution**: Run code examples in-app
3. **Bookmarks**: Save modules for later review
4. **Notes**: Allow users to write notes on lectures
5. **Search**: Find modules by topic or keyword
6. **Recommendations**: Suggest next module based on progress
7. **Analytics**: Track time spent, attempts per level
8. **Achievements**: Badges for milestones (complete chapter, perfect score)
9. **Leaderboards**: Compare progress with others (opt-in)
10. **Offline Mode**: Download modules for offline access

### Technical Improvements

1. **Schema Validation**: Runtime schema validation
2. **Hot Reload**: Update content without app restart
3. **A/B Testing**: Test different content variations
4. **Localization**: Multi-language UI support
5. **Accessibility**: Screen reader support, high contrast mode
6. **Performance**: Lazy loading, pagination
7. **Testing**: Unit tests for progress logic
8. **CI/CD**: Automated schema validation in pipeline

---

## Troubleshooting

### Common Issues

#### Schema Won't Load

**Symptoms**: Error message "Failed to load courses schema"

**Solutions**:
1. Check JSON syntax in schema file
2. Verify file path in `pubspec.yaml`
3. Ensure file exists in assets directory
4. Check for BOM or encoding issues
5. Restart app after schema changes

#### Content Not Displaying

**Symptoms**: Blank screen or "Content not implemented" message

**Solutions**:
1. Verify mode name spelling in schema
2. Check content structure matches mode requirements
3. Ensure all required fields present
4. Clear cache: `CourseDataSchema().clearCache()`
5. Check console for error messages

#### Progress Not Saving

**Symptoms**: User returns to same module after completion

**Solutions**:
1. Check Firestore connection
2. Verify user is authenticated
3. Check local storage permissions
4. Review console for save errors
5. Ensure `advanceModule()` is being called

#### Difficulty Still Locked

**Symptoms**: Intermediate/Advanced locked after completing prerequisite

**Solutions**:
1. Verify completion: `hasCompletedDifficulty()`
2. Check progress state (should be chapter > totalChapters)
3. Ensure all modules in all chapters completed
4. Check user data in Firestore for correct values
5. Try logging out and back in

#### Module Order Wrong

**Symptoms**: Modules appear in unexpected order

**Solutions**:
1. Check module IDs in schema (module_1, module_2, etc.)
2. Verify chapter IDs (chapter_1, chapter_2, etc.)
3. Ensure numeric ordering is consistent
4. Clear cache and reload
5. Check for duplicate IDs

---

## Appendix

### A. Complete Example: C++ Beginner Chapter 1

```json
{
  "programming_language": "C++",
  "beginner": {
    "estimated_duration": {
      "hours": 8,
      "minutes": 30
    },
    "chapter_1": {
      "module_1": {
        "title": "Introduction to C++",
        "level_schema": "schemas/courses/cpp/beginner/chapter_1/module_1_levels.txt"
      },
      "module_2": {
        "title": "Variables and Data Types",
        "level_schema": "schemas/courses/cpp/beginner/chapter_1/module_2_levels.txt"
      },
      "module_3": {
        "title": "Basic Input and Output",
        "level_schema": "schemas/courses/cpp/beginner/chapter_1/module_3_levels.txt"
      }
    }
  }
}
```

### B. Complete Example: Module with All Modes

See: `assets/schemas/courses/cpp/beginner/chapter_1/module_1_levels.txt`

This file demonstrates all five learning modes in sequence.

### C. User Progress Examples

**New User**:
```json
{
  "courseProgress": {
    "cpp": {
      "beginner": {"currentChapter": 1, "currentModule": 1},
      "intermediate": {"currentChapter": 1, "currentModule": 1},
      "advanced": {"currentChapter": 1, "currentModule": 1}
    }
  }
}
```

**Active Learner**:
```json
{
  "courseProgress": {
    "cpp": {
      "beginner": {"currentChapter": 3, "currentModule": 1},  // Completed
      "intermediate": {"currentChapter": 2, "currentModule": 2},
      "advanced": {"currentChapter": 1, "currentModule": 1}
    },
    "python": {
      "beginner": {"currentChapter": 1, "currentModule": 5},
      "intermediate": {"currentChapter": 1, "currentModule": 1},
      "advanced": {"currentChapter": 1, "currentModule": 1}
    }
  },
  "lastInteraction": {
    "languageId": "cpp",
    "difficulty": "intermediate"
  }
}
```

### D. API Reference Summary

#### CourseDataSchema Methods

| Method | Purpose | Returns |
|--------|---------|---------|
| `loadCoursesSchema()` | Load main index | `Map<String, CourseData>` |
| `loadModuleSchema(id)` | Load language modules | `ModuleData` |
| `loadLevelSchema(path)` | Load module levels | `LevelData` |
| `getAvailableLanguages()` | List all languages | `List<String>` |
| `getCurrentProgress(...)` | Get user position | `Map<String, int>` |
| `advanceModule(...)` | Move to next module | `Map<String, dynamic>` |
| `getProgressPercentage(...)` | Calculate completion | `double` (0.0-1.0) |
| `hasCompletedDifficulty(...)` | Check completion | `bool` |
| `isDifficultyLocked(...)` | Check accessibility | `bool` |

---

## Conclusion

The Code Sprout Courses System provides a robust, scalable framework for delivering programming education. Its schema-driven architecture allows for easy content updates while maintaining strong type safety and performance. The comprehensive progress tracking system ensures users can learn at their own pace across multiple languages and difficulties, with clear progression paths and meaningful accomplishments.

**Key Strengths**:
- Flexible schema-driven content
- Multi-language support
- Progressive difficulty system
- Robust progress tracking
- Rich learning modes
- Efficient caching
- Reactive UI updates

**Next Steps**:
- Add more languages and content
- Implement hints and notes
- Enhance analytics
- Improve accessibility
- Build community features

---

**Document Version**: 1.0.0  
**Last Updated**: November 27, 2025  
**Maintained By**: Code Sprout Development Team
