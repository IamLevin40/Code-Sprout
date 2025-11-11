# Course Schema System Documentation

## Overview

This document describes the schema-driven course system for Code Sprout. The system uses JSON structures stored in `.txt` files to define all course content in a flexible, maintainable way.

## Schema Structure

### 1. Main Course Schema (`courses_schema.txt`)

**Location:** `assets/schemas/courses_schema.txt`

**Purpose:** Maps programming language IDs to their module schema files.

**Structure:**
```json
{
    "[programming_language_id]": {
        "module_schema_file": "[path_to_module_schema]"
    }
}
```

**Example:**
```json
{
    "cpp": {
        "module_schema_file": "assets/schemas/courses/cpp/cpp_modules_schema.txt"
    }
}
```

**Supported Languages:**
- `cpp` - C++
- `csharp` - C#
- `java` - Java
- `python` - Python
- `javascript` - JavaScript

---

### 2. Module Schema (`[language]_modules_schema.txt`)

**Location:** `assets/schemas/courses/[language]/[language]_modules_schema.txt`

**Purpose:** Defines the complete module structure for a programming language, including all difficulty levels, chapters, and modules.

**Structure:**
```json
{
    "programming_language": "[language_name]",
    "beginner": { ... },
    "intermediate": { ... },
    "advanced": { ... }
}
```

**Difficulty Level Structure:**
```json
"beginner": {
    "estimated_duration": {
        "hours": [integer],
        "minutes": [integer]
    },
    "chapter_1": {
        "module_1": {
            "title": "[module_title]",
            "level_schema": "[path_to_level_schema]"
        }
    }
}
```

---

### 3. Level Schema (`module_[n]_levels.txt`)

**Location:** `assets/schemas/courses/[language]/[difficulty]/chapter_[n]/module_[n]_levels.txt`

**Purpose:** Defines all levels (learning activities) within a module.

**Structure:**
```json
{
    "level_1": {
        "mode": "[mode_id]",
        "content": { ... }
    },
    "level_2": { ... }
}
```

---

## Content Modes

### Mode 1: Lecture (`"mode": "lecture"`)

**Purpose:** Present educational content with text and code examples.

**Content Structure:**
```json
{
    "1_title": ["Title text"],
    "2_plain": ["Paragraph 1", "Paragraph 2"],
    "3_input_code": ["code line 1", "code line 2"],
    "4_output_code": ["output line 1"],
    "5_plain": ["More text"]
}
```

**Section Types:**
- `title` - Heading text (displayed prominently)
- `plain` - Regular paragraph text
- `input_code` - Code examples (formatted as code)
- `output_code` - Expected output (formatted differently)

**Ordering:** Prefix numbers (1_, 2_, etc.) determine display order.

---

### Mode 2: Multiple Choice (`"mode": "multiple_choice"`)

**Purpose:** Test understanding with multiple choice questions.

**Content Structure:**
```json
{
    "question": "What is the correct syntax?",
    "correct_answer": "cout << x;",
    "incorrect_answers": [
        "cout >> x;",
        "cin << x;",
        "print(x);"
    ]
}
```

**Fields:**
- `question` - The question text
- `correct_answer` - The correct answer
- `incorrect_answers` - Array of 3 incorrect options

---

### Mode 3: True or False (`"mode": "true_or_false"`)

**Purpose:** Test understanding with true/false questions.

**Content Structure:**
```json
{
    "question": "C++ requires semicolons at the end of statements.",
    "correct_answer": true
}
```

**Fields:**
- `question` - The question text
- `correct_answer` - Boolean (true or false)

---

### Mode 4: Fill in the Code (`"mode": "fill_in_the_code"`)

**Purpose:** Test ability to complete code by filling in blanks.

**Content Structure:**
```json
{
    "code_lines": [
        "int x [_] 5;",
        "cout << x[_]"
    ],
    "choices": ["=", ";", ":", ">>"],
    "correct_answers": ["=", ";"]
}
```

**Fields:**
- `code_lines` - Array of code lines with `[_]` marking blanks
- `choices` - Available options to fill blanks
- `correct_answers` - Correct answer for each blank (in order)

**Blank Marker:** Use `[_]` to indicate where user should fill in code.

---

### Mode 5: Assemble the Code (`"mode": "assemble_the_code"`)

**Purpose:** Test ability to arrange code blocks in correct order.

**Content Structure:**
```json
{
    "question": "Arrange the code to create a valid program",
    "correct_code_lines": [
        "#include <iostream>",
        "int main() {",
        "    return 0;",
        "}"
    ],
    "choices": [
        "#include <iostream>",
        "int main() {",
        "return 0;",
        "    return 0;",
        "}",
        "int start() {",
        "return 1;"
    ]
}
```

**Fields:**
- `question` - Instructions for the user
- `correct_code_lines` - The correct sequence of code lines
- `choices` - All available code blocks (includes correct and incorrect options)

**Note:** Include both correct and incorrect options, and variations with different indentation.

---

## File Organization

```
assets/schemas/
├── courses_schema.txt                          # Main course index
├── courses/
│   ├── cpp/
│   │   ├── cpp_modules_schema.txt             # C++ module structure
│   │   ├── beginner/
│   │   │   ├── chapter_1/
│   │   │   │   ├── module_1_levels.txt        # Level content
│   │   │   │   ├── module_2_levels.txt
│   │   │   │   └── module_3_levels.txt
│   │   │   └── chapter_2/
│   │   │       └── ...
│   │   ├── intermediate/
│   │   │   └── ...
│   │   └── advanced/
│   │       └── ...
│   ├── csharp/
│   │   └── ...
│   ├── java/
│   │   └── ...
│   ├── python/
│   │   └── ...
│   └── javascript/
│       └── ...
```

