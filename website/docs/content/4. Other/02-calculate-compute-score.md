# Compute Score

## Abstract

This document will explain in details how to prepare your systems for the benchmark, where to start the benchmark and how to review the scores.
The benchmarking is essential to measure the performances of the cloud server and be able to associate the right lable to the righe performance baseline in your infrastructure.
Before labeling on of your machine, it is a must to meet the minimum scores for each type of product you want to participate with.
In order to be part of SECA it is not essential or mandatory to participate with all the products and lables 

### Conditions

These are the baseline condition to run a test:

* The hardware tested must be **the same** as your **production** hardware
* You should test one size of server at the time
* The VM running the Benchmark must be running the latest Debian Linux 12 cloud image
* At the time of the test the Hypervisor must be topped up wit the same type of VMs running the same OS as the Benchmark VM
  * For example: you are testing a SECA.L (8 CPU, 16 GB RAM), the VM being tested must be hosted on a Hypervisor which is hosting as many SECA.L type as possible, all running Debian Linux 12.
* No additional software must be installed or run during the benchmark, not in he VM being tested not in the VMs running on the same Hypervisor
* The use of swap memory is allowed during the benchmark process; however, it is recommended to only avoid it.
* Hyper-threads should not be considered as physical cores when evaluating or reporting the system's CPU configuration.

### Software

The benchmark utilizes a carefully selected suite of software tools to ensure accurate and reliable performance measurements. 
The primary software used is **GeekBench 6**, a cross-platform benchmarking tool that evaluates system performance across diverse workloads, including single-core and multi-core tasks.

This software ensures consistency and comparability of results across various hardware configurations, providing a standardized approach to performance assessment.

### Shared or Dedicated vCPU

We created 2 types of classification for the compute power scores

- 1 Shared : in this model all the CPUs/Cores of an Hypervisor are pooled together and each VM will be using a portion of that power it is usually less performing in the multi-core tasks but it is also less expensive.
- 2 Dedicated : in this model each of the vCPU is pinned to a physical core; al model is more expensive but the performances fluctuate less in time and there is less impact of noisy neighbors.

### Minimum Score per SECA.Size

The table below outlines the required multi-core benchmark scores for each SECA instance of Shared Type.
It is importanto to note that while the number of vCPU is a suggestion as you can get to the specific value with less or more vCPU depending on type/architecture/frequency

| Seca.Size |GB RAM | Min.SCORE | Suggested vCPU |
| --------- | ----------- | --------- | --------- |
| SECA.2XS  | 1         | 500       |  1  |
| SECA.XS   | 2         | 750       |  1  |
| SECA.S    | 4         | 2200      |  2  |
| SECA.M    | 8         | 3500      |  4  |
| SECA.L    | 16        | 6000      |  8  |
| SECA.XL   | 32       | 9000      |  16  |
| SECA.2XL  | 64       | 13000     |  32  |


| Seca.Size | GB RAM | Min.SCORE | Suggested vCPU |
| --------- | ----------- | --------- | --------- |
| SECA.2XS  | 1         | 500       | 1 |
| SECA.XS   | 2         | 750       | 1 |
| SECA.S    | 4         | 2200      | 2 |
| SECA.M    | 8         | 3500      | 4 |
| SECA.L    | 16        | 6000      | 8 |
| SECA.XL   | 32       | 9000      | 16 |
| SECA.2XL  | 64       | 13000     | 32 |
