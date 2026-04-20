# Firebase Setup Guide

This guide will help you set up Firebase for your Flutter app to store student data, activity times, game results, and progress tracking.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "Nanapiyasa-Student-Tracker")
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

## Step 2: Add Firebase to Flutter App

1. In Firebase Console, click the Android icon to add an Android app
2. Enter package name: `com.nanapiyasa.research` (check your android/app/build.gradle for exact package name)
3. Download `google-services.json`
4. Place `google-services.json` in `android/app/` directory
5. Follow the setup instructions for Android

For iOS (if needed):
1. Click the iOS icon to add an iOS app
2. Enter iOS bundle ID
3. Download `GoogleService-Info.plist`
4. Place it in your iOS project

## Step 3: Update Android Configuration

Add the following to `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'

android {
    // ...
}

dependencies {
    // ...
    implementation 'com.google.firebase:firebase-bom:33.0.0'
    implementation 'com.google.firebase:firebase-analytics'
}
```

Add to `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        // ...
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

## Step 4: Update iOS Configuration (if needed)

Add to `ios/Runner/Info.plist`:

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

## Step 5: Configure Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to your users)
5. Click "Create"

## Step 6: Set Up Database Security Rules

For development and testing, use these permissive rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all users (for development)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

For production mode, use these secure rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to authenticated users only
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 7: Create Database Collections

Create the following collections in your Firestore database:

### 1. **students** Collection
| Field | Type | Description | Required |
|--------|------|-------------|-----------|
| firstName | String | Student's first name | Yes |
| lastName | String | Student's last name | Yes |
| age | String | Student's age | Yes |
| username | String | Unique username | Yes |
| createdAt | Timestamp | Account creation date | Yes |
| lastLogin | Timestamp | Last login time | No |
| isActive | Boolean | Account status | No |

### 2. **activities** Collection
| Field | Type | Description | Required |
|--------|------|-------------|-----------|
| studentId | String | Reference to student | Yes |
| activityType | String | Type of activity | Yes |
| startTime | Timestamp | Activity start time | Yes |
| endTime | Timestamp | Activity end time | Yes |
| duration | Number | Duration in seconds | Yes |
| completionPercentage | Number | Activity completion % | No |
| createdAt | Timestamp | Activity creation date | Yes |

### 3. **game_results** Collection
| Field | Type | Description | Required |
|--------|------|-------------|-----------|
| studentId | String | Reference to student | Yes |
| gameType | String | Game/module type | Yes |
| score | Number | Game score | Yes |
| maxScore | Number | Maximum possible score | Yes |
| percentage | Number | Score percentage | Yes |
| completionTime | Number | Time to complete (seconds) | Yes |
| attempts | Number | Number of attempts | Yes |
| bestScore | Number | Best score achieved | No |
| createdAt | Timestamp | Game completion date | Yes |

### 4. **module_progress** Collection
| Field | Type | Description | Required |
|--------|------|-------------|-----------|
| studentId | String | Reference to student | Yes |
| moduleKey | String | Module identifier | Yes |
| moduleName | String | Module display name | Yes |
| completionPercentage | Number | Progress percentage | Yes |
| totalTimeSpent | Number | Total time spent (seconds) | Yes |
| lastAccessed | Timestamp | Last access time | No |
| isCompleted | Boolean | Module completion status | No |
| startedAt | Timestamp | Module start date | No |
| completedAt | Timestamp | Module completion date | No |
| createdAt | Timestamp | Progress record date | Yes |

### 5. **questionnaire_results** Collection
| Field | Type | Description | Required |
|--------|------|-------------|-----------|
| studentId | String | Reference to student | Yes |
| questionnaireType | String | Type of questionnaire | Yes |
| responses | Map | Question answers | Yes |
| scores | Map | Calculated scores per module | Yes |
| recommendations | Map | Module recommendations | Yes |
| completedAt | Timestamp | Completion date | Yes |
| createdAt | Timestamp | Creation date | Yes |
    
    // Students collection
    match /students/{studentId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == studentId || 
         request.auth.token.admin == true);
    }
    
    // Activities collection
    match /activities/{activityId} {
      allow read, write: if request.auth != null;
    }
    
    // Game results collection
    match /game_results/{resultId} {
      allow read, write: if request.auth != null;
    }
    
    // Questionnaire results collection
    match /questionnaire_results/{resultId} {
      allow read, write: if request.auth != null;
    }
    
    // Game summaries collection
    match /game_summaries/{summaryId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 7: Run Flutter App

1. Run `flutter pub get` to install Firebase dependencies
2. Run `flutter run` to test the app
3. Check console for Firebase initialization messages

## Step 8: Test the Integration

1. Create a test student account using the signup form
2. Check Firebase Console > Firestore Database > Data
3. You should see:
   - A new document in the `students` collection
   - Student details (firstName, lastName, age, username, createdAt)
   - Empty gameResults, activityTimes, and moduleProgress maps

## Database Structure

The app will create the following structure in Firestore:

```
students/
  {studentId}/
    firstName: "John"
    lastName: "Doe"
    age: "25"
    username: "johndoe"
    createdAt: timestamp
    gameResults:
      chef:
        - gameType: "chef"
          score: 85
          timeSpent: 120
          timestamp: timestamp
          additionalData:
            maxScore: 100
            percentage: 85
    activityTimes:
      chef_game:
        - activityName: "chef_game"
          duration: 120
          startTime: timestamp
          endTime: timestamp
    moduleProgress:
      chef_level_01:
        moduleId: "chef_level_01"
        moduleName: "Chef Level 1"
        completionPercentage: 80.0
        completedTasks: ["task_1", "task_2", "task_3", "task_4"]
        lastUpdated: timestamp
    recommendedJobRole: "Chef"
