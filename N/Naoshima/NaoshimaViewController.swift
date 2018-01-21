import UIKit
import Photos

class NaoshimaViewController: UIViewController {
    
    @IBOutlet weak var output: UITextField!
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    var assetCollection: PHAssetCollection!
    var allPhotos: PHFetchResult<PHAsset>!
    var smartAlbums: PHFetchResult<PHAssetCollection>!
    var userCollections: PHFetchResult<PHCollection>!
    var kb: KnowledgeBase?
    var pc: UnsafeRawPointer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        output.isEnabled = false
        initNaoshima()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var targetSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: imageView.bounds.width * scale,
                      height: imageView.bounds.height * scale)
    }
    
    @IBAction func processQuery(_ sender: Any) {
        NSLog("Process Query")
        output.text =  input.text
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        NaoshimaCBridge.freePhotoCluster(pc)
    }
    
    func initNaoshima() {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        PHPhotoLibrary.shared().register(self)
        NSLog("total photos: %d \n", allPhotos.count)
        NSLog("smartAlbums photos: %d \n", smartAlbums.count)
        NSLog("userCollections photos: %d \n", userCollections.count)
        let rootPath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        pc = NaoshimaCBridge.initPhotoCluster(Bundle.main.path(forResource: "shape_predictor_68_face_landmarks.dat", ofType: nil),
                                           faceRecoModel: Bundle.main.path(forResource: "dlib_face_recognition_resnet_model_v1.dat", ofType: nil))
        do {
            kb = try KnowledgeBase(dblocation: rootPath.appendingPathComponent("pkg_photograph.sqlite").path)
        } catch {
            NSLog("Oops")
        }
        processImages()
    }
    
    func processImages() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        if allPhotos.count > 0 {
            allPhotos.enumerateObjects ({ asset, index, _ in
                PHImageManager.default().requestImageData(for: asset, options: nil, resultHandler: { _, _, _, info in
                    let photopath = (info?["PHImageFileURLKey"] as! NSURL).path
                    let v = NaoshimaCBridge.getFaceDescriptor(self.pc, photoPath: photopath) as NSArray
                    if v.count > 0 { //handle any photo with a human face
                        let id = self.kb!.AssertEntity(entity: Entity(name: photopath, uuid: UUID(), prob: 0.9, sourceMlEngine: "resnetModel", dataSource: photopath,
                                                                       data: Feature(tags: ["photo", "acme"], data: v)))
                        print("ingested:", photopath)
                    }
                })
                PHImageManager.default().requestImage(for: asset, targetSize: self.targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
                    // Hide the progress view now the request has completed.
                    // If successful, show the image view and display the image.
                    guard let image = image else { return }
                    self.imageView.isHidden = false
                    self.imageView.image = image
                })
            })
        }
    }
    
}

extension NaoshimaViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Check each of the three top-level fetches for changes.
            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
                // Update the cached fetch result.
                allPhotos = changeDetails.fetchResultAfterChanges
                // (The table row for this one doesn't need updating, it always says "All Photos".)
            }
            
            // Update the cached fetch results, and reload the table sections to match.
            if let changeDetails = changeInstance.changeDetails(for: smartAlbums) {
                smartAlbums = changeDetails.fetchResultAfterChanges
            }
            if let changeDetails = changeInstance.changeDetails(for: userCollections) {
                userCollections = changeDetails.fetchResultAfterChanges
            }
            
        }
    }
}

