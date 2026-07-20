# RectangleWin Project Comprehensive Analysis Report

> **Date**: 2026-02-09
> **Target**: nicewook/RectangleWin (fork of ahmetb/RectangleWin)
> **Go Version**: 1.25
> **License**: Apache 2.0

---

## 1. Project Overview

### 1.1 Basic Information

| Item | Details |
|------|---------|
| Project Name | RectangleWin |
| Description | Hotkey-based window snapping and resizing utility for Windows |
| Original | Windows reimplementation of macOS Rectangle.app/Spectacle.app |
| Language | Go 1.25+ |
| Target Platform | Windows only |
| License | Apache 2.0 |
| CI/CD | GitHub Actions + GoReleaser v2 |

### 1.2 Tech Stack

| Dependency | Version | Purpose |
|------------|---------|---------|
| `fyne.io/systray` | v1.12.0 | System tray icon and menu |
| `github.com/gonutz/w32/v2` | v2.12.1 | Win32 API bindings |
| `golang.org/x/sys` | v0.40.0 | Windows system calls (registry, etc.) |

### 1.3 Source File Structure

| File | Lines | Role |
|------|-------|------|
| `main.go` | 376 | Entry point, hotkey registration, resize logic, maximize/restore |
| `snap.go` | 136 | Snap position calculation functions (edge, corner, thirds, size adjustment) |
| `hotkey.go` | 93 | HotKey struct, registration, message loop |
| `keymap.go` | 186 | Virtual key code → string mapping table |
| `monitor.go` | 66 | Multi-monitor enumeration and info display |
| `systemwindow.go` | 101 | System window filtering (zonable determination) |
| `tray.go` | 140 | System tray icon, menu, shortcut dialog |
| `autorun.go` | 69 | Startup program registration via Windows registry |
| `multimon.go` | 197 | Multi-display window movement logic |
| `w32ex/functions.go` | 75 | Direct user32.dll calls (DPI, IsZoomed, etc.) |

**Total**: ~1,439 lines (including whitespace/comments)

---

## 2. Detailed Analysis of Implemented Features

### 2.1 Window Snapping

#### 2.1.1 Edge Snapping (Halves)
- **Shortcut**: `Ctrl + Alt + Arrow Keys`
- **Supported Positions**: Top / Bottom / Left / Right
- **Behavior**: Snaps to half the screen size
- **Multi-monitor support**: Left/Right arrow keys move to the next monitor on repeat press

| Shortcut | Function |
|----------|----------|
| `Ctrl+Alt+←` | Left half (moves to left monitor on repeat) |
| `Ctrl+Alt+→` | Right half (moves to right monitor on repeat) |
| `Ctrl+Alt+↑` | Top half |
| `Ctrl+Alt+↓` | Bottom half |

#### 2.1.2 Corner Snapping (Corners)
- **Shortcut**: `Ctrl + Alt + U/I/J/K`
- **Supported Positions**: 4 corners

| Shortcut | Function |
|----------|----------|
| `Ctrl+Alt+U` | Top-left corner |
| `Ctrl+Alt+I` | Top-right corner |
| `Ctrl+Alt+J` | Bottom-left corner |
| `Ctrl+Alt+K` | Bottom-right corner |

#### 2.1.3 Thirds Snapping (Thirds)
- **Shortcut**: `Ctrl + Alt + D/E/F/G/T`
- **Supported Positions**: 1/3, 2/3 sizes

| Shortcut | Function |
|----------|----------|
| `Ctrl+Alt+D` | First 1/3 (left, moves to left monitor on repeat) |
| `Ctrl+Alt+F` | Center 1/3 |
| `Ctrl+Alt+G` | Last 1/3 (right, moves to right monitor on repeat) |
| `Ctrl+Alt+E` | First 2/3 (moves to left monitor on repeat) |
| `Ctrl+Alt+T` | Last 2/3 (moves to right monitor on repeat) |

#### 2.1.4 Size Adjustment
- **Shortcut**: `Ctrl + Alt + +/-`
- **Behavior**: Adjusts size by 3% of resolution proportionally

| Shortcut | Function |
|----------|----------|
| `Ctrl+Alt+-` | Shrink (3% at a time, minimum 100x100) |
| `Ctrl+Alt++` | Grow (3% at a time) |

### 2.2 Window Placement Features

