#include "PhotoCluster.h"

static const char* facerecog  = "./dlib_face_recognition_resnet_model_v1.dat";
static const char* landmark  = "./shape_predictor_68_face_landmarks.dat";

#define DLIB_NO_GUI_SUPPORT
#define DLIB_JPEG_SUPPORT
#define NDEBUG
#define DLIB_USE_BLAS
#define DLIB_USE_LAPACK

int main(int argc, char** argv) {
  PhotoCluster pc(landmark, facerecog);
  std::vector<matrix<float,0,1>> faceDescriptors;

  pc.GetFaceDescriptor(argv[1], faceDescriptors);
  cout<<"face count:" << faceDescriptors.size() << std::endl;
}
