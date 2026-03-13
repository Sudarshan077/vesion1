# How to Launch the DMS Application

This guide contains the exact steps and commands needed to launch both the **Spring Boot Backend** and the **Flutter Frontend**.

It includes instructions for launching using your AI Assistant (Antigravity/Cursor) as well as launching manually via Android Studio/IntelliJ.

---

## 1. Launching the Backend (Spring Boot)

The backend is a Java Spring Boot application requiring JDK 21+.

### Option A: Using Antigravity / Agent (VS Code Terminal)
Ask your agent to run the backend, or run these exact commands in your terminal:

1. Open a terminal and navigate to the backend folder:
   ```bash
   cd c:\Users\srgow\OneDrive\Documents\version1\backend
   ```
2. Run the Spring Boot application using the Maven wrapper:
   ```bash
   ./mvnw spring-boot:run
   ```
*(Note: If you get a "Port 8080 already in use" error, ask the agent to kill the process first: `Get-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess | Stop-Process -Force`)*

### Option B: Using IntelliJ IDEA (Recommended for Backend)
1. Open **IntelliJ IDEA**.
2. Click **Open** and select the folder: `c:\Users\srgow\OneDrive\Documents\version1\backend`
3. Wait for IntelliJ to index and download Maven dependencies.
4. Open the file `src/main/java/com/dms/backend/BackendApplication.java`.
5. Click the green **Run** (Play) button next to the `main` method.

---

## 2. Launching the Frontend (Flutter)

The frontend is built with Flutter and uses a local SDK installed inside your project folder.

### Option A: Using Antigravity / Agent (VS Code Terminal)
Because your Flutter SDK is installed locally and not globally in your Windows system PATH, you must explicitly point to it when running commands in the VS Code terminal.

Ask the agent to launch it, or run this exact command:
```powershell
# Step 1: Navigate to the frontend folder
cd c:\Users\srgow\OneDrive\Documents\version1\frontend

# Step 2: Set the path to your local SDK for this session and run it on Chrome
$env:PATH = "c:\Users\srgow\OneDrive\Documents\version1\flutter-sdk\bin;" + $env:PATH; flutter run -d chrome
```

### Option B: Using Android Studio (Recommended for Mobile Frontend)
Android Studio gives you the best tools for running the app on a simulated Android phone.

1. Open **Android Studio**.
2. Click **Open** and select the folder: `c:\Users\srgow\OneDrive\Documents\version1\frontend`
3. **Crucial Step: Configure the SDK path!**
   *   If you see a banner saying "Flutter SDK not configured", click it. 
   *   *(Alternatively, go to `File` -> `Settings` -> `Languages & Frameworks` -> `Flutter`)*
   *   Set the **Flutter SDK path** exactly to: `C:\Users\srgow\OneDrive\Documents\version1\flutter-sdk`
   *   Click **Apply** and **OK**.
4. Open `pubspec.yaml` and click **Pub get** at the top right of the editor to install packages.
5. In the top toolbar, click the `<no device selected>` dropdown.
   *   Select **Chrome (web)** or your **Android Emulator**. 
   *   *(If you don't have an emulator, go to Tools -> Device Manager to create one).*
6. Click the green **Run (Play)** button in the top toolbar.

---
**Important Note on Order of Operations:**
Always ensure the **Backend is running first** on `localhost:8080` before you launch the Frontend, otherwise the Flutter app will fail to log in or fetch data.
