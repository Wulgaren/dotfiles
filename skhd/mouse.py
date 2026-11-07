#!/usr/bin/python3
"""Moves or clicks the pointer for skhd's mouse mode.

Usage:
    mouse.py move <dx> <dy>
    mouse.py click [left|right]
"""
import ctypes
import ctypes.util
import sys

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
cg.CGWarpMouseCursorPosition.restype = ctypes.c_int32
cg.CGWarpMouseCursorPosition.argtypes = [CGPoint]
cg.CFRelease.argtypes = [ctypes.c_void_p]

MOUSE_DOWN = {"left": 1, "right": 3}
MOUSE_UP = {"left": 2, "right": 4}
BUTTON = {"left": 0, "right": 1}


def location() -> CGPoint:
    event = cg.CGEventCreate(None)
    point = cg.CGEventGetLocation(event)
    cg.CFRelease(event)
    return point


def move(dx: float, dy: float) -> None:
    point = location()
    cg.CGWarpMouseCursorPosition(CGPoint(point.x + dx, point.y + dy))


def click(button: str) -> None:
    point = location()
    down = cg.CGEventCreateMouseEvent(
        None, MOUSE_DOWN[button], point, BUTTON[button]
    )
    up = cg.CGEventCreateMouseEvent(None, MOUSE_UP[button], point, BUTTON[button])
    cg.CGEventPost(0, down)
    cg.CGEventPost(0, up)
    cg.CFRelease(down)
    cg.CFRelease(up)


def main() -> None:
    if len(sys.argv) >= 4 and sys.argv[1] == "move":
        move(float(sys.argv[2]), float(sys.argv[3]))
    elif len(sys.argv) == 2 and sys.argv[1] == "click":
        click("left")
    elif len(sys.argv) == 3 and sys.argv[1] == "click" and sys.argv[2] in BUTTON:
        click(sys.argv[2])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
