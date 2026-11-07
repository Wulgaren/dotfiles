#!/usr/bin/python3
"""Moves or clicks the pointer for skhd's mouse mode.

Usage:
    mouse.py move <dx> <dy>
    mouse.py click [left|right]
    mouse.py scroll <lines>
"""
import ctypes
import ctypes.util
import sys
import tempfile
import time
from pathlib import Path

cg = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreGraphics"))


class CGPoint(ctypes.Structure):
    _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double)]


cg.CGEventCreate.restype = ctypes.c_void_p
cg.CGEventCreate.argtypes = [ctypes.c_void_p]
cg.CGEventGetLocation.restype = CGPoint
cg.CGEventGetLocation.argtypes = [ctypes.c_void_p]
cg.CGEventCreateMouseEvent.restype = ctypes.c_void_p
cg.CGEventCreateMouseEvent.argtypes = [
    ctypes.c_void_p,
    ctypes.c_uint32,
    CGPoint,
    ctypes.c_uint32,
]
cg.CGEventPost.argtypes = [ctypes.c_uint32, ctypes.c_void_p]
cg.CGEventCreateScrollWheelEvent.restype = ctypes.c_void_p
cg.CGEventCreateScrollWheelEvent.argtypes = [
    ctypes.c_void_p,
    ctypes.c_uint32,
    ctypes.c_uint32,
    ctypes.c_int32,
]
cg.CGWarpMouseCursorPosition.restype = ctypes.c_int32
cg.CGWarpMouseCursorPosition.argtypes = [CGPoint]
cg.CFRelease.argtypes = [ctypes.c_void_p]
cg.CGEventSetIntegerValueField.argtypes = [
    ctypes.c_void_p,
    ctypes.c_uint32,
    ctypes.c_int64,
]

MOUSE_DOWN = {"left": 1, "right": 3}
MOUSE_UP = {"left": 2, "right": 4}
BUTTON = {"left": 0, "right": 1}
SCROLL_LINE = 0
CLICK_STATE = 1  # kCGMouseEventClickState

# Each keypress runs a fresh process, so the previous click is remembered on disk
# to continue a double/triple click across invocations.
CLICK_STATE_FILE = Path(tempfile.gettempdir()) / "skhd-mouse-click-state"
DOUBLE_CLICK_DISTANCE = 4.0
DOUBLE_CLICK_INTERVAL = 0.5  # macOS default double-click speed


def location() -> CGPoint:
    event = cg.CGEventCreate(None)
    point = cg.CGEventGetLocation(event)
    cg.CFRelease(event)
    return point


def move(dx: float, dy: float) -> None:
    point = location()
    cg.CGWarpMouseCursorPosition(CGPoint(point.x + dx, point.y + dy))
    clear_click_state()


def scroll(lines: int) -> None:
    event = cg.CGEventCreateScrollWheelEvent(None, SCROLL_LINE, 1, lines)
    cg.CGEventPost(0, event)
    cg.CFRelease(event)


def clear_click_state() -> None:
    CLICK_STATE_FILE.unlink(missing_ok=True)


def read_click_state():
    """(time, x, y, button, count) of the previous click, or None."""
    try:
        ts, x, y, button, count = CLICK_STATE_FILE.read_text().split()
        return float(ts), float(x), float(y), button, int(count)
    except (OSError, ValueError):
        return None


def next_click_count(button: str, point: CGPoint) -> int:
    """Continue the previous click when it was the same button, place and time, else start at 1."""
    now = time.time()
    count = 1
    previous = read_click_state()
    if previous is not None:
        ts, x, y, previous_button, previous_count = previous
        same_button = previous_button == button
        same_place = (
            abs(point.x - x) <= DOUBLE_CLICK_DISTANCE
            and abs(point.y - y) <= DOUBLE_CLICK_DISTANCE
        )
        if same_button and same_place and now - ts <= DOUBLE_CLICK_INTERVAL:
            count = previous_count + 1
    CLICK_STATE_FILE.write_text(f"{now} {point.x} {point.y} {button} {count}")
    return count


def post_mouse_event(
    event_type: int, point: CGPoint, button: int, click_count: int
) -> None:
    event = cg.CGEventCreateMouseEvent(None, event_type, point, button)
    cg.CGEventSetIntegerValueField(event, CLICK_STATE, click_count)
    cg.CGEventPost(0, event)
    cg.CFRelease(event)


def click(button: str) -> None:
    point = location()
    count = next_click_count(button, point)
    post_mouse_event(MOUSE_DOWN[button], point, BUTTON[button], count)
    post_mouse_event(MOUSE_UP[button], point, BUTTON[button], count)


def main() -> None:
    if len(sys.argv) >= 4 and sys.argv[1] == "move":
        move(float(sys.argv[2]), float(sys.argv[3]))
    elif len(sys.argv) == 3 and sys.argv[1] == "scroll":
        scroll(int(sys.argv[2]))
    elif len(sys.argv) == 2 and sys.argv[1] == "click":
        click("left")
    elif len(sys.argv) == 3 and sys.argv[1] == "click" and sys.argv[2] in BUTTON:
        click(sys.argv[2])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
