import Foundation

extension Data : Value {
    
    public static var declaredDatatype: String {
        return Blob.declaredDatatype
    }
    
    public static func fromDatatypeValue(_ dataValue: Blob) -> Data {
        return Data(bytes: dataValue.bytes)
    }
    
    public var datatypeValue: Blob {
        return withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Blob in
            return Blob(bytes: pointer, length: count)
        }
    }
    
}

extension Date : Value {
    
    public static var declaredDatatype: String {
        return String.declaredDatatype
    }
    
    public static func fromDatatypeValue(_ stringValue: String) -> Date {
        return dateFormatter.date(from: stringValue)!
    }
    
    public var datatypeValue: String {
        return dateFormatter.string(from: self)
    }
    
}

/// A global date formatter used to serialize and deserialize `NSDate` objects.
/// If multiple date formats are used in an application’s database(s), use a
/// custom `Value` type per additional format.
public var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()
