#include "PhotoCluster.h"

PhotoCluster::PhotoCluster(const char* pathlandmarkdetectorPath, const char* faceRecognitionModelPath) {
    _faceDetector = get_frontal_face_detector();
    deserialize(pathlandmarkdetectorPath) >> _landmarkDetector;
    deserialize(faceRecognitionModelPath) >> _net;
}

void PhotoCluster::GetFaceDescriptor(const char* path, std::vector<matrix<float,0,1>>& faceDescriptors) {
    string imagePath = path;
    Mat im = cv::imread(imagePath, cv::IMREAD_COLOR);

    int height = im.rows;
    float IMAGE_RESIZE = (float)height/RESIZE_HEIGHT;

    // resize the original image to smaller size, the bigger image take lot more time to process in facedetetor
    cv::resize(im, im, Size(), 1.0/IMAGE_RESIZE, 1.0/IMAGE_RESIZE);
    cv::Size size = im.size();
    cv::Mat frame_small;

    // Downsample the image and resize it
    cv::resize(im, frame_small, size, 1.0/FACE_DOWNSAMPLE_RATIO_DLIB, 1.0/FACE_DOWNSAMPLE_RATIO_DLIB);

    // convert image from BGR to RGB
    // because Dlib used RGB format
    Mat imRGB;
    cv::cvtColor(frame_small, imRGB, cv::COLOR_BGR2RGB);

    // convert OpenCV image to Dlib's cv_image object, then to Dlib's matrix object
    // Dlib's dnn module doesn't accept Dlib's cv_image template
    dlib::matrix<dlib::rgb_pixel> imDlib(dlib::mat(dlib::cv_image<dlib::rgb_pixel>(imRGB)));

    // detect faces in image
    std::vector<dlib::rectangle> faceRects = _faceDetector(imDlib);

    for (int j = 0; j < faceRects.size(); j++) {
        // Find facial landmarks for each detected face
        full_object_detection landmarks = _landmarkDetector(imDlib, faceRects[j]);

        // object to hold preProcessed face rectangle cropped from image
        matrix<rgb_pixel> face_chip;

        // original face rectangle is warped to 150x150 patch.
        // Same pre-processing was also performed during training.
        extract_image_chip(imDlib, get_face_chip_details(landmarks, 150, 0.25), face_chip);

        // Compute face descriptor using neural network defined in Dlib.
        // It is a 128D vector that describes the face in img identified by shape.
        matrix<float,0,1> faceDescriptorQuery = _net(face_chip);
        faceDescriptors.push_back(faceDescriptorQuery);
    }
}
