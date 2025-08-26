//
//  DynamicIslandWindow.swift
//  EasyNotch
//
//  Created by Nikolay Fedorov on 26.08.2025.
//

import AppKit
import SwiftUI

final class DynamicIslandWindow: NSWindow {
    private var globalMonitor: Any?
    private var isVisibleForHover = false
    private var isExpanded = false
    
    // Окно для расширенного вида
    private var expandedWindow: NSWindow?
    
    init() {
        // Размер островка — подкорректируй под вкус
        let width: CGFloat = 220
        let height: CGFloat = 56

        let screen = NSScreen.main ?? NSScreen.screens.first!
        // Позиционируем по центру верхней грани экрана
        let x = screen.frame.midX - width / 2
        let y = screen.frame.maxY - height - 8

        let rect = NSRect(x: x, y: y, width: width, height: height)

        super.init(contentRect: rect,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)

        // window common config
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar            // поверх большинства окон
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        ignoresMouseEvents = true     // по умолчанию — не мешаем кликам
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false

        // Контент — SwiftUI view (используем уже существующий IslandView)
        let host = NSHostingView(rootView: IslandView())
        host.frame = contentRect(forFrameRect: rect)
        host.autoresizingMask = [.width, .height]
        contentView = host

        // по умолчанию скрыто
        alphaValue = 0
        orderOut(nil)

        // слушаем уведомления из IslandView про enter/exit hover
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(toggleInteraction(_:)),
                                               name: .init("IslandSetInteractive"),
                                               object: nil)
        
        // Создаем расширенное окно
        createExpandedWindow()
    }
    
    deinit {
        stopHoverMonitoring()
        NotificationCenter.default.removeObserver(self)
        expandedWindow?.close()
    }
    
    private func createExpandedWindow() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let width: CGFloat = 280
        let height: CGFloat = 400
        
        // Позиционируем по центру экрана
        let x = screen.frame.midX - width / 2
        let y = screen.frame.midY - height / 2
        
        let rect = NSRect(x: x, y: y, width: width, height: height)
        
        expandedWindow = NSWindow(
            contentRect: rect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        guard let expandedWindow = expandedWindow else { return }
        
        expandedWindow.isOpaque = false
        expandedWindow.backgroundColor = .clear
        expandedWindow.level = .statusBar
        expandedWindow.hasShadow = true
        expandedWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        expandedWindow.ignoresMouseEvents = false
        expandedWindow.titleVisibility = .hidden
        expandedWindow.titlebarAppearsTransparent = true
        expandedWindow.isMovableByWindowBackground = false
        
        let expandedHost = NSHostingView(rootView: ExpandedIslandView())
        expandedHost.frame = contentRect(forFrameRect: rect)
        expandedHost.autoresizingMask = [.width, .height]
        expandedWindow.contentView = expandedHost
        
        expandedWindow.alphaValue = 0
        expandedWindow.orderOut(nil)
    }

    // Запустить глобальный монитор мыши (включить появление островка)
    func startHoverMonitoring() {
        guard globalMonitor == nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            guard let self = self, let screen = NSScreen.main else { return }
            let mouse = NSEvent.mouseLocation // координаты в экранной системе (bottom-left origin)
            // чувствительная зона: N px от верха и N px от центра по X
            let thresholdY: CGFloat = 36
            let centerX = screen.frame.midX
            let maxXDelta = (self.frame.width / 2) + 30

            let nearTop = mouse.y >= (screen.frame.maxY - thresholdY)
            let nearCenter = abs(mouse.x - centerX) <= maxXDelta

            if nearTop && nearCenter {
                self.showIsland()
            } else {
                self.hideIsland()
            }
        }
    }

    func stopHoverMonitoring() {
        if let m = globalMonitor {
            NSEvent.removeMonitor(m)
            globalMonitor = nil
        }
    }

    private func showIsland() {
        DispatchQueue.main.async {
            guard !self.isVisibleForHover else { return }
            self.isVisibleForHover = true

            // позволяем нажимать на островок
            self.ignoresMouseEvents = false
            self.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                self.animator().alphaValue = 1
            }
        }
    }

    private func hideIsland() {
        DispatchQueue.main.async {
            guard self.isVisibleForHover else { return }
            self.isVisibleForHover = false

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.18
                self.animator().alphaValue = 0
            }, completionHandler: {
                self.orderOut(nil)
                // при скрытии снова пропускаем клики через окно
                self.ignoresMouseEvents = true
            })
            
            // Скрываем расширенное окно
            self.hideExpandedWindow()
        }
    }
    
    private func showExpandedWindow() {
        guard let expandedWindow = expandedWindow, !isExpanded else { return }
        
        isExpanded = true
        expandedWindow.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            expandedWindow.animator().alphaValue = 1
        }
    }
    
    private func hideExpandedWindow() {
        guard let expandedWindow = expandedWindow, isExpanded else { return }
        
        isExpanded = false
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            expandedWindow.animator().alphaValue = 0
        }, completionHandler: {
            expandedWindow.orderOut(nil)
        })
    }

    // Получаем уведомление от IslandView о том, что курсор внутри самой капсулы (expanded)
    @objc private func toggleInteraction(_ n: Notification) {
        if let interactive = n.object as? Bool {
            // interactive == true => внутри островка — не игнорируем клики
            ignoresMouseEvents = !interactive
            
            // Показываем/скрываем расширенное окно
            if interactive {
                showExpandedWindow()
            } else {
                hideExpandedWindow()
            }
        }
    }
}