---

## Usage in Code

### Loading Schemas

```dart
import 'package:code_sprout/models/course_data_schema.dart';

final courseService = CourseDataSchema();

// Load all available courses
final courses = await courseService.loadCoursesSchema();

// Load module structure for a language
final cppModules = await courseService.loadModuleSchema('cpp');

// Load specific level content
final level = await courseService.getLevel(
    levelSchemaPath: 'assets/schemas/courses/cpp/beginner/chapter_1/module_1_levels.txt',
    levelId: 'level_1',
);
```

### Working with Content

```dart
// For lecture content
if (level.mode == 'lecture') {
  final lectureContent = level.getLectureContent();
  final sections = lectureContent?.getOrderedSections();
  
  for (var section in sections ?? []) {
    final type = lectureContent?.getSectionType(section.key);
    final content = section.value;
    // Display based on type (title, plain, input_code, output_code)
  }
}

// For multiple choice
if (level.mode == 'multiple_choice') {
  final mcContent = level.getMultipleChoiceContent();
  final allChoices = mcContent?.getAllChoices(shuffled: true);
  // Display question and shuffled choices
}

// For fill in the code
if (level.mode == 'fill_in_the_code') {
  final fillContent = level.getFillInTheCodeContent();
  final blankCount = fillContent?.getBlankCount();
  // Display code with blanks and choices
}
```

---

## Progress Tracking

### User Progress Schema

User progress is stored in the `courseProgress` section of user data with the following structure:

```json
{
    "courseProgress": {
        "[language_id]": {
            "[difficulty]": {
                "currentChapter": [integer],
                "currentModule": [integer]
            }
        }
    }
}
```

**Example:**
```json
{
    "courseProgress": {
        "cpp": {
            "beginner": {
                "currentChapter": 1,
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
        }
    }
}
```

### Progress Tracking Methods

The `CourseDataSchema` class provides several helper methods for managing user progress:

#### Get Current Progress

```dart
final progress = courseService.getCurrentProgress(
  userData: userData,
  languageId: 'cpp',
  difficulty: 'beginner',
);
// Returns: {'currentChapter': 1, 'currentModule': 3}
```

#### Get Current Module

```dart
final currentModule = await courseService.getCurrentModule(
  userData: userData,
  languageId: 'cpp',
  difficulty: 'beginner',
);
// Returns: Module object user is currently on
```

#### Advance to Next Module

```dart
final updatedUserData = await courseService.advanceModule(
  userData: userData,
  languageId: 'cpp',
  difficulty: 'beginner',
);
// Automatically moves to next chapter if current chapter is completed
```

#### Calculate Progress Percentage

```dart
final percentage = await courseService.getProgressPercentage(
  userData: userData,
  languageId: 'cpp',
  difficulty: 'beginner',
);
// Returns: 0.0 to 1.0 (multiply by 100 for percentage)
```

#### Check Completion Status

```dart
final isCompleted = await courseService.hasCompletedDifficulty(
  userData: userData,
  languageId: 'cpp',
  difficulty: 'beginner',
);
// Returns: true if all modules in difficulty are completed
```

#### Reset Progress

```dart
final resetUserData = courseService.resetProgress(
  userData: userData,
  languageId: 'cpp',
  difficulty: 'beginner',
);
// Resets progress to chapter 1, module 1
```

### Progress Behavior

**Module Advancement:**
- When a user completes a module, call `advanceModule()`
- If there are more modules in the current chapter, moves to next module
- If current chapter is completed, moves to next chapter's first module
- Progress continues beyond defined modules (for future updates)

**Independence:**
- Each difficulty level tracks progress independently
- Completing beginner doesn't affect intermediate or advanced progress
- Each language tracks progress independently

**Level Progress:**
- Level progress (within modules) is NOT stored in user data
- Level progress is managed locally in the app
- Only chapter and module progress is persisted to Firestore

---

## Adding New Content

### Adding a New Module

1. Update the module schema file for the language
2. Add module entry under appropriate chapter
3. Create a new level schema file
4. Define levels with various modes
5. Update `pubspec.yaml` if adding new directories

### Adding a New Language

1. Add entry to `courses_schema.txt`
2. Create language directory structure
3. Create `[language]_modules_schema.txt`
4. Create chapter/module directories
5. Create level schema files
6. Update `pubspec.yaml` assets section

---

## Best Practices

1. **Consistent Naming:** Use snake_case for IDs (cpp, csharp, chapter_1, module_1)
2. **Progressive Difficulty:** Order levels from easiest to hardest
3. **Variety:** Mix different modes within each module
4. **Clear Questions:** Write unambiguous questions and answers
5. **Code Formatting:** Maintain proper indentation in code examples
6. **Validation:** Test all schemas load correctly before committing

---

## Example: Complete Module

See `assets/schemas/courses/cpp/beginner/chapter_1/module_1_levels.txt` for a complete example demonstrating all five content modes.

---

## Troubleshooting

**Schema won't load:**
- Check JSON syntax (use a JSON validator)
- Verify file paths are correct
- Ensure file is in `pubspec.yaml` assets

**Content not displaying:**
- Verify mode name is spelled correctly
- Check content structure matches mode requirements
- Ensure all required fields are present

**Order is wrong:**
- Check numeric prefixes in lecture sections
- Verify level IDs (level_1, level_2, etc.)
