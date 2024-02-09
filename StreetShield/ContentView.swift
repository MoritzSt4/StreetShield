//
//  ContentView.swift
//  StreetShield
//
//  Created by Moritz on 07.02.24.
//

import SwiftUI
import CoreData
import AVFoundation

import UIKit
import CoreMotion

struct ContentView: View {
    //Wird in der StreetShielApp.swift Datei festgelegt um beim Verlassen zurückgesetzt werden zu können
    @Binding var currentBrightness: CGFloat
    
    //AppStorage bleibt beim Neustart persistent
    @AppStorage("isTorchedAllowed") private var isTorchedAllowed = true // Soll die Taschenlampe angeschaltet werden?
    @AppStorage("isBlinkingOn") private var isBlinkingOn = false // Soll Display blinken?
    
    @State private var isTorchOn = false // Taschenlampe Status
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var doBlink = false
    @State private var displayScreenColor = Color(red: 255, green: 0, blue: 0)

    
    
    var body: some View {
        let maxWidth = UIScreen.main.bounds.width // Maximale Breite des Bildschirms
        
        ZStack{
            // Die gesamte ContentView wird eingefärbt
            Rectangle()
                .foregroundColor(displayScreenColor)
                .edgesIgnoringSafeArea(.all) // Rand ignorieren alles färben
            
            VStack{
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .padding(.top, 55)
                        .padding(.leading, 20)
                        .font(.system(size: 25))
                        .foregroundColor(Color(red: 190 / 255, green: 0, blue: 0))
                        .onTapGesture {
                            showHelp.toggle() // Settings anzeigen
                     }
                    
                    Spacer()
                    Image(systemName: "gearshape.fill")
                        .padding(.top, 55)
                        .padding(.trailing, 20)
                        .font(.system(size: 25))
                        .foregroundColor(Color(red: 190 / 255, green: 0, blue: 0))
                        .onTapGesture {
                            showSettings.toggle() // Settings anzeigen
                     }
                }
                
                Spacer()
               
                Image(systemName: isTorchOn ? "xmark.shield.fill" : "bolt.shield.fill")
                    .font(.system(size: 180))
                    .foregroundColor(Color(red: 190 / 255, green: 0, blue: 0))
                    .onTapGesture {
                        toggleTorch() // Taschenlampe ein-/ausschalten
                        toggleBlink() // schaut ob geblinkt werden soll
                     }
               
                
                Spacer()
                
                Button(action: {
                }) {
                        Text("DOUBLECLICK TO CLOSE")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: maxWidth, height: 150)
                            .background(Color(red: 190 / 255, green: 0, blue: 0))
                            .cornerRadius(40)
                        }.simultaneousGesture(TapGesture(count: 2).onEnded {
                            isTorchOn = false
                            doBlink = false
                            UIScreen.main.brightness = currentBrightness
                            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                        })

            } .edgesIgnoringSafeArea(.all)
           
            
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isTorchedAllowed: $isTorchedAllowed, isBlinkingOn: $isBlinkingOn, displayScreenColor: $displayScreenColor)
        }
        .sheet(isPresented: $showHelp) {
            HelpView(isBlinkingOn: $isBlinkingOn)
        }
    }
    
    
    // Funktion zum Ein-/Ausschalten der Taschenlampe
    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if isTorchOn {
                    UIScreen.main.brightness = currentBrightness
                    device.torchMode = .off
                    isTorchOn = false
                } else {
                    UIScreen.main.brightness = 1.0
                    isTorchOn = true
                    if isTorchedAllowed {
                        device.torchMode = .on
                    }
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    func toggleBlink() {
        if isBlinkingOn && !doBlink {
            doBlink = true
        } else {
            doBlink = false
        }
        
        if isBlinkingOn {
            blink() //kümmert sich ums Blinken
        }
    }
    
    // Funktion zum Blinken des Displays wenn der Boostmode aktiv ist
    func blink() {
        // Schleife, die jede Sekunde für 0.1 Sekunden das Display blinken lässt
        DispatchQueue.global().async {
            while doBlink {
                DispatchQueue.main.async {
                    UIScreen.main.brightness = 0.0 // Display ausschalten (schwarzer Bildschirm)
                }
                usleep(150000) // 0.15 Sekunden warten
                DispatchQueue.main.async {
                    UIScreen.main.brightness = 1.0 // Maximale Helligkeit
                }
                usleep(350000) // 0.35 Sekunden warten
            }
        }
        UIScreen.main.brightness = currentBrightness // ursprüngliche Helligkeit wiederherstellen
    }

}

//Einstellungsseite
struct SettingsView: View {
    @Binding var isTorchedAllowed: Bool
    @Binding var isBlinkingOn: Bool
    @Binding var displayScreenColor: Color
    
    var body: some View {
        VStack {
            Text("Settings").padding()
            List {
                Section(header: Text("General")) {
                    ColorPicker("Screen Color", selection: $displayScreenColor)
                }
            
                Section(header: Text("Boost Mode")) {
                    Toggle(isOn: $isBlinkingOn) {
                        Text("Blinking Screen")
                    }
                
                    Toggle(isOn: $isTorchedAllowed) {
                        Text("Flashlight")
                    }
                }
            }

            Button(action: {
                isTorchedAllowed = true
                isBlinkingOn = false
                displayScreenColor = Color(red: 255, green: 0, blue: 0)
            }) {
                Text("Reset Settings")
            }
        
        }.background(Color(.systemGray6))
    }
}

//Hilfeseite
struct HelpView: View {
    @Binding var isBlinkingOn: Bool
    @State private var selectedColor = Color(red: 255, green: 0, blue: 0) // Default color
    
    public let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var selection = 0
    let images = ["helper", "helper_glow", "helper_glow", "helper_glow"]
    
    var body: some View {
        VStack{
            Text("Help").padding()
            
            List {
               Text("StreetShield helps you to improve your visibility when crossing a road at night by displaying a red screen on your phone. Additionally, tapping the shield icon activates a boost mode for increased visibility.")
                
                Section(header: Text("Contact")) {
                    HStack {
                        Text("©Moritz Staigl")
                        Spacer()
                        Button(action: {
                            guard let url = URL(string: "mailto:moritzstaoriginal@gmail.com") else { return }
                            UIApplication.shared.open(url)
                        }) {
                            Image(systemName: "envelope")
                        }
                    }
                }
            }
            
            TabView(selection: $selection){
                ForEach(0..<4) { i in
                    Image("\(images[i])").resizable().ignoresSafeArea().background(Color(.systemGray6))
                }.tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    .onReceive(timer, perform: { _ in
                        withAnimation{
                            selection = selection < 4 ? selection + 1 : 0
                        }
                    })
            }.ignoresSafeArea()
        }.background(Color(.systemGray6))
        
        
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(currentBrightness: .constant(UIScreen.main.brightness))
    }
}