```

## Step 9: Production Considerations

For production, you should:

1. **Update Security Rules**: Make them more restrictive
2. **Enable Authentication**: Implement proper Firebase Auth
3. **Add Indexes**: Create Firestore indexes for common queries
4. **Monitor Usage**: Set up Firebase Analytics and Crashlytics
5. **Backup Data**: Regularly backup your Firestore data

## Step 10: Common Issues & Solutions

### Issue: "Firebase initialization failed"
- Solution: Ensure `google-services.json` is in the correct location
- Check that your package name matches the Firebase project

### Issue: "Permission denied" errors
- Solution: Update Firestore security rules
- Ensure user is authenticated

### Issue: "No such document" errors
- Solution: Check if the document exists before accessing
- Use proper error handling

### Issue: Performance issues
- Solution: Add Firestore indexes for complex queries
- Use pagination for large datasets
- Optimize your data structure

## Next Steps

Once Firebase is set up, you can:

1. **View Student Data**: Check the Firebase Console for real-time data
2. **Create Analytics**: Build dashboards to track student progress
3. **Add Reports**: Generate progress reports for students
4. **Implement Recommendations**: Use the job role recommendation system
5. **Add Leaderboards**: Create competitive elements with game leaderboards

## Complete Database Structure Overview

### 📊 All Firebase Collections

#### 1. **students** Collection
| Field | Type | Description | Required | Example |
|--------|------|-------------|-----------|----------|
| firstName | String | Student's first name | Yes | "John" |
| lastName | String | Student's last name | Yes | "Doe" |
| age | String | Student's age | Yes | "16" |
| username | String | Unique username | Yes | "johndoe" |
| createdAt | Timestamp | Account creation date | Yes | "2024-01-15T10:30:00Z" |
| lastLogin | Timestamp | Last login time | No | "2024-01-20T14:22:00Z" |
| isActive | Boolean | Account status | No | true |
| recommendedJobRole | String | Recommended career | No | "Chef" |

#### 2. **questionnaire_results** Collection
| Field | Type | Description | Required | Example |
|--------|------|-------------|-----------|----------|
| studentId | String | **Foreign Key to students.username** | Yes | "johndoe" |
| questionnaireType | String | Type of questionnaire | Yes | "vocational_assessment" |
| responses | Map | Question answers | Yes | {"q1": "4", "q2": "Yes", ...} |
| scores | Map | Calculated scores per module | Yes | {"chef": 0.85, "retail": 0.72, ...} |
| recommendations | Map | Module recommendations | Yes | {"primary": "Chef", "confidence": 0.85} |
| completedAt | Timestamp | Completion date | Yes | "2024-01-15T11:45:00Z" |
| createdAt | Timestamp | Creation date | Yes | "2024-01-15T10:30:00Z" |

#### 3. **activities** Collection
| Field | Type | Description | Required | Example |
|--------|------|-------------|-----------|----------|
| studentId | String | **Foreign Key to students.username** | Yes | "johndoe" |
| activityType | String | Type of activity | Yes | "chef_game" |
| startTime | Timestamp | Activity start time | Yes | "2024-01-15T10:30:00Z" |
| endTime | Timestamp | Activity end time | Yes | "2024-01-15T11:30:00Z" |
| duration | Number | Duration in seconds | Yes | 3600 |
| completionPercentage | Number | Activity completion % | No | 85.5 |
| createdAt | Timestamp | Activity creation date | Yes | "2024-01-15T10:30:00Z" |

#### 4. **game_results** Collection
| Field | Type | Description | Required | Example |
|--------|------|-------------|-----------|----------|
| studentId | String | **Foreign Key to students.username** | Yes | "johndoe" |
| gameType | String | Game/module type | Yes | "chef_level_01" |
| score | Number | Game score | Yes | 85 |
| maxScore | Number | Maximum possible score | Yes | 100 |
| percentage | Number | Score percentage | Yes | 85.0 |
| completionTime | Number | Time to complete (seconds) | Yes | 300 |
| attempts | Number | Number of attempts | Yes | 2 |
| bestScore | Number | Best score achieved | No | 92 |
| createdAt | Timestamp | Game completion date | Yes | "2024-01-15T11:45:00Z" |

#### 5. **module_progress** Collection
| Field | Type | Description | Required | Example |
|--------|------|-------------|-----------|----------|
| studentId | String | **Foreign Key to students.username** | Yes | "johndoe" |
| moduleKey | String | Module identifier | Yes | "chef_level_01" |
| moduleName | String | Module display name | Yes | "Chef Level 1" |
| completionPercentage | Number | Progress percentage | Yes | 75.0 |
| totalTimeSpent | Number | Total time spent (seconds) | Yes | 7200 |
| lastAccessed | Timestamp | Last access time | No | "2024-01-15T12:00:00Z" |
| isCompleted | Boolean | Module completion status | No | false |
| startedAt | Timestamp | Module start date | No | "2024-01-15T09:00:00Z" |
| completedAt | Timestamp | Module completion date | No | "2024-01-15T11:45:00Z" |
| createdAt | Timestamp | Progress record date | Yes | "2024-01-15T10:30:00Z" |

### 6. **game_summaries** Collection
| Field | Type | Description | Required | Example |
|--------|------|-------------|-----------|----------|
| studentId | String | **Foreign Key to students.username** | Yes | "johndoe" |
| gameType | String | Game/module type | Yes | "chef_level_01" |
| gameName | String | Display name of game | Yes | "Chef Level 1" |
| completionTime | Number | Time to complete (seconds) | Yes | 300 |
| finalScore | Number | Final score achieved | Yes | 85 |
| maxScore | Number | Maximum possible score | Yes | 100 |
| scorePercentage | Number | Score percentage | Yes | 85.0 |
| attempts | Number | Total attempts made | Yes | 12 |
| accuracy | Number | Accuracy percentage | No | 75.5 |
| bestTime | Number | Best completion time (seconds) | No | 280 |
| starsEarned | Number | Stars earned (1-3) | No | 2 |
| levelCompleted | Boolean | Level completion status | Yes | true |
| difficulty | String | Game difficulty level | No | "easy" |
| sessionDuration | Number | Total session time (seconds) | No | 450 |
| itemsCompleted | Number | Items/tasks completed | No | 6 |
| totalItems | Number | Total items/tasks in game | No | 6 |
| completedAt | Timestamp | Game completion date | Yes | "2024-01-15T11:45:00Z" |
| createdAt | Timestamp | Record creation date | Yes | "2024-01-15T10:30:00Z" |

### 🔗 Data Relationships (Foreign Key Structure)

```
students.username (PK) ←→ (FK) questionnaire_results.studentId
students.username (PK) ←→ (FK) activities.studentId  
students.username (PK) ←→ (FK) game_results.studentId
students.username (PK) ←→ (FK) module_progress.studentId
students.username (PK) ←→ (FK) game_summaries.studentId
```

**Key:**
- **PK** = Primary Key (students.username)
- **FK** = Foreign Key (references students.username)

**Relationship Benefits:**
- **Data Integrity** - All data linked to actual student accounts
- **No Anonymous Data** - Prevents orphaned records
- **Proper Joins** - Enables complex queries across collections
- **User Authentication** - Only authenticated users can save data

### 📱 Data Flow Example

1. **Student Signup** → Creates document in `students` collection
2. **Questionnaire Completion** → Creates document in `questionnaire_results` collection
3. **Game Play** → Creates documents in `activities` and `game_results` collections
4. **Module Progress** → Updates/creates documents in `module_progress` collection

## Testing Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Test Firebase connection
flutter test test/firebase_test.dart
```

## Support

If you encounter issues:
1. Check the Firebase documentation
2. Review the FlutterFire documentation
3. Check the console logs for specific error messages
4. Ensure all configuration files are correctly placed