#### 2.2.1 Center Placement (Center)
- **Shortcut**: `Ctrl + Alt + C`
- **Behavior**: Places at 75% of screen size, centered
- **Implementation**: `center()` function

```go
width := disp.Width() * 3 / 4   // 75%
height := disp.Height() * 3 / 4 // 75%
```

#### 2.2.2 Maximize
- **Shortcut**: `Ctrl + Alt + Enter`
- **Behavior**: Maximizes the window
- **Implementation**: `maximize()` function

#### 2.2.3 Restore
- **Shortcut**: `Ctrl + Alt + Backspace`
- **Behavior**:
  1. Maximized state → restores to normal window (`SW_RESTORE`)
  2. Snapped state → restores to original position before snapping
- **Implementation**: `restore()` function, using `savedStates` map

### 2.3 System Integration Features

#### 2.3.1 System Tray
- Resides with icon (embedded `assets/tray_icon.ico`)
- Menu items:
  - **About RectangleWin...**: Opens GitHub repository
  - **Keyboard Shortcuts...**: Displays shortcut list dialog
  - **Run on startup**: Toggle startup program registration
  - **Exit**: Exits the application

#### 2.3.2 Startup Program Registration
- **Registry Key**: `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`
- **Value Name**: `RectangleWin`
- **Implementation**: `autorun.go` (AutoRunEnable/Disable/Enabled)

#### 2.3.3 Multi-Monitor Support
- Monitor enumeration: `EnumMonitors()` (monitor.go)
- Monitor sorting: Sorted left-to-right by X coordinate
- Wraparound movement: Pressing left at the leftmost monitor wraps to the rightmost
- **Implementation**: `multimon.go`

#### 2.3.4 DPI Awareness
- Calls `SetProcessDPIAware()`
- Calculates per-window DPI via `GetDpiForWindow()`
- DPI correction via `resizeForDpi()`
- Includes invisible border correction logic

---

## 3. Architecture Analysis

### 3.1 Overall Structure

```
┌─────────────────────────────────────────────────────────┐
│                         main.go                         │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐   │
│  │   HotKey    │  │   resize()  │  │ savedStates  │   │
│  │ Registration│  │   Logic     │  │    (map)     │   │
│  └──────┬──────┘  └──────┬──────┘  └──────────────┘   │
└─────────┼────────────────┼────────────────────────────┘
          │                │
          ▼                ▼
┌─────────────────┐  ┌─────────────────────────────────┐
│   hotkey.go     │  │          snap.go                 │
│ - HotKey struct │  │ - toLeft/Right/Top/Bottom       │
│ - msgLoop()     │  │ - *Half, *Third functions       │
│ - RegisterHotKey│  │ - center, makeLarger/Smaller    │
└─────────────────┘  └─────────────────────────────────┘
          │                            │
          ▼                            ▼
┌─────────────────┐  ┌─────────────────────────────────┐
│   multimon.go   │  │      systemwindow.go             │
│ - getMonitorList│  │ - isZonableWindow()             │
│ - multiDisplay  │  │ - isStandardWindow()            │
│   Snap()        │  │ - hasNoVisibleOwner()           │
└─────────────────┘  └─────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│                    w32ex/functions.go                   │
│  - RegisterHotKey, GetDpiForWindow, IsZoomed           │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Data Flow

```
User key input
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│ Win32 RegisterHotKey() (w32ex)                          │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ GetMessage() message loop (hotkey.go:msgLoop)           │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼ WM_HOTKEY
┌─────────────────────────────────────────────────────────┐
│ Look up callback in hotkeyRegistrations map             │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ Execute callback (simpleResize/multiDisplayResize)      │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ GetForegroundWindow() → hwnd                            │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ isZonableWindow() filtering (systemwindow.go)           │
└──────────────────────┬──────────────────────────────────┘
                       │ window is valid
                       ▼
┌─────────────────────────────────────────────────────────┐
│ resize() / resizeWithMultiDisplay() (main.go)           │
│  - MonitorFromWindow() → current monitor               │
│  - GetMonitorInfo() → working area                     │
│  - DwmGetWindowAttributeEXTENDED_FRAME_BOUNDS()         │
│  - GetDpiForWindow() → DPI correction                  │
│  - resizeForDpi() → DPI conversion                     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ Execute resizeFunc (functions in snap.go)               │
│  - leftHalf, rightHalf, topHalf, bottomHalf            │
│  - topLeftHalf, topRightHalf, etc.                     │
│  - center, makeLarger, makeSmaller                     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ Invisible border correction (lExtra, rExtra, tExtra, bExtra) │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ ShowWindow(SW_SHOWNORMAL) + SetWindowPos()             │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
                  Window resize complete
