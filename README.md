# mask-number-script
Perl Script to mask number from custom position and rules

```
Number Mask Script v1.0,
    used to mask the sensetive data from files ,
Options:,
    --help              print this usage msg,
    --input_file        full path of input_file to be masked,
    --output_file       full path of output_file to be masked,
    --rules_file        (optional)full path of rules file to be used note file must contain a hash of rules perl format
                           every hash value will be regex or code ref,
    --start_position    (optional)start position of the string to be replaced note will count from 0
                           default is 103,
    --debug             (optional) print debug messages,

example:
        perl mask_data.pl --input_file=/tmp/input.txt --output_file=/tmp/output.txt --rules_file=rules.txt
example2:
        perl mask_data.pl --input_file=input.txt --output_file=output.txt,
```