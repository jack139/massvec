#include <sys/time.h>
#include <iostream>   
#include <iomanip>                                                                                                    
#include <stdio.h>
#include <stdlib.h>
#include <time.h>


using namespace std;

const int D = 2048;
const int N1 = 10000; // 数据文件条数
const int D1 = 1; // 数据重复倍数，方便模拟海量数据
const int N = N1*D1;

__global__ void cal_dis(double *train_data, double *test_data, double *dis, int pitch)
{
	int tid = blockIdx.x;
	if(tid<N)
	{
		double temp = 0.0;
		double sum = 0.0;
		for(int i=0;i<D;i++)
		{
			temp = *((double*)((char*)train_data + tid * pitch) + i) - test_data[i];
			sum += temp * temp;
		}
		dis[tid] = sum;
	}
}

void print(double *data)
{
	cout<<"training data:"<<endl;
	for(int i=0;i<N;i++)
	{
		for(int j=0;j<D;j++)
		{
			cout<< fixed << setprecision(8)<<*(data+i*D+j)<<" ";
		}
		cout<<endl;
	}
}
 
void print(double *data, int n)
{
	for(int i=0;i<n;i++)
	{
		cout<< fixed << setprecision(8)<<data[i]<<" ";
	}
	cout<<endl;
}


int read_data(double *data_set)
{
	double f1;
	const char s[2] = ",";
	char *token, *line;
	FILE *fp;
	double test[D];

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
	double *h_train_data, *h_test_data;
	double distance[N];
 
	double *d_train_data , *d_test_data , *d_dis;
 
	struct timeval t1,t2;
	double timeuse;

	cout<<"num= "<<N<<"\tdim= "<<D<<endl;

	h_train_data = (double*)malloc((N+1)*D*sizeof(double));
	if (h_train_data==NULL){
		puts("alloc memory fail!");
		exit(-1);
	}

	size_t pitch_d;
	size_t pitch_h = D * sizeof(double) ; 

	//allocate memory on GPU 
	cudaMallocPitch( &d_train_data, &pitch_d, D*sizeof(double), N); 
	cudaMalloc((void**)&d_test_data, D*sizeof(double));
	cudaMalloc((void**)&d_dis, N*sizeof(double));

	//initialize training data
	read_data(h_train_data);
	//print(h_train_data);
 
	//initialize testing data
	h_test_data = h_train_data+D*N;
	cout<<"testing data:"<<endl;
	//print(h_test_data,D);
 
	gettimeofday(&t1,NULL);

	//copy training and testing data from host to device
	cudaMemcpy2D(d_train_data, pitch_d, h_train_data, pitch_h, D*sizeof(double), N, cudaMemcpyHostToDevice);
	cudaMemcpy(d_test_data, h_test_data, D*sizeof(double), cudaMemcpyHostToDevice);
 
	//calculate the distance
	cal_dis<<<N,1>>>(d_train_data,d_test_data,d_dis,pitch_d);
 
	//copy distance data from device to host
	cudaMemcpy(distance, d_dis, N*sizeof(double), cudaMemcpyDeviceToHost);

	gettimeofday(&t2, NULL);
 
	cout<<"distance:"<<endl;
	//print(distance, N);

	cudaFree(d_train_data);
	cudaFree(d_test_data);
	cudaFree(d_dis);
	free(h_train_data);
	 
	timeuse = (t2.tv_sec - t1.tv_sec) + (double)(t2.tv_usec - t1.tv_usec)/1000000.0;
	cout << "[ time taken: " << fixed << setprecision(6) << timeuse << "s ]" << endl;



	return 0;
}  