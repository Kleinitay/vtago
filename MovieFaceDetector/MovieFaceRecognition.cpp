// MovieFaceRecognition.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

// simple_face_detect_warp_trackbar.cpp : Defines the entry point for the console application.
//


//#include <cv.hpp>
//#include <highgui.h>
#include <math.h>
#include <string>
#include "cv.h"
#include "highgui.h"
#include "MovieFaceExtractor.h"
//#include "cxcore.h"

static const double pi = 3.14159265358979323846;
#define N 500

inline static double square(int a)
{
	return a * a;
}

int thresh = 11;
double scale = 1;

// define a trackbar callback
void on_trackbar(int h)
{
	int b = h-11;
	if(b<0)
		scale = -1.0/(b-1);
	else if(b>0)
		scale = b*1.0+1;
	else
		scale = 1.0;
	printf("scale %d\n",b);
}


void detect_and_draw( IplImage* image , int scale,int min_neighbors,int min_size,IplImage* faceimg,  CvRect* tmprect );

//int main( int argc, char** argv ) {
//	char *filename = "C:\\TestData\\Movies\\IMG_1411_mpeg1video.mpg";
//	CvCapture* cap  = cvCreateFileCapture(filename);
//	MovieFaceExtractor::init();
//	MovieFaceExtractor::saveFacesToDiskAndGetTimeStamps(cap, "C:\\TestOutputs", 3, 1, false);
//	cvReleaseCapture(&cap);
//
//	return 0;
//}
