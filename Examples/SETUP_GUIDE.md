# Sample App Setup Guide

The Xcode project has been created! You can now run the sample apps.

## 🚀 How to Run

### Running CounterApp

1. **Open the project in Xcode**
   ```
   Examples/CounterApp/CounterApp.xcworkspace
   ```
   ⚠️ **Important**: You must open `.xcworkspace`, not `.xcodeproj`!

2. **Select Scheme**
   - Select "CounterApp" scheme from the top toolbar
   - Choose simulator or physical device

3. **Build and Run**
   - Press `Cmd + R` or click the ▶️ button

### Running TodoApp

1. **Open the project in Xcode**
   ```
   Examples/TodoApp/TodoApp.xcworkspace
   ```
   ⚠️ **Important**: You must open `.xcworkspace`, not `.xcodeproj`!

2. **Select Scheme**
   - Select "TodoApp" scheme from the top toolbar
   - Choose simulator or physical device

3. **Build and Run**
   - Press `Cmd + R` or click the ▶️ button

## 📦 Project Structure

Each sample app has the following structure:

```
CounterApp/
├── CounterApp.xcworkspace      # Workspace (open this!)
├── CounterApp.xcodeproj/        # Xcode project
├── CounterApp/                  # App target
│   └── CounterAppApp.swift      # App entry point
└── CounterAppPackage/           # Swift Package
    └── Sources/
        └── CounterAppFeature/
            └── ContentView.swift # Feature and View code
```

## 🔧 Troubleshooting

### "No such module 'InnoFlow'" Error

1. In Xcode, go to `File > Packages > Reset Package Caches`
2. Go to `File > Packages > Resolve Package Versions`
3. Clean the project: `Product > Clean Build Folder` (Shift + Cmd + K)
4. Build again: `Product > Build` (Cmd + B)

### Package Dependency Issues

If the project cannot find the InnoFlow package:

1. Check `CounterAppPackage/Package.swift` or `TodoAppPackage/Package.swift`
2. Verify the dependency path is correct:
   ```swift
   .package(path: "../../../InnoFlow")
   ```
3. Close and reopen the workspace

### Build Errors

1. **Check Swift version**: Requires Xcode 16.0 or later
2. **Check platform**: Targets iOS 18.4 or later
3. **Macro support**: Verify that `@InnoFlow` macro expands correctly
   - Check "Enable Macros" in Build Settings

## 📝 Notes

- Each project uses the **local InnoFlow package** as a dependency
- Automatically linked through Swift Package Manager
- Workspace (`.xcworkspace`) is used to include Swift Packages

## ✅ Checklist

Verify that the project is set up correctly:

1. ✅ Does the `.xcworkspace` file exist?
2. ✅ Is InnoFlow dependency added to Package.swift?
3. ✅ Is InnoFlow imported in ContentView.swift?
4. ✅ Does the app target depend on CounterAppFeature/TodoAppFeature package?

If all items are checked, you can build and run!

---

**If problems persist**: Please open an issue or try regenerating the project.
