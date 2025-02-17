//
//  TouchableMTKView.swift
//  ShaderView
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

import MetalKit
import TransformUtils

#if os(macOS)
public class TouchableMTKView: MTKView {
    let renderer: RendererBase

    init(renderer: RendererBase) {
        self.renderer = renderer
        super.init(frame: .zero, device: Library.device)
        initializeView()
        configure()
    }

    func initializeView() {
        self.frame = .zero
        self.delegate = renderer
        self.enableSetNeedsDisplay = false
        self.isPaused = false
        self.colorPixelFormat = .bgra8Unorm
        self.framebufferOnly = false
        self.preferredFramesPerSecond = 120
        self.autoResizeDrawable = true
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.sampleCount = 1
        self.layer?.isOpaque = false
    }

    func configure() {
        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .activeAlways,
            .inVisibleRect
        ]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getNormalizedMouseLocation(event: NSEvent) -> f2? {
        guard let window = self.window, let eventWindow = event.window else {
            return nil
        }
        guard let windowContentView = window.contentView else {
            return nil
        }
        let viewOriginInWindow = self.convert(NSPoint.zero, to: eventWindow.contentView)
        let mouseLocationInWindow = event.locationInWindow
        var localMouseLocation = mouseLocationInWindow
        localMouseLocation.x -= viewOriginInWindow.x
        localMouseLocation.y -= windowContentView.frame.maxY - viewOriginInWindow.y
        let normalizedLocation = NSPoint(x: localMouseLocation.x / self.frame.maxX,
                                         y: localMouseLocation.y / self.frame.maxY)
        return normalizedLocation.f2Value
    }

    public override var acceptsFirstResponder: Bool { return true }

    public override func mouseDown(with event: NSEvent) {
        renderer.mousePosition = getNormalizedMouseLocation(event: event)
        renderer.mouseDown()
    }

    public override func mouseMoved(with event: NSEvent) {
        var delta: f2?
        if let prevMousePos = renderer.mousePosition,
           let currentMousePos = getNormalizedMouseLocation(event: event) {
            delta = currentMousePos - prevMousePos
        }
        renderer.mousePosition = getNormalizedMouseLocation(event: event)
        renderer.mouseMoved(delta: delta)
    }

    public override func mouseDragged(with event: NSEvent) {
        let moveRadX = -Float(event.deltaX) * 0.01
        let moveRadY = Float(event.deltaY) * 0.01
        switch renderer.configuration.cameraType {
        case .orbit:
            renderer.camera.orbitCamera(
                lookAt: .zero,
                distanceDelta: 0,
                xDelta: moveRadX,
                yDelta: moveRadY
            )
        case .manual:
            break
        }
        var delta: f2?
        if let prevMousePos = renderer.mousePosition,
           let currentMousePos = getNormalizedMouseLocation(event: event) {
            delta = currentMousePos - prevMousePos
        }
        renderer.mousePosition = getNormalizedMouseLocation(event: event)
        renderer.mouseDragged(delta: delta)
    }

    public override func mouseUp(with event: NSEvent) {
        renderer.mousePosition = nil
        renderer.mouseUp()
    }

    public override func scrollWheel(with event: NSEvent) {
        switch renderer.configuration.cameraType {
        case .orbit:
            renderer.camera.orbitCamera(
                lookAt: .zero,
                distanceDelta: -Float(event.deltaY) * 0.3,
                xDelta: 0,
                yDelta: 0
            )
        case .manual:
            break
        }
        renderer.scrollWheel(delta: f2(Float(event.deltaX), Float(event.deltaY)))
    }

    public override func mouseEntered(with event: NSEvent) {
        renderer.mousePosition = getNormalizedMouseLocation(event: event)
        renderer.mouseEntered()
    }

    public override func mouseExited(with event: NSEvent) {
        renderer.mousePosition = nil
        renderer.mouseExited()
    }

    public override func keyDown(with event: NSEvent) {
        renderer.keyDown(keyCode: event.keyCode)
    }

    public override func keyUp(with event: NSEvent) {
        renderer.keyUp()
    }
}
#else

public class TouchableMTKView: MTKView {
    let renderer: RendererBase

    init(renderer: RendererBase) {
        self.renderer = renderer
        super.init(frame: .zero, device: Library.device)
        initializeView()
        configure()
    }

    func initializeView() {
        self.frame = .zero
        self.delegate = renderer
        self.enableSetNeedsDisplay = false
        self.isPaused = false
        self.colorPixelFormat = .bgra8Unorm
        self.framebufferOnly = false
        self.preferredFramesPerSecond = 120
        self.autoResizeDrawable = true
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.sampleCount = 1
        self.layer.isOpaque = false
    }

    func configure() {
        let scrollGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(onScroll))
        self.addGestureRecognizer(scrollGestureRecognizer)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getTouchLocations(touches: Set<UITouch>) -> [f2] {
        var locations: [f2] = []
        for touch in touches {
            var location = touch.location(in: self)
            location.x /= self.frame.width
            location.y /= self.frame.height
            location.y = 1 - location.y
            locations.append(location.f2Value)
        }
        return locations
    }

    private func getPrevTouchLocations(touches: Set<UITouch>) -> [f2] {
        var locations: [f2] = []
        for touch in touches {
            var location = touch.previousLocation(in: self)
            location.x /= self.frame.width
            location.y /= self.frame.height
            location.y = 1 - location.y
            locations.append(location.f2Value)
        }
        return locations
    }

    @objc func onScroll(recognizer: UIPinchGestureRecognizer) {
        let delta = recognizer.velocity
        switch renderer.configuration.cameraType {
        case .orbit:
            renderer.camera.orbitCamera(
                lookAt: .zero,
                distanceDelta: -Float(delta) * 0.1,
                xDelta: 0,
                yDelta: 0
            )
        case .manual:
            break
        }
        renderer.scrollWheel(delta: f2(Float(delta), Float(delta)))
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        renderer.mousePosition = getTouchLocations(touches: touches).first
        renderer.mouseDown()
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let position = getTouchLocations(touches: touches).first
        let prevPosition = getPrevTouchLocations(touches: touches).first
        let diff = (position ?? .zero) - (prevPosition ?? .zero)
        let moveRadX = -diff.x * 2
        let moveRadY = -diff.y * 2
        switch renderer.configuration.cameraType {
        case .orbit:
            renderer.camera.orbitCamera(
                lookAt: .zero,
                distanceDelta: 0,
                xDelta: moveRadX,
                yDelta: moveRadY
            )
        case .manual:
            break
        }
        renderer.mousePosition = position
        renderer.mouseDragged(delta: diff)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        renderer.mousePosition = nil
        renderer.mouseUp()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        renderer.mousePosition = nil
        renderer.mouseUp()
    }
}
#endif

