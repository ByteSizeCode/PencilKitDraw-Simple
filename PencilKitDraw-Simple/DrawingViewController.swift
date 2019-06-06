//
//  DrawingViewController.swift
//  PencilKitDraw-Simple
//
//  Created by Isaac Raval on 6/5/19.
//  Copyright © 2019 Isaac Raval. All rights reserved.
//
//  Based on Apple's WWDC 2019 Sample code. https://developer.apple.com/documentation/pencilkit/drawing_with_pencilkit
//
//

import UIKit
import PencilKit

class DrawingViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver, UIScreenshotServiceDelegate {
    
    // IBOutlets and properties
    @IBOutlet weak var canvasView: PKCanvasView!
    @IBOutlet weak var pencilFingerBarButtonItem: UIBarButtonItem!
    @IBOutlet var undoBarButtonitem: UIBarButtonItem!
    @IBOutlet var redoBarButtonItem: UIBarButtonItem!
    static let canvasOverscrollHeight: CGFloat = 500
    var dataModelController: DataModelController!
    var drawingIndex: Int = 0
    var hasModifiedDrawing = false
    
    // Set up the drawing
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set up the tool picker, using the window of our parent because our view has not
        // been added to a window yet.
        if let window = parent?.view.window, let toolPicker = PKToolPicker.shared(for: window) {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(self)
            canvasView.becomeFirstResponder() //Show drawing tools
        }
        
        parent?.view.window?.windowScene?.screenshotService?.delegate = self
    }
    
    // When the view is resized, adjust the canvas scale so that it is zoomed to the default `canvasWidth`.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let canvasScale = canvasView.bounds.width / DataModel.canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        
        // Scroll to the top
        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }
    
    // When the view is removed, save the modified drawing, if any
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Update the drawing in the data model if it has changed
        if hasModifiedDrawing {
            dataModelController.updateDrawing(canvasView.drawing, at: drawingIndex)
        }
        
        // Remove this view controller as the screenshot delegate
        view.window?.windowScene?.screenshotService?.delegate = nil
    }
    
    // Hide the home indicator, as it will affect latency
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

//Helper Functions
extension DrawingViewController {
    
    // Turn finger drawing on or off
    @IBAction func toggleFingerPencilDrawing(_ sender: Any) {
        canvasView.allowsFingerDrawing.toggle()
        pencilFingerBarButtonItem.title = canvasView.allowsFingerDrawing ? "Finger" : "Pencil"
    }
    
    // Set a new drawing, with an undo action to go back to the old one
    func setNewDrawingUndoable(_ newDrawing: PKDrawing) {
        let oldDrawing = canvasView.drawing
        undoManager?.registerUndo(withTarget: self) {
            $0.setNewDrawingUndoable(oldDrawing)
        }
        canvasView.drawing = newDrawing
    }
    
    // Executes when a drawing has changed
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        hasModifiedDrawing = true
        updateContentSizeForDrawing()
    }
    
    func updateContentSizeForDrawing() {
        // Update the content size to match the drawing.
        let drawing = canvasView.drawing
        let contentHeight: CGFloat
        
        // Adjust the content size to always be bigger than the drawing height.
        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + DrawingViewController.canvasOverscrollHeight) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }
        canvasView.contentSize = CGSize(width: DataModel.canvasWidth * canvasView.zoomScale, height: contentHeight)
    }
}
