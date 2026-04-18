#!/usr/bin/env python3
import sys
import platform
import psutil
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
                             QLabel, QPushButton, QFrame, QGridLayout, QScrollArea)
from PyQt6.QtCore import Qt, QSize
from PyQt6.QtGui import QIcon, QFont, QPixmap

class AxiomWelcome(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Welcome to AxiomOS")
        self.setMinimumSize(900, 600)
        self.setStyleSheet("""
            QMainWindow {
                background-color: #2f343f;
                color: #ffffff;
            }
            QLabel {
                color: #ffffff;
            }
            QPushButton {
                background-color: #3daee9;
                color: white;
                border: none;
                padding: 10px 20px;
                border-radius: 5px;
                font-weight: bold;
                font-size: 14px;
            }
            QPushButton:hover {
                background-color: #4dbef9;
            }
            QFrame#Card {
                background-color: #3b4252;
                border-radius: 10px;
                padding: 15px;
            }
        """)

        # Main Layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QHBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Sidebar
        sidebar = QFrame()
        sidebar.setStyleSheet("background-color: #232830; min-width: 200px;")
        sidebar_layout = QVBoxLayout(sidebar)
        sidebar_layout.setContentsMargins(20, 40, 20, 20)
        sidebar_layout.setSpacing(15)

        # Logo Placeholder
        logo_label = QLabel("AxiomOS")
        logo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        logo_label.setStyleSheet("font-size: 24px; font-weight: bold; color: #3daee9; margin-bottom: 20px;")
        sidebar_layout.addWidget(logo_label)

        # Sidebar Buttons
        self.btn_home = self.create_sidebar_btn("Home")
        self.btn_apps = self.create_sidebar_btn("Apps")
        self.btn_dev = self.create_sidebar_btn("Developer")
        self.btn_community = self.create_sidebar_btn("Community")
        
        sidebar_layout.addWidget(self.btn_home)
        sidebar_layout.addWidget(self.btn_apps)
        sidebar_layout.addWidget(self.btn_dev)
        sidebar_layout.addWidget(self.btn_community)
        sidebar_layout.addStretch()

        main_layout.addWidget(sidebar)

        # Content Area
        content_area = QScrollArea()
        content_area.setWidgetResizable(True)
        content_area.setStyleSheet("QScrollArea { border: none; background-color: #2f343f; }")
        
        self.content_widget = QWidget()
        self.content_layout = QVBoxLayout(self.content_widget)
        self.content_layout.setContentsMargins(40, 40, 40, 40)
        self.content_layout.setSpacing(30)

        # Header
        header = QLabel("Welcome to AxiomOS")
        header.setStyleSheet("font-size: 32px; font-weight: bold;")
        self.content_layout.addWidget(header)

        sub_header = QLabel("Minimal. Performance-Focused. Developer-First.")
        sub_header.setStyleSheet("font-size: 18px; color: #aeb7c4;")
        self.content_layout.addWidget(sub_header)

        # System Info Card
        info_card = self.create_card("System Status")
        info_layout = QGridLayout(info_card)
        
        info_layout.addWidget(QLabel("OS Version:"), 0, 0)
        info_layout.addWidget(QLabel("AxiomOS 1.0"), 0, 1)
        
        info_layout.addWidget(QLabel("Kernel:"), 1, 0)
        info_layout.addWidget(QLabel(platform.release()), 1, 1)
        
        cpu_usage = f"{psutil.cpu_percent()}%"
        info_layout.addWidget(QLabel("CPU Usage:"), 2, 0)
        info_layout.addWidget(QLabel(cpu_usage), 2, 1)
        
        ram = psutil.virtual_memory()
        ram_usage = f"{ram.percent}% ({ram.used // (1024**2)}MB / {ram.total // (1024**2)}MB)"
        info_layout.addWidget(QLabel("Memory:"), 3, 0)
        info_layout.addWidget(QLabel(ram_usage), 3, 1)

        self.content_layout.addWidget(info_card)

        # Quick Actions
        actions_label = QLabel("Quick Actions")
        actions_label.setStyleSheet("font-size: 20px; font-weight: bold; margin-top: 20px;")
        self.content_layout.addWidget(actions_label)

        actions_layout = QHBoxLayout()
        actions_layout.setSpacing(20)
        
        btn_update = QPushButton("Update System")
        btn_update.clicked.connect(lambda: self.run_cmd("pkexec apt-get update && pkexec apt-get upgrade -y"))
        
        btn_dev = QPushButton("Install Dev Profile")
        btn_dev.clicked.connect(lambda: self.run_cmd("pkexec axiom-install-dev"))
        
        btn_creator = QPushButton("Install Creator Profile")
        btn_creator.clicked.connect(lambda: self.run_cmd("pkexec axiom-install-creator"))
        
        btn_store = QPushButton("Software Center")
        btn_store.clicked.connect(lambda: self.run_cmd("plasma-discover"))

        btn_settings = QPushButton("Axiom Settings")
        btn_settings.clicked.connect(lambda: self.run_cmd("axiom-control-center"))
        
        actions_layout.addWidget(btn_update)
        actions_layout.addWidget(btn_dev)
        actions_layout.addWidget(btn_creator)
        actions_layout.addWidget(btn_store)
        actions_layout.addWidget(btn_settings)
        actions_layout.addStretch()
        
        self.content_layout.addLayout(actions_layout)

        self.content_layout.addStretch()
        content_area.setWidget(self.content_widget)
        main_layout.addWidget(content_area)

    def run_cmd(self, command):
        import subprocess
        try:
            subprocess.Popen(command.split())
        except Exception as e:
            print(f"Error executing {command}: {e}")

    def create_sidebar_btn(self, text):
        btn = QPushButton(text)
        btn.setStyleSheet("""
            QPushButton {
                background-color: transparent;
                text-align: left;
                padding: 10px;
                font-size: 16px;
                color: #aeb7c4;
            }
            QPushButton:hover {
                background-color: #3b4252;
                color: white;
                border-radius: 5px;
            }
        """)
        return btn

    def create_card(self, title):
        card = QFrame()
        card.setObjectName("Card")
        layout = QVBoxLayout(card)
        
        title_label = QLabel(title)
        title_label.setStyleSheet("font-size: 18px; font-weight: bold; margin-bottom: 10px; color: #3daee9;")
        layout.addWidget(title_label)
        
        return card

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = AxiomWelcome()
    window.show()
    sys.exit(app.exec())
