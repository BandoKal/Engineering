import Foundation
import Files

//TODO: Create TOC for Root Readme.md of all subsections (non-recursive)

struct Summary: Codable {
    let title: String
    let description: String
}

enum TOC: String {
    case start = "<!-- TOC Start -->"
    case header = """
    | Section |  |
    |--|--|
    """
    case end = "<!-- TOC End-->"

    static var newTOC: String {
        return """
        \(TOC.start.rawValue)
        \(TOC.header.rawValue)
        """
    }
}
//MARK: - Create TOC for all section ReadMes or generate a readme from template
let encoder = JSONEncoder()
let root = Folder.current.parent!
let sectionFolders = root.subfolders.filter { !$0.name.contains("scripts")}

func generateTOC(from files: [File]) -> String {
    var toc = TOC.newTOC


    let tocRows = files.compactMap { (file: File) -> String? in
        if let md = try? file.readAsString(encoding: .utf8),
            let endIndex = md.firstIndex(of: ">"){
            //get line that matches the pattern <!-- title:{value}, description:{value} -->
            // use the values here to build the toc row element

            let elements = md[...endIndex].replacingOccurrences(of: "<!--", with: "")
                .replacingOccurrences(of: "-->", with: "")
                .replacingOccurrences(of: " title:", with:  "")
                .replacingOccurrences(of: " description:", with:  "")
                .split(separator: ",")

            guard let title = elements.first,
                elements.count == 2 else {
                return "|\(file.name)|TODO|"
            }
            let description = elements[1]
            return "|\(title)|\(description)|"
        }
        return nil
        }.joined(separator: "\n")

    toc.append("\n")
    toc.append(tocRows)
    toc.append("\n" + TOC.end.rawValue)

    return toc
}
//.filter { !$0.containsFile(named: "README.md") }
sectionFolders.forEach { sectionFolder in

    let readMe = "README.md"
    let mds = sectionFolder.files.filter({ $0.extension == "md" })

    if let sectionReadmeString = try? sectionFolder.file(named: readMe).readAsString(encoding: .utf8) {
        let beforePart = sectionReadmeString.components(separatedBy: TOC.start.rawValue).first!
        let afterPart = sectionReadmeString.components(separatedBy: TOC.end.rawValue).last!
        //get names of all markdown files in section folder
        _ = try! sectionFolder.createFile(named: readMe, contents: beforePart + generateTOC(from: mds) + afterPart)

    } else {
        _ = try! sectionFolder.createFile(named: readMe, contents: "#\(sectionFolder.name)\n" + generateTOC(from: mds))
    }

    let summaryJson = "summary.json"
    if !sectionFolder.containsFile(named: summaryJson) {

        let summaryData = try! encoder.encode(Summary(title: "\(sectionFolder.name)", description: ""))
        _ = try! sectionFolder.createFile(named: summaryJson, contents: summaryData)
        print("WARNING: summary.json at location \(sectionFolder.path) does not have a description!")
    }
}


let rootReadme = try! root.file(named: "README.md").readAsString(encoding: .utf8)

let beforePart = rootReadme.components(separatedBy: TOC.start.rawValue).first!
let afterPart = rootReadme.components(separatedBy: TOC.end.rawValue).last!

var toc = TOC.newTOC
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

