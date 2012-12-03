// eigenface.c, by Robin Hewitt, 2007
//
// Example program showing how to implement eigenface with OpenCV

// Usage:
//
// First, you need some face images. I used the ORL face database.
// You can download it for free at
//    www.cl.cam.ac.uk/research/dtg/attarchive/facedatabase.html
//
// List the training and test face images you want to use in the
// input files train.txt and test.txt. (Example input files are provided
// in the download.) To use these input files exactly as provided, unzip
// the ORL face database, and place train.txt, test.txt, and eigenface.exe
// at the root of the unzipped database.
//
// To run the learning phase of eigenface, enter
//    eigenface train
// at the command prompt. To run the recognition phase, enter
//    eigenface test


#include <stdio.h>
#include <string.h>
#include <time.h>
#include "cv.h"
#include "cvaux.h"
#include "highgui.h"
#include "svm.h"

#define SKIN_PIX_THRESH_PERCENT 70
#define TIME_DIFF_THRESHOLD 300
#define X_POS_THRESHOLD 50
#define Y_POS_THRESHOLD 50

//#define NEAREST_NEIGHBOR_THRESHOLD 2700000
#define NEAREST_NEIGHBOR_THRESHOLD 1250000
#define NORM_THRESHOLD 3000
#define MAX_FACES 1000
#define THUMB_WIDTH (134 * 2)
#define THUMB_HEIGHT (110 * 2)
#define SMALL_THUMB_WIDTH 90
#define SMALL_THUMB_HEIGHT 48
#define SCALING_RATIO 1.2
#define ADDED_TIME 100
#define PLAY_ICON_STRENGTH 150


//#define TEST_MOVIE_PATH "C:\\rails\\dreamline\\Dreamline\\public\\videos\\000\\000\\261\\10150536855063645_28017.mp4"
#define TEST_MOVIE_PATH "C:\\TestData\\Movies\\pesach.avi"
//#define TEST_MOVIE_PATH "C:\\TestData\\Movies\\7_xvid.avi"
//#define TEST_MOVIE_PATH "C:\\TestData\\Movies\\Mika_xvid.avi"
#define FRAMES_TO_SKIP 0
/* Macros to get the max/min of 3 values */
#define MAX3(r,g,b) ((r)>(g)?((r)>(b)?(r):(b)):((g)>(b)?(g):(b)))
#define MIN3(r,g,b) ((r)<(g)?((r)<(b)?(r):(b)):((g)<(b)?(g):(b)))

#define MIN_FACE_SIZE 35
#define EXTRA_FRAME_SIZE 5
#define LBP_RAD 3.25
#define STANDARD_IMG_DIM_X (115 + 2 * EXTRA_FRAME_SIZE)
#define STANDARD_IMG_DIM_Y (105 + 2 * EXTRA_FRAME_SIZE)
#define LBP_ROWS 5
#define LBP_COLS 5
#define PCT_EXTRA_FACE_IMG_PIXELS 30
#define PIXEL_LBP_NOISE_THRESH 3
#define NOISE_PIX_VAL 0xAA
#define LBP_DIST_THRESH 4
#define OVERLAP_REGION_THRESH 50
#define AREA_SIZE_THRESH 2
#define DESC_SIZE gHistSize * LBP_ROWS * LBP_COLS
#define LFW_FILE "C:\\TestData\\pairsDevTest.txt"
#define LFW_LIB "C:\\TestData\\lfw2"
#define RES_FILE "c:\\TestOutputs\\lfw_res.txt"
#define MAX_DESCRIPTORS 50

struct DlTimeSegment
{
	int start_time;
	int end_time;
};

struct DlFaceAndTime
{
	bool skip;
	int id;
	char pathToSave[1024];
	char pathToThumb[1024];
	IplImage *face[MAX_DESCRIPTORS];
	IplImage *StandardizedFaces[20];
	float *eigenVecs[20];
	int numOfFacesFound;
	CvRect location;
	int numOfTimeSegments;
	DlTimeSegment timeSegments[100];
	int lastTimeStamp;
	bool lastSegmentClosed;
	int *LBPDescriptor[MAX_DESCRIPTORS];
	int bestFaceId;

};
//// Global variables

//Eigen faces
IplImage ** faceImgArr        = 0; // array of face images
CvMat    *  personNumTruthMat = 0; // array of person numbers
int nTrainFaces               = 0; // the number of training images
int nEigens                   = 0; // the number of eigenvalues
IplImage * pAvgTrainImg       = 0; // the average image
IplImage ** eigenVectArr      = 0; // eigenvectors
CvMat * eigenValMat           = 0; // eigenvalues
CvMat * projectedTrainFaceMat = 0; // projected training faces


//Face detection
// Create memory for calculations
CvMemStorage* storage;
//faces for computation
IplImage ** faces;
// avg eigen face
bool isInitialized;
// Haar classifier for face detection
CvHaarClassifierCascade* cascade;

//Faces and time segments
DlFaceAndTime dlFaces[MAX_FACES];
int numOfDlFaces;
int curNumTrainFaces;
IplImage * playIcon;
svm_model *gSvmModel;

//lbp
uchar lbp_lu[256];
uchar gHistTable_lu[256];
int gHistSize;


//// Function prototypes
void learn();
void recognize();
void doPCA();
void storeTrainingData();
int  loadTrainingData(CvMat ** pTrainPersonNumMat);
int  findNearestNeighbor(float * projectedTestFace);
int  loadFaceImgArray(char * filename);
void printUsage();
void myLearn();
bool cropImage(IplImage *src, IplImage *dst, int x, int y);
bool cropImage(IplImage *src, IplImage **dst, CvRect roi);
void  addStartSegment(int time, DlFaceAndTime &fandt);
void addEndTime(int time, DlFaceAndTime &fandt);
int findNearestNeighbor(float *testVec, double threshold);
void setEigenVecsToDlFaces();
int findTotalNumOfFaces();
void fillFaceImgArr();
void doTheEigenFaces();
int recognizeAndAddFace(IplImage *inputImg, float *projectedVec);
void standardizeImage(IplImage *inputImg, IplImage **outputImg,  int width, int height);
int findSimilarFaceNum (IplImage *img, DlFaceAndTime *faces, int timeCount, CvRect *location);
int skinColorPixelsCounter(IplImage *img, int skinPixelsThreshold);
bool isSkinPixelsInImg(IplImage *img, int skinPixelsThreshold);
void detectFace( IplImage* img, CvSeq** outSec, bool scaleDown);
void saveFacesToDiskAndGetTimeStamps(CvCapture* movieClip, 
	char *outputPath, int minPixels, int timeDelta, bool scaleDown);
void Dreamline(char *movieClipPath, char *outputPath, char *haarClassifierPath, char *ThumbPath, char *smallThumbPath, char *playSymbol);
void saveToXML(char *outputPath);
void embedSymbolOnImgCenter(IplImage *img, IplImage *symbol);
void createThumbAndIcon(const IplImage *img, IplImage **thumb);
void doLBP(IplImage *src, int *dscriptor);
void createLBPLookup(unsigned char *arr);
void createLBPImage(IplImage *src, IplImage *dst);
int initHistTableLookup();
void createDescriptor(IplImage *lbpSrc, int *desc);
bool isOverlappingEnough(CvRect r1, CvRect r2);
int findLbpNearestNeighbor(CvMat *lbpDesc);
void addToDlFacesVec(IplImage *img, int timestamp, char *outputPath, char *thumbPath, CvRect location, CvMat *lbpDesc = NULL);
void printDescriptor(int *descriptor);
double hellingerDist(int *desc1, int *desc2, int size);
uchar getLbpPixelVal(IplImage *img, int x, int y);
uchar getLbpPixelVal(IplImage *img, int x, int y, double rad);
double bilinearInterp(IplImage *img, double x, double y, double badVal = -999);
bool isSameFace(DlFaceAndTime& face1, DlFaceAndTime& face2);
bool tryAddFace(IplImage *face, DlFaceAndTime& dlFace);
void uniqueOnFaces();
void writeFacesToDisk(char *imageDirectory);



static const double pi = 3.14159265358979323846;

#define BYTETOBINARY(byte)  \
  (byte & 0x80 ? 1 : 0), \
  (byte & 0x40 ? 1 : 0), \
  (byte & 0x20 ? 1 : 0), \
  (byte & 0x10 ? 1 : 0), \
  (byte & 0x08 ? 1 : 0), \
  (byte & 0x04 ? 1 : 0), \
  (byte & 0x02 ? 1 : 0), \
  (byte & 0x01 ? 1 : 0) 
 


#ifndef LBT_TESTS

