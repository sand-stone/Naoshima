#ifndef FaceBlendCommon_HPP_
#define FaceBlendCommon_HPP_

#include "common.h"

#ifndef M_PI
#define M_PI 3.14159
#endif

using namespace dlib;

/**
 Get the cropped region from a face
 param Mat                        : image  image input to cropped
 param vector<Point2f>            : landmarks face landmarks point
 param Rect &                     : selectedRegion  rectangle region for face point
 */
Mat getCroppedFaceRegion(Mat image, std::vector<Point2f> landmarks, cv::Rect &selectedRegion);

/**
 Find nearest face descriptor from vector of enrolled faceDescriptor
 to a query face descriptor
 param matrix<float, 0, 1>&                         : faceDescriptorQuery faceDescriptor which need to match for nearest  neighbour
 param vector<dlib::matrix<float, 0, 1>>&           : faceDescriptor
 param string &                                     : lable for match face
 */
void nearestNeighbor(dlib::matrix<float, 0, 1>& faceDescriptorQuery,
                     std::vector<dlib::matrix<float, 0, 1>>& faceDescriptors,
                     std::vector<string>& faceLabels, string &label);

#endif
