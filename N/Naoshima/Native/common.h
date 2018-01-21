#ifndef common_h
#define common_h

#include "unistd.h"
#define PATH_SEP '/'
#define GETCWD getcwd
#define CHDIR chdir

#include "opencv2/opencv.hpp"
#include <sys/fcntl.h>
#include <iostream>
#include <fstream>
#include <math.h>
#include <cmath>
#include <map>
#include <stdlib.h>
#include <algorithm>
#include <vector>

#include <dlib/dnn.h>
#include <dlib/image_io.h>
#include <dlib/opencv.h>
#include <dlib/image_processing.h>
#include <dlib/image_processing/frontal_face_detector.h>

#include <sys/stat.h>
#define faceWidth 64
#define faceHeight 64
#define PI 3.14159265

#define THRESHOLD 0.5

#define STRTOLOWER(x) std::transform (x.begin(), x.end(), x.begin(), ::tolower)
#define STRTOUPPER(x) std::transform (x.begin(), x.end(), x.begin(), ::toupper)
#define STRTOUCFIRST(x) std::transform (x.begin(), x.begin()+1, x.begin(),  ::toupper); std::transform (x.begin()+1, x.end(),   x.begin()+1,::tolower)


using namespace cv;
using namespace std;
using std::cout;
using std::endl;
using std::string;

//To increase the speed of faceDetector we need to resize the iamge, so With 576 size the result is good for images with single face and also for images with 4 5 face up to some extent with size 300 for single face the speed increase 3X but produce bad result for 2 3 faces
#define RESIZE_HEIGHT 576
#define FACE_DOWNSAMPLE_RATIO_DLIB 4

#endif /* common_h */