const char *testFacesFiles[19] = { "C:\\TestData\\my_LFW\\Al_Pacino_0001.jpg", 
	"C:\\TestData\\my_LFW\\Al_Pacino_0003.jpg",
	"C:\\TestData\\my_LFW\\Alan_Greenspan_0002.jpg",
	"C:\\TestData\\my_LFW\\Alan_Greenspan_0003.jpg",
	"C:\\TestData\\my_LFW\\Alec_Baldwin_0002.jpg",
	"C:\\TestData\\my_LFW\\Alec_Baldwin_0004.jpg",
	"C:\\TestData\\my_LFW\\Angelina_Jolie_0001.jpg",
	"C:\\TestData\\my_LFW\\Angelina_Jolie_0002.jpg",
	"C:\\TestData\\my_LFW\\Angelina_Jolie_0007.jpg",
	"C:\\TestData\\my_LFW\\Angelina_Jolie_0016.jpg",
	"C:\\TestData\\my_LFW\\Angelina_Jolie_0020.jpg",
	"C:\\TestData\\my_LFW\\Barbra_Streisand_0001.jpg",
	"C:\\TestData\\my_LFW\\Barbra_Streisand_0003.jpg",
	"C:\\TestData\\my_LFW\\Bill_Gates_0001.jpg",
	"C:\\TestData\\my_LFW\\Bill_Gates_0005.jpg",
	"C:\\TestData\\my_LFW\\Abdullah_Gul_0001.jpg",
	"C:\\TestData\\my_LFW\\Abdullah_Gul_0005.jpg",
	"C:\\TestData\\my_LFW\\Abdullah_Gul_0012.jpg",
	"C:\\TestData\\my_LFW\\Abdullah_Gul_0013.jpg",
};

typedef struct 
{
	char filename1[256];
	char filename2[256];
	int *desc1;
	int *desc2;
	double distance;
} LfwPair;

double lbpSubTest(std::vector<LfwPair> *pairs);
void getImgDescriptor(IplImage *img, int *desc, IplImage **face);
void trainSVM(const std::vector<LfwPair>& matchGroup, const std::vector<LfwPair>& unmatchGroup);
void findSvmMinMax(const std::vector<LfwPair>& matchGroup, const std::vector<LfwPair>& unmatchGroup, double *min, double *max);
void runSvmTestPrediction(const std::vector<LfwPair>& matchGroup, const std::vector<LfwPair>& unmatchGroup);


void parseLFWTest(char *filename, char *imglib, std::vector<LfwPair> *matchingPairs, std::vector<LfwPair> *unmatchingPairs)
{
	char fname1[256];
	char fname2[256];
	char num1[16];
	char num2[16];
	FILE *file = fopen(filename, "r");
	char line[1024];
	fgets(line, 1024, file);
	fgets(line, 1024, file);
	for (int i = 0 ; line != NULL && i < 500 ;   i)
 	{
 		char *token;
 		token = strtok(line, " \t");
 		char *facename;
 		LfwPair pair;
 		strcpy(fname1, token);
 		token = strtok(NULL, " \t");
 		strcpy(num1, token);
 		token = strtok(NULL, " \t");
 		strcpy(num2, token);
 		sprintf(pair.filename1,"%s\\%s\\%s_%.4d.jpg", imglib, fname1, fname1, atoi(num1));
 		sprintf(pair.filename2,"%s\\%s\\%s_%.4d.jpg", imglib, fname1, fname1, atoi(num2));
 		matchingPairs->push_back(pair);
 		fgets(line, 1024, file);
 	}
 	for (int i = 0 ; line != NULL && i < 500 ;   i)
 	{
 		char *token;
 		token = strtok(line, " \t");
 		char *facename;
 		LfwPair pair;
 		strcpy(fname1, token);
 		token = strtok(NULL, " \t");
 		strcpy(num1, token);
 		token = strtok(NULL, " \t");
 		strcpy(fname2, token);
 		token = strtok(NULL, " \t");
 		strcpy(num2, token);
 		sprintf(pair.filename1,"%s\\%s\\%s_%.4d.jpg", imglib, fname1, fname1, atoi(num1));
 		sprintf(pair.filename2,"%s\\%s\\%s_%.4d.jpg", imglib, fname2, fname2, atoi(num2));
 		unmatchingPairs->push_back(pair);
 		fgets(line, 1024, file);
 	}

	fclose(file);
}

void lbpTest2()
{
	std::vector<LfwPair> matching;
	std::vector<LfwPair> unmatching;
	parseLFWTest(LFW_FILE, LFW_LIB, &matching, &unmatching);
	storage = cvCreateMemStorage(0);
	cascade = (CvHaarClassifierCascade*)cvLoad( "C:\\OpenCV2.2\\data\\haarcascades\\haarcascade_frontalface_alt_tree.xml", 0, 0, 0 );
	createLBPLookup(lbp_lu);
	initHistTableLookup();
	double matchingAvg = lbpSubTest(&matching);
	double unmatchingAvg = lbpSubTest(&unmatching);
	trainSVM(matching, unmatching);
	runSvmTestPrediction(matching, unmatching);
	printf("\n******************\nscore for matching = %f\nscore for unmatching = %f\n******************\n", matchingAvg, unmatchingAvg);
	FILE *resFile = fopen(RES_FILE, "w");
	for (int i = 0 ; i < matching.size() ; i++)
	{
		fprintf(resFile, "%s_%s\t%f\n", matching[i].filename1, matching[i].filename2, matching[i].distance);
	}
	for (int i = 0 ; i < matching.size() ; i++)
	{
		fprintf(resFile, "%s_%s\t%f\n", unmatching[i].filename1, unmatching[i].filename2, unmatching[i].distance);
	}
}

double lbpSubTest(std::vector<LfwPair> *pairs)
{
	double sum = 0;
	for (int i = 0 ; i < (*pairs).size() ; ++i)
	{
		int *desc1 = new int[DESC_SIZE];
		int *desc2 = new int[DESC_SIZE];
		IplImage *img1 = cvLoadImage((*pairs)[i].filename1, CV_LOAD_IMAGE_GRAYSCALE);
		IplImage *img2 = cvLoadImage((*pairs)[i].filename2, CV_LOAD_IMAGE_GRAYSCALE);
		IplImage *face1;
		IplImage *face2;
		getImgDescriptor(img1, desc1, &face1);
		getImgDescriptor(img2, desc2, &face2);
		(*pairs)[i].distance = hellingerDist(desc1, desc2, DESC_SIZE);
		sum += (*pairs)[i].distance;
	}
	return sum / (*pairs).size();
}

void getImgDescriptor(IplImage *img, int *desc, IplImage **face)
{
	CvSeq *faces;
	detectFace(img, &faces, false);
	IplImage *workImg;
	bool relImg = true;
	if (faces->total == 0)
	{
		relImg = false;
		workImg = img;
	}
	else
	{
		CvRect *faceRoi = (CvRect*)cvGetSeqElem(faces, 0);
		int extraPixW = (int)((double)faceRoi->width * PCT_EXTRA_FACE_IMG_PIXELS / 100);
		int extraPixH = (int)((double)faceRoi->height * PCT_EXTRA_FACE_IMG_PIXELS / 100);
		CvRect roi = cvRect(faceRoi->x - extraPixW > 0 ? faceRoi->x - extraPixW : 0,
			faceRoi->y - extraPixH > 0 ? faceRoi->y - extraPixH : 0,
			faceRoi->width + faceRoi->x + extraPixW < img->width ? faceRoi->width + extraPixW * 2 : img->width - faceRoi->x + extraPixW,
			faceRoi->height + faceRoi->y + extraPixH < img->height ? faceRoi->height + extraPixH * 2 : img->height - faceRoi->y + extraPixH);

		cropImage(img, &workImg, roi);
	}
	*face = workImg;
	IplImage *standardized;
	standardizeImage(workImg, &standardized, STANDARD_IMG_DIM_X, STANDARD_IMG_DIM_Y);
	doLBP(standardized, desc);
	//if (relImg) cvReleaseImage(&workImg);
	cvReleaseImage(&standardized);
}

void lbpTest()
{
	storage = cvCreateMemStorage(0);
	cascade = (CvHaarClassifierCascade*)cvLoad( "C:\\OpenCV2.2\\data\\haarcascades\\haarcascade_frontalface_alt_tree.xml", 0, 0, 0 );
	createLBPLookup(lbp_lu);
	initHistTableLookup();
	for (int i = 0 ; i < 256 ; i++)
	{
		printf("%d, %d, %d%d%d%d%d%d%d%d\t%d%d%d%d%d%d%d%d\n ", i, (int)lbp_lu[i],  BYTETOBINARY(i),  BYTETOBINARY(lbp_lu[i]));
	}
	printf("----------------------ghistsize=%d\n", gHistSize);
	int *descs[19];
	//IplImage *bwimg = cvLoadImage("c:\\TestData\\squretest.tif", CV_LOAD_IMAGE_GRAYSCALE);
	//int *d = new int[DESC_SIZE];
	//doLBP(bwimg, d);
	//printDescriptor(d);
	for (int i = 0 ; i < 19 ; ++i)
	{
		IplImage *img = cvLoadImage(testFacesFiles[i], CV_LOAD_IMAGE_GRAYSCALE);
		CvSeq *faces;
		detectFace(img, &faces, false);
		IplImage *workImg;
		if (faces->total == 0)
		{
			printf("error, couldnt find image in %d) %s\n", i, testFacesFiles[i]);
			workImg = img;
		}
		else
		{
			CvRect *faceRoi = (CvRect*)cvGetSeqElem(faces, 0);
			int extraPixW = (int)((double)faceRoi->width * PCT_EXTRA_FACE_IMG_PIXELS / 100);
			int extraPixH = (int)((double)faceRoi->height * PCT_EXTRA_FACE_IMG_PIXELS / 100);
			CvRect roi = cvRect(faceRoi->x - extraPixW > 0 ? faceRoi->x - extraPixW : 0,
				faceRoi->y - extraPixH > 0 ? faceRoi->y - extraPixH : 0,
				faceRoi->width + faceRoi->x + extraPixW < img->width ? faceRoi->width + extraPixW * 2 : img->width - faceRoi->x + extraPixW,
				faceRoi->height + faceRoi->y + extraPixH < img->height ? faceRoi->height + extraPixH * 2 : img->height - faceRoi->y + extraPixH);

			cropImage(img, &workImg, roi);
		}
		descs[i] = new int[DESC_SIZE];
		IplImage *standardized;
		printf("%d) ",i);
		standardizeImage(workImg, &standardized, STANDARD_IMG_DIM_X, STANDARD_IMG_DIM_Y);
		char fn[256];
		sprintf(fn,"C:\\TestOutputs\\%d.jpg", i);
		cvSaveImage(fn, standardized);
		doLBP(standardized, descs[i]);
		printDescriptor(descs[i]);
		//cvReleaseImage(&workImg);
	}
	
	for (int i = 0 ; i < 19 ; ++i)
	{
		printf("\n-------------------------------------------------------\n");
		for (int j = 0 ; j < 19 ; ++j)
		{
			double dist = hellingerDist(descs[i], descs[j], DESC_SIZE);
			if (dist < LBP_DIST_THRESH) printf("%d)%s --- %d)%s:\t %f\n", i, testFacesFiles[i], j, testFacesFiles[j], dist);
		}
	}
}
#endif

