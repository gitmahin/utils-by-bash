# `cpprun` — C++ Program Compilation Automation Tool

# Installation
```bash
chmod 755 install.sh
./install.sh 
```

## 🚀 Features:
- Compiles multiple files in parallel
- Automatically finds `.cpp` and `.c++` files using the `-apl` flag
- Get rid of vs `code runner` temp error
- Auto-corrects file extensions:
  Typing `home.c++` will fallback to `home.cpp` if `.c++` doesn't exist (and vice versa)
  Typing home or `home.out` will be interpreted correctly based on context
- Can merge source files and outputs into a new directory using the `-d` option

## 🧠 Usage & Options


| Option   | Description |
|----------|-------------|
| `-apl`   | Automatically find and compile all `.cpp` and `.c++` files in parallel (must include `-pl`) |
| `-d`     | Merge both the source file and the compiled output into a new directory |
| `-pl`    | Compile files in parallel mode |

## 🛠 Basic Run
To compile a cpp file;
```bash
cpprun myprogram.cpp
```
To simply run a compiled `.out` file, just type the file name:
```bash
cpprun myprogram
```
If the `.out` file was merged using the `-d` option, include it when running:
```bash
cpprun -d myprogram
```

## 📚 Detailed Examples

### 1. `-d`: Compile and Organize in a Directory
Say you have `home.cpp` and you want to compile and move both the `.cpp` and `.out` file into a new directory:
```bash
cpprun -d home.cpp # can compile & run only one file
```
To re-run it later, you can use:
```bash
cpprun -d home
```
✅ cpprun will auto-detect if you mistyped `.c++`, `.cpp`, or even `home.out`.
It will attempt to resolve the correct file before throwing an error.

### 2. `-pl`: Compile Multiple Files in Parallel
To compile several files simultaneously:
```bash
cpprun -pl home.cpp car.cpp tree.cpp
```
Combine it with `-d` to move all files and outputs to a new directory:
```bash
cpprun -pld home.cpp car.cpp tree.cpp
```
Note: In parallel mode, if any compilation fails, the other compilations will not be affected.

### 3. `-apl`: Auto-Find & Compile All C++ Files in Parallel
Its too annoying if we want to compile all of the cpp and c++ files at once in parallel mode by typing each cpp files manually.
So to solve this you can just leave it to cpprun to manage and get the all cpp and c++ files and compile at once.
```bash
cpprun -apl
```
To also merge them into a new directory:
```bash
cpprun -apld
```
⚠️ Note: When using `-apl` with `-d`, this operation is one-time only.
If you rerun the same command, `cpprun` will throw an error with "no file found" error.

## 🧠 Smart File Handling
- If you provide `home.c++` and the file doesn’t exist, `cpprun` will automatically check for `home.cpp` instead
- Similarly, if you type `home.out` or just home, it will resolve and run the corresponding output file