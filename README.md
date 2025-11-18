# Master-s-thesis-Project
Fuzzing to Open5Gs AMF with the intent to create a Denial of Service.

Starting from known vulnerabilities of the Open5Gs AMF in version 2.3.2, the objective of this project is to carry out a denial of service at the actual version of Open5Gs, by replaying fuzzed NGAP packets thanks to the tool NetworkFuzzer. In this case, VMware was used to simulate a virtual machine running Ubuntu 22.04; the virtual machine also has 4 GB of memory, 2 processors and 25 GB of hard disk drive.
Open5Gs and NetworkFuzzer could be downloaded by following tutorials on their GitHub pages. 
Note that it's critical to change networkfuzzer.conf file by changing in "forward" section:

        target-protocols = { SCTP }
        target-hosts     = { "127.0.0.5" }
        target-ports     = { 38412 }       # port SCTP for NGAP

At first there were used two different .xml rules to fuzz packets from a [pcap file](PCAP_File/5g-sa.pcap): 
- The [first one](XML_Rules/fuzzNGAPvalues.xml) takes a valid NGAP packet, forwards it, then creates three versions of the same packet by changing a specific attribute with a random value in a defined range each time;
- The [second one](XML_Rules/fuzzNGAPpackets.xml) replaces the first 20 bytes of the packet's NGAP protocol with a random buffer.

To activate a rule, it's needed to compile the .xml file, thereby creating the .so file; to change the fuzzing rule, the .so file was deleted and the other rule was compiled. With the info command, it is possible to check which rules are considered by the fuzzer.

To make the release, a [.sh file](File_.sh/run_amf_fuzz_tests.sh) was created, a benchmarking script that starts NetworkFuzzer by using different values of copies sent for each packet (10, 100, 500, 1000, 5000 and 8000) and periodically records the CPU and memory usage of the AMF by saving it in 
[CSV file](csv_file/FuzzCompare).

Using a [MATLAB script](MATLAB_Scripts/AMFUsageDataAnalysis.m), the data collected in the.csv files were analyzed, noting that only a small portion of the 4 GB of memory was exploited by the AMF, making it impossible to obtain a denial of service, however, it was still possible to note that the second fuzzing rule produced greater memory and CPU usage by the AMF.

Given the higher usage of CPU and Memory, the second fuzzing rule was chosen and memory limits for the AMF of 80, 100, 250 and 500 MB respectively were set; to change the memory limit it must be used command

         sudo systemctl edit open5gs-amfd.service

and must be added

        [Service]
        MemoryMax=500M # here must be choose the memory limit
        MemorySwapMax=0
        Restart=no

to ovverride the configuration file.
 
Also in this case, thanks to the [.sh file](File_.sh/run_amf_fuzz_tests.sh), the fuzzer command was launched by varying the number of copies sent for each file; specifically, for each MemoryLimit, 5 different tests were performed, thus obtaining [5 .csv files](csv_file/MemLimitCompare) for each limit. In this case too, the data obtained were analyzed using a [MATLAB script](MATLAB_Scripts/MemoryLimitCompare.m).

It is possible to notice how the AMF process is killed immediately when it exceeds the MemoryLimit, thus causing the users connected to it to disconnect. The fuzzer itself is also no longer able to connect to the AMF, thus reaching the Denial of Service sought for this work. From the tests carried out, it is possible to note that the only case in which a denial of service is not achieved is the one with a memory limit of 500 MB.

All results are shown in [Results](Results) folder.
