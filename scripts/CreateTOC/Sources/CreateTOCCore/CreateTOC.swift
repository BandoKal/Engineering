import Foundation
import Files

public func runCreateTOC() {
    //MARK: - Models used below
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
    let root = Folder.current.parent!.parent!// try! Folder(path: "/Users/JDU9706/Projects/Engineering")
    let sectionFolders = root.subfolders.filter { !$0.name.contains("scripts") && !$0.name.contains("readme-project")}

    
    func generateTOCRows(from files: [File], in folder: Folder) -> String {
        
        let tocRows = files.compactMap { (file: File) -> String? in
            if let md = try? file.readAsString(encoding: .utf8),
                let startIndex = md.firstIndex(of: "<"),
                let endIndex = md.firstIndex(of: ">"){
                //get line that matches the pattern <!-- title:{value}, description:{value} -->
                // use the values here to build the toc row element
                let elements = md[startIndex...endIndex].replacingOccurrences(of: "<!--", with: "")
                    .replacingOccurrences(of: "-->", with: "")
                    .replacingOccurrences(of: " title:", with:  "")
                    .replacingOccurrences(of: " description:", with:  "")
                    .split(separator: ",")

                guard let title = elements.first,
                    elements.count == 2 else {
                        return "|[\(file.name)](\(folder.name)/\(file.name))|TODO|"
                }
                let description = elements[1]
                return "|[\(title)](/\(folder.name)/\(file.name))|\(description)|"
            }
            return nil
            }.joined(separator: "\n")

        return tocRows
    }
    
    func generateTOCRows(from text: String) -> String {
        let hashTagComponents = text.components(separatedBy: "## ")
        let headers = hashTagComponents.compactMap {
           $0.components(separatedBy: "\n\n").first?.replacingOccurrences(of:" ", with: "-").trimmingCharacters(in: .whitespaces)
            }.compactMap{
                $0.isEmpty ? nil : "|[\($0)](#\($0.lowercased()))|"
        }
        return headers.joined(separator: "\n")
    }

    sectionFolders.forEach { sectionFolder in
        let readMe = "README.md"
        let mds = sectionFolder.files.filter({ $0.extension == "md" && !$0.name.contains("README")})

        if let sectionReadmeString = try? sectionFolder.file(named: readMe).readAsString(encoding: .utf8) {
            let beforePart = sectionReadmeString.components(separatedBy: TOC.start.rawValue).first!
            let afterPart = sectionReadmeString.components(separatedBy: TOC.end.rawValue).last!
            //get names of all markdown files in section folder
            
            let tocRows = generateTOCRows(from: mds, in: sectionFolder)
            let toc = TOC.newTOC + (tocRows.isEmpty ? generateTOCRows(from: afterPart) : tocRows) + "\n" + TOC.end.rawValue
            
            _ = try! sectionFolder.createFile(named: readMe, contents: beforePart + toc + afterPart)

        } else {
            _ = try! sectionFolder.createFile(named: readMe, contents: "#\(sectionFolder.name)\n" + generateTOCRows(from: mds, in: sectionFolder))
        }

        let summaryJson = "summary.json"
        if !sectionFolder.containsFile(named: summaryJson) {

            let summaryData = try! encoder.encode(Summary(title: "\(sectionFolder.name)", description: ""))
            _ = try! sectionFolder.createFile(named: summaryJson, contents: summaryData)
            print("WARNING: summary.json at location \(sectionFolder.path) does not have a description!")
        }
    }


    // MARK: - Create TOC for the Root Readme
    let rootReadme = try! root.file(named: "README.md").readAsString(encoding: .utf8)
    let beforePart = rootReadme.components(separatedBy: TOC.start.rawValue).first!
    let afterPart = rootReadme.components(separatedBy: TOC.end.rawValue).last!

    var toc = TOC.newTOC
    let decoder = JSONDecoder()
    sectionFolders.forEach {
        if let summaryData = try? $0.file(named: "summary.json").read(),
            let summary = try? decoder.decode(Summary.self, from: summaryData) {
            toc.append("|[\(summary.title)](/\($0.name)/README.md)|\(summary.description)|\n")
            if summary.description.isEmpty {
                print("WARNING: summary.json at location \($0.path) does not have a description!")
            }
        }
    }

    toc.append("\n" + TOC.end.rawValue)

    _ = try! root.createFile(named: "README.md", contents:  beforePart + toc + afterPart)
}
