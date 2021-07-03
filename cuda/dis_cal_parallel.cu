#include <iostream>   
#include <iomanip>                                                                                                    
#include <stdio.h>
#include <stdlib.h>
#include <time.h>


using namespace std;

const int D = 2048;
const int N1 = 10000; // 数据文件条数
const int D1 = 90; // 数据重复倍数，方便模拟海量数据
const long N = N1*D1;


__global__ void cal_dis(float *train_data, float *test_data, float *dis, int pitch)
{
	//long tid = blockIdx.x;
	long tid = threadIdx.x + blockIdx.x * blockDim.x;
	if(tid<N)
	{
		float temp = 0.0;
		float sum = 0.0;
		for(int i=0;i<D;i++)
		{
			temp = *((float*)((char*)train_data + tid * pitch) + i) - test_data[i];
			sum += temp * temp;
		}
		dis[tid] = sum;
	}
}

void print(float *data)
{
	cout<<"training data:"<<endl;
	for(long i=0;i<N;i++)
	{
		for(int j=0;j<D;j++)
		{
			cout<< fixed << setprecision(8)<<*(data+i*D+j)<<" ";
		}
		cout<<endl;
	}
}
 
void print(float *data, int n)
{
	for(int i=0;i<n;i++)
	{
		cout<< fixed << setprecision(8)<<data[i]<<" ";
	}
	cout<<endl;
}


int read_data(float *data_set)
{
	float f1;
	const char s[2] = ",";
	char *token, *line;
	FILE *fp;
	float test[D];

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
				*(data_set+i*D+j)=f1;

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
	

	float *h_train_data, *h_test_data;
	float distance[N];
 
	float *d_train_data , *d_test_data , *d_dis;
 
	float time1, time2;


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

	h_train_data = (float*)malloc((N+1)*D*sizeof(float));
	if (h_train_data==NULL){
		puts("alloc memory fail!");
		exit(-1);
	}

	size_t pitch_d;
	size_t pitch_h = D * sizeof(float) ; 

	//allocate memory on GPU 
	cudaMallocPitch( &d_train_data, &pitch_d, D*sizeof(float), N); 
	cudaMalloc((void**)&d_test_data, D*sizeof(float));
	cudaMalloc((void**)&d_dis, (N+1)*sizeof(float)); // d_ids[N] 存最小值

	//initialize training data
	read_data(h_train_data);
	//print(h_train_data);
 
	//initialize testing data
	h_test_data = h_train_data+D*N;
	cout<<"testing data:"<<endl;
	//print(h_test_data,D);
 
	cudaEventRecord(start1, 0);

	//copy training and testing data from host to device
	cudaMemcpy2D(d_train_data, pitch_d, h_train_data, pitch_h, D*sizeof(float), N, cudaMemcpyHostToDevice);
	cudaMemcpy(d_test_data, h_test_data, D*sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_dis, distance, N*sizeof(float), cudaMemcpyHostToDevice);
 
	// 定义kernel的执行配置
	dim3 blockSize(1);
	dim3 gridSize((N + blockSize.x - 1) / blockSize.x);
	printf("grid size: %d\tblock size: %d\n", gridSize.x, blockSize.x);
	// 执行kernel
	cal_dis<<<gridSize, blockSize>>>(d_train_data,d_test_data,d_dis,pitch_d);

	//calculate the distance
	//cal_dis<<<N,1>>>(d_train_data,d_test_data,d_dis,pitch_d);
 
	//copy distance data from device to host
	cudaMemcpy(distance, d_dis, N*sizeof(float), cudaMemcpyDeviceToHost);

	cudaEventRecord(stop1, 0);

	float minimum = distance[0];
	for(long i=1;i<N;i++) if (distance[i]<minimum) minimum=distance[i];

	cudaEventRecord(stop2, 0);
 
	cout<<"distance:"<<endl;
	//print(distance, N);

	cudaFree(d_train_data);
	cudaFree(d_test_data);
	cudaFree(d_dis);
	free(h_train_data);
	
	cout << "min= " << fixed << setprecision(8) << minimum << endl;

	cudaEventElapsedTime(&time1, start1, stop1);
	cudaEventElapsedTime(&time2, stop1, stop2);
	printf("[ time taken: %fms %fms ]\n",time1, time2);


	return 0;
}  
