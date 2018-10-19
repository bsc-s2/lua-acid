This is a test about the sm3 performance

The test result:

t/sm3.t .. TEST 1: sm3   
weighttp -c2 -k -n2000 http://127.0.0.1:1984/t   
weighttp 0.4 - a lightweight and simple webserver benchmarking tool   

starting benchmark...
spawning thread #1: 2 concurrent requests, 2000 total requests   
progress:  10% done   
progress:  20% done   
progress:  30% done   
progress:  40% done   
progress:  50% done   
progress:  60% done   
progress:  70% done   
progress:  80% done   
progress:  90% done   
progress: 100% done   

finished in 0 sec, 96 millisec and 516 microsec, 20721 req/s, 6170 kbyte/s   
requests: 2000 total, 2000 started, 2000 done, 2000 succeeded, 0 failed, 0
errored   
status codes: 2000 2xx, 0 3xx, 0 4xx, 0 5xx   
traffic: 609851 bytes total, 323905 bytes http, 285946 bytes data   
t/sm3.t .. ok   
All tests successful.   
Files=1, Tests=2,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.16 cusr  0.08 csys
=  0.26 CPU)   
Result: PASS   
