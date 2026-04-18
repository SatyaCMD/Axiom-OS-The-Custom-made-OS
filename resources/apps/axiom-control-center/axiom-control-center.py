#!/usr/bin/env python3
import sys
import subprocess
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
                             QLabel, QPushButton, QFrame, QGridLayout, QTabWidget, QCheckBox, QMessageBox)
from PyQt6.QtCore import Qt

class AxiomControlCenter(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Axiom Control Center")
        self.setMinimumSize(800, 600)
        self.setStyleSheet("""
            QMainWindow { background-color: #2f343f; color: #ffffff; }
            QLabel { color: #ffffff; }
            QCheckBox { color: #ffffff; spacing: 10px; }
            QPushButton {
                background-color: #3daee9; color: white; border: none;
                padding: 8px 16px; border-radius: 4px; font-weight: bold;
            }
            QPushButton:hover { background-color: #4dbef9; }
            QTabWidget::pane { border: 1px solid #3b4252; background: #2f343f; }
            QTabBar::tab {
                background: #232830; color: #aeb7c4; padding: 10px 20px;
                border-top-left-radius: 4px; border-top-right-radius: 4px;
            }
            QTabBar::tab:selected { background: #3b4252; color: white; }
        """)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)

        # Header
        header = QLabel("Axiom Control Center")
        header.setStyleSheet("font-size: 24px; font-weight: bold; margin-bottom: 20px;")
        layout.addWidget(header)

        # Tabs
        tabs = QTabWidget()
        tabs.addTab(self.create_performance_tab(), "Performance")
        tabs.addTab(self.create_security_tab(), "Security")
        tabs.addTab(self.create_maintenance_tab(), "Maintenance")
        layout.addWidget(tabs)

    def create_performance_tab(self):
        tab = QWidget()
        layout = QVBoxLayout(tab)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(20)

        layout.addWidget(QLabel("Power Profiles"))
        
        btn_layout = QHBoxLayout()
        btn_perf = QPushButton("Performance Mode")
        btn_bal = QPushButton("Balanced Mode")
        btn_save = QPushButton("Power Saver")
        
        btn_perf.clicked.connect(lambda: self.run_cmd("powerprofilesctl set performance"))
        btn_bal.clicked.connect(lambda: self.run_cmd("powerprofilesctl set balanced"))
        btn_save.clicked.connect(lambda: self.run_cmd("powerprofilesctl set power-saver"))

        btn_layout.addWidget(btn_perf)
        btn_layout.addWidget(btn_bal)
        btn_layout.addWidget(btn_save)
        layout.addLayout(btn_layout)

        layout.addStretch()
        return tab

    def create_security_tab(self):
        tab = QWidget()
        layout = QVBoxLayout(tab)
        layout.setContentsMargins(20, 20, 20, 20)
        
        self.ufw_check = QCheckBox("Enable Firewall (UFW)")
        self.ufw_check.clicked.connect(self.toggle_firewall)
        layout.addWidget(self.ufw_check)
        
        layout.addStretch()
        return tab

    def create_maintenance_tab(self):
        tab = QWidget()
        layout = QVBoxLayout(tab)
        layout.setContentsMargins(20, 20, 20, 20)
        
        btn_clean = QPushButton("Clean System Cache (apt clean)")
        btn_clean.clicked.connect(lambda: self.run_cmd("pkexec apt-get clean"))
        layout.addWidget(btn_clean)
        
        btn_autoremove = QPushButton("Remove Unused Packages (autoremove)")
        btn_autoremove.clicked.connect(lambda: self.run_cmd("pkexec apt-get autoremove -y"))
        layout.addWidget(btn_autoremove)

        layout.addStretch()
        return tab

    def toggle_firewall(self):
        if self.ufw_check.isChecked():
            self.run_cmd("pkexec ufw enable")
        else:
            self.run_cmd("pkexec ufw disable")

    def run_cmd(self, command):
        try:
            subprocess.Popen(command.split())
            QMessageBox.information(self, "Success", f"Command executed: {command}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to execute: {e}")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = AxiomControlCenter()
    window.show()
    sys.exit(app.exec())
