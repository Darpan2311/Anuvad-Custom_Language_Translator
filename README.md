## 📚 **Anuvad – Translator for Layman-Friendly Language**

**Anuvad** is a custom language translator designed to simplify programming concepts for  users by translating instructions into executable code. The project covers:

- Custom language syntax with defined grammar rules.
- Lexical and syntax analysis using YACC and Lex.
- Transition diagram to showcase token identification and language translation.

---

## 🚀 **Features**
- **Custom Language Support:** Translate simple human-readable instructions into code.
- **Token Identification:** Use Lex for lexical analysis and YACC for parsing.
- **Compiler Workflow:** Smooth translation from input to desired output.

---

## ⚙️ **Installation Guide**

### 🎯 **Step 1: Install Required Tools**

---

### 🔥 **1.1 Install MinGW (for GCC on Windows)**
- **Download Link:** [MinGW on SourceForge](https://sourceforge.net/projects/mingw/)
- **Installation Steps:**
   1. Download and run the MinGW installer.
   2. During installation, select:
      - `mingw32-base`
      - `mingw32-gcc-g++`
   3. Add `C:\MinGW\bin` to your `PATH` environment variable:
   ```bash
   setx PATH "%PATH%;C:\MinGW\bin"
   ```

---

### 🔥 **1.2 Install Flex and Bison**
- **Download Link:** [GnuWin32 Flex & Bison](https://gnuwin32.sourceforge.net/packages.html)
- **Installation:**
   1. Download and extract the `.zip` file.
   2. Add the extracted folder to your `PATH`:
   ```bash
   setx PATH "%PATH%;C:\path\to\flex-bison-folder\bin"
   ```

---

### 🎯 **Step 2: Verify Installation**
To ensure everything is installed correctly, run:
```bash
gcc --version
bison --version
flex --version
```

✅ If installed correctly, you will see the version details.

---

### 🎯 **Step 3: Compile Flex and Yacc Files**

---

### 📂 **3.1 Place Your Flex and Yacc Files in One Folder**
- `lexer.l` → Flex file
- `parser.y` → YACC/Bison file

---

### ⚡ **3.2 Run Flex**
```bash
flex lexer.l
```
✅ This generates `lex.yy.c`.

---

### ⚡ **3.3 Run Yacc/Bison**
```bash
bison -d parser.y
```
✅ This generates:
- `parser.tab.c` → Parser source
- `parser.tab.h` → Header file

---

### 🎯 **Step 4: Compile with GCC**

---

### 🛠️ **Compile All Files**
```bash
gcc -o mycompiler lex.yy.c parser.tab.c -lm
```
✅ This generates the `mycompiler.exe` file.

---

### 🎯 **Step 5: Run the Compiler**

---

### 📝 **Run with an Input File**
```bash
mycompiler.exe < input.txt
```
✅ The output will be displayed on the terminal.

## 📊 **Transition Diagram**

Here’s the transition diagram explaining token identification and parsing:

![Transition Diagram](./images/transition_diagram.png)

---

## 📷 **Screenshots and Results**
![Input Output](./o.jpg)