#ifndef REGION_MAIN
int main( int argc, char** argv )
{
	// validate that an input was specified
	if( argc < 2 )
	{
		printUsage();
		return 0;
	}

	if( !strcmp(argv[1], "train") ) learn();
	else if ( !strcmp(argv[1], "test") ) recognize();
	else if ( !strcmp(argv[1], "lbpTest")) lbpTest2(); 
	else if ( !strcmp(argv[1], "dreamline_test") ) Dreamline(TEST_MOVIE_PATH, 
		"C:\\TestOutputs", "C:\\OpenCV2.2\\data\\haarcascades\\haarcascade_frontalface_alt_tree.xml", "C:/TestOutputs/tn.jpg", "C:/TestOutputs/tn_s.jpg", "C:/ISoftware/play_icon.tif");
	else if ( !strcmp(argv[1], "Dreamline") && argc < 4 ) Dreamline( argv[2], argv[3], 
		"./haarcascades/haarcascade_frontalface_alt_tree.xml", NULL, NULL, NULL);
	else if ( !strcmp(argv[1],  "Dreamline") && argc < 5 ) Dreamline( argv[2], argv[3],argv[4], NULL, NULL, NULL);
	//args: 2 = input path, 3 = output dir, 4 = haar cascade, 5 = thumbnale path
	else if ( !strcmp(argv[1], "Dreamline") ) Dreamline( argv[2], argv[3],argv[4], argv[5], argv[6], argv[7]);

	else
	{
		printf("Unknown command: %s\n", argv[1]);
		printUsage();
	}

	return 0;
}


void printTimeDiffFromNow(int t1)
{

	int diff = abs (clock() - t1);	
	int diff_tmp_seconds = ((long)diff / 1000);

	int diff_tmp_minutes = (int)(diff_tmp_seconds / 60);
	int diff_minutes = (diff_tmp_minutes % 60);
	int diff_hours = (diff_tmp_minutes / 60);

	//printf("%02d:%02d:%02d:%f-----%f\n", diff_hours, diff_minutes, diff_seconds,((double)absDiff - (double)diff_seconds - (double)diff_hours - (double)diff_minutes) * 1000, diff);
	printf("%d,%03d\n", diff / 1000, diff % 1000);
}

void Dreamline(char *movieClipPath, char *outputPath, char *haarClassifierPath, char *thumbPath, char *smallThumbPath, char *playSymbol)
{

	createLBPLookup(lbp_lu);
	for (int i = 0 ; i < 256 ; i++)
	{
		printf("%d, %d, %d%d%d%d%d%d%d%d\t%d%d%d%d%d%d%d%d\n ", i, (int)lbp_lu[i],  BYTETOBINARY(i),  BYTETOBINARY(lbp_lu[i]));
	}
	initHistTableLookup();
	//printf("%d", findNumOfUniqueVals());
	if (!movieClipPath || strlen(movieClipPath) < 2)
	{
		printf("error in input path");
		return;
	}
	int start = clock();
	char *filename = movieClipPath;
	CvCapture* cap  = cvCreateFileCapture(filename);
	if (cap == NULL)
	{
		printf("error in input file");
		exit(-1);
	}
	printf("starting the run");
	storage = cvCreateMemStorage(0);
	cascade = (CvHaarClassifierCascade*)cvLoad( haarClassifierPath, 0, 0, 0 );
	if (playSymbol != NULL)
	{
		playIcon = cvLoadImage(playSymbol, 1);
		//cvCmpS(playIcon, 127, playIcon, CV_CMP_GT);
	}
	if (thumbPath && strlen(thumbPath) > 0)
	{
		IplImage *thumb = cvCreateImage(cvSize(THUMB_WIDTH, THUMB_HEIGHT), IPL_DEPTH_8U, 3);
		IplImage *frm = cvQueryFrame(cap);
		if (frm)
		{
			double heigtWidthRatio = (double)frm->width / (double)frm->height;
			if (heigtWidthRatio < 1)
			{
				createThumbAndIcon(frm, &thumb);
				//IplImage *tmpThumb = cvCreateImage(cvSize(THUMB_WIDTH, frm->height * THUMB_WIDTH / frm->width), IPL_DEPTH_8U, 3);
				//cvResize(frm, tmpThumb);
				//cvSetImageROI(tmpThumb, cvRect(0, 0, THUMB_WIDTH, THUMB_HEIGHT));
				//cvCopyImage(tmpThumb, thumb);
				//embedSymbolOnImgCenter(thumb, playIcon);
				//cvReleaseImage(&tmpThumb);
			}
			else
			{
				cvResize(frm, thumb);
				embedSymbolOnImgCenter(thumb, playIcon);
			}
			
			cvSaveImage(thumbPath, thumb);
			if (smallThumbPath && strlen(smallThumbPath) > 0)
			{
				IplImage *thumb_s = cvCreateImage(cvSize(SMALL_THUMB_WIDTH, SMALL_THUMB_HEIGHT), IPL_DEPTH_8U, 3);
				cvSetImageROI(thumb, cvRect((THUMB_WIDTH - SMALL_THUMB_WIDTH) / 2, (THUMB_HEIGHT - SMALL_THUMB_HEIGHT) / 2, SMALL_THUMB_WIDTH, SMALL_THUMB_HEIGHT));
				cvCopyImage(thumb, thumb_s);
				cvSaveImage(smallThumbPath, thumb_s);
				cvReleaseImage(&thumb_s);
			}
		}
		
		cvReleaseImage(&thumb);

	}
	saveFacesToDiskAndGetTimeStamps(cap, outputPath, 3, 1, false);
	uniqueOnFaces();
	writeFacesToDisk(outputPath);
	cvReleaseCapture(&cap);
	char outputFilePath[256];
	sprintf(outputFilePath, "%s/faces.xml", outputPath);
	printf("saving to xml");
	saveToXML(outputFilePath);
	time_t end = time(NULL);
	printf("entire process took:");
	printTimeDiffFromNow (start);
}
#endif

#ifndef REGION_LBP
////////////////////////////////////////////////////////////////  LBP  /////////////////////////////////////////////////////////////////////////

bool isLBPNoisePixels(uchar i)
{
	//return false;
	int noisey = 0;
	int prevVal = i & 1;
	for (int j = 0 ; j < 7 ; j++)
	{
		i >>= 1;
		if ((i & 1) != prevVal) noisey++;
		prevVal = i & 1;
		if (i == 0) break;
	}
	return noisey >= PIXEL_LBP_NOISE_THRESH;
}

int initHistTableLookup()
{
	for (int i = 0 ; i < 256; ++i) gHistTable_lu[i] = 0;
	for (int i = 0 ; i < 256 ; ++i)
	{
		gHistTable_lu[lbp_lu[i]]++;
	}
	gHistSize = 0;
	for (int i = 0 ; i < 256 ; ++i)
	{
		//printf("%d, %d\n", i, res[i]);
		if (gHistTable_lu[i]) gHistTable_lu[i] = gHistSize++;
	}
	return gHistSize;
}

void createLBPLookup(unsigned char *arr)
{
	gHistSize = 0;
	for (int i = 0 ; i < 256 ; i++) 
	{
#ifdef PERFORM_ROL	
		unsigned char maxval = i;
		unsigned char tester = i;
		for (int j = 0 ; j < 9 ; j++)
		{
			__asm
			{
				rol tester, 1
			}
			maxval = tester > maxval ? tester : maxval;
		}
		arr[i] = maxval;	
		if (isLBPNoisePixels(i))
		{
			arr[i] = NOISE_PIX_VAL;
		}
#else
		arr[i] = isLBPNoisePixels(i) ? 0 : ++gHistSize;	
#endif
	}
}

void printDescriptor(int *descriptor)
{
	printf("\n------------------------------------------------------\n");
	int checksum = 0;
	for (int i = 0 ; i < DESC_SIZE ; ++i)
	{
		checksum += descriptor[i];
		printf("%d, ", descriptor[i]);
		if (!((i+1) % gHistSize)) printf("\n\n");
	}
	printf(" cs=%d\n", checksum);
	printf("\n------------------------------------------------------\n");
}

