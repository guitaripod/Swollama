import Foundation
import Swollama


protocol ModelFormatter {



    func format(_ model: ModelListEntry) -> String
}


struct DefaultModelFormatter: ModelFormatter {

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()




    func format(_ model: ModelListEntry) -> String {
        """
        - \(model.name)
          Size: \(FileSize.format(bytes: Int(model.size)))
          Family: \(model.details.family)
          Parameters: \(model.details.parameterSize)
          Quantization: \(model.details.quantizationLevel)
          Modified: \(dateFormatter.string(from: model.modifiedAt))

        """
    }
}


struct FileSize {



    static func format(bytes: Int) -> String {
        let gigabyte = 1024 * 1024 * 1024
        let megabyte = 1024 * 1024
        let kilobyte = 1024

        if bytes >= gigabyte {
            return String(format: "%.2f GB", Double(bytes) / Double(gigabyte))
        } else if bytes >= megabyte {
            return String(format: "%.2f MB", Double(bytes) / Double(megabyte))
        } else if bytes >= kilobyte {
            return String(format: "%.2f KB", Double(bytes) / Double(kilobyte))
        }
        return "\(bytes) bytes"
    }
}