```

### 3.3 Key Design Patterns

#### 3.3.1 Function Type Usage (Strategy Pattern)
```go
type resizeFunc func(disp, cur w32.RECT) w32.RECT
```
- Expresses various resize strategies as functions
- Wrapped with `simpleResize`, `multiDisplayResize` helpers

#### 3.3.2 Hotkey Registration Pattern
```go
type HotKey struct {
    id, mod, vk int
    callback    func()
}
```
- Bundles hotkey ID, modifier key, virtual key code, and callback function
- Registered hotkeys managed via a map

#### 3.3.3 Multi-Monitor Pattern
```go
type SnapPosition int
type MoveDirection int

type snapPositionInfo struct {
    snapFunc      resizeFunc
    moveDirection MoveDirection
    edgeAligned   SnapPosition
}
```
- Defines move direction and edge alignment position per snap position
- Implements inter-monitor movement logic on repeated input

### 3.4 Strengths

1. **Clear separation of concerns**: Each file performs an independent role
2. **Pure function usage**: Calculation functions in `snap.go` are side-effect free
3. **DPI handling**: Accurately handles Windows 10/11 invisible borders and DPI
4. **Multi-monitor support**: Inter-monitor window movement implemented
5. **Robust error handling**: `panic` removed, graceful error handling
6. **User-friendly**: Shortcut dialog provided

### 3.5 Areas for Improvement

#### 3.5.1 Single Package Structure
- All files are in `package main`
- Structure that makes unit testing impossible

#### 3.5.2 Global State
```go
var savedStates = make(map[w32.HWND]w32.RECT)
var hotkeyRegistrations = make(map[int]*HotKey)
```
- Global map usage makes testing difficult

#### 3.5.3 Hardcoded Settings
- Shortcuts are hardcoded in code
- Snap ratios (75%, 3%, etc.) are fixed in code

---

## 4. Code Quality Analysis

### 4.1 Positive Improvements (Recent Changes)

#### ✅ Improved Error Handling
- All `panic()` calls flagged in previous reports have been removed
- Implemented graceful error handling with `fmt.Printf` and `return`

```go
// Before: panic("foreground window is NULL")
// Now:
if hwnd == 0 {
    fmt.Println("warn: foreground window is NULL")
    return
}
```

#### ✅ Signal Channel Buffer Added
```go
exitCh := make(chan os.Signal, 1)  // Buffer size 1
```

#### ✅ Latest Go Version Usage
- Using Go 1.25 (latest features available)

#### ✅ Structural Improvements
- Added maximized/snapped state differentiation logic to `restore()` function
- Stores pre-snap state via `savedStates`
- `multiDisplaySnap()` consolidates inter-monitor movement management

### 4.2 Current Issues

#### 4.2.1 Medium Severity

##### [M-1] Shortcut ID Management
```go
// main.go:92-122
hks := []HotKey{
    {id: 1, ...},  // Hardcoded IDs
    {id: 2, ...},
    // ...
    {id: 41, ...},
}
```
- Hardcoded IDs create potential for conflicts
- Consider using constants or auto-assignment

##### [M-2] Using reflect for RECT comparison
```go
// main.go:373-375
func sameRect(a, b *w32.RECT) bool {
    return a != nil && b != nil && reflect.DeepEqual(*a, *b)
}
```
- Since `w32.RECT` is a simple struct, direct field comparison would be more efficient

##### [M-3] No Test Code
- No `*_test.go` files exist at all
- Pure functions in `snap.go` are very easy to test

##### [M-4] Deprecated DPI API
```go
// w32ex/functions.go:65-68
func SetProcessDPIAware() bool {
    r1, _, _ := user32.NewProc("SetProcessDPIAware").Call()
    return r1 != 0
}
```
- Windows 10+ recommends `SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)`

#### 4.2.2 Low Severity

##### [L-1] Inconsistent Log Messages
```go
"fmt.Printf("> window: 0x%x %#v ...\n", hwnd, rect, ...)
"fmt.Printf("warn: foreground window is NULL\n")
```
- Uses `fmt.Printf` without structured logging

##### [L-2] Unused Function
- `w32ex.GetWindowModuleFileName`: not called anywhere

##### [L-3] Shortcut Mismatch
- Shortcuts described in README.md differ from actual code
  - README: `Win + Alt + Arrow Keys`
  - Code: `Ctrl + Alt + Arrow Keys`

---

## 5. Refactoring Proposals

### 5.1 High Priority

#### 5.1.1 Package Structure Reorganization
```
rectanglewin/
├── cmd/
│   └── rectanglewin/
│       └── main.go              # Entry point only
├── internal/
│   ├── snap/
│   │   ├── snap.go              # Snap calculations
│   │   └── snap_test.go         # Unit tests
│   ├── hotkey/
│   │   ├── hotkey.go            # Hotkey management
│   │   └── keymap.go            # Key mapping
│   ├── window/
│   │   ├── resize.go            # Resize logic
│   │   ├── filter.go            # Window filtering
│   │   └── state.go             # State save/restore
│   ├── monitor/
│   │   ├── monitor.go           # Monitor info
│   │   └── multimon.go          # Multi-monitor
│   ├── tray/
│   │   └── tray.go              # System tray
│   ├── autorun/
│   │   └── autorun.go           # Startup program
│   └── platform/
│       └── w32ex/               # Win32 wrapper
├── assets/
├── go.mod
└── README.md
```

#### 5.1.2 Add Tests
Start with functions in `snap.go`:

```go
// internal/snap/snap_test.go
package snap