void doLBP(IplImage *src, int *descriptor)
{
	IplImage *lbpImg = cvCreateImage(cvGetSize(src), IPL_DEPTH_8U, 1);
	createLBPImage(src, lbpImg);
	static int stammm = 0;
	//char tmp[256];
	//sprintf(tmp, "c:\\TestOutputs\\%d.tif", stammm++);
	//cvSaveImage(tmp, lbpImg);
	createDescriptor(lbpImg, descriptor);	
	cvReleaseImage(&lbpImg);
}

void createDescriptor(IplImage *lbpSrc, int *desc)
{
	for (int i = 0 ; i < DESC_SIZE ; ++i) desc[i] = 0; 
	int stepi = lbpSrc->height / LBP_ROWS;
	int stepj = lbpSrc->width /  LBP_COLS;
	for (int i = EXTRA_FRAME_SIZE ; i < lbpSrc->height - EXTRA_FRAME_SIZE ; ++i)
	{
		for (int j = EXTRA_FRAME_SIZE ; j < lbpSrc->width - EXTRA_FRAME_SIZE ; ++j)
		{
			
			int location = ((i - EXTRA_FRAME_SIZE) / stepi * LBP_COLS + (j - EXTRA_FRAME_SIZE) / stepj) * gHistSize;
			int lbpPlace =  ((uchar *)(lbpSrc->imageData + i * lbpSrc->widthStep))[j];
			//printf("[%d,%d] - %d - %d - %d - %d - %d - %d\n", i, j, i / stepi, j / stepj, i / stepi + j / stepj,  location, lbpPlace, location + lbpPlace);
			desc[location + lbpPlace]++;
		}
	}
}


void createLBPImage(IplImage *src, IplImage *dst)
{
	cvZero(dst);
	for (int i = EXTRA_FRAME_SIZE ; i < src->height - EXTRA_FRAME_SIZE ; ++i)
	{
		for (int j = EXTRA_FRAME_SIZE ; j < src->width - EXTRA_FRAME_SIZE ; ++j)
		{ 
			((uchar *)(dst->imageData + i * dst->widthStep))[j] = getLbpPixelVal(src, j, i, LBP_RAD); 
		}
	}
}

uchar getLbpPixelVal(IplImage *img, int x, int y)
{
	uchar pixVal = ((uchar *)(img->imageData + y*img->widthStep))[x];
	uchar val = 0;
	val = ((uchar *)(img->imageData + (y - 1)	* img->widthStep))[x - 1] < pixVal	? (val | 0x1)  : val;
	val = ((uchar *)(img->imageData + (y - 1)	* img->widthStep))[x]	  < pixVal	? (val | 0x2)  : val;
	val = ((uchar *)(img->imageData + (y - 1)   * img->widthStep))[x + 1] < pixVal	? (val | 0x4)  : val;
	val = ((uchar *)(img->imageData + (y)		* img->widthStep))[x - 1] < pixVal	? (val | 0x8)  : val;
	val = ((uchar *)(img->imageData + (y)		* img->widthStep))[x + 1] < pixVal	? (val | 0x10) : val;
	val = ((uchar *)(img->imageData + (y + 1)	* img->widthStep))[x - 1] < pixVal	? (val | 0x20) : val;
	val = ((uchar *)(img->imageData + (y + 1)	* img->widthStep))[x]	  < pixVal	? (val | 0x40) : val;
	val = ((uchar *)(img->imageData + (y + 1)	* img->widthStep))[x + 1] < pixVal	? (val | 0x80) : val;
	return lbp_lu[val];
}

uchar getLbpPixelVal(IplImage *img, int x, int y, double rad)
{
	uchar val = 0;
	for (double i = 0 ; i < 2*pi ; i = i + (2 * pi / 8))
	{
		double dx = -rad * sin(i);
		double dy = rad * cos(i);
		double pixval = ((uchar *)(img->imageData + y*img->widthStep))[x];
		double otherVal = bilinearInterp(img, x + dx, y + dy);
		if (pixval > otherVal) val |= 1;
		val <<= 1;
	}
	return lbp_lu[val];
}

int findLbpNearestNeighbor(int *lbpDesc)
{
	double minDist = 10000000; 
	int bestMatch = -1;
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		double dist = hellingerDist(lbpDesc, dlFaces[i].LBPDescriptor[0], DESC_SIZE);
		//printDescriptor(lbpDesc);
		//printDescriptor(dlFaces[i].LBPDescriptor);
		printf("the dist is %f\n", dist);
		if (dist < LBP_DIST_THRESH && dist < minDist)
		{
			minDist = dist;
			bestMatch = i;
		}
	}
	return bestMatch;
}

void trainSVM(const std::vector<LfwPair>& matchGroup, const std::vector<LfwPair>& unmatchGroup)
{
	double minval;
	double maxval;
	findSvmMinMax(matchGroup, unmatchGroup, &minval, &maxval);
	svm_problem problem;
	problem.l = matchGroup.size() + unmatchGroup.size();
	problem.x = new svm_node *[problem.l];
	problem.y = new double[problem.l];
	for (int i = 0 ; i < problem.l ; ++i)
	{
		problem.x[i] = new svm_node[2];
	}
	for (int i = 0 ; i < matchGroup.size() ; ++i)
	{
		problem.x[i][0].index = 0;
		problem.x[i][1].index = -1;
		problem.x[i][0].value = (matchGroup[i].distance - minval) / maxval;
		problem.y[i] = 1;
	}
	for (int i = 0 ; i < unmatchGroup.size() ; ++i)
	{
		problem.x[matchGroup.size() + i][0].index = 0;
		problem.x[matchGroup.size() + i][1].index = -1;
		problem.x[matchGroup.size() + i][0].value = (unmatchGroup[i].distance - minval) / maxval;
		problem.y[matchGroup.size() + i] = -1;
	}
	svm_parameter param;
	param.probability = 0;
	param.eps = 0.00000001;
	param.shrinking = 0;
	param.C = 1000;
	param.kernel_type = LINEAR;
	param.svm_type = C_SVC;
	param.cache_size = 1000;
	gSvmModel = svm_train(&problem, &param);
}

void runSvmTestPrediction(const std::vector<LfwPair>& matchGroup, const std::vector<LfwPair>& unmatchGroup)
{
	double minval;
	double maxval;
	findSvmMinMax(matchGroup, unmatchGroup, &minval, &maxval);
	svm_node nodes[2];
	double res = 0;
	int correct = 0;
	for (int i = 0 ; i < matchGroup.size() ; ++i)
	{
		nodes[0].index = 0;
		nodes[0].value = (matchGroup[i].distance - minval) / maxval;
		nodes[1].index = -1;
		
		if (svm_predict(gSvmModel, nodes) == 1) correct++;
	}
	printf("**************\nmatch res=%f\n", (double)correct / (double)matchGroup.size());
	correct = 0;
	for (int i = 0 ; i < unmatchGroup.size() ; ++i)
	{
		nodes[0].index = 0;
		nodes[0].value = (unmatchGroup[i].distance - minval) / maxval;
		nodes[1].index = -1;
		if (svm_predict(gSvmModel, nodes) == -1) correct++;
	}
	printf("unmatch res=%f\n**************\n", (double)correct / (double)unmatchGroup.size());
}

void findSvmMinMax(const std::vector<LfwPair>& matchGroup, const std::vector<LfwPair>& unmatchGroup, double *min, double *max)
{
	*min = 100000000;
	*max = -100000000;
	for (int i = 0 ; i < matchGroup.size() ; ++i)
	{
		*max = matchGroup[i].distance > *max ? matchGroup[i].distance : *max; 
		*min = matchGroup[i].distance < *min ? matchGroup[i].distance : *min;
	}
	for (int i = 0 ; i < unmatchGroup.size() ; ++i)
	{
		*max = unmatchGroup[i].distance > *max ? unmatchGroup[i].distance : *max; 
		*min = unmatchGroup[i].distance < *min ? unmatchGroup[i].distance : *min;
	}
}
/////////////////////////////////////////////////////////////  LBP end /////////////////////////////////////////////////////////
#endif

#ifndef REGION_GENERAL

/////////////////////////////////////////////General functions///////////////////////////////////////////////
double hellingerDist(int *desc1, int *desc2, int size)
{
	double dist = 0;
	for (int i = 0; i < size ; ++i)
	{
		double tmp = sqrt((double)desc1[i]) - sqrt((double)desc2[i]);
		dist += tmp * tmp;
	}
	return sqrt(dist);
}

double bilinearInterp(IplImage *img, double x, double y, double badVal)
{
	double epsi = 0.000000000001;
	if (x > epsi)
		x = x - epsi;
	if (y > epsi)
		y = y - epsi;

	int round_y = (int)floor(y);
	int round_x = (int)floor(x);
	y = y - (double)round_y;
	x = x - (double)round_x;
	double one_minus_y = 1 - y;
	double one_minus_x = 1 - x;
	double resval = 0;
	if (round_y < 0 || round_y >= img->height || round_x < 0 || round_x >= img->width - 1)
		return (resval);

	double patch_1_1 = cvGet2D(img,	round_y,	round_x		).val[0];
	double patch_1_2 = cvGet2D(img,	round_y,	round_x+1	).val[0];
	double patch_2_1 = cvGet2D(img,	round_y+1,	round_x		).val[0];
	double patch_2_2 = cvGet2D(img,	round_y+1,	round_x+1	).val[0];
	if ((patch_1_1 == badVal) || (patch_1_2 == badVal) || 
		(patch_2_2 == badVal) || (patch_2_1 == badVal))
	{
		return badVal;
	}

	resval = patch_1_1 * one_minus_y * one_minus_x + 
		patch_2_1 * y * one_minus_x + patch_1_2 * one_minus_y * x + patch_2_2 * y * x;
	return (resval);
}


