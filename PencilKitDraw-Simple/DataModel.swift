//
//  DataModel.swift
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
import os

// DataModel contains the drawings that make up the data model, including multiple image drawings.
struct DataModel: Codable {
    
    static let defaultDrawingNames: [String] = ["Notes"] // Names of the drawing assets to be used to initialize the data model the first time
    static let canvasWidth: CGFloat = 768 // The width used for drawing canvases
    var drawings: [PKDrawing] = [] // The drawings that make up the current data model
}

// DataModelControllerObserver is the behavior of an observer of data model changes
protocol DataModelControllerObserver {
    // Invoked when the data model changes.
    func dataModelChanged()
}

class DataModelController {
    var dataModel = DataModel()
    private let serializationQueue = DispatchQueue(label: "SerializationQueue", qos: .background) // Dispatch queues for the background operations done by this controller
   
    var observers = [DataModelControllerObserver]()  // Begin being informed of data model changes
    
    
    // Computed property providing access to the drawings in the data model
    var drawings: [PKDrawing] {
        get { dataModel.drawings }
        set { dataModel.drawings = newValue }
    }
    
    // Initialize a new data model
    init() {
        loadDataModel()
    }
    
    // Update a drawing at index
    func updateDrawing(_ drawing: PKDrawing, at index: Int) {
        dataModel.drawings[index] = drawing
        saveDataModel()
    }
    
    
    // Notify observer that the data model changed
    private func didChange() {
        for observer in self.observers {
            observer.dataModelChanged()
        }
    }
    
    // The URL of the file in which the current data model is saved
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths.first!
        return documentsDirectory.appendingPathComponent("PencilKitDraw.data")
    }
    
    // Save the data model to persistent storage
    func saveDataModel() {
        let savingDataModel = dataModel
        let url = saveURL
        serializationQueue.async {
            do {
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(savingDataModel)
                try data.write(to: url)
            } catch {
                os_log("Could not save data model: %s", type: .error, error.localizedDescription)
            }
        }
    }
    
    // Load the data model from persistent storage
    private func loadDataModel() {
        let url = saveURL
        serializationQueue.async {
            // Load the data model, or the initial test data
            let dataModel: DataModel
            
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let decoder = PropertyListDecoder()
                    let data = try Data(contentsOf: url)
                    dataModel = try decoder.decode(DataModel.self, from: data)
                } catch {
                    os_log("Could not load data model: %s", type: .error, error.localizedDescription)
                    dataModel = self.loadDefaultDrawings()
                }
            } else {
                dataModel = self.loadDefaultDrawings()
            }
            
            DispatchQueue.main.async {
                self.setLoadedDataModel(dataModel)
            }
        }
    }
    
    // Construct initial an data model when no data model already exists
    private func loadDefaultDrawings() -> DataModel {
        var testDataModel = DataModel()
        for sampleDataName in DataModel.defaultDrawingNames {
            guard let data = NSDataAsset(name: sampleDataName)?.data else { continue }
            if let drawing = try? PKDrawing(data: data) {
                testDataModel.drawings.append(drawing)
            }
        }
        return testDataModel
    }
    
    // Helper method to set the current data model to a data model created on a background queue
    private func setLoadedDataModel(_ dataModel: DataModel) {
        self.dataModel = dataModel
    }
    
    // Create a new drawing in the data model
    func newDrawing() {
        let newDrawing = PKDrawing()
        dataModel.drawings.append(newDrawing)
        updateDrawing(newDrawing, at: dataModel.drawings.count - 1)
    }
}
