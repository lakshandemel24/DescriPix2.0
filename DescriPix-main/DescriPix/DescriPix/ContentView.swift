//  ContentView.swift
//  ProvaImmagine
//
//  Created by student on 27/02/24.
//

import SwiftUI
import Mantis

struct ContentView: View {
    @State private var isImagePickerDisplay = false
    @State private var selectedImage: UIImage? = UIImage(named: "default")
    
    @State private var showCropper = false
    @State private var cropShapeType: Mantis.CropShapeType = .rect
    @State private var presetFixedRatioType: Mantis.PresetFixedRatioType = .canUseMultiplePresetFixedRatio()
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                VStack {
                    if let selectedImage = self.selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width * 1, height: UIScreen.main.bounds.height * 0.75)
                            .clipped()
                            .padding(.bottom, 10)
                            .onTapGesture {
                                self.showCropper = true
                            }
                    }
                    
                    Button("Select image") {
                        self.isImagePickerDisplay = true
                    }
                    .padding()
                    .frame(minWidth: 0, maxWidth: 250)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding()
                }
            }
            .sheet(isPresented: $isImagePickerDisplay, onDismiss: {
                if selectedImage != nil {
                    self.showCropper = true
                }
            }) {
                ImagePicker(image: self.$selectedImage, sourceType: .photoLibrary)
            }
            .fullScreenCover(isPresented: $showCropper, content: {
                ImageCropper(image: $selectedImage, cropShapeType: $cropShapeType, presetFixedRatioType: $presetFixedRatioType)
                    .ignoresSafeArea()
            })
        }
    }
}