CvRect intersect(CvRect r1, CvRect r2)
{
	CvRect intersection;

	// find overlapping region
	intersection.x = (r1.x < r2.x) ? r2.x : r1.x;
	intersection.y = (r1.y < r2.y) ? r2.y : r1.y;
	intersection.width = (r1.x + r1.width < r2.x + r2.width) ?
		r1.x + r1.width : r2.x + r2.width;
	intersection.width -= intersection.x;
	intersection.height = (r1.y + r1.height < r2.y + r2.height) ?
		r1.y + r1.height : r2.y + r2.height;
	intersection.height -= intersection.y;

	// check for non-overlapping regions
	if ((intersection.width <= 0) || (intersection.height <= 0)) {
		intersection = cvRect(0, 0, 0, 0);
	}
	return intersection;
}

bool isOverlappingEnoughAndNotTooBig(CvRect r1, CvRect r2)
{

	double area1 = r1.width * r1.height;
	double area2 = r2.height * r2.width;
	CvRect inter = intersect(r1, r2);
	double areaInter = inter.height * inter.width;
	//printf("%f\t%f\t%f\t%f percent\t%f diff\n", area1, area2, areaInter, areaInter / area1 * 100, area2 / area1);
	return (areaInter / area1 * 100 > OVERLAP_REGION_THRESH) && (area2 / area1 < AREA_SIZE_THRESH);
}


void createThumbAndIcon(const IplImage *img, IplImage **thumb)
{
	*thumb = cvCreateImage(cvSize(THUMB_WIDTH, THUMB_HEIGHT), IPL_DEPTH_8U, 3);
	IplImage *tmpThumb = cvCreateImage(cvSize(THUMB_WIDTH, img->height * THUMB_WIDTH / img->width), IPL_DEPTH_8U, 3);
	cvResize(img, tmpThumb);
	cvSetImageROI(tmpThumb, cvRect(0, 0, THUMB_WIDTH, THUMB_HEIGHT));
	cvCopyImage(tmpThumb, *thumb);
	embedSymbolOnImgCenter(*thumb, playIcon);
	cvReleaseImage(&tmpThumb);
}

void embedSymbolOnImgCenter(IplImage *img, IplImage *symbol)
{
	int x = img->width / 2 - symbol->width / 2;
	int y = img->height /2 - symbol->height / 2;
	cvSetImageROI(img, cvRect(x, y, symbol->width, symbol->height));
	cvAdd(img, symbol, img); 
	cvResetImageROI(img);
}

void addStartSegment(int time, DlFaceAndTime &fandt)
{
	if (fandt.timeSegments[fandt.numOfTimeSegments - 1].end_time > time)
	{
		fandt.timeSegments[fandt.numOfTimeSegments - 1].end_time = time + ADDED_TIME;
	}
	else
	{
		fandt.timeSegments[fandt.numOfTimeSegments].start_time = time;
		fandt.timeSegments[fandt.numOfTimeSegments].end_time = time + ADDED_TIME;
		fandt.numOfTimeSegments++;
		fandt.lastTimeStamp = time;
		fandt.lastSegmentClosed = false;
	}
}

void addEndTime(int time, DlFaceAndTime &fandt)
{
	fandt.timeSegments[fandt.numOfTimeSegments - 1].end_time = time;
	fandt.lastTimeStamp = time;
}

bool cropImage(IplImage *src, IplImage *dst, int x, int y)
{
	if (x < 0 || y < 0 || (x + dst->width) >= src->width || (y + dst->height) >= src->height)
		return false;
	CvRect rect = cvRect(x, y, dst->width, dst->height);
	cvSetImageROI(src, rect);
	cvCopy(src, dst);
	cvResetImageROI(src);
	return true;
}

bool cropImage(IplImage *src, IplImage **dst, CvRect roi)
{
	*dst = cvCreateImage(cvSize(roi.width, roi.height), src->depth, src->nChannels);
	return cropImage(src, *dst, roi.x, roi.y);
}

void uniteDlFaces(int dlfaceNum1, int dlFaceNum2)
{
	if (dlFaces[dlfaceNum1].lastTimeStamp < dlFaces[dlFaceNum2].lastTimeStamp)
	{
		for (int i = 0; i < dlFaces[dlFaceNum2].numOfTimeSegments ; ++i)
		{
			dlFaces[dlfaceNum1].timeSegments[dlFaces[dlfaceNum1].numOfTimeSegments++] = dlFaces[dlFaceNum2].timeSegments[i];
		}
		dlFaces[dlFaceNum2].skip = true;
	}
	else
	{
		for (int i = 0; i < dlFaces[dlfaceNum1].numOfTimeSegments ; ++i)
		{
			dlFaces[dlFaceNum2].timeSegments[dlFaces[dlFaceNum2].numOfTimeSegments++] = dlFaces[dlfaceNum1].timeSegments[i];
		}
		dlFaces[dlfaceNum1].skip = true;
	}
}
////////////////////////////////////////////////////////////////////////////////////////////////////
#endif


#ifndef REGION_MAIN_FUNCS
void uniqueOnFaces()
{
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		if (dlFaces[i].skip) continue;
		for (int j = i + 1 ; j < numOfDlFaces ; ++j)
		{
			if (isSameFace(dlFaces[i], dlFaces[j]))
			{
				if (dlFaces[j].skip) continue;
				uniteDlFaces(i, j);
			}
		}
	}
}

void writeFacesToDisk(char *imageDirectory)
{
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		if (!dlFaces[i].skip)
		{
			sprintf(dlFaces[i].pathToSave, "%s/aface_%d.jpg", imageDirectory, i);
			//sprintf(dlFaces[i].pathToThumb, "%s/thumb_%d.jpg", imageDirectory, i);
			cvSaveImage(dlFaces[i].pathToSave, dlFaces[i].face[dlFaces[i].bestFaceId]);
		}
	}
}

bool isSameFace(DlFaceAndTime& face1, DlFaceAndTime& face2)
{
	bool found = false;
	double minDist = 10000000000;
	for (int i = 0 ; i < face1.numOfFacesFound ; ++i)
	{
		for (int j = 0 ; j < face2.numOfFacesFound ; ++j)
		{
			double dist = hellingerDist(face2.LBPDescriptor[j], face1.LBPDescriptor[i], gHistSize);
			if (dist < LBP_DIST_THRESH && dist < minDist)
			{
				face1.bestFaceId = i;
				face2.bestFaceId = j;
				minDist = dist;
				found = true;
			}
		}
	}
	return found;
}

bool tryAddFace(IplImage *face, DlFaceAndTime& dlFace)
{
	if (dlFace.numOfFacesFound < MAX_DESCRIPTORS)
	{
		IplImage *workImg;
		standardizeImage(face, &workImg, STANDARD_IMG_DIM_X, STANDARD_IMG_DIM_Y);
		int *desc = new int[DESC_SIZE];
		doLBP(workImg, desc);
		dlFace.face[dlFace.numOfFacesFound] = face;
		dlFace.LBPDescriptor[dlFace.numOfFacesFound++] = desc;
		return true;
	}
	return false;
}

int findSimilarFaceNum (IplImage *img, DlFaceAndTime *faces, int timeCount, CvRect *location, int **lbpDesc)
{
	for (int i = numOfDlFaces - 1 ; i >= 0 ; --i)
	{ 
		//printf("time diff from %d is %d\n", i,  timeCount - faces[i].lastTimeStamp);
		if ( (timeCount - faces[i].lastTimeStamp) < TIME_DIFF_THRESHOLD
			&& isOverlappingEnoughAndNotTooBig(faces[i].location, *location))
		{
			faces[i].location = *location;
			addEndTime(timeCount, faces[i]);
			tryAddFace(img, faces[i]);
			return i;
		}
	}

	//add more face comparison logic here
	IplImage *workImg;
	standardizeImage(img, &workImg, STANDARD_IMG_DIM_X, STANDARD_IMG_DIM_Y);

	//lbp
	*lbpDesc = new int[DESC_SIZE];
	doLBP(workImg, *lbpDesc);
	return -1;//findLbpNearestNeighbor(*lbpDesc); switching to comparing only in the end

	//just compare the face to the one found
	//if (numOfDlFaces == 1)
	//{
	//	double images_diff = cvNorm(workImg, dlFaces[0].StandardizedFaces[0]);
	//	return (images_diff < NORM_THRESHOLD ? 0 : -1);
	//}
	//static int count = 0;
	//float *projectedVec;
	//int res = nTrainFaces > 1 ? recognizeAndAddFace(workImg, &projectedVec) : -1;
	////printf("_%d", res);
	//return res;
	/*char stam[256];
	sprintf(stam, "C:\\TestOutputs\\standard_%d.tif", count++);
	cvSaveImage(stam, workImg);
	cvReleaseImage(&workImg);*/
}

