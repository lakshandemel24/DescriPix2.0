//
//  ImageStorage.swift
//  DescriPix
//
//  Created by student on 06/03/24.
//
import SwiftUI

class ImageStorage {
    static let shared = ImageStorage()
    private init() {} // Questo previene la creazione di altre istanze della classe
    
    var croppedImage: UIImage?
}
