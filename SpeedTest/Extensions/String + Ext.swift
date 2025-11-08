
import UIKit

extension String {
    var localized: String {
        let bundle: Bundle
        
        if let languageCode = Bundle.main.preferredLocalizations.first,
           let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else if let basePath = Bundle.main.path(forResource: "Base", ofType: "lproj"),
                  let baseBundle = Bundle(path: basePath) {
            bundle = baseBundle
        } else {
            bundle = .main
        }
        
        return NSLocalizedString(self, tableName: "LocalizationNew", bundle: bundle, comment: "")
    }
    
    var localizedd: String {
        return NSLocalizedString(self, comment: "")
    }
}