void detectFace( IplImage* img, CvSeq** outSec, bool scaleDown)
{
	static int i = 0;
	//int t = clock();
	int scale = scaleDown ? 2 : 1;
	IplImage* small_image = img;
	if( scaleDown )
	{
		small_image = cvCreateImage( cvSize(img->width * SCALING_RATIO, img->height * SCALING_RATIO), IPL_DEPTH_8U, 3 );
		cvResize( img, small_image);
		scale = 2;
	}
	//char stam[256];
	//sprintf(stam, "C:\\TestOutputs\\img_%d.tif", i++);
	//cvSaveImage(stam, small_image);
	// Create a new image based on the input image
	IplImage* temp = cvCreateImage( cvSize(small_image->width/scale,small_image->height/scale), 8, 3 );

	// Create two points to represent the face locations
	CvPoint pt1, pt2;

	// Clear the memory storage which was used before
	cvClearMemStorage( storage );

	// Find whether the cascade is loaded, to find the faces. If yes, then:
	if( cascade )
	{

		// There can be more than one face in an image. So create a growable sequence of faces.
		// Detect the objects and store them in the sequence
		*outSec = cvHaarDetectObjects( small_image, cascade, storage,
			1.2, 2, CV_HAAR_DO_CANNY_PRUNING,
			cvSize(MIN_FACE_SIZE, MIN_FACE_SIZE) );
	}

	if( scaleDown )
	{
		// Release the temp image created.
		cvReleaseImage( &small_image );
	}
	//printf("==========detect faces took ");
	//printTimeDiffFromNow(t);
}

void addToDlFacesVec(IplImage *img, int timestamp, char *outputPath, char *thumbPath, CvRect location, int *lbpDesc)
{
	DlFaceAndTime faceAndTime;
	faceAndTime.numOfFacesFound = 0;
	faceAndTime.numOfTimeSegments = 0;
	faceAndTime.bestFaceId = 0;
	faceAndTime.skip = false;
	faceAndTime.face[faceAndTime.numOfFacesFound] = img;
	addStartSegment(timestamp, faceAndTime);
	faceAndTime.lastTimeStamp = timestamp;
	faceAndTime.location = location;
	strcpy(faceAndTime.pathToSave, outputPath);
	faceAndTime.id = numOfDlFaces;
	strcpy(faceAndTime.pathToThumb, thumbPath);

	IplImage *standardizedImg;
	standardizeImage(img, &standardizedImg, STANDARD_IMG_DIM_X, STANDARD_IMG_DIM_Y);
	faceAndTime.StandardizedFaces[0] = standardizedImg;
	faceAndTime.LBPDescriptor[faceAndTime.numOfFacesFound++] = lbpDesc;


	dlFaces[numOfDlFaces] = faceAndTime;
	numOfDlFaces++;
}

void standardizeImage(IplImage *inputImg, IplImage **outputImg,  int width, int height)
{
	*outputImg = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 1);
	if (inputImg->nChannels > 1)
	{
		IplImage *tmpGrayImage = cvCreateImage(cvGetSize(inputImg), IPL_DEPTH_8U, 1);
		cvCvtColor(inputImg, tmpGrayImage, CV_BGR2GRAY );
		cvResize(tmpGrayImage, *outputImg, CV_INTER_NN);
	}
	else
	{
		cvResize(inputImg, *outputImg, CV_INTER_LINEAR);
	}
	//cvEqualizeHist(*outputImg, *outputImg);
}

void cropImageToFace(IplImage *img, IplImage **dst, CvRect *faceRect)
{
	int extraPixW = (int)((double)faceRect->width * PCT_EXTRA_FACE_IMG_PIXELS / 100);
	int extraPixH = (int)((double)faceRect->height * PCT_EXTRA_FACE_IMG_PIXELS / 100);
	int addedLeft = faceRect->x - extraPixW > 0 ? extraPixW : faceRect->x;
	int addedUp = faceRect->y - extraPixH > 0 ? extraPixH : faceRect->y;
	CvRect roi = cvRect(faceRect->x - extraPixW > 0 ? faceRect->x - extraPixW : 0,
				faceRect->y - extraPixH > 0 ? faceRect->y - extraPixH : 0,
				faceRect->width + faceRect->x + extraPixW < img->width ? faceRect->width + extraPixW + addedLeft : img->width - faceRect->x + addedLeft,
				faceRect->height + faceRect->y + extraPixH < img->height ? faceRect->height + extraPixH + addedUp : img->height - faceRect->y + addedUp);
	CvRect dstRoi = cvRect(faceRect->x - extraPixW < 0 ? abs(faceRect->x - extraPixW) : 0,
				faceRect->y - extraPixH < 0 ? abs(faceRect->y - extraPixH) : 0,
				roi.width,
				roi.height);
	*dst = cvCreateImage(cvSize(faceRect->width + extraPixW * 2, faceRect->height + extraPixH * 2), img->depth, img->nChannels);
	cvZero(*dst);
	cvSetImageROI(img, roi);
	cvSetImageROI(*dst, dstRoi); 
	cvCopy(img, *dst);
	cvResetImageROI(img);
	cvResetImageROI(*dst);
}
//////////////////////////////main function/////////////////////////////////
void saveFacesToDiskAndGetTimeStamps(CvCapture* movieClip, 
	char *outputPath, int minPixels, int timeDelta, bool scaleDown)
{
	double scale = scaleDown ? SCALING_RATIO : 1;
	char imgOutputPath[256];
	char thumbOutputPath[256];
	int count = 0;
	int id = 0;
	while (1)
	{
		cvClearMemStorage(storage);
		//char tmppath[256];
		//sprintf(tmppath, "%s/%s%d.tif", outputPath, "frame", timeCount);
		IplImage *img = NULL;
		img = cvQueryFrame(movieClip);
		for (int i = 0 ; i < FRAMES_TO_SKIP ; ++i)
			img = cvQueryFrame(movieClip);
		if (img == NULL)
		{
			printf("End of clip\n");
			break;
		}
		//cvSaveImage(tmppath, img);
		//printf("Frame aquired\n");
		CvSeq *faces;
		detectFace(img, &faces, scaleDown);
		//printf("After face detect found %d faces\n", faces->total);
		CvRect *faceRect;
		int foundFaces[100];
		int foundFacesCount = 0;
		if (faces->total > 0) printf("|");

		for( int i = 0; i < (faces ? faces->total : 0); i++ )
		{
			int nowTimeInSec = cvGetCaptureProperty(movieClip, CV_CAP_PROP_POS_MSEC);
			
			printf("-%d-", nowTimeInSec);
			faceRect = (CvRect*)cvGetSeqElem( faces, i );
			if ((faceRect->height < 1) || (faceRect->width < 1)) continue; 
			IplImage *imgToSave;
			cropImageToFace(img, &imgToSave, faceRect);
			//int extraPixW = (int)((double)faceRect->width * PCT_EXTRA_FACE_IMG_PIXELS / 100);
			//int extraPixH = (int)((double)faceRect->height * PCT_EXTRA_FACE_IMG_PIXELS / 100);
			//CvRect roi = cvRect(faceRect->x - extraPixW > 0 ? faceRect->x - extraPixW : 0,
			//	faceRect->y - extraPixH > 0 ? faceRect->y - extraPixH : 0,
			//	faceRect->width + faceRect->x + extraPixW < img->width ? faceRect->width + extraPixW * 2 : img->width - faceRect->x + extraPixW,
			//	faceRect->height + faceRect->y + extraPixH < img->height ? faceRect->height + extraPixH * 2 : img->height - faceRect->y + extraPixH);
			////CvRect roi = cvRect((int)((double)faceRect->x / scale), 
			////	(int)((double)faceRect->y / scale), 
			////	(int)((double)faceRect->width / scale), 
			////	(int)((double)faceRect->height / scale));
			//IplImage* imgToSave = cvCreateImage(cvSize(roi.width, roi.height), img->depth, img->nChannels);
			//cvSetImageROI(img, roi);
			//cvCopy(img, imgToSave);
			//cvResetImageROI(img);
			/*if (!isSkinPixelsInImg(imgToSave, imgToSave->width * imgToSave->height * SKIN_PIX_THRESH_PERCENT / 100))
			{
				printf("not a face");
				cvReleaseImage(&imgToSave);
				continue;
			}*/
			bool matchFound = false;
			int *lbpDesc;
			int faceNum = findSimilarFaceNum(imgToSave, dlFaces, nowTimeInSec, faceRect, &lbpDesc);
			
			if (faceNum >= 0)
			{
				foundFaces[foundFacesCount++] = faceNum;
				matchFound = true;
				if (dlFaces[faceNum].lastSegmentClosed)
				{
					addStartSegment(nowTimeInSec - ADDED_TIME, dlFaces[faceNum]);
				}
				else
				{
					addEndTime(nowTimeInSec + ADDED_TIME, dlFaces[faceNum]);
				}
				//doThEigensWhen(5);
				break;
			}

			if (matchFound)
			{
				continue;
			}
			sprintf(imgOutputPath, "%s/face_%d_%d.jpg", outputPath, numOfDlFaces + 1, i);
			cvSaveImage(imgOutputPath, imgToSave);			
			sprintf(thumbOutputPath, "%s/thumb_%d_%d.jpg", outputPath, numOfDlFaces + 1, i);
			addToDlFacesVec(imgToSave, nowTimeInSec, imgOutputPath, thumbOutputPath, *faceRect, lbpDesc);
			embedSymbolOnImgCenter(img, playIcon);
			cvSaveImage(thumbOutputPath, img);
			//dont release it is kept in vector - cvReleaseImage(&imgToSave);
			int fnum = cvGetCaptureProperty(movieClip, CV_CAP_PROP_POS_FRAMES);
			printf("found face at frame %d\t pos: %d %d\t size %d X %d\ttime count:%d\n", fnum, faceRect->x, faceRect->y, faceRect->width, faceRect->height, nowTimeInSec);

			//doThEigensWhen(1);
		}
		for (int j = 0 ; j < numOfDlFaces ; ++j)
		{
			bool found = false;
			for (int k = 0; k < foundFacesCount; k++)
			{
				if (foundFaces[k] == j)
				{
					found = true;
					break;
				}
			}
			if (!found)
			{
				//addEndTime(timeCount, &dlFaces[j]);
				dlFaces[j].lastSegmentClosed = true;
			}
		}
		//timeCount++;
		//cvReleaseImage(&img);
		//if((cvWaitKey(timeDelta) & 255) == 27) break;
	}

}