import "testing"

func TestLeftHalf(t *testing.T) {
    display := w32.RECT{Left: 0, Top: 0, Right: 1920, Bottom: 1080}
    got := LeftHalf(display, w32.RECT{})
    want := w32.RECT{Left: 0, Top: 0, Right: 960, Bottom: 1080}
    if got != want {
        t.Errorf("LeftHalf() = %v, want %v", got, want)
    }
}
```

#### 5.1.3 RECT Comparison Optimization
```go
// Before
func sameRect(a, b *w32.RECT) bool {
    return a != nil && b != nil && reflect.DeepEqual(*a, *b)
}

// After
func sameRect(a, b *w32.RECT) bool {
    if a == nil || b == nil {
        return false
    }
    return a.Left == b.Left && a.Top == b.Top &&
           a.Right == b.Right && a.Bottom == b.Bottom
}
```

### 5.2 Medium Priority

#### 5.2.1 Auto-assign Hotkey IDs
```go
var nextHotKeyID = 1

func RegisterHotKeyWithAutoID(mod, vk int, callback func()) (int, error) {
    id := nextHotKeyID
    nextHotKeyID++
    // Registration logic...
    return id, nil
}
```

#### 5.2.2 Structured Logging
```go
import "log/slog"

logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
logger.Info("hotkey triggered", "name", name, "hwnd", hwnd)
logger.Warn("foreground window is NULL")
```

#### 5.2.3 Use Modern DPI API
```go
func SetProcessDpiAwarenessContext() bool {
    const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4
    r1, _, _ := user32.NewProc("SetProcessDpiAwarenessContext").Call(
        uintptr(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2))
    return r1 != 0
}
```

### 5.3 Low Priority

#### 5.3.1 Remove Unused Code
- Delete `w32ex.GetWindowModuleFileName`

#### 5.3.2 Update README
- Fix to match actual shortcuts (`Ctrl + Alt`)

#### 5.3.3 Consistent Error Messages
- Unify "warn:" prefix
- Define error types

---

## 6. New Feature Proposals

### 6.1 High Priority

#### 6.1.1 Customizable Shortcuts
- **Config file**: `~/.rectanglewin/config.json`
- **Tray menu**: Add "Edit Shortcuts..." menu item
- **Conflict detection**: Notify user on registration failure

```json
{
  "hotkeys": {
    "leftHalf": { "mod": "MOD_CONTROL|MOD_ALT", "key": "VK_LEFT" },
    "rightHalf": { "mod": "MOD_CONTROL|MOD_ALT", "key": "VK_RIGHT" },
    "center": { "mod": "MOD_CONTROL|MOD_ALT", "key": "0x43" }
  }
}
```

#### 6.1.2 Undo/Redo Feature
- **Shortcut**: `Ctrl + Alt + Z`
- **Implementation**: Expand `savedStates` into a stack
- **Depth**: Store last 10 states

```go
type WindowHistory struct {
    hwnd    w32.HWND
    history []w32.RECT
    current int
}

