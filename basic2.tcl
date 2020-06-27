# basic2.tcl simulation:
#1             5
# \           /
#  3 - - - - 4
# /           \
#2             6

#3 and 4 are routers
#1,2,5,6 are hosts
#Create a simulator object
set ns [new Simulator]

set time_incr 1
# ?
#set tcp0 [new Agent/TCP]
#set tcp1 [new Agent/TCP]

#get commandline argumet
set TcpMode [lindex $argv 0]
set SimulationNo [lindex $argv 1]


if {$TcpMode == "Newreno"} {
    set tcp0 [new Agent/TCP/Newreno]
    set tcp1 [new Agent/TCP/Newreno]
} elseif {$TcpMode == "Tahoe"} {
    set tcp0 [new Agent/TCP]
    set tcp1 [new Agent/TCP]
} elseif {$TcpMode == "Vegas"} {
    set tcp0 [new Agent/TCP/Vegas]
    set tcp1 [new Agent/TCP/Vegas]
}

set cwndTraceFile0 [open [format "%s/flow%d/cwnd/trace%d.txt" $TcpMode 0 $SimulationNo] w]
set cwndTraceFile1 [open [format "%s/flow%d/cwnd/trace%d.txt" $TcpMode 1 $SimulationNo] w]

set rttTraceFile0 [open [format "%s/flow%d/rtt/trace%d.txt" $TcpMode 0 $SimulationNo] w]
set rttTraceFile1 [open [format "%s/flow%d/rtt/trace%d.txt" $TcpMode 1 $SimulationNo] w]

set goodPutTraceFile0 [open [format "%s/flow%d/goodPut/trace%d.txt" $TcpMode 0 $SimulationNo] w]
set goodPutTraceFile1 [open [format "%s/flow%d/goodPut/trace%d.txt" $TcpMode 1 $SimulationNo] w]

set namfile [open basic2.nam w]
$ns namtrace-all $namfile
set tracefile [open [format "%s/packetLoss/trace%d.tr" $TcpMode $SimulationNo] w]
$ns trace-all $tracefile

#Define a 'finish' procedure
proc finish {} {
        global ns namfile tracefile cwndTraceFile0 cwndTraceFile1 rttTraceFile0 rttTraceFile1 goodPutTraceFile0 goodPutTraceFile1
        $ns flush-trace
        close $namfile
        close $tracefile
        close $cwndTraceFile0
        close $cwndTraceFile1
        close $rttTraceFile0
        close $rttTraceFile1
        close $goodPutTraceFile0
        close $goodPutTraceFile1

        exit 0
}



proc plotCWND {tcpSource outfile} {
   global ns
   global time_incr
   set now [$ns now]
   set cwnd_ [$tcpSource set cwnd_]

   puts  $outfile  "$now $cwnd_"
   $ns at [expr $now + $time_incr] "plotCWND $tcpSource  $outfile"
}

# Define "TraceApp" as a child class of "Application"
Class TraceGoodPutApp -superclass Application

# Define (override) "init" method to create "TraceApp" object
TraceGoodPutApp instproc init {outfile} {
    $self set bytes_ 0
    $self set outFile_ $outfile
    eval $self next $outfile
}

# Define (override) "recv" method for "TraceApp" object
TraceGoodPutApp instproc recv {byte} {
    global ns
    $self instvar bytes_
    set bytes_ [expr $bytes_ + $byte]

    #$self instvar outFile_
    #set now [$ns now]
    #puts $outFile_ "$now $bytes_"

    return $bytes_
}

proc plotGoodPut {tcpSink outfile} {
    global ns time_incr
    set now [$ns now]
    set nbytes [$tcpSink set bytes_]
    set goodPut [expr ($nbytes * 8) / $time_incr]

    $tcpSink set bytes_ 0
    puts $outfile "$now $goodPut"
    $ns at [expr $now + $time_incr] "plotGoodPut $tcpSink  $outfile"

}

proc plotRTT {tcpSource outfile} {
    global ns time_incr
    set now [$ns now]
    set rtt [$tcpSource set rtt_]
    puts $outfile "$now $rtt"
    $ns at [expr $now + $time_incr] "plotRTT $tcpSource  $outfile"

}




#Create the network nodes
set H1 [$ns node]
set H2 [$ns node]
set R3 [$ns node]
set R4 [$ns node]
set H5 [$ns node]
set H6 [$ns node]



#creating random number
proc randomGenerator {} {
    expr { ((rand() * 20 +5)*1.0) / 1000}
}

set randomDelay0 [randomGenerator]
set randomDelay1 [randomGenerator]
set randomDelay2 [randomGenerator]
set randomDelay3 [randomGenerator]
puts stdout "$randomDelay0 $randomDelay1"

#Create a duplex link between the nodes
#$ns duplex-link $H1 $R3 100Mb 5ms DropTail
#Create simplex-link between node to set queue link to links that is desired

$ns simplex-link $H1 $R3 100Mb 5ms DropTail
$ns simplex-link $R3 $H1 100Mb 5ms DropTail