void saveToXML(char *outputPath)
{
	FILE *file = fopen(outputPath, "w");
	if (!file) return;
	fprintf(file, "<?xml version=\"1.0\"?>\n");
	fprintf(file, "<faces>\n");
	for (int i = 0; i < numOfDlFaces; i++)
	{
		if (dlFaces[i].skip) continue;
		fprintf(file, "<face id=\"%d\" path=\"%s\" thumb_path=\"%s\">\n", dlFaces[i].id, dlFaces[i].pathToSave, dlFaces[i].pathToThumb);
		for (int j = 0; j < dlFaces[i].numOfTimeSegments; j++)
		{
			fprintf(file, "\t<timesegment start=\"%d\" end =\"%d\"/>\n", dlFaces[i].timeSegments[j].start_time, dlFaces[i].timeSegments[j].end_time);
		}
		fprintf(file, "</face>");
	}
	fprintf(file, "</faces>\n");
	fclose(file);
}
/////////////////////////////////////////////////////////////////////////////////////////////////
#endif








#ifndef REGION_MYEIGENFACES
///////////////////////////////////////////Eigenfaces////////////////////////////////////////////
int findNearestNeighbor(float *testVec, double threshold)
{
	int resVal = -1;
	double minVal = DBL_MAX;
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		for (int j = 0 ; j < dlFaces[i].numOfFacesFound ; ++j)
		{
			double distance = 0;
			for (int k = 0 ; k < nEigens ; ++k)
			{
				double val = testVec[k] - dlFaces[i].eigenVecs[j][k];
				double valSq = val * val;
				distance += valSq;
			}
			if (distance < minVal && distance < threshold)
			{
				minVal = distance;
				resVal = i;
				//printf("\n------%d out of %d\t%f\n-------\n", i, numOfDlFaces, distance);
			}
			else
			{
				//printf("%d\t%f\n",i,distance);
			}
		}
	}
	return resVal;
}

void setEigenVecsToDlFaces()
{
	int offset = projectedTrainFaceMat->step / sizeof(float);
	int index = 0;
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		for (int j = 0 ; j < dlFaces[i].numOfFacesFound ; ++j)
		{
			dlFaces[i].eigenVecs[j] = (float *)malloc(nEigens * sizeof(float));
			for (int k = 0 ; k < nEigens ; ++k)
			{
				dlFaces[i].eigenVecs[j][k] = (projectedTrainFaceMat->data.fl + index * offset)[k];
			}
			index++;
		}
	}
}

int findTotalNumOfFaces()
{
	int resval = 0;
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		resval += dlFaces[i].numOfFacesFound; 
	}
	return resval;
}

void fillFaceImgArr()
{
	int totNumOfFaces = findTotalNumOfFaces();
	faceImgArr = (IplImage **)cvAlloc(totNumOfFaces * sizeof(IplImage *));
	int index = 0;
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		for (int j = 0 ; j < dlFaces[i].numOfFacesFound ; ++j)
		{
			faceImgArr[index++] = dlFaces[i].StandardizedFaces[j];
		}
	}
	nTrainFaces = index;
}

void doTheEigenFaces()
{
	//int start = clock();
	fillFaceImgArr();
	myLearn();
	//IplImage *tmp = cvCreateImage(cvGetSize(pAvgTrainImg), IPL_DEPTH_8U, 1);
	//cvConvert(pAvgTrainImg, tmp);
	//cvSaveImage("C:\\TestOutputs\\avg.tif", tmp);
	//cvReleaseImage(&tmp);
	setEigenVecsToDlFaces();
	time_t end = time(NULL);
	//printf("-----eigen Faces took:");
	//printTimeDiffFromNow(start);
}

int recognizeAndAddFace(IplImage *inputImg, float **projectedTestFace)
{
	//int start = clock();
	*projectedTestFace = (float *)cvAlloc( nEigens*sizeof(float) );
	// project the test image onto the PCA subspace
	cvEigenDecomposite(
		inputImg,
		nEigens,
		eigenVectArr,
		0, 0,
		pAvgTrainImg,
		*projectedTestFace);
	int nearest = findNearestNeighbor(*projectedTestFace, NEAREST_NEIGHBOR_THRESHOLD);
	if (nearest == -1) return -1;
	if (dlFaces[nearest].numOfFacesFound < 20)
	{
		dlFaces[nearest].StandardizedFaces[dlFaces[nearest].numOfFacesFound] = inputImg;
		dlFaces[nearest].eigenVecs[dlFaces[nearest].numOfFacesFound] = *projectedTestFace; 
		dlFaces[nearest].numOfFacesFound++;
	}
	//printf("-----eigen decomposite and find nearest neighbor took:");
	//printTimeDiffFromNow(start);
	return nearest;
}







int skinColorPixelsCounter(IplImage *img, int skinPixelsThreshold)
{
	int skinColorPixelsCounter = 0;
	int maxCOunter = img->width * img->height * skinPixelsThreshold / 100;
	IplImage *outputImg = cvCloneImage(img);
	uchar *aPixelIn, *aPixelOut;
	aPixelIn = (uchar *)img->imageData;
	aPixelOut = (uchar *)outputImg->imageData;

	for ( int iRow = 0; iRow < img->height; iRow++ ) 
	{
		for ( int iCol = 0; iCol < img->width; iCol++ ) 
		{
			int R, B, G, F, I, X, H, S, V;

			/* Get RGB values -- OpenCV stores RGB images in BGR order!! */
			B = aPixelIn[ iRow * img->widthStep + iCol * 3 + 0 ];
			G = aPixelIn[ iRow * img->widthStep + iCol * 3 + 1 ];
			R = aPixelIn[ iRow * img->widthStep + iCol * 3 + 2 ];

			/* Convert RGB to HSV */
			X = MIN3( R, G, B );
			V = MAX3( R, G, B );
			if ( V == X ) 
			{
				H = 0; S = 0;
			} 
			else 
			{
				S = (float)(V-X)/(float)V * 255.0;
				F = ( R==V ) ? (G-B) : (( G==V ) ? ( B-R ) : ( R-G ));
				I = ( R==V ) ? 0 : (( G==V ) ? 2 : 4 );
				H = ( I + (float)F/(float)(V-X) )/6.0*255.0;
				if ( H < 0 ) H += 255;
				if ( H < 0 || H > 255 || V < 0 || V > 255 ) 
				{
					fprintf( stderr, "%s %d: bad HS values: %d,%d\n",
						__FILE__, __LINE__, H, S );
					exit( -1 );
				}
			}
			float sVal = (float)S / 255.0;
			if (H > 0 && H < 50)// && sVal > 0.23 && sVal < 0.68)
			{
				if (skinColorPixelsCounter++ > maxCOunter);
				//return skinColorPixelsCounter;
				aPixelOut[ iRow * img->widthStep + iCol * 3 + 0 ] = 255;
			}
		}
	}
	/*static int t = 0;
	char stam[256];
	sprintf(stam, "C:\\TestOutputs\\test_%d.tif", t++);
	cvSaveImage(stam, outputImg); 
	cvReleaseImage(&outputImg);*/
	return skinColorPixelsCounter;
}

bool isSkinPixelsInImg(IplImage *img, int skinPixelsThreshold)
{
	//int t = clock();
	static int countEntrances = 0;
	int numOfPix = skinColorPixelsCounter(img, skinPixelsThreshold);
	bool isItTrue = numOfPix >= skinPixelsThreshold;
	//printf("---skin pixel took: "); 
	//printTimeDiffFromNow(t);
	return isItTrue;
}





void doThEigensWhen(int modWhen)
{
	int totNumOfFaces = findTotalNumOfFaces();
	if (totNumOfFaces > 1 && (totNumOfFaces == 2 || totNumOfFaces % modWhen == 0))
	{
		doTheEigenFaces();
	}

}


#endif


