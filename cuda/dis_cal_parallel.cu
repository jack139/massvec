#include <sys/time.h>
#include <iostream>   
#include <iomanip>                                                                                                    
#include <stdio.h>
#include <stdlib.h>
#include <time.h>


using namespace std;

const int N = 100;
const int D = 10;
const float MAX = 10000.0;

__global__ void cal_dis(float *train_data, float *test_data, float *dis,int pitch)
{
	int tid = blockIdx.x;
	if(tid<N)
	{
		int temp = 0;
		int sum = 0;
		for(int i=0;i<D;i++)
		{
			temp = *((int*)((char*)train_data + tid * pitch) + i) - test_data[i];
			sum += temp * temp;
		}
		dis[tid] = sum;
	}
}
 
void print(float data[][D])
{
	cout<<"training data:"<<endl;
 	for(int i=0;i<N;i++)
	{
		for(int j=0;j<D;j++)
		{
			cout<< fixed << setprecision(6)<<*(*(data+i)+j)<<" ";		
		}
		cout<<endl;
	}
}
 
void print(float *data,int n)
{
	for(int i=0;i<n;i++)
	{
		cout<< fixed << setprecision(6)<<data[i]<<" ";
	}
	cout<<endl;
}
 
int main()
{
	float h_train_data[N][D] , h_test_data[D] , distance[N];
 
	float *d_train_data , *d_test_data , *d_dis;
 
 	struct timeval t1,t2;
    double timeuse;

	size_t pitch_d;
	size_t pitch_h = D * sizeof(float) ;
 
	//allocate memory on GPU 
	cudaMallocPitch( &d_train_data , &pitch_d , D * sizeof(float) , N ); 
	cudaMalloc( (void**)&d_test_data ,  D*sizeof(float) );
	cudaMalloc( (void**)&d_dis , N*sizeof(float) );
 
	//initialize training data
	srand( (unsigned)time(NULL) );
	for( int i=0;i<N;i++ )
	{
		for( int j=0;j<D;j++)
		{
			h_train_data[i][j] = rand()/MAX;
		}
	}
	print(h_train_data);
 
	//initialize testing data
	for( int j=0;j<D;j++ )
	{
	  	h_test_data[j] = rand()/MAX;
	}
	cout<<"testing data:"<<endl;
	print(h_test_data,D);
 
	gettimeofday(&t1,NULL);

	//copy training and testing data from host to device
	cudaMemcpy2D( d_train_data , pitch_d , h_train_data , pitch_h , D * sizeof(float) , N , cudaMemcpyHostToDevice );
	cudaMemcpy( d_test_data,  h_test_data ,  D*sizeof(float), cudaMemcpyHostToDevice);
 
	//calculate the distance
	cal_dis<<<N,1>>>( d_train_data,d_test_data,d_dis,pitch_d );
 
	//copy distance data from device to host
	cudaMemcpy( distance , d_dis  , N*sizeof(float) , cudaMemcpyDeviceToHost);

	gettimeofday(&t2,NULL);
 
	cout<<"distance:"<<endl;
	print(distance , N);

	cudaFree(d_train_data);
	cudaFree(d_test_data);
	cudaFree(d_dis);
 
 	timeuse = (t2.tv_sec - t1.tv_sec) + (double)(t2.tv_usec - t1.tv_usec)/1000000.0;
  	cout << "[ time taken: " << fixed << setprecision(6) << timeuse << "s ]" << endl;

	return 0;
}  
