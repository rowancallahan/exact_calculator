"""Frontend shim: draws buttons from a layout JSON, shows images from the backend.

usage: python3 frontend/shim.py layout.json .lake/build/bin/backend

Protocol, once per tick (60 Hz):
  shim -> backend   one line: the id of a pressed button, or an empty line
  backend -> shim   one line "<page> <width> <height>", then width * height RGB pixels
"""
import json, subprocess, sys
from PyQt6.QtCore import QTimer
from PyQt6.QtGui import QImage, QPixmap
from PyQt6.QtWidgets import QApplication, QLabel, QPushButton, QWidget

layout = json.load(open(sys.argv[1]))
backend = subprocess.Popen(sys.argv[2:], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
pressed = []  # button ids waiting to be sent

app = QApplication([])
window = QWidget()
window.setFixedSize(*layout["size"])
screen = QLabel(window)
screen.setGeometry(*layout["screen"])

pages = {}
for name, buttons in layout["pages"].items():
    pages[name] = QWidget(window)
    pages[name].setGeometry(0, 0, *layout["size"])
    for b in buttons:
        button = QPushButton(b["label"], pages[name])
        button.setGeometry(*b["rect"])
        button.clicked.connect(lambda _, id=b["id"]: pressed.append(id))
screen.raise_()

def tick():
    backend.stdin.write((pressed.pop(0) if pressed else "").encode() + b"\n")
    backend.stdin.flush()
    page, w, h = backend.stdout.readline().decode().split()
    w, h = int(w), int(h)
    pixels = backend.stdout.read(w * h * 3)
    for name, widget in pages.items():
        widget.setVisible(name == page)
    screen.setPixmap(QPixmap.fromImage(QImage(pixels, w, h, w * 3, QImage.Format.Format_RGB888)))

timer = QTimer()
timer.timeout.connect(tick)
timer.start(1000 // 60)
window.show()
app.exec()
