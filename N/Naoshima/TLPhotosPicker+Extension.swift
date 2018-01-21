import Foundation
import TLPhotoPicker

extension TLPhotosPickerViewController {

    func wrapNavigationControllerWithoutBar() -> UINavigationController {
        let navController = UINavigationController(rootViewController: self)
        navController.navigationBar.isHidden = true
        return navController
    }
}
