//
//  ContentView.swift
//  fember
//
//  Created by Chris Davis on 21/12/2019.
//  Copyright © 2019 nthState. All rights reserved.
//

import SwiftUI
import Combine
import os.log

/**
Custom logging
*/
extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let actions = OSLog(subsystem: subsystem, category: "actions")
}

/**
Main content view
*/
struct ContentView: View {
  
  /// ViewModel contains target number
  @ObservedObject var memory: ViewModel = ViewModel()
  
  /// result updates the UI
  @State var result: Bool? = nil
  
  var body: some View {
    VStack() {
      
      ResultView(result: $result, name: "Correct", assert: true)
      ResultView(result: $result, name: "Incorrect", assert: false)
      
      Text("Number of digits 2-10")
      Slider(value: $memory.digitLength, in: 2...10)
      Text("Display time: 0.1 to 2 seconds")
      Slider(value: $memory.time, in: 0.1...2)
      
      GuessNumber(numberToRemember: $memory.numberToRemember, opacity: $memory.numberOpacity)
      
      TextField("Enter:", text: $memory.rememberedNumber)
        .onReceive(memory.publisher, perform: { (output) in
          
          self.result = output

          // Dispatch after, otherwise the textfield isn't cleared
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.result = nil
            self.memory.generateNew()
          }
          
        })
        .border(Color.black)
        .keyboardType(/*@START_MENU_TOKEN@*/.numberPad/*@END_MENU_TOKEN@*/)
      Spacer()
    }.onAppear {
      self.memory.generateNew()
    }
  }
  
}

/**
Correct/Incorrect view
*/
struct ResultView : View {
  
  @Binding var result: Bool?
  var name: String = ""
  var assert: Bool
  
  var body: some View {
    Text(name)
      .opacity((result == assert) ? 1 : 0)
      .animation(Animation.easeOut(duration: 1))
  }
}

/**
The number the user should try and guess
*/
struct GuessNumber: View {
  @Binding var numberToRemember: String
  @Binding var opacity: Double

  var body: some View {
    Text(numberToRemember)
    .opacity(opacity)
  }
  
}

/**
 Content view preview
 */
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

class ViewModel : ObservableObject {
  
  /// Time in seconds that the number to remember is flashed on the screen
  @State var time: TimeInterval = 0.5
  
  /// Fade opacity
  @Published var numberOpacity: Double = 1
  
  /// Number of digits to try and remember
  @State var digitLength: Float = 6
  
  /// What the user has entered as the string they remember
  @Published var rememberedNumber: String = ""
  
  /// What number to rememember
  @Published var numberToRemember: String = "a"
  
  var publisher = PassthroughSubject<Bool, Never>()
  
  var numberSink: AnyCancellable?
  
  /**
    Create a sink to the $rememberedNumber, which is bound to a textfield,
      as the text changes, check against the value
   */
  init() {
    
    numberSink = $rememberedNumber.sink{[weak self] currentText in
      guard let strongSelf = self else { return }
      
      os_log("current: %@", log: OSLog.actions, type: .info, currentText)
      
      if !strongSelf.numberToRemember.hasPrefix(currentText) {
        return strongSelf.publisher.send(false)
      }
      
      if strongSelf.numberToRemember == currentText {
        strongSelf.publisher.send(true)
      }
      
    }
  }
  
  /**
    Generate a new target number
   */
  func generateNew() {
    
    let amount = Int(digitLength)
    let x = (0..<amount).compactMap({ _ in
      "\(Int.random(in: 0...9))" })
      .joined(separator: "")
    
    numberOpacity = 1
    numberToRemember = x
    rememberedNumber = ""
    
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(time)) {
      self.numberOpacity = 0
    }
    
    os_log("Generate new", log: OSLog.actions, type: .info)
  }
}
