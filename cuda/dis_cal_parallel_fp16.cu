#include <iostream>   
#include <iomanip>                                                                                                    
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "cuda_fp16.h"

// float16 半精度计算 100万2048维向量，占显存4G
// 注意：精度降低可能导致计算结果错误

using namespace std;

const int D = 2048;
const int N1 = 10000; // 数据文件条数
const int D1 = 100; // 数据重复倍数，方便模拟海量数据
const unsigned long N = N1*D1;


__global__ void cal_dis(half *train_data, half *test_data, half *dis, int pitch)
{
	//long tid = blockIdx.x;
	unsigned long tid = threadIdx.x + blockIdx.x * blockDim.x;
	if(tid<N)
	{
		half temp = 0.0;
		half sum = 0.0;
		for(int i=0;i<D;i++)
		{
			temp = __hsub(*((half*)((char*)train_data + tid * pitch) + i), test_data[i]);
			sum = __hadd(sum, __hmul(temp, temp));
		}
		dis[tid] = sum;
	}
}

void print(half *data)
{
	cout<<"training data:"<<endl;
	for(unsigned long i=0;i<N;i++)
	{
		for(int j=0;j<D;j++)
		{
			cout<< fixed << setprecision(8)<<__half2float(*(data+i*D+j))<<" ";
		}
		cout<<endl;
	}
}
 
void print(half *data, unsigned long n)
{
	for(unsigned long i=0;i<n;i++)
	{
		cout<< fixed << setprecision(8)<<__half2float(data[i])<<" ";
	}
	cout<<endl;
}


int read_data(half *data_set)
{
	float f1;
	const char s[2] = ",";
	char *token, *line;
	FILE *fp;
	half test[D];

	// 一个数字假设占20字符，目前是保留16位小数，一共18个字符
	line = (char *)malloc(20*D*sizeof(char)); 

	fp = fopen("../vector.data" , "r");
	if(fp == NULL) {
		perror("打开文件时发生错误");
		return(-1);
	}

	// 读N+1行，最后1行做测试
	for(int i=0;i<N1+1;i++) {
		if( fgets (line, 20*D*sizeof(char), fp)!=NULL ) {
			token = strtok(line, s);

			int j = 0;
			while (token != NULL)
			{
				f1 = atof(token);
				//printf("%.8f ", f1);
				*(data_set+i*D+j)=__float2half(f1*10.0); // 增加10倍的精度

				token = strtok(NULL, s);
				j++;
			}
			//puts("");

		} else {
			break;
		}
	}

	fclose(fp);

	free(line);

	for(int i=0;i<D;i++) test[i]=*(data_set+N1*D+i); // 保存测试向量

	for(int d=1;d<D1;d++){ // 复制数据
		for(int i=0;i<N1;i++){
			for(int j=0;j<D;j++){
				*(data_set+(N1*d+i)*D+j)= *(data_set+i*D+j);
			}
		}
	}

	for(int i=0;i<D;i++) *(data_set+N*D+i)=test[i]; // 恢复测试向量

	return 0;
}

int main()
{
	

	half *h_train_data, *h_test_data;
	half distance[N];
 
	half *d_train_data , *d_test_data , *d_dis;
 
	float time1, time2;

	//printf("%d %d %d\n", sizeof(float), sizeof(half2), sizeof(half));

	// 显示GPU资源
	int dev = 0;
    cudaDeviceProp devProp;
    cudaGetDeviceProperties(&devProp, dev);
    std::cout << "使用GPU device " << dev << ": " << devProp.name << std::endl;
    std::cout << "SM的数量：" << devProp.multiProcessorCount << std::endl;
    std::cout << "每个线程块的共享内存大小：" << devProp.sharedMemPerBlock / 1024.0 << " KB" << std::endl;
    std::cout << "每个线程块的最大线程数：" << devProp.maxThreadsPerBlock << std::endl;
    std::cout << "每个EM的最大线程数：" << devProp.maxThreadsPerMultiProcessor << std::endl;
    std::cout << "每个EM的最大线程束数：" << devProp.maxThreadsPerMultiProcessor / 32 << std::endl;
    //-----------

	cudaEvent_t start1, stop1, stop2;
	cudaEventCreate(&start1);
	cudaEventCreate(&stop1); 
	cudaEventCreate(&stop2); 

	cout<<"num= "<<N<<"\tdim= "<<D<<endl;

	h_train_data = (half*)malloc((N+1)*D*sizeof(half));
	if (h_train_data==NULL){
		puts("alloc memory fail!");
		exit(-1);
	}

	size_t pitch_d;
	size_t pitch_h = D * sizeof(half) ; 

	//allocate memory on GPU 
	cudaMallocPitch( &d_train_data, &pitch_d, D*sizeof(half), N); 
	cudaMalloc((void**)&d_test_data, D*sizeof(half));
	cudaMalloc((void**)&d_dis, N*sizeof(half)); // d_ids[N] 存最小值

	//initialize training data
	read_data(h_train_data);
	//print(h_train_data);
 
	//initialize testing data
	h_test_data = h_train_data+D*N;
	//cout<<"testing data:"<<endl;
	//print(h_test_data,D);
 

	//copy training and testing data from host to device
	cudaMemcpy2D(d_train_data, pitch_d, h_train_data, pitch_h, D*sizeof(half), N, cudaMemcpyHostToDevice);
	cudaEventRecord(start1, 0); // 批量数据复制进GPU的耗时，不计入，现实中会提前载入
	cudaMemcpy(d_test_data, h_test_data, D*sizeof(half), cudaMemcpyHostToDevice);
 
	// 定义kernel的执行配置
	dim3 blockSize(256);
	dim3 gridSize((N + blockSize.x - 1) / blockSize.x);
	printf("grid size: %d\tblock size: %d\n", gridSize.x, blockSize.x);
	// 执行kernel
	cal_dis<<<gridSize, blockSize>>>(d_train_data,d_test_data,d_dis,pitch_d);

	//calculate the distance
	//cal_dis<<<N,1>>>(d_train_data,d_test_data,d_dis,pitch_d);
 
	//copy distance data from device to host
	cudaMemcpy(distance, d_dis, N*sizeof(half), cudaMemcpyDeviceToHost);

	cudaEventRecord(stop1, 0);

	// 找最小值
	float minimum = __half2float(distance[0]);
	unsigned long min_pos = 0;
	for(unsigned long i=1;i<N;i++) {
		float tmp_dis = __half2float(distance[i]);
		if (tmp_dis<minimum) {
			minimum=tmp_dis;
			min_pos=i;
		}
	}

	cudaEventRecord(stop2, 0);
 
	//cout<<"distance:"<<endl;
	//print(distance, N);

	cudaFree(d_train_data);
	cudaFree(d_test_data);
	cudaFree(d_dis);
	free(h_train_data);
	
	printf("min= %.8f\tpos= %ld\n", minimum, min_pos);

	cudaEventElapsedTime(&time1, start1, stop1);
	cudaEventElapsedTime(&time2, stop1, stop2);
	printf("[ time taken: %fms %fms ]\n",time1, time2);


	return 0;
}  