#ifndef REGION_THEIRCODE 
//////////////////////////////////
// learn()
//
void learn()
{
	int i, offset;

	// load training data
	nTrainFaces = loadFaceImgArray("train.txt");
	if( nTrainFaces < 2 )
	{
		fprintf(stderr,
			"Need 2 or more training faces\n"
			"Input file contains only %d\n", nTrainFaces);
		return;
	}

	// do PCA on the training faces
	doPCA();

	// project the training images onto the PCA subspace
	projectedTrainFaceMat = cvCreateMat( nTrainFaces, nEigens, CV_32FC1 );
	offset = projectedTrainFaceMat->step / sizeof(float);
	for(i=0; i<nTrainFaces; i++)
	{
		//int offset = i * nEigens;
		cvEigenDecomposite(
			faceImgArr[i],
			nEigens,
			eigenVectArr,
			0, 0,
			pAvgTrainImg,
			//projectedTrainFaceMat->data.fl + i*nEigens);
			projectedTrainFaceMat->data.fl + i*offset);
	}

	// store the recognition data as an xml file
	storeTrainingData();
}

//////////////////////////////////
// learn()
//
void myLearn()
{
	int i, offset;

	// do PCA on the training faces
	doPCA();
	printf(",");
	// project the training images onto the PCA subspace
	projectedTrainFaceMat = cvCreateMat( nTrainFaces, nEigens, CV_32FC1 );
	offset = projectedTrainFaceMat->step / sizeof(float);
	for(i=0; i<nTrainFaces; i++)
	{
		//int offset = i * nEigens;
		cvEigenDecomposite(
			faceImgArr[i],
			nEigens,
			eigenVectArr,
			0, 0,
			pAvgTrainImg,
			//projectedTrainFaceMat->data.fl + i*nEigens);
			projectedTrainFaceMat->data.fl + i*offset);
	}
}

//////////////////////////////////
// recognize()
//
void recognize()
{
	int i, nTestFaces  = 0;         // the number of test images
	CvMat * trainPersonNumMat = 0;  // the person numbers during training
	float * projectedTestFace = 0;
	int correct = 0; // number of correct matches

	// load test images and ground truth for person number
	nTestFaces = loadFaceImgArray("test.txt");
	printf("%d test faces loaded\n", nTestFaces);

	// load the saved training data
	if( !loadTrainingData( &trainPersonNumMat ) ) return;

	// project the test images onto the PCA subspace
	projectedTestFace = (float *)cvAlloc( nEigens*sizeof(float) );
	for(i=0; i<nTestFaces; i++)
	{
		int iNearest, nearest, truth;

		// project the test image onto the PCA subspace
		cvEigenDecomposite(
			faceImgArr[i],
			nEigens,
			eigenVectArr,
			0, 0,
			pAvgTrainImg,
			projectedTestFace);

		iNearest = findNearestNeighbor(projectedTestFace);
		truth    = personNumTruthMat->data.i[i];
		nearest  = trainPersonNumMat->data.i[iNearest];

		printf("nearest = %d, Truth = %d\n", nearest, truth);

		if(nearest==truth)
			correct++;
	}

	printf("The percentage of correct recognitions is %f \n", (double)correct/(double)nTestFaces);
}


//////////////////////////////////
// loadTrainingData()
//
int loadTrainingData(CvMat ** pTrainPersonNumMat)
{
	CvFileStorage * fileStorage;
	int i;

	// create a file-storage interface
	fileStorage = cvOpenFileStorage( "facedata.xml", 0, CV_STORAGE_READ );
	if( !fileStorage )
	{
		fprintf(stderr, "Can't open facedata.xml\n");
		return 0;
	}

	nEigens = cvReadIntByName(fileStorage, 0, "nEigens", 0);
	nTrainFaces = cvReadIntByName(fileStorage, 0, "nTrainFaces", 0);
	*pTrainPersonNumMat = (CvMat *)cvReadByName(fileStorage, 0, "trainPersonNumMat", 0);
	eigenValMat  = (CvMat *)cvReadByName(fileStorage, 0, "eigenValMat", 0);
	projectedTrainFaceMat = (CvMat *)cvReadByName(fileStorage, 0, "projectedTrainFaceMat", 0);
	pAvgTrainImg = (IplImage *)cvReadByName(fileStorage, 0, "avgTrainImg", 0);
	eigenVectArr = (IplImage **)cvAlloc(nTrainFaces*sizeof(IplImage *));
	for(i=0; i<nEigens; i++)
	{
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		eigenVectArr[i] = (IplImage *)cvReadByName(fileStorage, 0, varname, 0);
	}

	// release the file-storage interface
	cvReleaseFileStorage( &fileStorage );

	return 1;
}


//////////////////////////////////
// storeTrainingData()
//
void storeTrainingData()
{
	CvFileStorage * fileStorage;
	int i;

	// create a file-storage interface
	fileStorage = cvOpenFileStorage( "facedata.xml", 0, CV_STORAGE_WRITE );

	// store all the data
	cvWriteInt( fileStorage, "nEigens", nEigens );
	cvWriteInt( fileStorage, "nTrainFaces", nTrainFaces );
	cvWrite(fileStorage, "trainPersonNumMat", personNumTruthMat, cvAttrList(0,0));
	cvWrite(fileStorage, "eigenValMat", eigenValMat, cvAttrList(0,0));
	cvWrite(fileStorage, "projectedTrainFaceMat", projectedTrainFaceMat, cvAttrList(0,0));
	cvWrite(fileStorage, "avgTrainImg", pAvgTrainImg, cvAttrList(0,0));
	for(i=0; i<nEigens; i++)
	{
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		cvWrite(fileStorage, varname, eigenVectArr[i], cvAttrList(0,0));
	}

	// release the file-storage interface
	cvReleaseFileStorage( &fileStorage );
}


//////////////////////////////////
// findNearestNeighbor()
//
int findNearestNeighbor(float * projectedTestFace)
{
	//double leastDistSq = 1e12;
	double leastDistSq = DBL_MAX;
	int i, iTrain, iNearest = 0;

	for(iTrain=0; iTrain<nTrainFaces; iTrain++)
	{
		double distSq=0;

		for(i=0; i<nEigens; i++)
		{
			float d_i = projectedTestFace[i] - projectedTrainFaceMat->data.fl[iTrain*nEigens + i];
			//distSq += d_i*d_i / eigenValMat->data.fl[i];  // Mahalanobis
			distSq += d_i*d_i; // Euclidean
		}

		if(distSq < leastDistSq)
		{
			leastDistSq = distSq;
			iNearest = iTrain;
		}
	}

	return iNearest;
}


//////////////////////////////////
// doPCA()
//
void doPCA()
{
	int i;
	CvTermCriteria calcLimit;
	CvSize faceImgSize;

	// set the number of eigenvalues to use
	nEigens = nTrainFaces-1;

	// allocate the eigenvector images
	faceImgSize.width  = faceImgArr[0]->width;
	faceImgSize.height = faceImgArr[0]->height;
	eigenVectArr = (IplImage**)cvAlloc(sizeof(IplImage*) * nEigens);
	for(i=0; i<nEigens; i++)
		eigenVectArr[i] = cvCreateImage(faceImgSize, IPL_DEPTH_32F, 1);

	// allocate the eigenvalue array
	eigenValMat = cvCreateMat( 1, nEigens, CV_32FC1 );

	// allocate the averaged image
	pAvgTrainImg = cvCreateImage(faceImgSize, IPL_DEPTH_32F, 1);

	// set the PCA termination criterion
	calcLimit = cvTermCriteria( CV_TERMCRIT_ITER, nEigens, 1);

	// compute average image, eigenvalues, and eigenvectors
	cvCalcEigenObjects(
		nTrainFaces,
		(void*)faceImgArr,
		(void*)eigenVectArr,
		CV_EIGOBJ_NO_CALLBACK,
		0,
		0,
		&calcLimit,
		pAvgTrainImg,
		eigenValMat->data.fl);

	cvNormalize(eigenValMat, eigenValMat, 1, 0, CV_L1, 0);
}


//////////////////////////////////
// loadFaceImgArray()
//
int loadFaceImgArray(char * filename)
{
	FILE * imgListFile = 0;
	char imgFilename[512];
	int iFace, nFaces=0;


	// open the input file
	if( !(imgListFile = fopen(filename, "r")) )
	{
		fprintf(stderr, "Can\'t open file %s\n", filename);
		return 0;
	}

	// count the number of faces
	while( fgets(imgFilename, 512, imgListFile) ) ++nFaces;
	rewind(imgListFile);

	// allocate the face-image array and person number matrix
	faceImgArr        = (IplImage **)cvAlloc( nFaces*sizeof(IplImage *) );
	personNumTruthMat = cvCreateMat( 1, nFaces, CV_32SC1 );

	// store the face images in an array
	for(iFace=0; iFace<nFaces; iFace++)
	{
		// read person number and name of image file
		fscanf(imgListFile,
			"%d %s", personNumTruthMat->data.i+iFace, imgFilename);

		// load the face image
		faceImgArr[iFace] = cvLoadImage(imgFilename, CV_LOAD_IMAGE_GRAYSCALE);

		if( !faceImgArr[iFace] )
		{
			fprintf(stderr, "Can\'t load image from %s\n", imgFilename);
			return 0;
		}
	}

	fclose(imgListFile);

	return nFaces;
}


//////////////////////////////////
// printUsage()
//
void printUsage()
{
	printf("Usage: eigenface <command>\n",
		"  Valid commands are\n"
		"    train\n"
		"    test\n");
}

#endif



class EigenFaceDetector
{
public:
	EigenFaceDetector(void);
	~EigenFaceDetector(void);
};

