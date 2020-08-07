//
//  ViewController.swift
//  GamePants
//
//  Created by Goran Svorcan on 8/6/20.
//  Copyright © 2020 Goran Svorcan. All rights reserved.
//

import UIKit

struct ButtonObject {
    var x: Int?
    var y: Int?
    var click: (() -> Void)?
    var imageName: String?
}

enum TokenType: String {
    case winState = "WINIF"
    case obj = "OBJECT"
    case eq = "="
    case startDef = "{"
    case endDef = "}"
}

class ViewController: UIViewController {
    
    var variables = [String:Any]()
    var buttonObjects = [String:ButtonObject]()

    var currentToken: TokenType?
    var currentObjectName: String?

    var tokenStack = [Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
        let path = Bundle.main.path(forResource: "GamePants", ofType: "txt")!
        let codeString = try! String(contentsOfFile: path, encoding: .utf8)
        
        let lines = codeString.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let words = trimmedLine.components(separatedBy: .whitespaces)

            for word in words {
                if let existingToken = currentToken {
                    if existingToken == .winState {
                        if let defToken = TokenType(rawValue: word) {
                            tokenStack.append(defToken)
                        } else if let topToken = tokenStack.last as? TokenType {
                            if topToken == .eq {
                                tokenStack.removeLast()
                                if let variableName = tokenStack.last as? String {
                                    if word == "true" {
                                        variables[variableName] = true
                                    } else if word == "false" {
                                        variables[variableName] = false
                                    } else if let num = Int(word) {
                                        variables[variableName] = num
                                    } else {
                                        variables[variableName] = word
                                    }
                                }
                            }
                            tokenStack.removeAll()
                            currentToken = nil
                        } else {
                            tokenStack.append(word)
                        }
                    } else if existingToken == .obj {
                        if let defToken = TokenType(rawValue: word) {
                            if defToken == .startDef, tokenStack.count == 1, let objName = tokenStack.first as? String {
                                let obj = ButtonObject()
                                buttonObjects[objName] = obj
                            } else if defToken == .endDef, tokenStack.count == 1 {
                                tokenStack.removeAll()
                                currentToken = nil
                            } else {
                                tokenStack.append(defToken)
                            }
                        } else if let topToken = tokenStack.last as? TokenType {
                            if topToken == .eq, tokenStack[1] as? String == "click" {
                                if let objName = tokenStack.first as? String, var obj = buttonObjects[objName] {
                                    tokenStack.removeLast()
                                    if let variableName = tokenStack.last as? String {
                                        if word == "true" {
                                            obj.click = { [weak self] in
                                                self?.variables[variableName] = true
                                            }
                                        } else if word == "false" {
                                            obj.click = { [weak self] in
                                                self?.variables[variableName] = false
                                            }
                                        } else if let num = Int(word) {
                                            obj.click = { [weak self] in
                                                self?.variables[variableName] = num
                                            }
                                        } else {
                                            obj.click = { [weak self] in
                                                self?.variables[variableName] = word
                                            }
                                        }
                                        buttonObjects[objName] = obj
                                    }
                                }
                                tokenStack.removeLast()
                            } else if topToken == .eq, tokenStack[tokenStack.count - 2] as? String != "click" {
                                if let objName = tokenStack.first as? String, var obj = buttonObjects[objName] {
                                    tokenStack.removeLast()
                                    if let variableName = tokenStack.last as? String {
                                        if variableName == "x", let xValue = Int(word) {
                                            obj.x = xValue
                                        } else if variableName == "y", let yValue = Int(word) {
                                            obj.y = yValue
                                        } else if variableName == "image" {
                                            obj.imageName = word
                                        }
                                        buttonObjects[objName] = obj
                                        tokenStack.removeLast()
                                    }
                                }
                            } else if topToken == .startDef {
                                tokenStack.removeLast()
                                tokenStack.removeLast()
                                tokenStack.append(word)
                            } else if topToken == .endDef {
                                tokenStack.removeLast()
                                tokenStack.removeLast()
                                tokenStack.append(word)
                            }
                        } else {
                            tokenStack.append(word)
                        }
                    }
                } else if let token = TokenType(rawValue: word) {
                    if token == .winState || token == .obj {
                        currentToken = token
                    }
                }
            }
        }

        for (buttonName, buttonObj) in buttonObjects {
            let button = UIButton(frame: CGRect(x: buttonObj.x!, y: buttonObj.y!, width: 50, height: 50))
            button.setImage(UIImage(named: buttonObj.imageName!), for: .normal)
            button.accessibilityLabel = buttonName
            button.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
            view.addSubview(button)
        }
        
    }
    
    @objc private func buttonClick(button: UIButton) {
        buttonObjects[button.accessibilityLabel!]?.click?()
    }

}

