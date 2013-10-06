Config { font = "-misc-fixed-*-*-*-*-10-*-*-*-*-*-*-*"
       , bgColor = "black"
       , fgColor = "grey"
       , position = Top
       , lowerOnStart = True
       , commands = [ Run Network "wlan0" ["-L","0","-H","32","-n","green","-h","red"] 10
                    , Run Cpu ["-L","8 ","-H","64","-n","green","-h","red"] 10
                    , Run CpuFreq ["-t","<cpu0>"] 10
                    , Run Battery ["-t","<left>% = <timeleft>","-L","50","-H","75","-h","green","-n","yell","-l","red"] 10
                    , Run ThermalZone 0 ["-t","<temp> C","-L","40","-H","79","-h","red","-n","yellow","-l","green"] 10
                    , Run Memory ["-t","<usedratio>%"] 10
                    , Run Swap ["-t","<usedratio>%"] 10
                    , Run Date "%a %_d/%m %H:%M" "date" 10
                    , Run StdinReader
                    ]
       , sepChar = "%"
       , alignSep = "}{"
       , template = "%StdinReader% }{ %cpu% @ %cpufreq% | Memory: %memory% * Swap: %swap% | %wlan0% | %battery% | %thermal0% | <fc=#dd3377>%date%</fc>"
       }