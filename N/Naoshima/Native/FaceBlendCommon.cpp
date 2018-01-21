#include "FaceBlendCommon.h"
extern string rootDirPath;
extern string resultDirPath;
extern string facesDirPath;
Mat getCroppedFaceRegion(Mat image, std::vector<Point2f> landmarks, cv::Rect &selectedRegion)
{
    int x1Limit = landmarks[0].x - (landmarks[36].x - landmarks[0].x);
    int x2Limit = landmarks[16].x + (landmarks[16].x - landmarks[45].x);
    int y1Limit = landmarks[27].y - 3*(landmarks[30].y - landmarks[27].y);
    int y2Limit = landmarks[8].y + (landmarks[30].y - landmarks[29].y);
    
    int imWidth = image.cols;
    int imHeight = image.rows;
    int x1 = max(x1Limit,0);
    int x2 = min(x2Limit, imWidth);
    int y1 = max(y1Limit, 0);
    int y2 = min(y2Limit, imHeight);
    
    // Take a patch over the eye region
    Mat cropped;
    selectedRegion = cv::Rect( x1, y1, x2-x1, y2-y1 );
    cropped = image(selectedRegion);
    return cropped;
}

// find nearest face descriptor from vector of enrolled faceDescriptor
// to a query face descriptor
void nearestNeighbor(dlib::matrix<float, 0, 1>& faceDescriptorQuery,
                     std::vector<dlib::matrix<float, 0, 1>>& faceDescriptors,
                     std::vector<string>& faceLabels, string &label) {
    int minDistIndex = 0;
    float minDistance = 1.0;
    label = "NEW_FACE";
    // Calculate Euclidean distances between face descriptor calculated on face dectected
    // in current frame with all the face descriptors we calculated while enrolling faces
    // Calculate minimum distance and index of this face
    for (int i = 0; i < faceDescriptors.size(); i++) {
        double distance = length(faceDescriptors[i] - faceDescriptorQuery);
        if (distance < minDistance) {
            minDistance = distance;
            minDistIndex = i;
        }
    }
    // Dlib specifies that in general, if two face descriptor vectors have a Euclidean
    // distance between them less than 0.6 then they are from the same
    // person, otherwise they are from different people.
    
    // This threshold will vary depending upon number of images enrolled
    // and various variations (illuminaton, camera quality) between
    // enrolled images and query image
    // We are using a threshold of 0.5
    // if minimum distance is greater than a threshold
    // assign integer label -1 or NEW_FACE i.e. unknown face
    if (minDistance > THRESHOLD){
        label = "NEW_FACE";
    } else {
        label = faceLabels[minDistIndex];
    }
}
