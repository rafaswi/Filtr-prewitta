#pragma once
#include<iostream>
#include<fstream>
#include<memory>
#include<qvector.h>
#include <QtCore\qstring.h>

#define BMP_HEADER_SIZE 14
#define OFFSET_TO_bfOffBits 10
#define OFFSET_TO_WIDTH 4
#define OFFSET_TO_HEIGHT 8
#define GB 1024*1024*1024

static std::string imageFilePath;
static int numberOfThreads;

long GetFileSize(std::string filename);

unsigned int get_int(char* data, int offset);


class Bitmap
{

	char* bitmap_header;
	char* DIB_header;
	char* pixel_data;
	int width;
	int height;
	int offset_to_pixel_data;
	int padding;
	long filesize;
	int rDistribution[256];
	int gDistribution[256];
	int bDistribution[256];

	

public:
	
	Bitmap();
	
	Bitmap(std::string filePath);

	bool loadBitmap(std::string filePath);

	int* getRDistribution();

	int* getGDistribution();

	int* getBDistribution();

	void calculateHistogram();

	void normalizeHistogram();

	void castPixelCharArrayToUnsignedCharArray();

	char* getBitmap_header();

	char* getDIB_header();

	int getWidth();

	int getHeight();

	char* getPixels();

	int getOffsetToPixels();

	long getFilesize();

	void saveToFile(std::string filePath, bool dllCppLibrary);

	void makeMagic();

	void grayscale();

	void setPixels(char* newPixels);



	

};