var windowHistories = make(map[w32.HWND]*WindowHistory)
```

#### 6.1.3 Settings GUI
- **Simple dialog**: Display current shortcut list
- **Editing**: Click to record new shortcuts
- **Apply**: Immediate or after restart

### 6.2 Medium Priority

#### 6.2.1 Visual Feedback
- Display target area overlay during snap action
- Show semi-transparent rectangle for 0.5 seconds then fade

#### 6.2.2 Custom Snap Ratios
```json
{
  "snapRatios": [
    {"name": "Half", "value": 0.5},
    {"name": "Golden Ratio", "value": 0.618},
    {"name": "Two Thirds", "value": 0.667},
    {"name": "Third", "value": 0.333}
  ],
  "defaultRatio": 0.5
}
```

#### 6.2.3 Window Size Presets
```json
{
  "presets": [
    {"name": "HD 720p", "width": 1280, "height": 720},
    {"name": "FHD 1080p", "width": 1920, "height": 1080},
    {"name": "Mobile", "width": 375, "height": 812}
  ]
}
```

### 6.3 Low Priority

#### 6.3.1 Action Log
- Display last N snap actions
- Tray menu "Recent Actions"

#### 6.3.2 Auto Update Check
- Check GitHub Releases API
- Tray menu "Check for Updates"

#### 6.3.3 Window Group Layouts
```json
{
  "layouts": {
    "Coding": [
      {"app": "code.exe", "snap": "leftTwoThirds"},
      {"app": "WindowsTerminal.exe", "snap": "lastThird"}
    ]
  }
}
```

---

## 7. Overall Evaluation

### 7.1 Scorecard

| Category | Score | Notes |
|----------|:-----:|-------|
| Feature Completeness | 4.0/5 | Core features solid, multi-monitor support complete |
| Code Quality | 3.5/5 | Panics removed, consistent style, no tests |
| Architecture | 3.0/5 | Good separation of concerns, single package structure |
| Maintainability | 3.0/5 | Clear naming, global state, hardcoded values |
| User Experience | 4.0/5 | Intuitive shortcuts, dialog provided |
| CI/CD | 4.0/5 | GitHub Actions + GoReleaser, gofmt check |
| Documentation | 3.5/5 | README and CLAUDE.md exist, shortcut mismatch |
| **Overall** | **3.5/5** | **Healthy state, room for improvement** |

### 7.2 Strengths

1. ✅ **Stability**: Panics removed, graceful error handling
2. ✅ **Multi-monitor**: Inter-monitor window movement implemented
3. ✅ **Restore Feature**: Pre-snap state saved and restorable
4. ✅ **User Feedback**: Shortcut dialog provided
5. ✅ **DPI Handling**: Invisible border and DPI correction
6. ✅ **Modern Go**: Using Go 1.25

### 7.3 Improvement Priorities

| Rank | Item | Est. Effort | Impact |
|:----:|------|:-----------:|:------:|
| 1 | Add tests | Medium | High |
| 2 | Fix README shortcuts | Low | Medium |
| 3 | RECT comparison optimization | Low | Low |
| 4 | Structured logging | Medium | Medium |
| 5 | Customizable shortcuts | High | High |
| 6 | Package structure reorganization | High | Medium |

---

## 8. Conclusion

RectangleWin is a **healthy project** that faithfully implements core functionality as a **Windows reimplementation of macOS Rectangle.app**. Recent improvements have removed `panic` calls and completed multi-monitor support, significantly improving stability.

**Key Strengths:**
- Intuitive hotkey-based window management
- Multi-monitor environment support
- DPI awareness and invisible border handling
- Pre-snap state save and restore

**Primary Improvement Directions:**
1. **Add test code** for stability assurance
2. **Customizable shortcuts** for improved user experience
3. **Configuration file** for flexibility
4. **Documentation updates** to prevent user confusion

Overall, this is a **well-maintained project**, and applying the proposed improvements incrementally will further raise its quality as a Windows window management utility.

---

*Report written: 2026-02-09*
*Analysis target: commit 6486692*