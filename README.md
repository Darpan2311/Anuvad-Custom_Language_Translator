Here’s the updated version of your **Anuvad** `README.md` with the Windows setup and debugging steps included:

---

## 📚 **Anuvad – Translator for Layman-Friendly Language**

**Anuvad** is a custom language translator designed to simplify complex programming concepts for layman users by translating high-level instructions into executable code. The project covers:

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

---

## 📝 **Usage**

1. **Input Code Format**
```
start
    declare x as integer
    set x to 5
    if x is greater than 3 then
        print "X is large"
    else
        print "X is small"
    end if
stop
```

2. **Run the Code**
```
mycompiler.exe < input.txt
```

3. **Sample Output**
```
X is large
```

---

## 📊 **Transition Diagram**

Here’s the transition diagram explaining token identification and parsing:

![Transition Diagram](./images/transition_diagram.png)

---

## 🔎 **Debugging Steps**

### 🕵️ **Check Version Details**
To verify if the tools are installed:
```bash
gcc --version
bison --version
flex --version
```

---

### 🛠️ **Run Flex and Bison with Debug Options**
1. **Flex Debug Mode**
```bash
flex -d lexer.l
```
2. **Bison Debug Mode**
```bash
bison -t -d parser.y
```

---

### 🚩 **Common Errors and Fixes**
- `flex: command not found` → Add Flex to PATH or reinstall.
- `gcc: fatal error` → Check if MinGW is installed and added to PATH.
- `undefined reference to yylex()` → Flex and Bison files may not be compiled in the correct order.

---

## 📸 **Input-Output Examples**

### 🎉 **Example 1: Basic Arithmetic**
**Input:**
```
start
    declare a as integer
    set a to 10
    print "Value of A is ", a
stop
```
**Output:**
```
Value of A is 10
```

### 🎉 **Example 2: Conditional Statement**
**Input:**
```
start
    declare num as integer
    set num to 20
    if num is equal to 20 then
        print "Number is 20"
    end if
stop
```
**Output:**
```
Number is 20
```

---

## 📚 **Language Specifications**
- **Case Sensitivity:** Case-insensitive.
- **Keywords:** `start`, `stop`, `declare`, `set`, `if`, `else`, `print`
- **Data Types:** `integer`, `string`
- **Operators:** `is equal to`, `is greater than`, `is less than`

---

## 📷 **Screenshots and Results**

### 🎉 **Successful Execution**
![Execution Result](./images/success_result.png)

### ⚠️ **Error Handling**
![Error Example](./images/error_example.png)

---

## 🎯 **Project Workflow**

1. **Lexical Analysis:** Tokenizes the input to identify keywords, operators, and variables.
2. **Syntax Analysis:** Parses the tokenized input to check grammar and structure.
3. **Semantic Analysis:** Ensures logical correctness and generates output.

---

## 💡 **Contributing**
If you'd like to contribute to **Anuvad**, feel free to fork the repo and submit a pull request. Feedback and suggestions are always welcome!

---

## 📧 **Contact**
For any questions or suggestions, contact:
- [Your Name](mailto:your.email@example.com)
- GitHub: [@yourusername](https://github.com/yourusername)

---

✅ **Done!** Now you can add your input-output photos and transition diagrams to the `images` folder and update the file paths accordingly. Let me know if you need help with generating diagrams or sample screenshots! 😊
