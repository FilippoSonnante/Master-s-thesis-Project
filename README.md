# Master-s-thesis-Project
Fuzzing to Open5Gs AMF with the intent to create a Denial of Service.

Starting from known vulnerabilities of the Open5Gs AMF in version 2.3.2, the objective of this project is to carry out a denial of service at the actual version of Open5Gs, by replaying fuzzed NGAP packets thanks to the tool NetworkFuzzer. In this case, VMware was used to simulate a virtual machine running Ubuntu 22.04; the virtual machine also has 4 GB of memory, 2 processors and 25 GB of hard disk drive.
Open5Gs and NetworkFuzzer could be downloaded by following tutorials on their GitHub pages. 
Note that it's critical to change reference protocol from DICOM to SCTP, and select the correct IP and port in NetworkFuzzer configuration file.

At first there were used two different .xml rules to fuzz packets from a PCAP file: 
- The first one takes a valid NGAP packet, forwards it, then creates three versions of the same packet by changing a specific attribute with a random value in a defined range each time (fuzzNGAPvalues.xml);
- The second one replaces the first 20 bytes of the packet's NGAP protocol with a random buffer (fuzzNGAPpackets.xml).

To make the release, a .sh file was created (run_amf_fuzz_tests.sh), a benchmarking script that starts NetworkFuzzer by using different values of copies sent for each packet (10, 100, 500, 1000, 5000 and 8000) and periodically records the CPU and memory usage of the AMF by saving it in a CSV file.

Using a MATLAB script (AMFUsageDataAnalysis.m), the data collected in the.csv files were analyzed, noting that only a small portion of the 4 GB of memory was exploited by the AMF, making it impossible to obtain a denial of service, however, it was still possible to note that the second fuzzing rule produced greater memory and CPU usage by the AMF.

Given the higher usage of CPU and Memory, the second fuzzing rule was chosen and memory limits for the AMF of 80, 100, 250 and 500 MB respectively were set (in the systemctl configuration file of the AMF service you must also set no to the MemorySwap entry and no to the Restart entry). Also in this case, thanks to the .sh file, the fuzzer command was launched by varying the number of copies sent for each file; specifically, for each MemoryLimit, 5 different tests were performed, thus obtaining 5 .csv files for each limit. In this case too, the data obtained were analyzed using a MATLAB script (MemoryLimitCompare.m).

In this case, it is possible to notice how the AMF process is killed immediately when it exceeds the MemoryLimit, thus causing the users connected to it to disconnect. The fuzzer itself is also no longer able to connect to the AMF, thus reaching the Denial of Service sought for this work. From the tests carried out, it is possible to note that the only case in which a denial of service is not achieved is the one with a memory limit of 500 MB.