#todo:We have to add variable delay
$ns simplex-link $H2 $R3 100Mb $randomDelay0 DropTail
$ns simplex-link $R3 $H2 100Mb $randomDelay2 DropTail

#$ns duplex-link $R3 $R4 100kb 1ms DropTail
$ns simplex-link $R3 $R4 100kb 1ms DropTail
$ns simplex-link $R4 $R3 100kb 1ms DropTail

#$ns duplex-link $R4 $H5 100Mb 5ms DropTail
$ns simplex-link $R4 $H5 100Mb 5ms DropTail
$ns simplex-link $H5 $R4 100Mb 5ms DropTail
#todo:We have to add variable delay
$ns simplex-link $R4 $H6 100Mb $randomDelay1 DropTail
$ns simplex-link $H6 $R4 100Mb $randomDelay3 DropTail

#queue size
#3 -> 1
$ns queue-limit $R3 $H1 10
#3 -> 2
$ns queue-limit $R3 $H2 10
#3 -> 4
$ns queue-limit $R3 $R4 10
#4 -> 3
$ns queue-limit $R4 $R3 10
#4 -> 5
$ns queue-limit $R4 $H5 10
#4 -> 6
$ns queue-limit $R4 $H6 10

# some hints for nam
# color packets of flow 0 red
$ns color 0 Red
# color packets of flow 1 blue
$ns color 1 Blue
$ns simplex-link-op $H1 $R3 orient right-down
$ns simplex-link-op $R3 $H1 orient left-up

$ns simplex-link-op $H2 $R3 orient right-up
$ns simplex-link-op $R3 $H2 orient left-down


#$ns duplex-link-op $H1 $R3 queuePos 0.5
#$ns duplex-link-op $H2 $R3 queuePos 0.5
$ns simplex-link-op $R3 $R4 orient right
$ns simplex-link-op $R4 $R3 orient left

$ns simplex-link-op $R4 $H5 orient right-up
$ns simplex-link-op $H5 $R4 orient left-down

$ns simplex-link-op $R4 $H6 orient right-down
$ns simplex-link-op $H6 $R4 orient left-up
#$ns duplex-link-op $R4 $H5 queuePos 0.5
#$ns duplex-link-op $R4 $H6 queuePos 0.5


$tcp0 set class_ 0
$tcp0 set window_ 100
$tcp0 set packetSize_ 1000
$ns attach-agent $H1 $tcp0

$tcp1 set class_ 1
$tcp1 set window_ 100
$tcp1 set packetSize_ 1000
$ns attach-agent $H2 $tcp1

#ttl
$tcp1 set ttl_ 64
$tcp0 set ttl_ 64
#rtt
$tcp1 tracevar rtt_
$tcp0 tracevar rtt_

# Let's trace some variables
#$tcp0 attach $tracefile
#$tcp0 tracevar cwnd_
#$tcp0 tracevar ssthresh_
#$tcp0 tracevar ack_
#$tcp0 tracevar maxseq_
# Let's trace some variables
#$tcp1 attach $tracefile
#$tcp1 tracevar cwnd_
#$tcp1 tracevar ssthresh_
#$tcp1 tracevar ack_
#$tcp1 tracevar maxseq_



#Create a TCP receive agent (a traffic sink) and attach it to H5
set end0 [new Agent/TCPSink]
$ns attach-agent $H5 $end0
#Create a TCP receive agent (a traffic sink) and attach it to H6
set end1 [new Agent/TCPSink]
$ns attach-agent $H6 $end1

#Connect the traffic source with the traffic sink
$ns connect $tcp0 $end0
$ns connect $tcp1 $end1

#Schedule the connection data flow; start sending data at T=0, stop at T=10.0
set myftp [new Application/FTP]
$myftp attach-agent $tcp0
set myftp1 [new Application/FTP]
$myftp1 attach-agent $tcp1



set traceGoodPut0 [new TraceGoodPutApp $goodPutTraceFile0]
$traceGoodPut0 attach-agent $end0
set traceGoodPut1 [new TraceGoodPutApp $goodPutTraceFile1]
$traceGoodPut1 attach-agent $end1

$ns  at  0.0  "$traceGoodPut0  start"   ;# Start the traceapp object
$ns  at  0.0  "$traceGoodPut1  start"   ;# Start the traceapp object

$ns at 0.0 "$myftp start"
$ns at 0.0 "$myftp1 start"

$ns  at  0.0  "plotGoodPut $traceGoodPut0  $goodPutTraceFile0"
$ns  at  0.0  "plotGoodPut $traceGoodPut1  $goodPutTraceFile1"

$ns  at  0.0  "plotCWND $tcp0  $cwndTraceFile0"
$ns  at  0.0  "plotCWND $tcp1  $cwndTraceFile1"

$ns  at  0.0  "plotRTT $tcp0  $rttTraceFile0"
$ns  at  0.0  "plotRTT $tcp1  $rttTraceFile1"

$ns at 1000.0 "finish"




#Run the simulation
$ns run
