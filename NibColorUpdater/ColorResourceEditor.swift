/**
 * The MIT License (MIT)
 *
 * Copyright (C) 2022 Mauricio Ventura Pérez.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import SwiftyXMLParser

class NibColorResourceEditor {
    let fm = FileManager.default
    var catalog: [String: String] = [:]
    var editedColors = 0
    var editedFiles = 0
    var errors = [String]()
    
    @discardableResult init(sourcePath: String, xibCatalogPath: String) {
        catalog = createCatalog(xibCatalogPath: xibCatalogPath)
        guard !catalog.isEmpty else {
            let error = "Couldn't create catalog from path: \(xibCatalogPath)"
            errors.append(error)
            print(error)
            return
        }
        iterateOverPath(sourcePath)
        print("\(editedColors) were updated in \(editedFiles) files")
        guard !errors.isEmpty else {
            print("No errors found")
            return
        }
        print("ERRORS:")
        errors.forEach { print($0) }
    }
    
    func createCatalog(xibCatalogPath: String) -> [String: String] {
        guard let data = fm.contents(atPath: xibCatalogPath) else { return [:] }
        let xml = XML.parse(data)
        var colorsCatalog = [String: String]()
        xml["document", "resources", "namedColor"].forEach {
            guard let colorName = $0.attributes["name"],
                  let colorString = $0.colorString else {
                return
            }
            print("String for new color \(colorName) was created")
            colorsCatalog[colorName] = colorString
        }
        return colorsCatalog
    }
    
    func iterateOverPath(_ path: String) {
        let items = readContentsOfFolder(path)
        items.forEach {
            let currentPath = path + "/\($0)"
            if $0.contains(".storyboard") || $0.contains(".xib") {
                print("==================\nEditing \($0)")
                editXib(path: currentPath)
            } else if !$0.contains(".") {
                iterateOverPath(currentPath)
            }
        }
    }
    
    func readContentsOfFolder(_ folder: String) -> [String] {
        do {
            return try fm.contentsOfDirectory(atPath: folder)
        } catch {
            errors.append(error.localizedDescription)
            print(error)
            return [String]()
        }
    }
    
    func editXib(path: String) {
        let data = fm.contents(atPath: path)!
        var xibString = String(decoding: data, as: UTF8.self)
        let xml = XML.parse(data)
        let resources = xml["document", "resources"]
        var colorsCount = 0
        resources["namedColor"].forEach {
            guard let colorName = $0.attributes["name"],
                  let oldColorString = $0.colorString else { return }
            guard let catalogColor = catalog[colorName] else {
                let error = "Couldn't find \(colorName) in catalog"
                errors.append(error)
                print(error)
                return
            }
            xibString = xibString.replacingOccurrences(of: oldColorString, with:  catalogColor)
            print("  Color \(colorName) was modified")
            colorsCount += 1
        }
        do {
            //try fm.removeItem(atPath: path)
            //try xibString.write(toFile: path, atomically: false, encoding: .utf8)
            if colorsCount > 0 {
                print("\(colorsCount) were updated in \(path)\n==================")
                editedColors += colorsCount
                editedFiles += 1
            }
        } catch {
            errors.append(error.localizedDescription)
            print(error)
        }
    }
}
