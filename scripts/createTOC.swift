import Foundation
import Files

//TODO: Create TOC for Root Readme.md of all subsections (non-recursive)

struct Summary: Codable {
    let title: String
    let description: String
}
//MARK: - Create TOC for all section ReadMes or generate a readme from template
let encoder = JSONEncoder()
let root = Folder.current.parent!
let sectionFolders = root.subfolders.filter { !$0.name.contains("scripts")}
sectionFolders.filter { !$0.containsFile(named: "README.md") }.forEach { sectionFolder in
    //TODO: -
    // IF Readme exists:
    //  THEN Generate TOC from headers of the readme if they exists
    // ELSE
    //  THEN Generate template ReadMe
    let readMe = "README.md"
    if let fileString = try? sectionFolder.file(named: readMe).readAsString(encoding: .utf8) {
        print(fileString)
    } else {
        _ = try! sectionFolder.createFile(named: readMe)
    }

    let summaryJson = "summary.json"
    if !sectionFolder.containsFile(named: summaryJson) {

        let summaryData = try! encoder.encode(Summary(title: "\(sectionFolder.name)", description: ""))
        _ = try! sectionFolder.createFile(named: summaryJson, contents: summaryData)
        print("WARNING: summary.json at location \(sectionFolder.path) does not have a description!")
    }
}

enum TOC: String {
    case start = "<!-- TOC Start -->"
    case header = """
    | Section |  |
    |--|--|
    """
    case end = "<!-- TOC End-->"
}

let rootReadme = try! root.file(named: "README.md").readAsString(encoding: .utf8)

let beforePart = rootReadme.components(separatedBy: TOC.start.rawValue).first!
let afterPart = rootReadme.components(separatedBy: TOC.end.rawValue).last!

var toc = """
\(TOC.start.rawValue)
\(TOC.header.rawValue)
"""
let decoder = JSONDecoder()
sectionFolders.forEach {
    if let summaryData = try? $0.file(named: "summary.json").read(),
        let summary = try? decoder.decode(Summary.self, from: summaryData) {
        toc.append("\n|\(summary.title)|\(summary.description)|")
        if summary.description.isEmpty {
            print("WARNING: summary.json at location \($0.path) does not have a description!")
        }
    }
}

toc.append("\n" + TOC.end.rawValue)

_ = try! root.createFile(named: "README.md", contents:  beforePart + toc + afterPart)

