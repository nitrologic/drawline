#pragma once
#include <deque>
#include <mutex>

typedef double Sample;

class AudioPipe{

	std::mutex mutex;
	std::deque<Sample> buffer;

public:
	int readPointer=0;
	int writePointer=0;
		
	void WriteSamples(Sample *samples,int count){	
		mutex.lock();
		for(int i=0;i<count;i++){
			buffer.push_back(samples[i]);
		}
		writePointer+=count;
		mutex.unlock();
	}

	static float clamp(double a,double low, double hi){
		if (a<low) a=low;
		if (a>hi) a=hi;
		return a;
	}
	
	void readSamples(short *dest, int sampleCount){
		mutex.lock();	
		int available=buffer.size();
		if (available>=sampleCount){
			for(int i=0;i<sampleCount;i++){
				Sample s=buffer.front();
				buffer.pop_front();			
				dest[i]=32767*clamp(s, -1.0, 1.0);
			}
			readPointer+=sampleCount;
		}
		mutex.unlock();
	}

	static void Callback(void *a, unsigned char *b, int c){
		memset(b,0,c);
		auto pipe=(AudioPipe*)a;		
		int sampleCount=c/2;
		short *dest=(short *)b;
		pipe->readSamples(dest,sampleCount);
	}
	
	void *Handle(){
		return (void *)this;
	}

	static AudioPipe *Create(){
		return new AudioPipe();
	}
};
